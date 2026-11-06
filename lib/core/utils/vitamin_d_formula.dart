// =============================================================================
// vitamin_d_formula.dart
// =============================================================================
//
// WHAT: Dual-source Vitamin D calculation engine for the Nutri360 app.
//
//       Two independent Vitamin D sources are modelled:
//         1. Dietary intake (IU) — from the user's nutrition diary.
//         2. Cutaneous synthesis — from UVB sun exposure (NutriBand sensor
//            data or manually logged sunlight minutes).
//
//       The engine returns a [VitaminDResult] object that bundles both source
//       contributions, the grand total, body surface area, percentage of the
//       paediatric RDA, and a human-readable status label + colour.
//
// WHY:  Vitamin D deficiency is endemic in Indian infants due to limited
//       dietary sources and culturally reduced sun exposure.  Nutri360 must
//       quantify BOTH sources to give caregivers an accurate picture and
//       targeted guidance (e.g. "increase sunbathing by 10 minutes" vs
//       "introduce egg yolk").
//
// PORT: Direct port of vitaminDFormula.ts from the Nutri360 React Native
//       codebase.  Webb & Holick biophysical model constants are preserved.
//
// FORMULAE (embedded as comments throughout the file):
//   BSA (m²)          = 0.007184 × weight(kg)^0.425 × height(cm)^0.725
//   Sunlight Vit D (IU) = minutes × UVI × BSA × 16
//   Total Vit D (IU)  = dietary IU + sunlight IU
//   % RDA             = (total IU / 400) × 100
//
// REFERENCES:
//   Webb AR, Holick MF (1988). The role of sunlight in the cutaneous
//     production of Vitamin D3. Annu Rev Nutr 8:375-99.
//   AAP (2022). Vitamin D supplementation: 400 IU/day for infants 0–12 mo.
//   DuBois D, DuBois EF (1916). BSA formula. Arch Intern Med 17:863-71.
// =============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// VitaminDResult — the data class returned by VitaminDCalculator.calculateTotal
// ---------------------------------------------------------------------------

/// Immutable result object produced by [VitaminDCalculator.calculateTotal].
///
/// All IU values are doubles to allow fractional accumulation from multiple
/// foods in a single diary session.
class VitaminDResult {
  /// Vitamin D contributed by food intake (IU), as summed from the nutrition
  /// diary by the caller.
  final double dietaryIU;

  /// Vitamin D synthesised by UVB skin exposure (IU), computed from the
  /// Webb & Holick model.
  final double sunlightIU;

  /// Grand total Vitamin D intake: dietary + sunlight (IU).
  final double totalIU;

  /// Estimated body surface area in m², computed by the DuBois formula.
  final double bsa;

  /// Total IU expressed as a percentage of the paediatric RDA (400 IU/day),
  /// clamped to [0, 200] to prevent UI overflow at extremes.
  final double percentOfRDA;

  const VitaminDResult({
    required this.dietaryIU,
    required this.sunlightIU,
    required this.totalIU,
    required this.bsa,
    required this.percentOfRDA,
  });

  // -------------------------------------------------------------------------
  // Derived display properties
  // -------------------------------------------------------------------------

  /// Human-readable status label derived from total Vitamin D intake.
  ///
  /// Thresholds follow AAP / ESPGHAN clinical classification:
  ///   < 100 IU → Deficient    (immediate supplementation needed)
  ///   < 200 IU → Insufficient (supplementation recommended)
  ///   < 400 IU → Adequate     (meeting minimum RDA)
  ///   ≥ 400 IU → Optimal      (meeting full RDA)
  String get statusLabel {
    if (totalIU < 100) return 'Deficient';
    if (totalIU < 200) return 'Insufficient';
    if (totalIU < 400) return 'Adequate';
    return 'Optimal';
  }

  /// Flutter [Color] matching [statusLabel] for use in dashboard badges,
  /// progress rings, and alert banners.
  ///
  ///   Deficient    → Red    (immediate clinical concern)
  ///   Insufficient → Amber  (caution)
  ///   Adequate     → Blue   (acceptable, can improve)
  ///   Optimal      → Green  (target achieved)
  Color get statusColor {
    switch (statusLabel) {
      case 'Deficient':
        return const Color(0xFFF44336);   // Material Red 500
      case 'Insufficient':
        return const Color(0xFFFF9800);   // Material Amber 600
      case 'Adequate':
        return const Color(0xFF2196F3);   // Material Blue 500
      case 'Optimal':
      default:
        return const Color(0xFF4CAF50);   // Material Green 500
    }
  }

