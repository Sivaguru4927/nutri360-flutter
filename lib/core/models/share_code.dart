// =============================================================================
// FILE: share_code.dart
// WHAT: Defines the [ShareCode] model, which represents a one-time 7-character
//       code (format "NTR-XXXXXX") that a parent generates to grant a health
//       worker temporary read access to their child's screening records.
// WHY:  Ported from the TypeScript `ShareCode` interface (src/types/index.ts).
//
//       BUG FIX – [isExpired] computed getter:
//         In the original React Native app the expiry check was missing; the
//         list screen showed ALL codes as valid regardless of age.  The fix
//         defines "expired" as the code being older than 7 days relative to
//         [createdAt].  This getter is the single authoritative expiry
//         definition — do NOT replicate the logic elsewhere.
//
//         Any UI rendering a code should gate on:
//           • [isActive]  – not manually revoked by the parent
//           • [isExpired] – not older than 7 days (this was the bug)
//         Both must be true for a code to be redeemable.
// =============================================================================

/// A short-lived access code that a parent shares with a health worker.
///
/// The health worker enters the code in the "Redeem Code" screen; on success,
/// they receive read-only access to the linked child's growth and nutrition
/// records for 7 days.
class ShareCode {
  // ── Identity ──────────────────────────────────────────────────────────────

  /// Firestore document ID (auto-generated UUID).
  final String id;

  /// The 7-character human-readable code displayed to the parent.
  ///
  /// Format: "NTR-" followed by 6 uppercase alphanumeric characters.
  /// Example: "NTR-A3KP9Z"
  ///
  /// The "NTR" prefix makes it unambiguous that this is a Nutri360 code when
  /// the parent reads it aloud or shares it via WhatsApp.
  final String code;

  // ── Linked Child ──────────────────────────────────────────────────────────

  /// Firestore ID of the child whose records this code grants access to.
  final String childId;

  /// Display name of the child, cached here so the health worker's redemption
  /// screen can show a confirmation without an extra Firestore read.
  final String childName;

  // ── Ownership & Status ────────────────────────────────────────────────────

  /// Firebase UID of the parent who generated this code.
  ///
  /// Used in Firestore security rules to ensure only the owning parent can
  /// revoke the code.
  final String createdByParent;

  /// Whether the parent has explicitly revoked the code.
  ///
  /// A code should only be considered valid when BOTH [isActive] is `true`
  /// AND [isExpired] is `false`.  See [isExpired] for the bug-fix rationale.
  final bool isActive;

  // ── Timestamps ────────────────────────────────────────────────────────────

  /// ISO-8601 timestamp when this code was generated.
  ///
  /// Used by [isExpired] to compute the 7-day TTL.  Stored as a String (not
  /// [DateTime]) for round-trip JSON safety across timezones.
  final String createdAt;

  // ── Constructor ───────────────────────────────────────────────────────────

  /// Creates an immutable [ShareCode].
  const ShareCode({
    required this.id,
    required this.code,
    required this.childId,
    required this.childName,
    required this.createdByParent,
    required this.isActive,
    required this.createdAt,
  });

  // ── Computed Getters ──────────────────────────────────────────────────────

  /// Returns `true` when this code is older than 7 days and should no longer
  /// be accepted by the health worker's redemption flow.
  ///
  /// **Bug fix**: The original React Native app omitted this check entirely,
  /// causing the list screen to show all codes as "Active" regardless of age.
  /// This getter is now the single source of truth for expiry logic; call it
  /// from both the list UI and the cloud function that validates redeemed codes.
  ///
  /// A code is expired when:
  ///   `DateTime.now() – DateTime.parse(createdAt) >= 7 days`
  bool get isExpired {
    final created = DateTime.parse(createdAt);
    // Use UTC to avoid DST-shift edge cases around midnight.
    final age = DateTime.now().toUtc().difference(created.toUtc());
    return age.inDays >= 7;
  }

  /// Convenience getter: `true` only when the code is both active (not revoked)
  /// and within its 7-day validity window.
  ///
  /// Use this in UI rendering and backend validation instead of combining the
  /// two checks manually.
  bool get isRedeemable => isActive && !isExpired;

  // ── Serialisation ─────────────────────────────────────────────────────────

  /// Deserialises from a Firestore / REST JSON map.
  factory ShareCode.fromJson(Map<String, dynamic> json) {
    return ShareCode(
      id: json['id'] as String,
      code: json['code'] as String,
      childId: json['childId'] as String,
      childName: json['childName'] as String,
      createdByParent: json['createdByParent'] as String,
      isActive: json['isActive'] as bool,
      createdAt: json['createdAt'] as String,
    );
  }

  /// Serialises to a JSON-compatible [Map].
  ///
  /// Note: [isExpired] and [isRedeemable] are computed locally and are NOT
  /// included in the serialised output — the backend recomputes them from
  /// [createdAt] and [isActive] to prevent clock-skew exploits.
  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'childId': childId,
        'childName': childName,
        'createdByParent': createdByParent,
        'isActive': isActive,
        'createdAt': createdAt,
      };

  // ── copyWith ──────────────────────────────────────────────────────────────

  /// Returns a new [ShareCode] with selected fields replaced.
  ///
  /// The most common use case is flipping [isActive] to `false` when a parent
  /// revokes a code (before the Firestore write confirms):
  ///
  /// ```dart
  /// final revoked = code.copyWith(isActive: false);
  /// ```
  ShareCode copyWith({
    String? id,
    String? code,
    String? childId,
    String? childName,
    String? createdByParent,
    bool? isActive,
    String? createdAt,
  }) {
    return ShareCode(
      id: id ?? this.id,
      code: code ?? this.code,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      createdByParent: createdByParent ?? this.createdByParent,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'ShareCode(code: $code, childName: $childName, '
      'isActive: $isActive, isExpired: $isExpired)';
}
