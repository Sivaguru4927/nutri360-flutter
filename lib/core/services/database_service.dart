// =============================================================================
// FILE: database_service.dart
// PURPOSE: Provides all CRUD operations for the Nutri360 Supabase Postgres
//          database.  Covers four domain areas:
//            • Children        (table: children)
//            • Growth records  (table: growth_records)
//            • Share codes     (tables: share_codes, health_worker_access)
//            • Worker children (JOIN view across children + health_worker_access)
//
// WHY IT EXISTS: Centralising every Supabase query here keeps screens and
//   BLoCs free of raw SQL strings and prevents duplicated query logic.  Any
//   schema change only needs to be updated in one place.
//
// PATTERN: Singleton via factory constructor.  Obtain with `DatabaseService()`.
// =============================================================================

import 'dart:math'; // for Random — used when generating share codes

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/child.dart';
import '../models/growth_record.dart';
import '../models/share_code.dart';

// ---------------------------------------------------------------------------
// DatabaseService — singleton
// ---------------------------------------------------------------------------
class DatabaseService {
  // ---- Singleton plumbing --------------------------------------------------
  static final DatabaseService _instance = DatabaseService._internal();

  /// Factory constructor — returns the same instance every call.
  factory DatabaseService() => _instance;
  static DatabaseService get instance => _instance;

  DatabaseService._internal();
  // -------------------------------------------------------------------------

  /// Convenience accessor for the shared Supabase client.
  final SupabaseClient _supabase = Supabase.instance.client;

  // ===========================================================================
  // CHILDREN
  // ===========================================================================

