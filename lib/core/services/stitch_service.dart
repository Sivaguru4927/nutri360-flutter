// =============================================================================
// FILE: stitch_service.dart
// PURPOSE: Integrates MongoDB Atlas App Services (formerly Stitch) alongside
//          Supabase as a secondary data layer for the Nutri360 app.
//
// DUAL-DATABASE ARCHITECTURE:
//   • Supabase  — primary transactional store (children, growth records, auth)
//   • MongoDB Atlas — analytics + serverless functions layer, used for:
//       1. Device Sync   — replicates screening data to Atlas as a durable
//                          second copy, enabling cross-region analytics and
//                          potential offline device-sync via Realm SDK.
//       2. Triggers      — Atlas Database Triggers fire serverless Functions
//                          when new referrals are inserted into Supabase
//                          (via a Change Stream connector set up in Atlas).
//       3. Functions     — Atlas Functions provide AI-generated referral
//                          summaries (powered by a hosted LLM integration
//                          configured in the Atlas Functions console).
//
// WHY THIS FILE EXISTS: Separating Atlas concerns into a dedicated service keeps
//   the DatabaseService (Supabase) clean and makes the Atlas layer swappable.
//   If Atlas is decommissioned or migrated, only this file needs to change.
//
// ENVIRONMENT VARIABLES (loaded via flutter_dotenv from .env):
//   ATLAS_APP_ID   — the Atlas App Services application ID (e.g. 'nutri360-abcde')
//   ATLAS_BASE_URL — base URL for the Atlas Data API
//                    (e.g. 'https://data.mongodb-api.com')
//   ATLAS_API_KEY  — Atlas Data API key for server-to-server auth
//
// PATTERN: Singleton via factory constructor.  Obtain with `StitchService()`.
// =============================================================================

import 'dart:convert'; // json encode/decode

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// StitchService — singleton
// ---------------------------------------------------------------------------
class StitchService {
  // ---- Singleton plumbing --------------------------------------------------
  static final StitchService _instance = StitchService._internal();

  /// Factory constructor — always returns the same instance.
  factory StitchService() => _instance;
  static StitchService get instance => _instance;

  StitchService._internal();
  // -------------------------------------------------------------------------

  // ---- Configuration (populated during init()) ----------------------------
  /// The Atlas App Services application ID, e.g. 'nutri360-abcde'.
  late final String _appId;

  /// Base URL for the Atlas Data API, e.g. 'https://data.mongodb-api.com'.
  late final String _baseUrl;

  /// Bearer token / API key used in the Authorization header of every request.
  late final String _apiKey;

  /// Whether the service was successfully initialised with valid env vars.
  /// Analytics calls check this flag before attempting any HTTP request.
  bool _isReady = false;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  /// Reads environment variables and validates that Atlas is properly configured.
  ///
  /// Call this once from `main()` after `dotenv.load()`.  If any required env
  /// var is missing we log a warning and set [_isReady] to false — the service
  /// will then no-op gracefully rather than crash the app, because Atlas is a
  /// secondary (non-critical) layer.
  Future<void> init() async {
    final appId = dotenv.maybeGet('ATLAS_APP_ID');
    final baseUrl = dotenv.maybeGet('ATLAS_BASE_URL');
    final apiKey = dotenv.maybeGet('ATLAS_API_KEY');

    if (appId == null || baseUrl == null || apiKey == null) {
      // ignore: avoid_print
      print(
        '[StitchService] WARNING: One or more Atlas env vars are missing '
        '(ATLAS_APP_ID, ATLAS_BASE_URL, ATLAS_API_KEY). '
        'Atlas features will be silently disabled.',
      );
      _isReady = false;
      return;
    }

    _appId = appId;
    _baseUrl = baseUrl;
    _apiKey = apiKey;
    _isReady = true;

    // ignore: avoid_print
    print('[StitchService] Atlas App Services connected. App ID: $_appId');
  }

  // ===========================================================================
  // DEVICE SYNC — replicate screening data to Atlas
  // ===========================================================================

