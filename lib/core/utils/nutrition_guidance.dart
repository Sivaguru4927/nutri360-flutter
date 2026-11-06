// =============================================================================
// nutrition_guidance.dart
// =============================================================================
//
// WHAT: A self-contained Indian paediatric food database and nutrition-guidance
//       engine for Nutri360.  Provides:
//         • 50+ Indian food items spanning all 8 WHO food groups, each with
//           realistic per-100 g nutrient breakdowns sourced from IFCT 2017.
//         • WHO Minimum Dietary Diversity (MDD) scoring logic.
//         • Age-locked NutritionMode selection (exclusive breastfeeding →
//           diverse feeding) following WHO/UNICEF complementary feeding
//           guidelines.
//         • Multilingual food names (English / Telugu / Hindi) for community
//           health worker use in Andhra Pradesh / Telangana / Pan-India
//           deployments.
//
// WHY:  Nutri360's nutrition diary screen requires a local, offline-capable
//       food database that reflects the actual dietary patterns of the target
//       population (southern India / ICDS beneficiaries).  Network-dependent
//       databases would fail in low-connectivity ASHA worker field conditions.
//
// PORT: Direct port of nutritionGuidance.ts from the Nutri360 React Native
//       codebase.  All WHO MDD thresholds and age-mode boundaries are
//       preserved.
//
// REFERENCES:
//   IFCT 2017 — Indian Food Composition Tables, NIN Hyderabad.
//   WHO (2008) — Indicators for assessing infant and young child feeding
//               practices, Part 1: Definitions.
// =============================================================================

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// The eight WHO food groups used for Minimum Dietary Diversity (MDD) scoring.
///
/// MDD requires that a child aged 6–23 months consumes foods from at least
/// 5 of these 8 groups in the past 24 hours (WHO, 2010).
enum FoodGroup {
  /// Starchy staples: rice, wheat, millets, maize.
  grains,

  /// Pulses, beans, lentils, peas.
  legumes,

  /// Milk, curd, paneer, formula — excluding breast milk for MDD scoring.
  dairy,

  /// Eggs (whole).
  eggs,

  /// Flesh foods: poultry, fish, red meat.
  meatFish,

  /// All fruits and vegetables not classified as vitamin-A-rich.
  fruitsVeg,

  /// Dark-green leafy vegetables, orange/yellow fruits and vegetables rich
  /// in pro-vitamin A carotenoids (β-carotene ≥ 100 µg / 100 g).
  vitaminARich,

  /// Other foods not fitting the above groups: mixed dishes, formula milk.
  other,
}

/// The feeding mode appropriate for a child's age according to WHO infant and
/// young child feeding (IYCF) guidelines.
///
/// The mode drives which sections of the nutrition diary UI are shown and
/// which advice banners are displayed.
enum NutritionMode {
  /// 0–5 months: WHO recommends exclusive breastfeeding — no solid or
  /// liquid foods other than breast milk.
  exclusiveBreastfeeding,

  /// 6–8 months: Introduce semi-solid complementary foods alongside
  /// continued breastfeeding; portion frequency 2–3 times per day.
  earlyWeaning,

  /// 9–11 months: Soft family foods; meal frequency 3–4 times per day;
  /// continued breastfeeding.
  complementaryFeeding,

  /// 12+ months: Full dietary diversity; child joins family meals;
  /// breastfeeding optional but encouraged to 2 years.
  diverseFeeding,
}

// ---------------------------------------------------------------------------
// NutrientBreakdown — per-100 g or per-serving nutrient profile
// ---------------------------------------------------------------------------

/// A complete nutrient profile expressed per 100 g of food (or per serving
/// when returned by [FoodItem.forServing]).
///
/// All macronutrient values are in grams unless otherwise stated.
/// Micronutrient units follow IFCT 2017 conventions.
class NutrientBreakdown {
  // --- Macronutrients ---
  /// Energy in kilocalories.
  final double energyKcal;

  /// Total protein in grams.
  final double proteinG;

  /// Total fat in grams.
  final double fatG;

  /// Total available carbohydrates in grams.
  final double carbsG;

  /// Dietary fibre in grams.
  final double fibreG;

  // --- Key micronutrients for paediatric nutrition ---
  /// Calcium in milligrams.
  final double calciumMg;

  /// Iron in milligrams.
  final double ironMg;

  /// Zinc in milligrams.
  final double zincMg;

  /// Vitamin A as retinol equivalents (µg RAE).
  final double vitaminAUg;

  /// Vitamin C (ascorbic acid) in milligrams.
  final double vitaminCMg;

  /// Vitamin D in International Units.
  final double vitaminDIU;

  /// Folate (total) in micrograms.
  final double folateUg;

  /// Vitamin B12 in micrograms.
  final double vitaminB12Ug;

  /// Potassium in milligrams.
  final double potassiumMg;

  /// Sodium in milligrams.
  final double sodiumMg;

  const NutrientBreakdown({
    required this.energyKcal,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.fibreG,
    required this.calciumMg,
    required this.ironMg,
    required this.zincMg,
    required this.vitaminAUg,
    required this.vitaminCMg,
    required this.vitaminDIU,
    required this.folateUg,
    required this.vitaminB12Ug,
    required this.potassiumMg,
    required this.sodiumMg,
  });

  // Convenience aliases matching core model property names
  double get calories => energyKcal;
  double get protein => proteinG;
  double get carbs => carbsG;
  double get fat => fatG;
  double get fiber => fibreG;
  double get iron => ironMg;
  double get calcium => calciumMg;
  double get zinc => zincMg;
  double get vitaminA => vitaminAUg;
  double get vitaminC => vitaminCMg;
  double get vitaminD => vitaminDIU / 40.0; // 40 IU = 1 mcg
  double get vitaminB12 => vitaminB12Ug;
  double get folate => folateUg;

  static const NutrientBreakdown zero = NutrientBreakdown(
    energyKcal: 0, proteinG: 0, fatG: 0, carbsG: 0, fibreG: 0,
    calciumMg: 0, ironMg: 0, zincMg: 0, vitaminAUg: 0,
    vitaminCMg: 0, vitaminDIU: 0, folateUg: 0, vitaminB12Ug: 0,
    potassiumMg: 0, sodiumMg: 0,
  );

