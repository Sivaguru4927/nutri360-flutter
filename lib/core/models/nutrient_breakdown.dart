// =============================================================================
// FILE: nutrient_breakdown.dart
// WHAT: Defines [NutrientBreakdown], an immutable value object that holds the
//       full macro- and micro-nutrient profile of a food item or an entire
//       dietary record.
// WHY:  Ported from the TypeScript `NutrientBreakdown` interface
//       (src/types/index.ts).  Three capabilities are added beyond the TS
//       source that were repeatedly needed in widget and service code:
//
//         • [operator +]  – sums two breakdowns so callers can fold a list of
//                           food items into a daily total with a single reduce().
//         • [scale()]     – multiplies every field by a factor, enabling
//                           portion-size adjustments without touching the
//                           base nutrient data.
//         • [zero]        – a const all-zeros instance used as an identity
//                           element for the fold / accumulator pattern.
//
//       All nutrient values are in standard SI / nutritional units:
//         Macros (calories, protein, carbs, fat, fiber) → grams (or kcal).
//         Minerals (iron, calcium, zinc, potassium, magnesium, sodium) → mg.
//         Vitamins A, C → mg; vitamin D → mcg (µg); B12, folate → mcg (µg).
// =============================================================================

/// An immutable record of the nutritional content of one food item or the
/// aggregate daily intake of a child.
///
/// All fields represent **per-serving** amounts (or totals when produced by
/// [operator +]).  Use [scale] to adjust for portion sizes before adding.
class NutrientBreakdown {
  // ── Macronutrients ────────────────────────────────────────────────────────

  /// Energy content in kilocalories (kcal).
  final double calories;

  /// Protein content in grams (g).
  final double protein;

  /// Total carbohydrate content in grams (g).
  final double carbs;

  /// Total fat content in grams (g).
  final double fat;

  /// Dietary fibre content in grams (g).
  final double fiber;

  // ── Minerals ──────────────────────────────────────────────────────────────

  /// Iron content in milligrams (mg).  Critical for anaemia detection.
  final double iron;

  /// Calcium content in milligrams (mg).
  final double calcium;

  /// Zinc content in milligrams (mg).  Important for linear growth.
  final double zinc;

  /// Potassium content in milligrams (mg).
  final double potassium;

  /// Magnesium content in milligrams (mg).
  final double magnesium;

  /// Sodium content in milligrams (mg).
  final double sodium;

  // ── Vitamins ──────────────────────────────────────────────────────────────

  /// Vitamin A (retinol equivalents) in milligrams (mg).
  final double vitaminA;

  /// Vitamin C (ascorbic acid) in milligrams (mg).
  final double vitaminC;

  /// Vitamin D in micrograms (mcg / µg).
  ///
  /// Stored as mcg here; conversion to IU (×40) is done in display widgets
  /// and the sunlight synthesis service to avoid double-conversion bugs.
  final double vitaminD;

  /// Vitamin B12 (cobalamin) in micrograms (mcg / µg).
  final double vitaminB12;

  /// Folate (vitamin B9) in micrograms (mcg / µg).
  final double folate;

  // ── Constructor ───────────────────────────────────────────────────────────

  /// Creates an immutable [NutrientBreakdown].
  ///
  /// Every field defaults to `0.0` so callers only need to supply the
  /// nutrients that are known (useful for sparse food database entries).
  const NutrientBreakdown({
    this.calories = 0.0,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
    this.fiber = 0.0,
    this.iron = 0.0,
    this.calcium = 0.0,
    this.zinc = 0.0,
    this.potassium = 0.0,
    this.magnesium = 0.0,
    this.sodium = 0.0,
    this.vitaminA = 0.0,
    this.vitaminC = 0.0,
    this.vitaminD = 0.0,
    this.vitaminB12 = 0.0,
    this.folate = 0.0,
  });

  // ── Identity Element ──────────────────────────────────────────────────────

  /// A const all-zeros instance used as the identity element when folding a
  /// list of food items:
  ///
  /// ```dart
  /// final total = items.fold(
  ///   NutrientBreakdown.zero,
  ///   (acc, item) => acc + item.nutrients.scale(item.portionFactor),
  /// );
  /// ```
  static const NutrientBreakdown zero = NutrientBreakdown();

  // ── Arithmetic Operators ──────────────────────────────────────────────────

