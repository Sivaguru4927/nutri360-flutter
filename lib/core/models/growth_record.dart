// =============================================================================
// FILE: growth_record.dart
// WHAT: Defines the [GrowthRecord] model, which stores a single set of
//       anthropometric measurements for a child along with WHO Z-scores and
//       the resulting growth flag.
// WHY:  Ported from the TypeScript `GrowthRecord` interface (src/types/index.ts).
//       A typed Dart class prevents the category of bugs seen in the RN app
//       where nullable Z-score fields were accidentally compared as non-null,
//       causing incorrect WHO reference interpretations.
//
//       The [GrowthFlag] enum drives the colour-coded dashboard cards:
//         NO_FLAG          → green  (healthy)
//         POTENTIAL_CONCERN → amber  (watch)
//         REVIEW_DUE        → red    (action needed)
//         INSUFFICIENT_DATA → grey   (not enough measurements)
// =============================================================================

/// Enum representing the clinical flag assigned to a growth record after
/// comparing the child's Z-scores against WHO reference thresholds.
///
/// Values are stored as SCREAMING_SNAKE_CASE strings in the backend to match
/// the original TypeScript enum.
enum GrowthFlag {
  /// All Z-scores are within normal range; no action required.
  noFlag,

  /// One or more Z-scores are approaching a threshold; monitor closely.
  potentialConcern,

  /// One or more Z-scores have crossed a clinical threshold; schedule review.
  reviewDue,

  /// Measurements are missing or the child is too young for a full assessment.
  insufficientData;

  /// Serialises to the backend SCREAMING_SNAKE_CASE string.
  String toJson() {
    switch (this) {
      case GrowthFlag.noFlag:
        return 'NO_FLAG';
      case GrowthFlag.potentialConcern:
        return 'POTENTIAL_CONCERN';
      case GrowthFlag.reviewDue:
        return 'REVIEW_DUE';
      case GrowthFlag.insufficientData:
        return 'INSUFFICIENT_DATA';
    }
  }

  /// Deserialises from the backend SCREAMING_SNAKE_CASE string.
  static GrowthFlag fromJson(String value) {
    switch (value) {
      case 'NO_FLAG':
        return GrowthFlag.noFlag;
      case 'POTENTIAL_CONCERN':
        return GrowthFlag.potentialConcern;
      case 'REVIEW_DUE':
        return GrowthFlag.reviewDue;
      case 'INSUFFICIENT_DATA':
        return GrowthFlag.insufficientData;
      default:
        throw ArgumentError('Unknown GrowthFlag value: "$value"');
    }
  }

  /// A short label for dashboard badges and PDF legends.
  String get displayLabel {
    switch (this) {
      case GrowthFlag.noFlag:
        return 'Healthy';
      case GrowthFlag.potentialConcern:
        return 'Potential Concern';
      case GrowthFlag.reviewDue:
        return 'Review Due';
      case GrowthFlag.insufficientData:
        return 'Insufficient Data';
    }
  }
}

/// A single anthropometric screening session for one child.
///
/// Each record captures height, weight, and optional head circumference, then
/// stores the WHO Z-scores calculated by the backend (or a local Dart service)
/// along with a human-readable WHO reference interpretation string and an
/// overall [GrowthFlag].
class GrowthRecord {
  // ── Identity ──────────────────────────────────────────────────────────────

  /// Firestore document ID; null while the record is still being saved locally
  /// (e.g. in offline / draft state before sync).
  final String? id;

  /// ID of the [Child] this record belongs to (matches [Child.id]).
  final String childId;

  // ── Measurement ───────────────────────────────────────────────────────────

  /// ISO-8601 date string ("YYYY-MM-DD") on which measurements were taken.
  final String measurementDate;

  /// Measured height in centimetres.
  final double heightCm;

  /// Measured weight in kilograms.
  final double weightKg;

  /// Measured head circumference in centimetres; null if not measured.
  ///
  /// Head circumference is typically collected only up to 24 months of age.
  final double? headCircumferenceCm;

  // ── Derived Values ────────────────────────────────────────────────────────

  /// Body Mass Index, pre-computed as weight(kg) / height(m)².
  ///
  /// Stored (not computed here) because the backend applies age-specific
  /// rounding rules consistent with WHO methodology.
  final double bmi;

  // ── WHO Z-Scores ──────────────────────────────────────────────────────────
  // Z-scores are null when insufficient data exists (e.g. age < 1 month,
  // or head circumference not measured).  Always null-check before use.

  /// Z-score for head circumference vs WHO reference; null if [headCircumferenceCm] is null.
  final double? zScoreHc;

  /// Z-score for BMI-for-age vs WHO reference.
  final double? zScoreBmi;

  /// Z-score for weight-for-age vs WHO reference.
  final double? zScoreWeight;

  /// Z-score for height-for-age vs WHO reference.
  final double? zScoreHeight;

  // ── Interpretation ────────────────────────────────────────────────────────

  /// A backend-generated sentence summarising how this record compares to the
  /// WHO Multicentre Growth Reference Study (MGRS) standards.
  ///
  /// Example: "Weight-for-age: Normal. Height-for-age: Stunted (moderate)."
  final String whoReferenceInterpretation;

  /// The aggregate flag assigned after evaluating all Z-scores against the
  /// WHO clinical thresholds configured in the backend.
  final GrowthFlag growthFlag;

  // ── Timestamps ────────────────────────────────────────────────────────────

  /// ISO-8601 timestamp when this record was first persisted.
  final String createdAt;

  // ── Constructor ───────────────────────────────────────────────────────────

