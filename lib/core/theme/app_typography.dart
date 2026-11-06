// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/core/theme/app_typography.dart
//
// WHAT THIS FILE DOES:
//   Defines every text style used across the Nutri360 app.
//   This is a direct port of the React Native `src/constants/typography.ts`
//   file into Flutter TextStyle objects.
//
// WHY IT EXISTS:
//   Having a single source-of-truth for type scale, font weights, and
//   line heights prevents inconsistencies across screens. Any designer-driven
//   change needs to happen in exactly one place and propagates everywhere.
//
//   The 'Inter' font family is registered in pubspec.yaml and loaded via
//   Flutter's asset pipeline. All styles fall back to the system sans-serif
//   if 'Inter' has not been correctly configured.
//
// DESIGN TOKEN MAPPING (from typography.ts):
//   Font sizes  → xs=11, sm=13, base=15, md=17, lg=19, xl=22, 2xl=26, 3xl=30, display=36
//   Weights     → regular=400, medium=500, semiBold=600, bold=700
//   Line heights → tight=1.2, normal=1.5, relaxed=1.75
//
// USAGE:
//   Text('Hello', style: AppTypography.bodyMedium)
//   Text('Title', style: AppTypography.titleLarge.copyWith(color: Colors.white))
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// Central typography registry for Nutri360.
///
/// All getters return a [TextStyle] configured with the 'Inter' font,
/// the appropriate size/weight/line-height from the design token scale,
/// and [AppColors.textPrimary] (0xFF0F172A) as the default ink colour.
///
/// Use `.copyWith()` on any style to override individual properties
/// (colour, decoration, etc.) without breaking the base design system.
class AppTypography {
  // Private constructor — this class is used as a namespace only.
  AppTypography._();

  // ── Font family ────────────────────────────────────────────────────────────
  /// The custom font registered in pubspec.yaml under `fonts:`.
  static const String _fontFamily = 'Inter';

  // ── Design-token: font sizes (dp / logical pixels) ─────────────────────────
  static const double _sizeXs      = 11; // xs
  static const double _sizeSm      = 13; // sm
  static const double _sizeBase    = 15; // base
  static const double _sizeMd      = 17; // md
  static const double _sizeLg      = 19; // lg
  static const double _sizeXl      = 22; // xl
  static const double _size2xl     = 26; // 2xl
  static const double _size3xl     = 30; // 3xl
  static const double _sizeDisplay = 36; // display

  // ── Design-token: font weights ─────────────────────────────────────────────
  static const FontWeight _regular  = FontWeight.w400;
  static const FontWeight _medium   = FontWeight.w500;
  static const FontWeight _semiBold = FontWeight.w600;
  static const FontWeight _bold     = FontWeight.w700;

  // ── Design-token: line-height multipliers ──────────────────────────────────
  // Flutter uses `height` as a multiplier of fontSize (1.5 means 1.5× the size).
  static const double _tight   = 1.2;
  static const double _normal  = 1.5;
  static const double _relaxed = 1.75;

  // ── Default text colour (textPrimary = neutral900 = 0xFF0F172A) ────────────
  /// Matches AppColors.textPrimary — defined inline to avoid a circular import
  /// at the token level; app_theme.dart references both files together.
  static const Color _textPrimary = Color(0xFF0F172A);

  // ════════════════════════════════════════════════════════════════════════════
  // BODY STYLES
  // Used for: paragraphs, descriptions, list items, general prose.
  // ════════════════════════════════════════════════════════════════════════════