  /// Returns a new [NutrientBreakdown] whose fields are the element-wise sum
  /// of [this] and [other].
  ///
  /// This makes [NutrientBreakdown] usable with [Iterable.fold] and
  /// [Iterable.reduce] without boilerplate.
  NutrientBreakdown operator +(NutrientBreakdown other) {
    return NutrientBreakdown(
      calories: calories + other.calories,
      protein: protein + other.protein,
      carbs: carbs + other.carbs,
      fat: fat + other.fat,
      fiber: fiber + other.fiber,
      iron: iron + other.iron,
      calcium: calcium + other.calcium,
      zinc: zinc + other.zinc,
      potassium: potassium + other.potassium,
      magnesium: magnesium + other.magnesium,
      sodium: sodium + other.sodium,
      vitaminA: vitaminA + other.vitaminA,
      vitaminC: vitaminC + other.vitaminC,
      vitaminD: vitaminD + other.vitaminD,
      vitaminB12: vitaminB12 + other.vitaminB12,
      folate: folate + other.folate,
    );
  }

  // ── Scaling ───────────────────────────────────────────────────────────────

  /// Returns a new [NutrientBreakdown] with every field multiplied by [factor].
  ///
  /// Use this to adjust for portion size before summing:
  ///
  /// ```dart
  /// // 150 g serving when the reference is per 100 g:
  /// final adjusted = baseNutrients.scale(1.5);
  /// ```
  ///
  /// A [factor] of `0` returns [NutrientBreakdown.zero].
  NutrientBreakdown scale(double factor) {
    return NutrientBreakdown(
      calories: calories * factor,
      protein: protein * factor,
      carbs: carbs * factor,
      fat: fat * factor,
      fiber: fiber * factor,
      iron: iron * factor,
      calcium: calcium * factor,
      zinc: zinc * factor,
      potassium: potassium * factor,
      magnesium: magnesium * factor,
      sodium: sodium * factor,
      vitaminA: vitaminA * factor,
      vitaminC: vitaminC * factor,
      vitaminD: vitaminD * factor,
      vitaminB12: vitaminB12 * factor,
      folate: folate * factor,
    );
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  /// Deserialises from a Firestore / REST JSON map.
  factory NutrientBreakdown.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse a num field that may be int or double in JSON.
    double d(String key) => (json[key] as num?)?.toDouble() ?? 0.0;

    return NutrientBreakdown(
      calories: d('calories'),
      protein: d('protein'),
      carbs: d('carbs'),
      fat: d('fat'),
      fiber: d('fiber'),
      iron: d('iron'),
      calcium: d('calcium'),
      zinc: d('zinc'),
      potassium: d('potassium'),
      magnesium: d('magnesium'),
      sodium: d('sodium'),
      vitaminA: d('vitaminA'),
      vitaminC: d('vitaminC'),
      vitaminD: d('vitaminD'),
      vitaminB12: d('vitaminB12'),
      folate: d('folate'),
    );
  }

  /// Serialises to a JSON-compatible [Map].
  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'iron': iron,
        'calcium': calcium,
        'zinc': zinc,
        'potassium': potassium,
        'magnesium': magnesium,
        'sodium': sodium,
        'vitaminA': vitaminA,
        'vitaminC': vitaminC,
        'vitaminD': vitaminD,
        'vitaminB12': vitaminB12,
        'folate': folate,
      };

  // ── copyWith ──────────────────────────────────────────────────────────────

  /// Returns a new [NutrientBreakdown] with selected fields replaced.
  NutrientBreakdown copyWith({
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? iron,
    double? calcium,
    double? zinc,
    double? potassium,
    double? magnesium,
    double? sodium,
    double? vitaminA,
    double? vitaminC,
    double? vitaminD,
    double? vitaminB12,
    double? folate,
  }) {
    return NutrientBreakdown(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      iron: iron ?? this.iron,
      calcium: calcium ?? this.calcium,
      zinc: zinc ?? this.zinc,
      potassium: potassium ?? this.potassium,
      magnesium: magnesium ?? this.magnesium,
      sodium: sodium ?? this.sodium,
      vitaminA: vitaminA ?? this.vitaminA,
      vitaminC: vitaminC ?? this.vitaminC,
      vitaminD: vitaminD ?? this.vitaminD,
      vitaminB12: vitaminB12 ?? this.vitaminB12,
      folate: folate ?? this.folate,
    );
  }

  @override
  String toString() =>
      'NutrientBreakdown(kcal: $calories, protein: ${protein}g, '
      'vitD: ${vitaminD}mcg)';
}