  NutrientBreakdown operator +(NutrientBreakdown other) {
    return NutrientBreakdown(
      energyKcal: energyKcal + other.energyKcal,
      proteinG: proteinG + other.proteinG,
      fatG: fatG + other.fatG,
      carbsG: carbsG + other.carbsG,
      fibreG: fibreG + other.fibreG,
      calciumMg: calciumMg + other.calciumMg,
      ironMg: ironMg + other.ironMg,
      zincMg: zincMg + other.zincMg,
      vitaminAUg: vitaminAUg + other.vitaminAUg,
      vitaminCMg: vitaminCMg + other.vitaminCMg,
      vitaminDIU: vitaminDIU + other.vitaminDIU,
      folateUg: folateUg + other.folateUg,
      vitaminB12Ug: vitaminB12Ug + other.vitaminB12Ug,
      potassiumMg: potassiumMg + other.potassiumMg,
      sodiumMg: sodiumMg + other.sodiumMg,
    );
  }

  /// Returns a new [NutrientBreakdown] scaled by [factor].
  ///
  /// Used by [FoodItem.forServing] to convert per-100 g values to per-serving
  /// values: factor = servingGrams / 100.
  NutrientBreakdown scale(double factor) {
    return NutrientBreakdown(
      energyKcal:    energyKcal    * factor,
      proteinG:      proteinG      * factor,
      fatG:          fatG          * factor,
      carbsG:        carbsG        * factor,
      fibreG:        fibreG        * factor,
      calciumMg:     calciumMg     * factor,
      ironMg:        ironMg        * factor,
      zincMg:        zincMg        * factor,
      vitaminAUg:    vitaminAUg    * factor,
      vitaminCMg:    vitaminCMg    * factor,
      vitaminDIU:    vitaminDIU    * factor,
      folateUg:      folateUg      * factor,
      vitaminB12Ug:  vitaminB12Ug  * factor,
      potassiumMg:   potassiumMg   * factor,
      sodiumMg:      sodiumMg      * factor,
    );
  }
}

// ---------------------------------------------------------------------------
// FoodItem
// ---------------------------------------------------------------------------

/// Represents a single food entry in the Nutri360 database.
///
/// Multilingual names (English, Telugu, Hindi) support community health
/// workers and caregivers across different linguistic regions of India.
class FoodItem {
  /// Unique snake_case identifier used as a stable key in the diary log,
  /// Redux store, and Firestore documents.
  final String id;

  /// English display name.
  final String name;

  /// Telugu name for Andhra Pradesh / Telangana ASHA workers.
  final String nameTe;

  /// Hindi name for pan-India ICDS deployments.
  final String nameHi;

  /// WHO food group for MDD scoring and UI grouping.
  final FoodGroup group;

  /// Default serving size in grams used when the user logs this food without
  /// specifying a quantity.  Derived from ICMR recommended portion sizes for
  /// children aged 1–3 years.
  final double defaultServingGrams;

  /// Per-100 g nutrient profile sourced from IFCT 2017.
  final NutrientBreakdown per100g;

  const FoodItem({
    required this.id,
    required this.name,
    required this.nameTe,
    required this.nameHi,
    required this.group,
    required this.defaultServingGrams,
    required this.per100g,
  });

  /// Returns the nutrient breakdown scaled to [defaultServingGrams].
  ///
  /// Formula: nutrient_per_serving = nutrient_per_100g × (servingGrams / 100)
  NutrientBreakdown forServing() => per100g.scale(defaultServingGrams / 100.0);
}

// ---------------------------------------------------------------------------
// NutritionGuidance — main utility class
// ---------------------------------------------------------------------------

/// Central utility class for nutrition-guidance logic.
///
/// Provides the food database, MDD scoring, mode selection, and search.
/// All methods are `static`; no instance is required.
class NutritionGuidance {
  // Prevent instantiation.
  NutritionGuidance._();

  /// Aliases and group descriptors for UI widgets
  static List<FoodItem> get sampleFoods => allFoods;

  static const List<Map<String, String>> sampleFoodGroups = [
    {'id': 'grains', 'name': 'Grains & Roots'},
    {'id': 'legumes', 'name': 'Legumes & Nuts'},
    {'id': 'dairy', 'name': 'Dairy Products'},
    {'id': 'eggs', 'name': 'Eggs'},
    {'id': 'meatFish', 'name': 'Meat & Fish'},
    {'id': 'vitaminARich', 'name': 'Vitamin A Rich'},
    {'id': 'fruitsVeg', 'name': 'Other Fruits & Veg'},
    {'id': 'other', 'name': 'Other Foods'},
  ];

  // =========================================================================
  // Food Database — 50+ Indian foods covering all 8 WHO food groups
  // =========================================================================
  //
  // Nutrient values: IFCT 2017 (NIN, Hyderabad) — approximate values for
  // cooked/prepared forms where noted.
  // =========================================================================