  /// Creates an immutable [GrowthRecord].
  const GrowthRecord({
    this.id,
    required this.childId,
    required this.measurementDate,
    required this.heightCm,
    required this.weightKg,
    this.headCircumferenceCm,
    required this.bmi,
    this.zScoreHc,
    this.zScoreBmi,
    this.zScoreWeight,
    this.zScoreHeight,
    required this.whoReferenceInterpretation,
    required this.growthFlag,
    required this.createdAt,
  });

  // ── Serialisation ─────────────────────────────────────────────────────────

  /// Deserialises a [GrowthRecord] from a Supabase / REST JSON map.
  /// Supports both snake_case and camelCase keys.
  factory GrowthRecord.fromJson(Map<String, dynamic> json) {
    return GrowthRecord(
      id: json['id'] as String?,
      childId: (json['child_id'] ?? json['childId'] ?? '') as String,
      measurementDate: (json['measurement_date'] ?? json['measurementDate'] ?? '') as String,
      heightCm: ((json['height_cm'] ?? json['heightCm'] ?? 0) as num).toDouble(),
      weightKg: ((json['weight_kg'] ?? json['weightKg'] ?? 0) as num).toDouble(),
      headCircumferenceCm:
          (json['head_circumference_cm'] ?? json['headCircumferenceCm'] as num?)?.toDouble(),
      bmi: ((json['bmi'] ?? 0) as num).toDouble(),
      zScoreHc: (json['z_score_hc'] ?? json['zScoreHc'] as num?)?.toDouble(),
      zScoreBmi: (json['z_score_bmi'] ?? json['zScoreBmi'] as num?)?.toDouble(),
      zScoreWeight: (json['z_score_weight'] ?? json['zScoreWeight'] as num?)?.toDouble(),
      zScoreHeight: (json['z_score_height'] ?? json['zScoreHeight'] as num?)?.toDouble(),
      whoReferenceInterpretation:
          (json['who_reference_interpretation'] ?? json['whoReferenceInterpretation'] ?? 'Normal') as String,
      growthFlag: GrowthFlag.fromJson((json['growth_flag'] ?? json['growthFlag'] ?? 'NO_FLAG') as String),
      createdAt: (json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()) as String,
    );
  }

  /// Serialises to a JSON-compatible [Map].
  Map<String, dynamic> toJson() => {
        'id': id,
        'child_id': childId,
        'childId': childId,
        'measurement_date': measurementDate,
        'measurementDate': measurementDate,
        'height_cm': heightCm,
        'heightCm': heightCm,
        'weight_kg': weightKg,
        'weightKg': weightKg,
        'head_circumference_cm': headCircumferenceCm,
        'headCircumferenceCm': headCircumferenceCm,
        'bmi': bmi,
        'z_score_hc': zScoreHc,
        'z_score_bmi': zScoreBmi,
        'z_score_weight': zScoreWeight,
        'z_score_height': zScoreHeight,
        'who_reference_interpretation': whoReferenceInterpretation,
        'growth_flag': growthFlag.toJson(),
        'created_at': createdAt,
      };

  /// Serialises fields for Supabase table `growth_records` INSERT.
  Map<String, dynamic> toInsertJson() => {
        'child_id': childId,
        'measurement_date': measurementDate,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        if (headCircumferenceCm != null) 'head_circumference_cm': headCircumferenceCm,
        'bmi': bmi,
        if (zScoreHc != null) 'z_score_hc': zScoreHc,
        if (zScoreBmi != null) 'z_score_bmi': zScoreBmi,
        if (zScoreWeight != null) 'z_score_weight': zScoreWeight,
        if (zScoreHeight != null) 'z_score_height': zScoreHeight,
        'who_reference_interpretation': whoReferenceInterpretation,
        'growth_flag': growthFlag.toJson(),
      };

  // ── copyWith ──────────────────────────────────────────────────────────────

  /// Returns a new [GrowthRecord] with selected fields replaced.
  GrowthRecord copyWith({
    Object? id = _sentinel,
    String? childId,
    String? measurementDate,
    double? heightCm,
    double? weightKg,
    Object? headCircumferenceCm = _sentinel,
    double? bmi,
    Object? zScoreHc = _sentinel,
    Object? zScoreBmi = _sentinel,
    Object? zScoreWeight = _sentinel,
    Object? zScoreHeight = _sentinel,
    String? whoReferenceInterpretation,
    GrowthFlag? growthFlag,
    String? createdAt,
  }) {
    return GrowthRecord(
      id: id == _sentinel ? this.id : id as String?,
      childId: childId ?? this.childId,
      measurementDate: measurementDate ?? this.measurementDate,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      headCircumferenceCm: headCircumferenceCm == _sentinel
          ? this.headCircumferenceCm
          : headCircumferenceCm as double?,
      bmi: bmi ?? this.bmi,
      zScoreHc: zScoreHc == _sentinel ? this.zScoreHc : zScoreHc as double?,
      zScoreBmi:
          zScoreBmi == _sentinel ? this.zScoreBmi : zScoreBmi as double?,
      zScoreWeight: zScoreWeight == _sentinel
          ? this.zScoreWeight
          : zScoreWeight as double?,
      zScoreHeight: zScoreHeight == _sentinel
          ? this.zScoreHeight
          : zScoreHeight as double?,
      whoReferenceInterpretation:
          whoReferenceInterpretation ?? this.whoReferenceInterpretation,
      growthFlag: growthFlag ?? this.growthFlag,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'GrowthRecord(id: $id, childId: $childId, date: $measurementDate, '
      'flag: ${growthFlag.toJson()})';
}

// Private sentinel used by [copyWith] to distinguish "not passed" from null.
const Object _sentinel = Object();