  /// Body text — smallest variant (xs / 11 dp, regular, normal line-height).
  /// Ideal for captions, helper text, and secondary metadata labels.
  static TextStyle get bodySmall => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: _sizeXs,
    fontWeight: _regular,
    height: _normal,
    color: _textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Body text — standard variant (base / 15 dp, regular, normal line-height).
  /// The go-to style for most readable prose and form field content.
  static TextStyle get bodyMedium => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: _sizeBase,
    fontWeight: _regular,
    height: _normal,
    color: _textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Body text — large variant (md / 17 dp, regular, relaxed line-height).
  /// Used for introductory paragraphs or onboarding copy that needs breathing
  /// room.
  static TextStyle get bodyLarge => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: _sizeMd,
    fontWeight: _regular,
    height: _relaxed,
    color: _textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  // ════════════════════════════════════════════════════════════════════════════
  // LABEL STYLES
  // Used for: form labels, button text, chips, tags, metadata keys.
  // ════════════════════════════════════════════════════════════════════════════

  /// Label — smallest variant (xs / 11 dp, medium weight, tight line-height).
  /// Perfect for chip text, badge labels, or column headers in dense tables.
  static TextStyle get labelSmall => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: _sizeXs,
    fontWeight: _medium,
    height: _tight,
    color: _textPrimary,
    letterSpacing: 0.1,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Label — standard variant (sm / 13 dp, medium weight, tight line-height).
  /// Used for form field labels, navigation item text, and secondary buttons.
  static TextStyle get labelMedium => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: _sizeSm,
    fontWeight: _medium,
    height: _tight,
    color: _textPrimary,
    letterSpacing: 0.1,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Label — large variant (base / 15 dp, semiBold, tight line-height).
  /// Used for primary button text and prominent action labels.
  static TextStyle get labelLarge => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: _sizeBase,
    fontWeight: _semiBold,
    height: _tight,
    color: _textPrimary,
    letterSpacing: 0.1,
    leadingDistribution: TextLeadingDistribution.even,
  );

  // ════════════════════════════════════════════════════════════════════════════
  // TITLE STYLES
  // Used for: card headers, section titles, modal headings, screen sub-titles.
  // ════════════════════════════════════════════════════════════════════════════

  /// Title — smallest variant (md / 17 dp, semiBold, tight line-height).
  /// Suitable for card headers and compact section dividers.
  static TextStyle get titleSmall => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: _sizeMd,
    fontWeight: _semiBold,
    height: _tight,
    color: _textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Title — standard variant (lg / 19 dp, semiBold, tight line-height).
  /// The primary style for screen-level section headings and drawer items.
  static TextStyle get titleMedium => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: _sizeLg,
    fontWeight: _semiBold,
    height: _tight,
    color: _textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Title — large variant (xl / 22 dp, bold, tight line-height).
  /// Used for modal/bottom-sheet titles and prominent section markers.
  static TextStyle get titleLarge => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: _sizeXl,
    fontWeight: _bold,
    height: _tight,
    color: _textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  // ════════════════════════════════════════════════════════════════════════════
  // HEADLINE STYLES
  // Used for: screen titles shown in AppBar or at the top of full screens.
  // ════════════════════════════════════════════════════════════════════════════

  /// Headline — medium variant (2xl / 26 dp, bold, tight line-height).
  /// Standard AppBar / screen title size for most Nutri360 screens.
  static TextStyle get headlineMedium => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: _size2xl,
    fontWeight: _bold,
    height: _tight,
    color: _textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Headline — large variant (3xl / 30 dp, bold, tight line-height).
  /// Reserved for dashboard top banners, welcome screens, and report headers.
  static TextStyle get headlineLarge => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: _size3xl,
    fontWeight: _bold,
    height: _tight,
    color: _textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );

  // ════════════════════════════════════════════════════════════════════════════
  // DISPLAY STYLES
  // Used for: hero numbers, big stats (BMI, calorie counts), splash screens.
  // ════════════════════════════════════════════════════════════════════════════

  /// Display — largest style in the system (display / 36 dp, bold, tight).
  /// Used for impactful hero numbers: weight, calorie total, vitamin D score.
  static TextStyle get displayLarge => const TextStyle(
    fontFamily: _fontFamily,
    fontSize: _sizeDisplay,
    fontWeight: _bold,
    height: _tight,
    color: _textPrimary,
    leadingDistribution: TextLeadingDistribution.even,
  );
}