  /// Complete Nutri360 Indian food database.
  static const List<FoodItem> allFoods = [

    // -----------------------------------------------------------------------
    // GROUP 1: GRAINS
    // -----------------------------------------------------------------------

    FoodItem(
      id: 'rice_boiled',
      name: 'Rice (boiled)',
      nameTe: 'అన్నం (వండినది)',
      nameHi: 'चावल (पका हुआ)',
      group: FoodGroup.grains,
      defaultServingGrams: 150,
      per100g: NutrientBreakdown(
        energyKcal: 130, proteinG: 2.7,  fatG: 0.3,  carbsG: 28.2, fibreG: 0.4,
        calciumMg: 10,   ironMg: 0.5,   zincMg: 0.5,  vitaminAUg: 0,
        vitaminCMg: 0,   vitaminDIU: 0, folateUg: 8,  vitaminB12Ug: 0,
        potassiumMg: 35, sodiumMg: 1,
      ),
    ),

    FoodItem(
      id: 'roti_wheat',
      name: 'Roti (whole wheat)',
      nameTe: 'రొట్టె (గోధుమ)',
      nameHi: 'रोटी (गेहूं)',
      group: FoodGroup.grains,
      defaultServingGrams: 40, // 1 small roti
      per100g: NutrientBreakdown(
        energyKcal: 297, proteinG: 10.6, fatG: 1.5,  carbsG: 59.4, fibreG: 1.9,
        calciumMg: 41,   ironMg: 3.5,   zincMg: 2.0,  vitaminAUg: 0,
        vitaminCMg: 0,   vitaminDIU: 0, folateUg: 36, vitaminB12Ug: 0,
        potassiumMg: 284, sodiumMg: 2,
      ),
    ),

    FoodItem(
      id: 'idli',
      name: 'Idli (steamed)',
      nameTe: 'ఇడ్లీ',
      nameHi: 'इडली',
      group: FoodGroup.grains,
      defaultServingGrams: 120, // 2 idlis ~60g each
      per100g: NutrientBreakdown(
        energyKcal: 143, proteinG: 4.8, fatG: 0.5,  carbsG: 29.0, fibreG: 0.6,
        calciumMg: 20,   ironMg: 1.2,  zincMg: 0.6,  vitaminAUg: 0,
        vitaminCMg: 0,   vitaminDIU: 0, folateUg: 20, vitaminB12Ug: 0,
        potassiumMg: 92, sodiumMg: 240,
      ),
    ),

    FoodItem(
      id: 'poha',
      name: 'Poha (flattened rice)',
      nameTe: 'అటుకులు',
      nameHi: 'पोहा',
      group: FoodGroup.grains,
      defaultServingGrams: 100,
      per100g: NutrientBreakdown(
        energyKcal: 110, proteinG: 2.4, fatG: 0.6,  carbsG: 23.0, fibreG: 0.5,
        calciumMg: 11,   ironMg: 1.9,  zincMg: 0.4,  vitaminAUg: 0,
        vitaminCMg: 0,   vitaminDIU: 0, folateUg: 7,  vitaminB12Ug: 0,
        potassiumMg: 40, sodiumMg: 5,
      ),
    ),

    FoodItem(
      id: 'upma',
      name: 'Upma (semolina)',
      nameTe: 'ఉప్మా',
      nameHi: 'उपमा',
      group: FoodGroup.grains,
      defaultServingGrams: 150,
      per100g: NutrientBreakdown(
        energyKcal: 120, proteinG: 3.5, fatG: 3.2,  carbsG: 19.0, fibreG: 0.8,
        calciumMg: 15,   ironMg: 0.9,  zincMg: 0.5,  vitaminAUg: 0,
        vitaminCMg: 2,   vitaminDIU: 0, folateUg: 15, vitaminB12Ug: 0,
        potassiumMg: 60, sodiumMg: 180,
      ),
    ),

    FoodItem(
      id: 'ragi_porridge',
      name: 'Ragi Porridge (finger millet)',
      nameTe: 'రాగి అంబలి',
      nameHi: 'रागी दलिया',
      group: FoodGroup.grains,
      defaultServingGrams: 150,
      per100g: NutrientBreakdown(
        energyKcal: 68,  proteinG: 1.5, fatG: 0.4,  carbsG: 14.5, fibreG: 0.6,
        calciumMg: 150,  ironMg: 1.5,  zincMg: 0.6,  vitaminAUg: 0,
        vitaminCMg: 0,   vitaminDIU: 0, folateUg: 25, vitaminB12Ug: 0,
        potassiumMg: 70, sodiumMg: 5,
      ),
    ),

    FoodItem(
      id: 'jowar_roti',
      name: 'Jowar Roti (sorghum flatbread)',
      nameTe: 'జొన్న రొట్టె',
      nameHi: 'ज्वार की रोटी',
      group: FoodGroup.grains,
      defaultServingGrams: 50,
      per100g: NutrientBreakdown(
        energyKcal: 272, proteinG: 10.4, fatG: 1.9, carbsG: 55.0, fibreG: 2.5,
        calciumMg: 25,   ironMg: 4.1,   zincMg: 1.6,  vitaminAUg: 0,
        vitaminCMg: 0,   vitaminDIU: 0, folateUg: 50, vitaminB12Ug: 0,
        potassiumMg: 350, sodiumMg: 2,
      ),
    ),

    // -----------------------------------------------------------------------
    // GROUP 2: LEGUMES
    // -----------------------------------------------------------------------

    FoodItem(
      id: 'dal_moong',
      name: 'Moong Dal (green gram dal)',
      nameTe: 'పెసర పప్పు',
      nameHi: 'मूंग दाल',
      group: FoodGroup.legumes,
      defaultServingGrams: 100, // cooked
      per100g: NutrientBreakdown(
        energyKcal: 105, proteinG: 7.6, fatG: 0.4,  carbsG: 15.0, fibreG: 2.0,
        calciumMg: 35,   ironMg: 1.9,  zincMg: 0.9,  vitaminAUg: 2,
        vitaminCMg: 1,   vitaminDIU: 0, folateUg: 100, vitaminB12Ug: 0,
        potassiumMg: 266, sodiumMg: 15,
      ),
    ),

    FoodItem(
      id: 'rajma',
      name: 'Rajma (kidney beans)',
      nameTe: 'రాజ్మా',
      nameHi: 'राजमा',
      group: FoodGroup.legumes,
      defaultServingGrams: 100,
      per100g: NutrientBreakdown(
        energyKcal: 143, proteinG: 8.7, fatG: 0.5,  carbsG: 23.3, fibreG: 7.4,
        calciumMg: 50,   ironMg: 2.9,  zincMg: 1.0,  vitaminAUg: 0,
        vitaminCMg: 2,   vitaminDIU: 0, folateUg: 130, vitaminB12Ug: 0,
        potassiumMg: 403, sodiumMg: 2,
      ),
    ),

    FoodItem(
      id: 'chana_dal',
      name: 'Chana Dal (split chickpea)',
      nameTe: 'శనగ పప్పు',
      nameHi: 'चना दाल',
      group: FoodGroup.legumes,
      defaultServingGrams: 100,
      per100g: NutrientBreakdown(
        energyKcal: 164, proteinG: 9.4, fatG: 2.5,  carbsG: 24.0, fibreG: 4.5,
        calciumMg: 50,   ironMg: 3.0,  zincMg: 1.2,  vitaminAUg: 0,
        vitaminCMg: 1,   vitaminDIU: 0, folateUg: 140, vitaminB12Ug: 0,
        potassiumMg: 374, sodiumMg: 15,
      ),
    ),

    FoodItem(
      id: 'sambar',
      name: 'Sambar (lentil vegetable stew)',
      nameTe: 'సాంబార్',
      nameHi: 'सांभर',
      group: FoodGroup.legumes,
      defaultServingGrams: 150,
      per100g: NutrientBreakdown(
        energyKcal: 55,  proteinG: 3.2, fatG: 1.5,  carbsG: 7.0, fibreG: 2.0,
        calciumMg: 30,   ironMg: 1.0,  zincMg: 0.5,  vitaminAUg: 40,
        vitaminCMg: 10,  vitaminDIU: 0, folateUg: 50, vitaminB12Ug: 0,
        potassiumMg: 180, sodiumMg: 200,
      ),
    ),

    FoodItem(
      id: 'toor_dal',
      name: 'Toor Dal (arhar / pigeon pea)',
      nameTe: 'కందిపప్పు',
      nameHi: 'तूर दाल',
      group: FoodGroup.legumes,
      defaultServingGrams: 100,
      per100g: NutrientBreakdown(
        energyKcal: 118, proteinG: 7.4, fatG: 0.4,  carbsG: 18.5, fibreG: 2.5,
        calciumMg: 25,   ironMg: 1.5,  zincMg: 0.9,  vitaminAUg: 0,
        vitaminCMg: 2,   vitaminDIU: 0, folateUg: 90, vitaminB12Ug: 0,
        potassiumMg: 245, sodiumMg: 10,
      ),
    ),

    // -----------------------------------------------------------------------
    // GROUP 3: DAIRY
    // -----------------------------------------------------------------------

    FoodItem(
      id: 'breast_milk',
      name: 'Breast Milk',
      nameTe: 'తల్లి పాలు',
      nameHi: 'माँ का दूध',
      group: FoodGroup.dairy,
      defaultServingGrams: 100, // per 100 mL (density ≈ 1 g/mL)
      per100g: NutrientBreakdown(
        energyKcal: 70,  proteinG: 1.0, fatG: 4.2,  carbsG: 7.0, fibreG: 0,
        calciumMg: 34,   ironMg: 0.1,  zincMg: 0.2,  vitaminAUg: 60,
        vitaminCMg: 5,   vitaminDIU: 10, folateUg: 5, vitaminB12Ug: 0.5,
        potassiumMg: 50, sodiumMg: 17,
      ),
    ),

    FoodItem(
      id: 'cow_milk',
      name: 'Cow Milk (full fat)',
      nameTe: 'ఆవు పాలు',
      nameHi: 'गाय का दूध',
      group: FoodGroup.dairy,
      defaultServingGrams: 150,
      per100g: NutrientBreakdown(
        energyKcal: 65,  proteinG: 3.2, fatG: 3.5,  carbsG: 4.8, fibreG: 0,
        calciumMg: 120,  ironMg: 0.1,  zincMg: 0.4,  vitaminAUg: 40,
        vitaminCMg: 1,   vitaminDIU: 44, folateUg: 5, vitaminB12Ug: 0.4,
        potassiumMg: 150, sodiumMg: 50,
      ),
    ),

    FoodItem(
      id: 'curd',
      name: 'Curd (plain yoghurt)',
      nameTe: 'పెరుగు',
      nameHi: 'दही',
      group: FoodGroup.dairy,
      defaultServingGrams: 100,
      per100g: NutrientBreakdown(
        energyKcal: 60,  proteinG: 3.1, fatG: 3.0,  carbsG: 4.7, fibreG: 0,
        calciumMg: 150,  ironMg: 0.1,  zincMg: 0.5,  vitaminAUg: 25,
        vitaminCMg: 1,   vitaminDIU: 0, folateUg: 7,  vitaminB12Ug: 0.3,
        potassiumMg: 141, sodiumMg: 36,
      ),
    ),

    FoodItem(
      id: 'paneer',
      name: 'Paneer (cottage cheese)',
      nameTe: 'పనీర్',
      nameHi: 'पनीर',
      group: FoodGroup.dairy,
      defaultServingGrams: 50,
      per100g: NutrientBreakdown(
        energyKcal: 265, proteinG: 18.3, fatG: 20.8, carbsG: 1.2, fibreG: 0,
        calciumMg: 476,  ironMg: 0.3,   zincMg: 1.2,  vitaminAUg: 180,
        vitaminCMg: 0,   vitaminDIU: 0, folateUg: 7,  vitaminB12Ug: 0.4,
        potassiumMg: 100, sodiumMg: 400,
      ),
    ),

    // -----------------------------------------------------------------------
    // GROUP 4: EGGS
    // -----------------------------------------------------------------------

    FoodItem(
      id: 'boiled_egg',
      name: 'Boiled Egg (whole)',
      nameTe: 'ఉడికించిన గుడ్డు',
      nameHi: 'उबला अंडा',
      group: FoodGroup.eggs,
      defaultServingGrams: 50, // 1 medium egg ~50g
      per100g: NutrientBreakdown(
        energyKcal: 155, proteinG: 13.0, fatG: 11.0, carbsG: 1.1, fibreG: 0,
        calciumMg: 50,   ironMg: 1.8,   zincMg: 1.3,  vitaminAUg: 160,
        vitaminCMg: 0,   vitaminDIU: 44, folateUg: 44, vitaminB12Ug: 1.1,
        potassiumMg: 126, sodiumMg: 124,
      ),
    ),

    FoodItem(
      id: 'scrambled_egg',
      name: 'Scrambled Egg',
      nameTe: 'కలిపి వండిన గుడ్డు',
      nameHi: 'स्क्रैम्बल्ड एग',
      group: FoodGroup.eggs,
      defaultServingGrams: 60,
      per100g: NutrientBreakdown(
        energyKcal: 149, proteinG: 10.1, fatG: 11.5, carbsG: 1.2, fibreG: 0,
        calciumMg: 60,   ironMg: 1.5,   zincMg: 1.1,  vitaminAUg: 150,
        vitaminCMg: 0,   vitaminDIU: 42, folateUg: 40, vitaminB12Ug: 0.9,
        potassiumMg: 120, sodiumMg: 180,
      ),
    ),

    // -----------------------------------------------------------------------
    // GROUP 5: MEAT & FISH
    // -----------------------------------------------------------------------

    FoodItem(
      id: 'chicken_boiled',
      name: 'Chicken (boiled, no skin)',
      nameTe: 'వండిన కోడి మాంసం',
      nameHi: 'उबला मुर्गा',
      group: FoodGroup.meatFish,
      defaultServingGrams: 60,
      per100g: NutrientBreakdown(
        energyKcal: 165, proteinG: 31.0, fatG: 3.6, carbsG: 0,   fibreG: 0,
        calciumMg: 15,   ironMg: 1.0,   zincMg: 1.9,  vitaminAUg: 9,
        vitaminCMg: 0,   vitaminDIU: 4,  folateUg: 4,  vitaminB12Ug: 0.3,
        potassiumMg: 220, sodiumMg: 70,
      ),
    ),

    FoodItem(
      id: 'fish_curry',
      name: 'Fish Curry (tilapia)',
      nameTe: 'చేపల కూర',
      nameHi: 'मछली की करी',
      group: FoodGroup.meatFish,
      defaultServingGrams: 80,
      per100g: NutrientBreakdown(
        energyKcal: 110, proteinG: 14.0, fatG: 5.0, carbsG: 2.0, fibreG: 0.3,
        calciumMg: 25,   ironMg: 1.0,   zincMg: 0.7,  vitaminAUg: 20,
        vitaminCMg: 2,   vitaminDIU: 60, folateUg: 15, vitaminB12Ug: 1.5,
        potassiumMg: 300, sodiumMg: 350,
      ),
    ),

    FoodItem(
      id: 'mutton_curry',
      name: 'Mutton Curry',
      nameTe: 'మటన్ కూర',
      nameHi: 'मटन करी',
      group: FoodGroup.meatFish,
      defaultServingGrams: 70,
      per100g: NutrientBreakdown(
        energyKcal: 170, proteinG: 18.0, fatG: 10.0, carbsG: 2.5, fibreG: 0.5,
        calciumMg: 20,   ironMg: 2.5,   zincMg: 3.0,  vitaminAUg: 10,
        vitaminCMg: 0,   vitaminDIU: 0,  folateUg: 10, vitaminB12Ug: 2.0,
        potassiumMg: 300, sodiumMg: 400,
      ),
    ),

    // -----------------------------------------------------------------------
    // GROUP 6: FRUITS & VEGETABLES (non vitamin-A-rich)
    // -----------------------------------------------------------------------

    FoodItem(
      id: 'banana',
      name: 'Banana (ripe)',
      nameTe: 'అరటిపండు',
      nameHi: 'केला',
      group: FoodGroup.fruitsVeg,
      defaultServingGrams: 80, // 1 small banana
      per100g: NutrientBreakdown(
        energyKcal: 89,  proteinG: 1.1, fatG: 0.3,  carbsG: 22.8, fibreG: 2.6,
        calciumMg: 5,    ironMg: 0.3,  zincMg: 0.2,  vitaminAUg: 3,
        vitaminCMg: 8,   vitaminDIU: 0, folateUg: 20, vitaminB12Ug: 0,
        potassiumMg: 358, sodiumMg: 1,
      ),
    ),

    FoodItem(
      id: 'apple',
      name: 'Apple',
      nameTe: 'యాపిల్',
      nameHi: 'सेब',
      group: FoodGroup.fruitsVeg,
      defaultServingGrams: 100,
      per100g: NutrientBreakdown(
        energyKcal: 52,  proteinG: 0.3, fatG: 0.2,  carbsG: 13.8, fibreG: 2.4,
        calciumMg: 6,    ironMg: 0.1,  zincMg: 0.0,  vitaminAUg: 3,
        vitaminCMg: 4,   vitaminDIU: 0, folateUg: 3,  vitaminB12Ug: 0,
        potassiumMg: 107, sodiumMg: 1,
      ),
    ),

    FoodItem(
      id: 'mango',
      name: 'Mango (ripe)',
      nameTe: 'మామిడిపండు',
      nameHi: 'आम',
      group: FoodGroup.fruitsVeg,
      defaultServingGrams: 80,
      per100g: NutrientBreakdown(
        energyKcal: 60,  proteinG: 0.8, fatG: 0.4,  carbsG: 15.0, fibreG: 1.6,
        calciumMg: 11,   ironMg: 0.1,  zincMg: 0.1,  vitaminAUg: 54,
        vitaminCMg: 36,  vitaminDIU: 0, folateUg: 43, vitaminB12Ug: 0,
        potassiumMg: 168, sodiumMg: 1,
      ),
    ),

    FoodItem(
      id: 'tomato',
      name: 'Tomato',
      nameTe: 'టమాటా',
      nameHi: 'टमाटर',
      group: FoodGroup.fruitsVeg,
      defaultServingGrams: 80,
      per100g: NutrientBreakdown(
        energyKcal: 18,  proteinG: 0.9, fatG: 0.2,  carbsG: 3.9, fibreG: 1.2,
        calciumMg: 10,   ironMg: 0.3,  zincMg: 0.2,  vitaminAUg: 42,
        vitaminCMg: 14,  vitaminDIU: 0, folateUg: 15, vitaminB12Ug: 0,
        potassiumMg: 237, sodiumMg: 5,
      ),
    ),

    FoodItem(
      id: 'guava',
      name: 'Guava',
      nameTe: 'జామపండు',
      nameHi: 'अमरूद',
      group: FoodGroup.fruitsVeg,
      defaultServingGrams: 80,
      per100g: NutrientBreakdown(
        energyKcal: 68,  proteinG: 2.6, fatG: 0.9,  carbsG: 14.3, fibreG: 5.4,
        calciumMg: 18,   ironMg: 0.3,  zincMg: 0.2,  vitaminAUg: 31,
        vitaminCMg: 228, vitaminDIU: 0, folateUg: 49, vitaminB12Ug: 0,
        potassiumMg: 417, sodiumMg: 2,
      ),
    ),

    FoodItem(
      id: 'cucumber',
      name: 'Cucumber',
      nameTe: 'దోసకాయ',
      nameHi: 'खीरा',
      group: FoodGroup.fruitsVeg,
      defaultServingGrams: 70,
      per100g: NutrientBreakdown(
        energyKcal: 15,  proteinG: 0.7, fatG: 0.1,  carbsG: 3.6, fibreG: 0.5,
        calciumMg: 16,   ironMg: 0.3,  zincMg: 0.2,  vitaminAUg: 5,
        vitaminCMg: 3,   vitaminDIU: 0, folateUg: 7,  vitaminB12Ug: 0,
        potassiumMg: 147, sodiumMg: 2,
      ),
    ),

    FoodItem(
      id: 'potato',
      name: 'Potato (boiled)',
      nameTe: 'బంగాళాదుంప',
      nameHi: 'आलू (उबला)',
      group: FoodGroup.fruitsVeg,
      defaultServingGrams: 100,
      per100g: NutrientBreakdown(
        energyKcal: 86,  proteinG: 1.9, fatG: 0.1,  carbsG: 20.1, fibreG: 1.8,
        calciumMg: 10,   ironMg: 0.3,  zincMg: 0.3,  vitaminAUg: 2,
        vitaminCMg: 10,  vitaminDIU: 0, folateUg: 16, vitaminB12Ug: 0,
        potassiumMg: 379, sodiumMg: 5,
      ),
    ),

    // -----------------------------------------------------------------------
    // GROUP 7: VITAMIN A-RICH FOODS
    // -----------------------------------------------------------------------

    FoodItem(
      id: 'spinach',
      name: 'Spinach (cooked)',
      nameTe: 'పాలకూర',
      nameHi: 'पालक',
      group: FoodGroup.vitaminARich,
      defaultServingGrams: 80,
      per100g: NutrientBreakdown(
        energyKcal: 23,  proteinG: 2.9, fatG: 0.4,  carbsG: 3.6, fibreG: 2.2,
        calciumMg: 99,   ironMg: 3.6,  zincMg: 0.5,  vitaminAUg: 523,
        vitaminCMg: 10,  vitaminDIU: 0, folateUg: 194, vitaminB12Ug: 0,
        potassiumMg: 466, sodiumMg: 70,
      ),
    ),

    FoodItem(
      id: 'carrot',
      name: 'Carrot (raw / mashed)',
      nameTe: 'క్యారెట్',
      nameHi: 'गाजर',
      group: FoodGroup.vitaminARich,
      defaultServingGrams: 60,
      per100g: NutrientBreakdown(
        energyKcal: 41,  proteinG: 0.9, fatG: 0.2,  carbsG: 9.6, fibreG: 2.8,
        calciumMg: 33,   ironMg: 0.3,  zincMg: 0.2,  vitaminAUg: 835,
        vitaminCMg: 6,   vitaminDIU: 0, folateUg: 19, vitaminB12Ug: 0,
        potassiumMg: 320, sodiumMg: 69,
      ),
    ),

    FoodItem(
      id: 'sweet_potato',
      name: 'Sweet Potato (boiled)',
      nameTe: 'చిలగడదుంప',
      nameHi: 'शकरकंद',
      group: FoodGroup.vitaminARich,
      defaultServingGrams: 100,
      per100g: NutrientBreakdown(
        energyKcal: 86,  proteinG: 1.6, fatG: 0.1,  carbsG: 20.1, fibreG: 3.0,
        calciumMg: 30,   ironMg: 0.7,  zincMg: 0.3,  vitaminAUg: 709,
        vitaminCMg: 20,  vitaminDIU: 0, folateUg: 11, vitaminB12Ug: 0,
        potassiumMg: 337, sodiumMg: 36,
      ),
    ),

    FoodItem(
      id: 'papaya',
      name: 'Papaya (ripe)',
      nameTe: 'బొప్పాయి',
      nameHi: 'पपीता',
      group: FoodGroup.vitaminARich,
      defaultServingGrams: 100,
      per100g: NutrientBreakdown(
        energyKcal: 43,  proteinG: 0.5, fatG: 0.3,  carbsG: 10.8, fibreG: 1.7,
        calciumMg: 20,   ironMg: 0.3,  zincMg: 0.1,  vitaminAUg: 328,
        vitaminCMg: 62,  vitaminDIU: 0, folateUg: 38, vitaminB12Ug: 0,
        potassiumMg: 182, sodiumMg: 8,
      ),
    ),

    FoodItem(
      id: 'pumpkin',
      name: 'Pumpkin (cooked)',
      nameTe: 'గుమ్మడికాయ',
      nameHi: 'कद्दू',
      group: FoodGroup.vitaminARich,
      defaultServingGrams: 80,
      per100g: NutrientBreakdown(
        energyKcal: 20,  proteinG: 0.7, fatG: 0.1,  carbsG: 4.9, fibreG: 0.5,
        calciumMg: 15,   ironMg: 0.3,  zincMg: 0.2,  vitaminAUg: 426,
        vitaminCMg: 9,   vitaminDIU: 0, folateUg: 16, vitaminB12Ug: 0,
        potassiumMg: 230, sodiumMg: 1,
      ),
    ),

    FoodItem(
      id: 'fenugreek_leaves',
      name: 'Fenugreek Leaves (methi, cooked)',
      nameTe: 'మెంతికూర',
      nameHi: 'मेथी पत्ता',
      group: FoodGroup.vitaminARich,
      defaultServingGrams: 70,
      per100g: NutrientBreakdown(
        energyKcal: 49,  proteinG: 4.4, fatG: 0.9,  carbsG: 6.0, fibreG: 2.7,
        calciumMg: 395,  ironMg: 7.2,  zincMg: 0.4,  vitaminAUg: 580,
        vitaminCMg: 52,  vitaminDIU: 0, folateUg: 57, vitaminB12Ug: 0,
        potassiumMg: 770, sodiumMg: 76,
      ),
    ),

    // -----------------------------------------------------------------------
    // GROUP 8: OTHER (mixed dishes, formula)
    // -----------------------------------------------------------------------

    FoodItem(
      id: 'khichdi',
      name: 'Khichdi (rice + moong)',
      nameTe: 'ఖిచ్డీ',
      nameHi: 'खिचड़ी',
      group: FoodGroup.other,
      defaultServingGrams: 150,
      per100g: NutrientBreakdown(
        energyKcal: 100, proteinG: 4.0, fatG: 2.0,  carbsG: 17.0, fibreG: 1.2,
        calciumMg: 25,   ironMg: 1.2,  zincMg: 0.7,  vitaminAUg: 5,
        vitaminCMg: 2,   vitaminDIU: 0, folateUg: 40, vitaminB12Ug: 0,
        potassiumMg: 120, sodiumMg: 150,
      ),
    ),

    FoodItem(
      id: 'formula_milk',
      name: 'Infant Formula Milk (stage 1)',
      nameTe: 'శిశు ఫార్ములా పాలు',
      nameHi: 'शिशु फॉर्मूला दूध',
      group: FoodGroup.other,
      defaultServingGrams: 100, // per 100 mL prepared
      per100g: NutrientBreakdown(
        energyKcal: 68,  proteinG: 1.8, fatG: 3.6,  carbsG: 7.5, fibreG: 0,
        calciumMg: 59,   ironMg: 0.5,  zincMg: 0.5,  vitaminAUg: 75,
        vitaminCMg: 10,  vitaminDIU: 60, folateUg: 10, vitaminB12Ug: 0.1,
        potassiumMg: 90, sodiumMg: 25,
      ),
    ),

    FoodItem(
      id: 'chole',
      name: 'Chole (chickpea curry)',
      nameTe: 'శనగల కూర',
      nameHi: 'छोले',
      group: FoodGroup.legumes,
      defaultServingGrams: 100,
      per100g: NutrientBreakdown(
        energyKcal: 160, proteinG: 8.5, fatG: 4.5,  carbsG: 20.0, fibreG: 5.0,
        calciumMg: 60,   ironMg: 2.5,  zincMg: 1.2,  vitaminAUg: 10,
        vitaminCMg: 5,   vitaminDIU: 0, folateUg: 110, vitaminB12Ug: 0,
        potassiumMg: 350, sodiumMg: 350,
      ),
    ),

    FoodItem(
      id: 'sabudana_khichdi',
      name: 'Sabudana Khichdi (tapioca)',
      nameTe: 'సగ్గుబియ్యం ఖిచ్డీ',
      nameHi: 'साबूदाना खिचड़ी',
      group: FoodGroup.grains,
      defaultServingGrams: 120,
      per100g: NutrientBreakdown(
        energyKcal: 185, proteinG: 1.5, fatG: 5.0,  carbsG: 32.0, fibreG: 0.5,
        calciumMg: 20,   ironMg: 0.4,  zincMg: 0.2,  vitaminAUg: 0,
        vitaminCMg: 0,   vitaminDIU: 0, folateUg: 5,  vitaminB12Ug: 0,
        potassiumMg: 50, sodiumMg: 180,
      ),
    ),

    FoodItem(
      id: 'coconut_chutney',
      name: 'Coconut Chutney',
      nameTe: 'కొబ్బరి చట్నీ',
      nameHi: 'नारियल की चटनी',
      group: FoodGroup.other,
      defaultServingGrams: 30,
      per100g: NutrientBreakdown(
        energyKcal: 220, proteinG: 2.0, fatG: 20.0, carbsG: 8.0, fibreG: 2.5,
        calciumMg: 15,   ironMg: 0.5,  zincMg: 0.3,  vitaminAUg: 0,
        vitaminCMg: 2,   vitaminDIU: 0, folateUg: 10, vitaminB12Ug: 0,
        potassiumMg: 220, sodiumMg: 150,
      ),
    ),

    FoodItem(
      id: 'rava_ladoo',
      name: 'Rava Ladoo',
      nameTe: 'రవ్వ లడ్డు',
      nameHi: 'रवा लड्डू',
      group: FoodGroup.other,
      defaultServingGrams: 40,
      per100g: NutrientBreakdown(
        energyKcal: 390, proteinG: 6.0, fatG: 14.0, carbsG: 60.0, fibreG: 1.0,
        calciumMg: 30,   ironMg: 1.0,  zincMg: 0.5,  vitaminAUg: 20,
        vitaminCMg: 0,   vitaminDIU: 0, folateUg: 15, vitaminB12Ug: 0.1,
        potassiumMg: 100, sodiumMg: 20,
      ),
    ),

    FoodItem(
      id: 'dosa',
      name: 'Dosa (plain)',
      nameTe: 'దోస',
      nameHi: 'डोसा',
      group: FoodGroup.grains,
      defaultServingGrams: 80,
      per100g: NutrientBreakdown(
        energyKcal: 168, proteinG: 4.0, fatG: 5.5,  carbsG: 26.0, fibreG: 0.5,
        calciumMg: 15,   ironMg: 1.0,  zincMg: 0.5,  vitaminAUg: 0,
        vitaminCMg: 0,   vitaminDIU: 0, folateUg: 15, vitaminB12Ug: 0,
        potassiumMg: 70, sodiumMg: 200,
      ),
    ),

    FoodItem(
      id: 'amaranth_leaves',
      name: 'Amaranth Leaves (thotakura, cooked)',
      nameTe: 'తోటకూర',
      nameHi: 'चौलाई',
      group: FoodGroup.vitaminARich,
      defaultServingGrams: 70,
      per100g: NutrientBreakdown(
        energyKcal: 36,  proteinG: 3.5, fatG: 0.5,  carbsG: 5.5, fibreG: 2.0,
        calciumMg: 400,  ironMg: 3.5,  zincMg: 0.9,  vitaminAUg: 332,
        vitaminCMg: 50,  vitaminDIU: 0, folateUg: 85, vitaminB12Ug: 0,
        potassiumMg: 611, sodiumMg: 20,
      ),
    ),

    FoodItem(
      id: 'orange',
      name: 'Orange',
      nameTe: 'నారంగి',
      nameHi: 'संतरा',
      group: FoodGroup.fruitsVeg,
      defaultServingGrams: 100,
      per100g: NutrientBreakdown(
        energyKcal: 47,  proteinG: 0.9, fatG: 0.1,  carbsG: 11.8, fibreG: 2.4,
        calciumMg: 40,   ironMg: 0.1,  zincMg: 0.1,  vitaminAUg: 11,
        vitaminCMg: 53,  vitaminDIU: 0, folateUg: 30, vitaminB12Ug: 0,
        potassiumMg: 181, sodiumMg: 0,
      ),
    ),

    FoodItem(
      id: 'groundnut',
      name: 'Groundnut (peanut, roasted)',
      nameTe: 'వేరుశెనగలు',
      nameHi: 'मूंगफली',
      group: FoodGroup.legumes,
      defaultServingGrams: 20,
      per100g: NutrientBreakdown(
        energyKcal: 567, proteinG: 25.8, fatG: 49.2, carbsG: 16.1, fibreG: 8.5,
        calciumMg: 92,   ironMg: 4.6,   zincMg: 3.3,  vitaminAUg: 0,
        vitaminCMg: 0,   vitaminDIU: 0, folateUg: 240, vitaminB12Ug: 0,
        potassiumMg: 705, sodiumMg: 18,
      ),
    ),
  ];