  /// Fetches every child that belongs to [parentId], newest first.
  ///
  /// Query:
  ///   SELECT * FROM children WHERE parent_id = $parentId ORDER BY created_at DESC
  ///
  /// Returns an empty list (never throws) when the parent has no children yet,
  /// so callers can safely display an empty-state widget without null checks.
  Future<List<Child>> getParentChildren(String parentId) async {
    final rows = await _supabase
        .from('children')
        .select()
        .eq('parent_id', parentId)
        .order('created_at', ascending: false);

    // Map each raw JSON row to a typed Child model.
    return (rows as List<dynamic>)
        .map((row) => Child.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a single child by its primary key [childId].
  Future<Child?> getChildById(String childId) async {
    final row = await _supabase
        .from('children')
        .select()
        .eq('id', childId)
        .maybeSingle();

    if (row == null) return null;
    return Child.fromJson(row as Map<String, dynamic>);
  }

  /// Inserts a new child record for [parentId] and returns the inserted row
  /// (including the database-generated UUID and timestamps).
  ///
  /// We use `.select().single()` after the insert to retrieve the auto-
  /// generated fields (`id`, `created_at`) without a separate SELECT query.
  ///
  /// Query:
  ///   INSERT INTO children (parent_id, name, dob, sex, height_cm, weight_kg, ...)
  ///   VALUES (...) RETURNING *
  Future<Child> addChild(String parentId, Child child) async {
    // Build the payload — `id` is omitted so Postgres generates a UUID.
    final payload = {
      'parent_id': parentId,
      ...child.toInsertJson(), // Child model exposes a map without 'id'
    };

    final row = await _supabase
        .from('children')
        .insert(payload)
        .select()
        .single();

    return Child.fromJson(row as Map<String, dynamic>);
  }

  /// Updates mutable fields of an existing child record and returns the
  /// freshly-updated row from the database.
  ///
  /// We update by primary key (`id`) and re-fetch with `.select().single()`
  /// so the returned model always reflects the server's authoritative state
  /// (e.g. server-side `updated_at` triggers).
  ///
  /// Query:
  ///   UPDATE children SET name=$name, dob=$dob, ... WHERE id=$id RETURNING *
  Future<Child> updateChild(Child child) async {
    final row = await _supabase
        .from('children')
        .update(child.toUpdateJson()) // excludes immutable fields like id/parent_id
        .eq('id', child.id)
        .select()
        .single();

    return Child.fromJson(row as Map<String, dynamic>);
  }

  /// Hard-deletes a child record by primary key.
  ///
  /// NOTE: Supabase cascades this delete to `growth_records`, `nutrition_records`,
  /// and `share_codes` via FK constraints defined in the schema migrations.
  /// There is no soft-delete — this action is permanent.
  ///
  /// Query:
  ///   DELETE FROM children WHERE id = $childId
  Future<void> deleteChild(String childId) async {
    await _supabase.from('children').delete().eq('id', childId);
  }

  // ===========================================================================
  // GROWTH RECORDS
  // ===========================================================================

  /// Retrieves the 20 most recent growth measurements for [childId].
  ///
  /// Limiting to 20 keeps the payload small for the chart widgets.  If the
  /// full history is ever needed, the caller should pass pagination params
  /// through a separate method (not implemented here to avoid premature
  /// over-engineering).
  ///
  /// Query:
  ///   SELECT * FROM growth_records WHERE child_id = $childId
  ///   ORDER BY measurement_date DESC LIMIT 20
  Future<List<GrowthRecord>> getGrowthHistory(String childId) async {
    final rows = await _supabase
        .from('growth_records')
        .select()
        .eq('child_id', childId)
        .order('measurement_date', ascending: false)
        .limit(20);

    return (rows as List<dynamic>)
        .map((row) => GrowthRecord.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Inserts a growth measurement record and returns the persisted row.
  ///
  /// This is called both by the online save path in the Growth screen and by
  /// `OfflineStore._flushQueues()` when records queued offline are synced.
  ///
  /// Query:
  ///   INSERT INTO growth_records (child_id, weight_kg, height_cm, muac_cm,
  ///     measurement_date, recorded_by, classification)
  ///   VALUES (...) RETURNING *
  Future<GrowthRecord> saveGrowthRecord(GrowthRecord record) async {
    final row = await _supabase
        .from('growth_records')
        .insert(record.toInsertJson())
        .select()
        .single();

    return GrowthRecord.fromJson(row as Map<String, dynamic>);
  }

  // ===========================================================================
  // SHARE CODES
  // ===========================================================================

  /// Generates a unique share code and stores it, then returns the new record.
  ///
  /// Share codes let a parent grant a health worker read access to one child's
  /// data for a 7-day window.  The code format is `NTR-XXXXXX` where X is an
  /// uppercase alphanumeric character.  Collision probability at this length
  /// is negligible for the expected user base (~1 in 2.1 billion per code).
  ///
  /// Query:
  ///   INSERT INTO share_codes
  ///     (code, child_id, child_name, created_by_parent, is_active, created_at)
  ///   VALUES (...) RETURNING *
  Future<ShareCode> generateShareCode(
    String childId,
    String childName,
    String parentId,
  ) async {
    final code = _buildShareCode(); // e.g. 'NTR-K3X9PW'

    final payload = {
      'code': code,
      'child_id': childId,
      'child_name': childName,
      'created_by_parent': parentId,
      'is_active': true,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    final row = await _supabase
        .from('share_codes')
        .insert(payload)
        .select()
        .single();

    return ShareCode.fromJson(row as Map<String, dynamic>);
  }

  /// Redeems a share code entered by a health worker, grants them access to the
  /// linked child, and returns the Child record.
  ///
  /// Validation steps (in order):
  ///   1. Find an active share code row matching [code] (case-insensitive).
  ///   2. Check whether the code was created more than 7 days ago — if so, it
  ///      has expired.  We expire in code rather than via a DB trigger so that
  ///      offline clients can display the right error message without a network
  ///      round-trip.
  ///   3. Insert a row into `health_worker_access` to record the grant.
  ///   4. Fetch and return the linked Child.
  ///
  /// Throws [Exception] with a user-friendly message on each failure path.
  Future<Child?> redeemShareCode(String code, String workerId) async {
    // Normalise to uppercase so codes like 'ntr-k3x9pw' still match.
    final normalisedCode = code.trim().toUpperCase();

    // Step 1: Look up the share code.
    final shareRow = await _supabase
        .from('share_codes')
        .select()
        .eq('code', normalisedCode)
        .eq('is_active', true)
        .maybeSingle();

    if (shareRow == null) {
      throw Exception('Share code not found or already used.');
    }

    // Step 2: Check expiry — codes are valid for 7 days after creation.
    final createdAt = DateTime.parse(shareRow['created_at'] as String);
    final age = DateTime.now().toUtc().difference(createdAt);
    if (age.inDays >= 7) {
      throw Exception('Share code has expired');
    }

    final childId = shareRow['child_id'] as String;

    // Step 3: Grant health_worker_access.  Using `upsert` with ignoreDuplicates
    // so re-scanning the same code doesn't throw a unique constraint error.
    await _supabase.from('health_worker_access').upsert(
      {
        'worker_id': workerId,
        'child_id': childId,
        'granted_via_code': normalisedCode,
        'is_active': true,
        'granted_at': DateTime.now().toUtc().toIso8601String(),
      },
      ignoreDuplicates: true,
    );

    // Step 4: Fetch and return the child.
    final childRow = await _supabase
        .from('children')
        .select()
        .eq('id', childId)
        .maybeSingle();

    if (childRow == null) return null;
    return Child.fromJson(childRow as Map<String, dynamic>);
  }

  /// Revokes a share code so it can no longer be redeemed.
  ///
  /// We soft-delete by setting `is_active = false` rather than deleting the row
  /// so that audit logs remain intact.
  ///
  /// Query:
  ///   UPDATE share_codes SET is_active = false WHERE id = $shareCodeId
  Future<void> revokeShareCode(String shareCodeId) async {
    await _supabase
        .from('share_codes')
        .update({'is_active': false})
        .eq('id', shareCodeId);
  }

  // ===========================================================================
  // WORKER — children they have access to
  // ===========================================================================

  /// Fetches all children that [workerId] is currently authorised to view.
  ///
  /// Uses Supabase's foreign-table syntax to express the JOIN:
  ///   SELECT children.* FROM children
  ///   JOIN health_worker_access ON children.id = health_worker_access.child_id
  ///   WHERE health_worker_access.worker_id = $workerId
  ///     AND health_worker_access.is_active = true
  ///
  /// The `!inner` hint in the select string tells PostgREST to treat the join
  /// as INNER JOIN (only return children that have a matching access row).
  Future<List<Child>> getWorkerChildren(String workerId) async {
    // PostgREST resource embedding: `health_worker_access!inner(worker_id,is_active)`
    // filters to rows where the join condition is met.
    final rows = await _supabase
        .from('children')
        .select('*, health_worker_access!inner(worker_id, is_active)')
        .eq('health_worker_access.worker_id', workerId)
        .eq('health_worker_access.is_active', true);

    return (rows as List<dynamic>)
        .map((row) => Child.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  // ===========================================================================
  // PRIVATE HELPERS
  // ===========================================================================

  /// Generates a random share code in the format `NTR-XXXXXX`.
  ///
  /// Uses only uppercase A–Z and digits 0–9 (36 chars), excluding visually
  /// ambiguous characters (0/O, 1/I) to reduce user transcription errors.
  String _buildShareCode() {
    // Alphabet deliberately excludes '0', 'O', '1', 'I' for legibility.
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure(); // Cryptographically secure RNG.
    final suffix = List.generate(6, (_) => alphabet[rng.nextInt(alphabet.length)])
        .join();
    return 'NTR-$suffix';
  }
}
