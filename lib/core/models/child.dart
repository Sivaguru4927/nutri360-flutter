// =============================================================================
// FILE: child.dart
// WHAT: Defines the [Child] model class representing a child enrolled in the
//       Nutri360 nutrition-screening program.
// WHY:  This is a direct Dart port of the `Child` TypeScript interface from
//       the original React Native app (src/types/index.ts).  Using a typed
//       class (instead of raw Maps) gives us compile-time safety, IDE
//       auto-complete, and clean serialisation for Firestore / REST APIs.
//
//       Key additions over the TS source:
//         • [ageInMonths]  – computed getter; avoids duplicating the logic
//                            everywhere age-based WHO references are needed.
//         • [ageDisplay]   – human-readable string ("1y 3m" / "8m 12d") for
//                            use in list tiles and PDF reports.
// =============================================================================

/// Biological sex options for a child.
///
/// Keeping this as an enum (not a bare String) prevents silent misspellings
/// and makes exhaustive switch/case checks possible in widget code.
enum Sex {
  male,
  female,
  other;

  /// Serialise to the lowercase string stored in the backend.
  String toJson() => name; // 'male' | 'female' | 'other'

  /// Deserialise from a backend string.
  static Sex fromJson(String value) =>
      Sex.values.firstWhere(
        (s) => s.name == value.toLowerCase(),
        orElse: () => Sex.other,
      );
}

/// Represents a single child record in the Nutri360 system.
///
/// Instances are typically obtained from Firestore via [Child.fromJson] and
/// sent back via [Child.toJson].  UI code should prefer [copyWith] when
/// updating individual fields so the rest of the object stays intact.
class Child {
  // ── Identity ──────────────────────────────────────────────────────────────

  /// Firestore document ID (auto-generated UUID).
  final String id;

  /// Human-readable ID shown to field workers, e.g. "CHD-2024-001".
  final String childId;

  /// Full name of the child as registered.
  final String name;

  // ── Demographics ──────────────────────────────────────────────────────────

  /// Date of birth as an ISO-8601 date string ("YYYY-MM-DD").
  ///
  /// Stored as a String (not [DateTime]) to avoid timezone-shift bugs when
  /// round-tripping through JSON on devices in different locales.
  final String dob;

  /// Biological sex of the child; used to select the correct WHO growth chart.
  final Sex sex;

  /// Birth status narrative (e.g. "Preterm – 34 weeks"), if recorded.
  final String? birthStatus;

  /// Birth weight in kilograms; null if not measured at birth.
  final double? birthWeight;

  // ── Anthropometrics ───────────────────────────────────────────────────────

  /// Most-recently measured height in centimetres.
  final double heightCm;

  /// Most-recently measured weight in kilograms.
  final double weightKg;

  // ── Contact & Location ────────────────────────────────────────────────────

  /// Name of the screening facility or village, if provided.
  final String? screeningLocation;

  /// Name of the parent / primary guardian, if captured.
  final String? parentName;

  /// Phone number of the parent / primary guardian, if captured.
  final String? parentPhone;

  // ── Timestamps ────────────────────────────────────────────────────────────

  /// ISO-8601 timestamp when this record was first created.
  final String createdAt;

  /// ISO-8601 timestamp when this record was last modified.
  final String updatedAt;

  // ── Constructor ───────────────────────────────────────────────────────────