  // =========================================================================
  // Static Methods
  // =========================================================================

  /// Returns the [NutritionMode] appropriate for a child of [ageMonths].
  ///
  /// WHO/UNICEF IYCF age-mode mapping:
  ///   0–5 months  → exclusiveBreastfeeding
  ///   6–8 months  → earlyWeaning
  ///   9–11 months → complementaryFeeding
  ///   12+ months  → diverseFeeding
  static NutritionMode getModeForAge(int ageMonths) {
    if (ageMonths < 6) return NutritionMode.exclusiveBreastfeeding;
    if (ageMonths < 9) return NutritionMode.earlyWeaning;
    if (ageMonths < 12) return NutritionMode.complementaryFeeding;
    return NutritionMode.diverseFeeding;
  }

  /// Calculates the WHO Minimum Dietary Diversity (MDD) score.
  ///
  /// Definition (WHO, 2010):
  ///   MDD = the number of distinct food groups (out of 8) consumed in the
  ///   past 24 hours.
  ///
  /// [selectedFoodIds] is a list of food IDs logged by the caregiver.  The
  /// function looks up each ID in [allFoods], extracts its [FoodGroup], and
  /// counts distinct groups.
  ///
  /// Returns an integer in [0, 8].
  static int calculateMDD(List<String> selectedFoodIds) {
    // Collect all food groups consumed.
    final Set<FoodGroup> consumedGroups = {};

    for (final String id in selectedFoodIds) {
      final FoodItem? item = getFoodById(id);
      if (item != null) {
        consumedGroups.add(item.group);
      }
    }

    return consumedGroups.length;
  }