  @override
  String toString() =>
      'VitaminDResult(dietary=${dietaryIU.toStringAsFixed(1)} IU, '
      'sunlight=${sunlightIU.toStringAsFixed(1)} IU, '
      'total=${totalIU.toStringAsFixed(1)} IU, '
      'BSA=${bsa.toStringAsFixed(3)} m², '
      'RDA=${percentOfRDA.toStringAsFixed(1)}%, '
      'status=$statusLabel)';
}

// ---------------------------------------------------------------------------
// VitaminDCalculator — pure-static calculation engine
// ---------------------------------------------------------------------------

/// Engine that computes Vitamin D intake from dietary and cutaneous sources.
///
/// All methods are `static`.  No instance state is maintained.
class VitaminDCalculator {
  // Prevent instantiation.
  VitaminDCalculator._();

  // -------------------------------------------------------------------------
  // Paediatric Vitamin D RDA constant
  // -------------------------------------------------------------------------

  /// Paediatric Recommended Dietary Allowance for Vitamin D (IU/day).
  ///
  /// Source: American Academy of Pediatrics (2022) and WHO (2012).
  /// 400 IU/day for all infants from birth to 12 months.
  /// 600 IU/day for children 1–18 years; we retain 400 as the shared
  /// baseline threshold used by Nutri360's alert system.
  static const double pediatricRDA = 400.0;

  // -------------------------------------------------------------------------
  // Webb & Holick sunlight model constant
  // -------------------------------------------------------------------------

  /// Empirical scaling factor (IU per minute per UVI unit per m² BSA) derived
  /// from Webb & Holick (1988) for fair-to-medium skin tone (Fitzpatrick II–IV).
  ///
  /// Sunlight IU = minutes × UVI × BSA(m²) × [this constant]
  static const double _webHolickFactor = 16.0;

  /// Safety ceiling for sunlight-derived Vitamin D (IU).
  ///
  /// The skin's photosynthetic pathway self-limits above this threshold via
  /// photodegradation of pre-vitamin D3.  Clamping prevents the model from
  /// suggesting physiologically impossible values during long UV exposures.
  static const double _sunlightMaxIU = 2000.0;

  // -------------------------------------------------------------------------
  // Public methods
  // -------------------------------------------------------------------------

  /// Estimates body surface area using the DuBois & DuBois (1916) formula.
  ///
  /// Formula:
  ///   BSA (m²) = 0.007184 × weight(kg)^0.425 × height(cm)^0.725
  ///
  /// This is the most widely validated BSA formula for infants and children,
  /// and is used by the Webb & Holick sunlight model to scale cutaneous
  /// synthesis to the individual child's exposed skin surface.
  ///
  /// [weightKg] must be > 0.  [heightCm] must be > 0.
  /// Returns 0.0 on invalid inputs to prevent downstream NaN propagation.
  static double estimateBSA({
    required double weightKg,
    required double heightCm,
  }) {
    // Guard: reject non-positive anthropometric measurements.
    if (weightKg <= 0 || heightCm <= 0) return 0.0;

    // DuBois formula:
    //   BSA = 0.007184 × W^0.425 × H^0.725
    return 0.007184 *
        math.pow(weightKg, 0.425) *
        math.pow(heightCm, 0.725);
  }