  /// Creates an immutable [Child] instance.
  const Child({
    required this.id,
    required this.childId,
    required this.name,
    required this.dob,
    required this.sex,
    this.birthStatus,
    this.birthWeight,
    required this.heightCm,
    required this.weightKg,
    this.screeningLocation,
    this.parentName,
    this.parentPhone,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Computed Getters ──────────────────────────────────────────────────────

  /// Returns the child's age expressed as a whole number of completed months
  /// from [dob] to today's date.
  ///
  /// Used for WHO Z-score table lookups (which are indexed by age-in-months).
  int get ageInMonths {
    final birth = DateTime.parse(dob);
    final now = DateTime.now();
    // Count completed calendar months then subtract if the day hasn't arrived.
    int months = (now.year - birth.year) * 12 + (now.month - birth.month);
    if (now.day < birth.day) months--;
    return months < 0 ? 0 : months;
  }

  /// Returns a compact, human-readable age string for display in the UI.
  ///
  /// Examples:
  ///   • A child born exactly 14 months ago → "1y 2m"
  ///   • A child born 8 months and 12 days ago → "8m 12d"
  ///   • A child born today → "0m 0d"
  String get ageDisplay {
    final birth = DateTime.parse(dob);
    final now = DateTime.now();

    int years = now.year - birth.year;
    int months = now.month - birth.month;
    int days = now.day - birth.day;

    // Borrow from months when days are negative.
    if (days < 0) {
      months--;
      // Add the number of days in the previous month.
      final prevMonth = DateTime(now.year, now.month, 0);
      days += prevMonth.day;
    }
    // Borrow from years when months are negative.
    if (months < 0) {
      years--;
      months += 12;
    }

    if (years > 0) {
      // For children ≥ 1 year old show years + months.
      return '${years}y ${months}m';
    }
    // For children < 1 year show months + days (useful for neonates).
    return '${months}m ${days}d';
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  /// Deserialises a [Child] from a Supabase / REST JSON [Map].
  /// Supports both snake_case (Postgres) and camelCase (Firestore/legacy) keys.
  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: (json['id'] ?? '') as String,
      childId: (json['child_id'] ?? json['childId'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      dob: (json['dob'] ?? '') as String,
      sex: Sex.fromJson((json['sex'] ?? 'other') as String),
      birthStatus: (json['birth_status'] ?? json['birthStatus']) as String?,
      birthWeight: (json['birth_weight'] ?? json['birthWeight'] as num?)?.toDouble(),
      heightCm: ((json['height_cm'] ?? json['heightCm'] ?? 0) as num).toDouble(),
      weightKg: ((json['weight_kg'] ?? json['weightKg'] ?? 0) as num).toDouble(),
      screeningLocation: (json['screening_location'] ?? json['screeningLocation']) as String?,
      parentName: (json['parent_name'] ?? json['parentName']) as String?,
      parentPhone: (json['parent_phone'] ?? json['parentPhone']) as String?,
      createdAt: (json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()) as String,
      updatedAt: (json['updated_at'] ?? json['updatedAt'] ?? DateTime.now().toIso8601String()) as String,
    );
  }

  /// Serialises this [Child] to a JSON-compatible [Map] suitable for
  /// Firestore writes or REST POST bodies.
  Map<String, dynamic> toJson() => {
        'id': id,
        'child_id': childId,
        'childId': childId,
        'name': name,
        'dob': dob,
        'sex': sex.toJson(),
        'birth_status': birthStatus,
        'birth_weight': birthWeight,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'screening_location': screeningLocation,
        'parent_name': parentName,
        'parent_phone': parentPhone,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  /// Serialises fields for Supabase table `children` INSERT operations.
  Map<String, dynamic> toInsertJson() => {
        'child_id': childId,
        'name': name,
        'dob': dob,
        'sex': sex.toJson(),
        'birth_status': birthStatus,
        'birth_weight': birthWeight,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'screening_location': screeningLocation,
        'parent_name': parentName,
        'parent_phone': parentPhone,
      };

  /// Serialises mutable fields for Supabase table `children` UPDATE operations.
  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'dob': dob,
        'sex': sex.toJson(),
        'birth_status': birthStatus,
        'birth_weight': birthWeight,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'screening_location': screeningLocation,
        'parent_name': parentName,
        'parent_phone': parentPhone,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  // ── copyWith ──────────────────────────────────────────────────────────────

  /// Returns a new [Child] with the specified fields replaced.
  ///
  /// All fields not passed to [copyWith] retain their original values,
  /// preserving immutability while allowing targeted updates in state
  /// management (Riverpod / BLoC).
  Child copyWith({
    String? id,
    String? childId,
    String? name,
    String? dob,
    Sex? sex,
    Object? birthStatus = _sentinel,
    Object? birthWeight = _sentinel,
    double? heightCm,
    double? weightKg,
    Object? screeningLocation = _sentinel,
    Object? parentName = _sentinel,
    Object? parentPhone = _sentinel,
    String? createdAt,
    String? updatedAt,
  }) {
    return Child(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      sex: sex ?? this.sex,
      // Nullable fields use a sentinel so callers can explicitly pass null.
      birthStatus: birthStatus == _sentinel
          ? this.birthStatus
          : birthStatus as String?,
      birthWeight: birthWeight == _sentinel
          ? this.birthWeight
          : birthWeight as double?,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      screeningLocation: screeningLocation == _sentinel
          ? this.screeningLocation
          : screeningLocation as String?,
      parentName: parentName == _sentinel ? this.parentName : parentName as String?,
      parentPhone:
          parentPhone == _sentinel ? this.parentPhone : parentPhone as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Child(id: $id, childId: $childId, name: $name, ageInMonths: $ageInMonths)';
}

// Private sentinel object used by [copyWith] to distinguish "not passed"
// from an explicitly passed `null`.
const Object _sentinel = Object();