  /// Inserts a screening record into the Atlas `screenings` collection.
  ///
  /// This is called after every successful growth/screening save in Supabase so
  /// that Atlas receives a copy for analytics, cross-region reporting, and as
  /// the trigger source for serverless referral functions.
  ///
  /// The Atlas Data API endpoint used is:
  ///   POST /app/{appId}/endpoint/data/v1/action/insertOne
  ///
  /// [record] should include at minimum:
  ///   { child_id, weight_kg, height_cm, muac_cm, classification,
  ///     measurement_date, recorded_by_worker_id }
  ///
  /// Throws on HTTP errors so the caller can decide whether to retry or
  /// silently ignore (the UI should NOT crash because Atlas is non-critical).
  Future<void> syncScreeningRecord(Map<String, dynamic> record) async {
    if (!_isReady) {
      // ignore: avoid_print
      print('[StitchService] syncScreeningRecord skipped — service not ready.');
      return;
    }

    final uri = Uri.parse(
      '$_baseUrl/app/$_appId/endpoint/data/v1/action/insertOne',
    );

    final body = jsonEncode({
      'dataSource': 'Nutri360Cluster', // Atlas cluster name configured in App Services
      'database': 'nutri360',
      'collection': 'screenings',
      'document': record,
    });

    final response = await http.post(
      uri,
      headers: _buildHeaders(),
      body: body,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        '[StitchService] syncScreeningRecord failed '
        '(HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }

  // ===========================================================================
  // AI — generate referral summary via Atlas Function
  // ===========================================================================

  /// Calls an Atlas Serverless Function to generate an AI clinical summary for
  /// a child that has been classified as SAM or MAM.
  ///
  /// The Atlas Function (`referral_summary`) is configured in the Atlas App
  /// Services console.  It calls an LLM API (OpenAI / Google PaLM, whichever
  /// is wired up server-side) and returns a plain-text clinical summary
  /// suitable for printing on a referral slip.
  ///
  /// Parameters:
  ///   [childName]      — child's first name (used in the narrative)
  ///   [weightKg]       — latest weight measurement
  ///   [heightCm]       — latest height measurement
  ///   [classification] — 'SAM', 'MAM', or 'Normal'
  ///   [ageMonths]      — child's age in whole months
  ///
  /// Returns the AI-generated summary string on success.
  /// On ANY failure (network, Function error, bad response), returns a
  /// hard-coded fallback summary so the referral screen always has something
  /// useful to display — the UI must NEVER crash due to an Atlas failure.
  Future<String> generateReferralSummary({
    required String childName,
    required double weightKg,
    required double heightCm,
    required String classification,
    required int ageMonths,
  }) async {
    // Build the fallback now so we can return it in every catch block.
    final fallback = _buildFallbackSummary(
      childName: childName,
      weightKg: weightKg,
      heightCm: heightCm,
      classification: classification,
      ageMonths: ageMonths,
    );

    if (!_isReady) return fallback;

    try {
      final uri = Uri.parse(
        '$_baseUrl/app/$_appId/endpoint/referral_summary',
      );

      final body = jsonEncode({
        'child_name': childName,
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'classification': classification,
        'age_months': ageMonths,
      });

      final response = await http
          .post(uri, headers: _buildHeaders(), body: body)
          .timeout(
            const Duration(seconds: 15), // Don't block UI for more than 15 s.
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final summary = data['summary'] as String?;
        // If the function returned an empty or null summary, fall back.
        if (summary != null && summary.trim().isNotEmpty) return summary;
      }

      // Non-200 or empty payload → use fallback.
      // ignore: avoid_print
      print(
        '[StitchService] generateReferralSummary returned '
        'HTTP ${response.statusCode} — using fallback summary.',
      );
      return fallback;
    } catch (e) {
      // Any exception (timeout, network, JSON parse) → use fallback.
      // ignore: avoid_print
      print('[StitchService] generateReferralSummary error: $e');
      return fallback;
    }
  }

  // ===========================================================================
  // ANALYTICS — fire-and-forget event logging
  // ===========================================================================

  /// Logs an analytics event to the Atlas `analytics_events` collection.
  ///
  /// This is intentionally fire-and-forget: the method is `void` (not async
  /// from the caller's perspective), errors are swallowed, and it never blocks
  /// the calling code.  Analytics must NEVER degrade the user experience.
  ///
  /// [eventName] — a snake_case identifier, e.g. 'screening_completed'
  /// [props]     — arbitrary key-value metadata to attach to the event
  ///
  /// A `timestamp` field (UTC ISO-8601) is automatically appended.
  Future<void> logAnalyticsEvent(
    String eventName,
    Map<String, dynamic> props,
  ) async {
    if (!_isReady) return; // Silently skip if Atlas is not configured.

    try {
      final uri = Uri.parse(
        '$_baseUrl/app/$_appId/endpoint/data/v1/action/insertOne',
      );

      final document = {
        'event': eventName,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        ...props,
      };

      final body = jsonEncode({
        'dataSource': 'Nutri360Cluster',
        'database': 'nutri360',
        'collection': 'analytics_events',
        'document': document,
      });

      // We deliberately do not await or check the response — this is
      // fire-and-forget.  The unawaited future is intentional.
      http.post(uri, headers: _buildHeaders(), body: body);
    } catch (e) {
      // Silently swallow — analytics failures must never surface to the user.
      // ignore: avoid_print
      print('[StitchService] logAnalyticsEvent silently failed: $e');
    }
  }

  // ===========================================================================
  // PRIVATE HELPERS
  // ===========================================================================

  /// Builds the standard HTTP headers for every Atlas Data API request.
  ///
  /// The `Authorization: Bearer` token is the Atlas API key.  Some Atlas App
  /// Services configurations use `apiKey` header instead of Bearer — adjust
  /// the header name in the Atlas console if needed.
  Map<String, String> _buildHeaders() => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
        // Optionally set the Atlas app ID header if the endpoint requires it.
        // 'Atlas-App-Id': _appId,
      };

  /// Returns a plain-text clinical summary generated from local data, used as a
  /// fallback when the Atlas Function is unavailable.
  ///
  /// This ensures the referral slip can always be printed even in areas with no
  /// internet connectivity — which is precisely the environment Nutri360 operates
  /// in (rural ICDS centres, PHCs with intermittent connectivity).
  String _buildFallbackSummary({
    required String childName,
    required double weightKg,
    required double heightCm,
    required String classification,
    required int ageMonths,
  }) {
    final years = ageMonths ~/ 12;
    final months = ageMonths % 12;
    final ageStr = years > 0 ? '$years yr $months mo' : '$ageMonths months';

    return '''
Referral Summary — Nutri360

Child Name   : $childName
Age          : $ageStr
Weight       : ${weightKg.toStringAsFixed(1)} kg
Height       : ${heightCm.toStringAsFixed(1)} cm
Status       : $classification

$childName has been assessed and classified as $classification based on 
anthropometric measurements taken today.  Please refer to the nearest 
Nutrition Rehabilitation Centre (NRC) for further evaluation and management 
as per IMNCI/MAM/SAM protocol guidelines.

This summary was generated offline.  Please verify measurements before 
finalising the referral.
'''.trim();
  }
}
