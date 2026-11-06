// =============================================================================
// FILE: user.dart
// WHAT: Defines the [User] model and [UserRole] enum for authenticated users
//       of the Nutri360 platform.
// WHY:  Ported from the TypeScript `User` interface (src/types/index.ts) to
//       give Flutter code compile-time safety on user roles, clean JSON
//       round-trip support, and a set of static demo instances that mirror
//       the demo accounts used in the original React Native app's mock data.
//
//       The static demo instances ([User.demoParent] / [User.demoWorker]) are
//       used in development, Storybook-style widget previews, and integration
//       tests — no real Firebase credentials are needed to render the UI.
// =============================================================================

/// Roles that determine which screens and actions are available to a user.
///
/// The enum order matches the privilege hierarchy:
///   parent < health_worker < clinician < admin
enum UserRole {
  /// A parent / guardian who can view their own child's data and share
  /// screening access codes with health workers.
  parent,

  /// An Anganwadi or PHC field worker who performs screenings and can
  /// redeem share codes to access child records.
  healthWorker,

  /// A clinical dietitian or paediatrician who reviews flagged records and
  /// adds intervention notes.
  clinician,

  /// A platform administrator with full CRUD access to all records.
  admin;

  /// Serialises to the snake_case string stored in Firestore / JWT claims.
  String toJson() {
    switch (this) {
      case UserRole.parent:
        return 'parent';
      case UserRole.healthWorker:
        return 'health_worker';
      case UserRole.clinician:
        return 'clinician';
      case UserRole.admin:
        return 'admin';
    }
  }

  /// Deserialises from the backend snake_case string.
  static UserRole fromJson(String value) {
    switch (value) {
      case 'parent':
        return UserRole.parent;
      case 'health_worker':
        return UserRole.healthWorker;
      case 'clinician':
        return UserRole.clinician;
      case 'admin':
        return UserRole.admin;
      default:
        // Fail loudly so misconfigured Firestore documents surface quickly.
        throw ArgumentError('Unknown UserRole value: "$value"');
    }
  }

  /// A display-friendly label for use in UI chips, dropdowns, and audit logs.
  String get displayLabel {
    switch (this) {
      case UserRole.parent:
        return 'Parent / Guardian';
      case UserRole.healthWorker:
        return 'Health Worker';
      case UserRole.clinician:
        return 'Clinician';
      case UserRole.admin:
        return 'Administrator';
    }
  }
}

/// Represents an authenticated user of the Nutri360 platform.
///
/// Obtained from Firebase Auth + a Firestore `/users/{uid}` document that
/// stores the role and supplementary profile fields.
class User {
  // ── Identity ──────────────────────────────────────────────────────────────

  /// Firebase UID – used as the Firestore document ID.
  final String id;

  /// Email address used for Firebase Auth login.
  final String email;

  /// Display name shown in the app header and audit logs.
  final String name;

  // ── Role & Access ─────────────────────────────────────────────────────────

  /// The user's role, which drives navigation guards and Firestore rules.
  final UserRole role;

  /// Government / NGO worker ID, e.g. "HW-ANG-4019".
  ///
  /// Non-null for [UserRole.healthWorker] and [UserRole.clinician] accounts;
  /// null for parents and admins.
  final String? workerId;

  /// Name of the organisation the user belongs to, e.g. "Anganwadi Center 12".
  ///
  /// Used in PDF report headers and for filtering records by facility.
  final String? organization;

  // ── Constructor ───────────────────────────────────────────────────────────

  /// Creates an immutable [User].
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.workerId,
    this.organization,
  });

  // ── Static Demo Instances ─────────────────────────────────────────────────

  /// A demo **parent** account pre-populated with realistic Indian data.
  ///
  /// Useful for widget tests, Storybook previews, and onboarding screenshots
  /// without hitting Firebase.
  static const User demoParent = User(
    id: 'a1111111-1111-1111-1111-111111111111',
    email: 'pooja.parent@nutri360.org',
    name: 'Pooja Sharma',
    role: UserRole.parent,
    // Parents typically don't have a workerId or organisation.
    workerId: null,
    organization: null,
  );

  /// A demo **health worker** account representing an Anganwadi field worker.
  ///
  /// Used in health-worker-specific widget tests and demo flows.
  static const User demoWorker = User(
    id: 'b2222222-2222-2222-2222-222222222222',
    email: 'rekha.worker@anganwadi.gov.in',
    name: 'Rekha Devi',
    role: UserRole.healthWorker,
    workerId: 'HW-ANG-4019',
    organization: 'Anganwadi Center 12',
  );

  // ── Serialisation ─────────────────────────────────────────────────────────

  /// Deserialises a [User] from a Firestore document snapshot's data map.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: UserRole.fromJson(json['role'] as String),
      workerId: json['workerId'] as String?,
      organization: json['organization'] as String?,
    );
  }

  /// Serialises to a [Map] suitable for Firestore writes or REST bodies.
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role.toJson(),
        'workerId': workerId,
        'organization': organization,
      };

  // ── copyWith ──────────────────────────────────────────────────────────────

  /// Returns a new [User] with selected fields replaced.
  ///
  /// Nullable fields ([workerId], [organization]) use the sentinel pattern
  /// so callers can explicitly clear them by passing `null`.
  User copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    Object? workerId = _sentinel,
    Object? organization = _sentinel,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      workerId: workerId == _sentinel ? this.workerId : workerId as String?,
      organization: organization == _sentinel
          ? this.organization
          : organization as String?,
    );
  }

  @override
  String toString() =>
      'User(id: $id, name: $name, role: ${role.toJson()})';
}

// Private sentinel used by [copyWith] to distinguish "not passed" from null.
const Object _sentinel = Object();