  /// Calculates Vitamin D synthesised from UVB sun exposure.
  ///
  /// Webb & Holick biophysical model (simplified linear form):
  ///   Sunlight IU = minutes × UVI × BSA(m²) × 16
  ///
  /// Assumptions / limitations:
  ///   • Applies to UV Index 1–11 (the range validated by Webb & Holick).
  ///   • Assumes arms + face exposed (≈ 25–30% of total BSA for an infant).
  ///     Callers should pass the exposed-fraction BSA when known.
  ///   • Does not model melanin skin-tone corrections; Nutri360 v2 may add
  ///     a Fitzpatrick scale multiplier.
  ///
  /// The result is clamped to [0, 2000] IU — the physiological self-limiting
  /// ceiling of cutaneous Vitamin D synthesis.
  static double calculateSunlightVitaminD({
    required double minutes,
    required double uvi,
    required double bsa, // exposed body surface area in m²
  }) {
    // Guard: negative inputs are physiologically impossible.
    if (minutes <= 0 || uvi <= 0 || bsa <= 0) return 0.0;

    // Sunlight IU = minutes × UVI × BSA × webHolickFactor
    final double rawIU = minutes * uvi * bsa * _webHolickFactor;

    // Clamp to the physiological ceiling.
    return rawIU.clamp(0.0, _sunlightMaxIU);
  }

  /// Performs the complete dual-source Vitamin D calculation.
  ///
  /// Steps:
  ///   1. Compute BSA from [weightKg] and [heightCm] using the DuBois formula.
  ///   2. Compute sunlight IU from [sunlightMinutes] and [uvi] using the
  ///      Webb & Holick model.
  ///   3. Sum dietary and sunlight IU to get total IU.
  ///   4. Compute percentage of the 400 IU/day paediatric RDA.
  ///   5. Return a [VitaminDResult] with all values and derived display props.
  ///
  /// Parameters:
  ///   [dietaryVitaminD]  — IU accumulated from the nutrition diary.
  ///   [sunlightMinutes]  — Minutes of UVB-effective sun exposure today.
  ///   [uvi]              — UV Index at time of exposure (from NutriBand or
  ///                        a weather API).
  ///   [weightKg]         — Child's current weight in kilograms.
  ///   [heightCm]         — Child's current height in centimetres.
  static VitaminDResult calculateTotal({
    required double dietaryVitaminD,  // IU from food diary
    required double sunlightMinutes,
    required double uvi,
    required double weightKg,
    required double heightCm,
  }) {
    // Step 1 — Estimate body surface area.
    // BSA (m²) = 0.007184 × weight(kg)^0.425 × height(cm)^0.725
    final double bsa = estimateBSA(weightKg: weightKg, heightCm: heightCm);

    // Step 2 — Cutaneous synthesis.
    // Sunlight IU = minutes × UVI × BSA × 16   [clamped to 2000 IU]
    final double sunlightIU = calculateSunlightVitaminD(
      minutes: sunlightMinutes,
      uvi: uvi,
      bsa: bsa,
    );

    // Step 3 — Grand total.
    // Total IU = dietary IU + sunlight IU
    final double totalIU = dietaryVitaminD + sunlightIU;

    // Step 4 — Percentage of RDA (clamped to [0, 200] for display).
    // % RDA = (total IU / 400) × 100
    final double percentOfRDA = (totalIU / pediatricRDA * 100.0).clamp(0.0, 200.0);

    // Step 5 — Assemble and return the result.
    return VitaminDResult(
      dietaryIU: dietaryVitaminD,
      sunlightIU: sunlightIU,
      totalIU: totalIU,
      bsa: bsa,
      percentOfRDA: percentOfRDA,
    );
  }

  // -------------------------------------------------------------------------
  // Convenience / advisory helpers
  // -------------------------------------------------------------------------

  /// Returns the additional Vitamin D (IU) still needed to reach the RDA.
  ///
  /// A positive return value means the child is below target; zero means the
  /// RDA has been met.  Negative values (surplus) are floored to 0.
  static double deficitIU(VitaminDResult result) {
    return (pediatricRDA - result.totalIU).clamp(0.0, double.infinity);
  }

  /// Estimates additional safe sunlight minutes needed to close the
  /// [deficitIU] gap, given the current [uvi] and [bsa].
  ///
  /// Derived by rearranging the Webb & Holick model:
  ///   minutes = deficit / (UVI × BSA × 16)
  ///
  /// Returns 0.0 when no additional exposure is needed or inputs are invalid.
  static double recommendedExtraMinutes({
    required VitaminDResult result,
    required double uvi,
  }) {
    final double deficit = deficitIU(result);
    if (deficit <= 0 || uvi <= 0 || result.bsa <= 0) return 0.0;

    // Rearranged formula: minutes = deficit / (UVI × BSA × factor)
    return deficit / (uvi * result.bsa * _webHolickFactor);
  }
}

