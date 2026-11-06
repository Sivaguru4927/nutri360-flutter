// =============================================================================
// FILE: nutrition_record.dart
// WHAT: Defines the [NutritionScreeningRecord] model, which captures a single
//       dietary screening session for a child — including dietary diversity
//       score, food groups consumed, meals per day, sunlight exposure, and the
//       computed vitamin D intake from both diet and sun synthesis.
// WHY:  Ported from the TypeScript `NutritionScreeningRecord` interface
//       (src/types/index.ts).  Using a typed Dart class prevents the class of
//       bugs seen in the RN app where nullable nutrition-flag strings were
//       directly displayed without null checks.
//
//       [SyncSource] is promoted to a proper enum so the UI can render
//       device-specific icons (phone / Wi-Fi ESP32 / BLE ESP32 / NutriBand)
//       and so the data-provenance audit screen has type-safe filtering.
// =============================================================================

/// The hardware / software source from which this record was synchronised.
///
/// Used to show data-provenance icons on the history screen and to filter
/// records by collection method in the analytics dashboard.
enum SyncSource {
  /// Record entered manually by a health worker or parent through the app UI.
  manual,

  /// Record received from an ESP32 microcontroller via Wi-Fi (HTTP POST).
  esp32Wifi,

  /// Record received from an ESP32 microcontroller via Bluetooth LE.
  esp32Ble,

  /// Record received from the NutriBand wearable sensor via Wi-Fi.
  nutribandWifi;

  /// Serialises to the camelCase string stored in the backend.
  String toJson() {
    switch (this) {
      case SyncSource.manual:
        return 'manual';
      case SyncSource.esp32Wifi:
        return 'esp32Wifi';
      case SyncSource.esp32Ble:
        return 'esp32Ble';
      case SyncSource.nutribandWifi:
        return 'nutribandWifi';
    }
  }

  /// Deserialises from the backend camelCase string.
  static SyncSource fromJson(String value) {
    switch (value) {
      case 'manual':
        return SyncSource.manual;
      case 'esp32Wifi':
        return SyncSource.esp32Wifi;
      case 'esp32Ble':
        return SyncSource.esp32Ble;
      case 'nutribandWifi':
        return SyncSource.nutribandWifi;
      default:
        throw ArgumentError('Unknown SyncSource value: "$value"');
    }
  }

  /// A short label used in device-provenance chips and filter dropdowns.
  String get displayLabel {
    switch (this) {
      case SyncSource.manual:
        return 'Manual Entry';
      case SyncSource.esp32Wifi:
        return 'ESP32 Wi-Fi';
      case SyncSource.esp32Ble:
        return 'ESP32 BLE';
      case SyncSource.nutribandWifi:
        return 'NutriBand Wi-Fi';
    }
  }
}

/// A single dietary and sunlight screening session for one child.
///
/// A new record is created every time a health worker or device submits a
/// screening.  The list of records for a child constitutes the longitudinal
/// nutrition history shown in charts and PDF reports.
class NutritionScreeningRecord {
  // ── Identity ──────────────────────────────────────────────────────────────

  /// Firestore document ID; null while in local draft / offline state.
  final String? id;

  /// ID of the [Child] this record belongs to (matches [Child.id]).
  final String childId;

  // ── Dietary Diversity ─────────────────────────────────────────────────────

  /// IYCF dietary diversity score (0–8), based on the eight WHO food groups.
  ///
  /// A score ≥ 5 indicates minimum dietary diversity for children 6–23 months.
  /// Null when the dietary diversity section of the form was not completed.
  final int? dietaryDiversityScore;

  /// The list of WHO food group codes that the child consumed in the previous
  /// 24-hour recall period.
  ///
  /// Valid codes: "grains", "legumes", "dairy", "fleshFoods", "eggs",
  /// "vitARichVeg", "otherVeg", "otherFruits" (matches backend constants).
  final List<String> selectedFoodGroups;

  /// Number of main meals (including porridge / complementary feeds) consumed
  /// in the previous 24 hours; null if not recorded.
  final int? mealsPerDay;

  // ── Sunlight Exposure ─────────────────────────────────────────────────────

  /// Duration of outdoor sun exposure in minutes on the measurement day.
  ///
  /// Captured from the ESP32 ambient-light sensor or entered manually.
  final double sunlightMinutes;

  /// UV Index at the time of exposure; null if sensor data is unavailable.
  final double? sunlightUvi;

  /// Body surface area exposed to sunlight (0.0–1.0 fraction of total BSA);
  /// null if not calculated.
  ///
  /// Computed by the backend from the child's height, weight, and clothing
  /// data using the Mosteller formula.
  final double? sunlightBsa;

  // ── Vitamin D Synthesis ───────────────────────────────────────────────────

  /// Estimated vitamin D synthesised from sunlight, in International Units (IU).
  ///
  /// Calculated by the backend using UVI × BSA × minutes × skin-type factor.
  final double sunlightVitaminDIu;

  /// Vitamin D obtained from dietary sources, in IU.
  ///
  /// Derived from the food groups selected and the IFCT food composition table.
  final double dietaryVitaminDIu;

  /// Total vitamin D intake (sunlight + dietary), in IU.
  ///
  /// Used to compare against the ICMR recommended dietary allowance (600 IU/day
  /// for children 1–18 years).
  final double totalVitaminDIu;

  // ── Metadata ──────────────────────────────────────────────────────────────

  /// The hardware/software source from which this record was synchronised.
  final SyncSource syncSource;

  /// ISO-8601 timestamp when the screening was recorded (device-local time
  /// for offline records; UTC for cloud-synced records).
  final String recordedAt;