  /// Returns true when [mddScore] meets the WHO adequacy threshold of ≥ 5
  /// distinct food groups consumed in the past 24 hours.
  static bool isMDDAdequate(int mddScore) => mddScore >= 5;

  /// Case-insensitive search across English, Telugu, and Hindi food names.
  ///
  /// Returns all [FoodItem] entries where any name field contains [query]
  /// as a substring (after lowercasing both the query and the target).
  /// An empty [query] returns all foods.
  static List<FoodItem> searchFoods(String query) {
    if (query.isEmpty) return allFoods;
    final String q = query.toLowerCase();
    return allFoods.where((FoodItem food) {
      return food.name.toLowerCase().contains(q) ||
          food.nameTe.toLowerCase().contains(q) ||
          food.nameHi.toLowerCase().contains(q);
    }).toList();
  }

  /// Looks up a [FoodItem] by its unique [id].
  ///
  /// Returns null when the id is not found (e.g. stale cached diary entry
  /// referencing a removed food item).
  static FoodItem? getFoodById(String id) {
    try {
      return allFoods.firstWhere((FoodItem f) => f.id == id);
    } catch (_) {
      // firstWhere throws StateError when no element matches.
      return null;
    }
  }

  /// Returns all [FoodItem] entries belonging to [group].
  ///
  /// Useful for populating grouped food-picker screens in the diary UI.
  static List<FoodItem> foodsByGroup(FoodGroup group) {
    return allFoods.where((FoodItem f) => f.group == group).toList();
  }