  /// A backend-generated flag string if the nutrition data triggers a clinical
  /// alert (e.g. "VITAMIN_D_DEFICIENCY_RISK"), or null if the record is clean.
  ///
  /// Stored as a nullable [String] (not an enum) because the set of possible
  /// flag codes can be extended server-side without a client app update.
  final String? nutritionFlag;

  // ── Constructor ───────────────────────────────────────────────────────────

  /// Creates an immutable [NutritionScreeningRecord].
  const NutritionScreeningRecord({
    this.id,
    required this.childId,
    this.dietaryDiversityScore,
    required this.selectedFoodGroups,
    this.mealsPerDay,
    required this.sunlightMinutes,
    this.sunlightUvi,
    this.sunlightBsa,
    required this.sunlightVitaminDIu,
    required this.dietaryVitaminDIu,
    required this.totalVitaminDIu,
    required this.syncSource,
    required this.recordedAt,
    this.nutritionFlag,
  });

  // ── Serialisation ─────────────────────────────────────────────────────────

  /// Deserialises from a Firestore / REST JSON map.
  factory NutritionScreeningRecord.fromJson(Map<String, dynamic> json) {
    return NutritionScreeningRecord(
      id: json['id'] as String?,
      childId: json['childId'] as String,
      dietaryDiversityScore: json['dietaryDiversityScore'] as int?,
      selectedFoodGroups: (json['selectedFoodGroups'] as List<dynamic>)
          .cast<String>(),
      mealsPerDay: json['mealsPerDay'] as int?,
      sunlightMinutes: (json['sunlightMinutes'] as num).toDouble(),
      sunlightUvi: (json['sunlightUvi'] as num?)?.toDouble(),
      sunlightBsa: (json['sunlightBsa'] as num?)?.toDouble(),
      sunlightVitaminDIu: (json['sunlightVitaminDIu'] as num).toDouble(),
      dietaryVitaminDIu: (json['dietaryVitaminDIu'] as num).toDouble(),
      totalVitaminDIu: (json['totalVitaminDIu'] as num).toDouble(),
      syncSource: SyncSource.fromJson(json['syncSource'] as String),
      recordedAt: json['recordedAt'] as String,
      nutritionFlag: json['nutritionFlag'] as String?,
    );
  }

  /// Serialises to a JSON-compatible [Map].
  Map<String, dynamic> toJson() => {
        'id': id,
        'childId': childId,
        'dietaryDiversityScore': dietaryDiversityScore,
        'selectedFoodGroups': selectedFoodGroups,
        'mealsPerDay': mealsPerDay,
        'sunlightMinutes': sunlightMinutes,
        'sunlightUvi': sunlightUvi,
        'sunlightBsa': sunlightBsa,
        'sunlightVitaminDIu': sunlightVitaminDIu,
        'dietaryVitaminDIu': dietaryVitaminDIu,
        'totalVitaminDIu': totalVitaminDIu,
        'syncSource': syncSource.toJson(),
        'recordedAt': recordedAt,
        'nutritionFlag': nutritionFlag,
      };

  // ── copyWith ──────────────────────────────────────────────────────────────

  /// Returns a new [NutritionScreeningRecord] with selected fields replaced.
  NutritionScreeningRecord copyWith({
    Object? id = _sentinel,
    String? childId,
    Object? dietaryDiversityScore = _sentinel,
    List<String>? selectedFoodGroups,
    Object? mealsPerDay = _sentinel,
    double? sunlightMinutes,
    Object? sunlightUvi = _sentinel,
    Object? sunlightBsa = _sentinel,
    double? sunlightVitaminDIu,
    double? dietaryVitaminDIu,
    double? totalVitaminDIu,
    SyncSource? syncSource,
    String? recordedAt,
    Object? nutritionFlag = _sentinel,
  }) {
    return NutritionScreeningRecord(
      id: id == _sentinel ? this.id : id as String?,
      childId: childId ?? this.childId,
      dietaryDiversityScore: dietaryDiversityScore == _sentinel
          ? this.dietaryDiversityScore
          : dietaryDiversityScore as int?,
      selectedFoodGroups: selectedFoodGroups ?? this.selectedFoodGroups,
      mealsPerDay:
          mealsPerDay == _sentinel ? this.mealsPerDay : mealsPerDay as int?,
      sunlightMinutes: sunlightMinutes ?? this.sunlightMinutes,
      sunlightUvi:
          sunlightUvi == _sentinel ? this.sunlightUvi : sunlightUvi as double?,
      sunlightBsa:
          sunlightBsa == _sentinel ? this.sunlightBsa : sunlightBsa as double?,
      sunlightVitaminDIu: sunlightVitaminDIu ?? this.sunlightVitaminDIu,
      dietaryVitaminDIu: dietaryVitaminDIu ?? this.dietaryVitaminDIu,
      totalVitaminDIu: totalVitaminDIu ?? this.totalVitaminDIu,
      syncSource: syncSource ?? this.syncSource,
      recordedAt: recordedAt ?? this.recordedAt,
      nutritionFlag: nutritionFlag == _sentinel
          ? this.nutritionFlag
          : nutritionFlag as String?,
    );
  }

  @override
  String toString() =>
      'NutritionScreeningRecord(id: $id, childId: $childId, '
      'dds: $dietaryDiversityScore, totalVitD: ${totalVitaminDIu}IU, '
      'source: ${syncSource.toJson()})';
}

// Private sentinel used by [copyWith] to distinguish "not passed" from null.
const Object _sentinel = Object();