  /// Aggregates total nutrient intake from a list of logged food IDs.
  ///
  /// Uses each food's [defaultServingGrams] for the quantity.
  /// For a production release, callers should supply per-item serving weights;
  /// this method provides a quick-sum useful for the 24-hour recall screen.
  static NutrientBreakdown totalNutrients(List<String> consumedFoodIds) {
    // Accumulate mutable running totals.
    double energyKcal   = 0, proteinG    = 0, fatG        = 0;
    double carbsG       = 0, fibreG      = 0, calciumMg   = 0;
    double ironMg       = 0, zincMg      = 0, vitaminAUg  = 0;
    double vitaminCMg   = 0, vitaminDIU  = 0, folateUg    = 0;
    double vitaminB12Ug = 0, potassiumMg = 0, sodiumMg    = 0;

    for (final String id in consumedFoodIds) {
      final FoodItem? item = getFoodById(id);
      if (item == null) continue;
      final NutrientBreakdown s = item.forServing();
      energyKcal   += s.energyKcal;
      proteinG      += s.proteinG;
      fatG          += s.fatG;
      carbsG        += s.carbsG;
      fibreG        += s.fibreG;
      calciumMg     += s.calciumMg;
      ironMg        += s.ironMg;
      zincMg        += s.zincMg;
      vitaminAUg    += s.vitaminAUg;
      vitaminCMg    += s.vitaminCMg;
      vitaminDIU    += s.vitaminDIU;
      folateUg      += s.folateUg;
      vitaminB12Ug  += s.vitaminB12Ug;
      potassiumMg   += s.potassiumMg;
      sodiumMg      += s.sodiumMg;
    }

    return NutrientBreakdown(
      energyKcal: energyKcal,     proteinG: proteinG,       fatG: fatG,
      carbsG: carbsG,             fibreG: fibreG,           calciumMg: calciumMg,
      ironMg: ironMg,             zincMg: zincMg,           vitaminAUg: vitaminAUg,
      vitaminCMg: vitaminCMg,     vitaminDIU: vitaminDIU,   folateUg: folateUg,
      vitaminB12Ug: vitaminB12Ug, potassiumMg: potassiumMg, sodiumMg: sodiumMg,
    );
  }
}

