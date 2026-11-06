// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/core/theme/app_theme.dart
//
// WHAT THIS FILE DOES:
//   Assembles the single [ThemeData] object consumed by [MaterialApp] in
//   main.dart. It wires AppColors and AppTypography into Flutter's Material3
//   design system so every standard widget (ElevatedButton, TextField, Card,
//   AppBar, BottomNavigationBar, Chip …) automatically adopts the Nutri360
//   brand look without requiring per-widget style overrides in feature code.
//
// WHY IT EXISTS:
//   Centralising theme configuration here means:
//     • Feature developers never hard-code colours or font sizes in screen files.
//     • A rebrand requires changes in this file and app_colors.dart only.
//     • Consistent Material3 semantics (colorScheme, textTheme) allow Flutter
//       to generate accessible tonal variants automatically.
//
// STRUCTURE:
//   AppTheme.light() → ThemeData  (only light mode is in scope for v1)
//
// USAGE (main.dart):
//   MaterialApp(
//     theme: AppTheme.light(),
//     ...
//   )
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Namespace class that exposes factory methods for Nutri360 [ThemeData].
///
/// Currently only [light] is defined. A `dark()` factory can be added
/// in a future sprint by cloning this method and substituting dark-mode
/// equivalents from AppColors.
class AppTheme {
  // Private constructor — use the static factory methods only.
  AppTheme._();

  // ════════════════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ════════════════════════════════════════════════════════════════════════════

  /// Builds and returns the Nutri360 light [ThemeData].
  ///
  /// Pass the returned value directly to [MaterialApp.theme].
  /// All sub-themes below mirror decisions originally encoded in the
  /// React Native design tokens (colors.ts / typography.ts).
  static ThemeData light() {
    // ── Color scheme ─────────────────────────────────────────────────────────
    // ColorScheme.fromSeed could auto-generate tonal variants, but we pin
    // specific hex values from the design spec to avoid any AI-generated
    // tonal drift. This guarantees pixel-perfect brand colours.
    final ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.light,

      // Primary brand: sky blue used for CTAs, links, active states.
      primary: AppColors.primary500,
      onPrimary: AppColors.white, // text/icon ON a primary-coloured surface

      // Primary container: light tint used for filled chips, selected cards.
      primaryContainer: AppColors.primary100,
      onPrimaryContainer: AppColors.primary800,

      // Secondary accent: teal used in health-worker screens, clinical charts.
      secondary: AppColors.teal500,
      onSecondary: AppColors.white,

      // Secondary container: light teal tint.
      secondaryContainer: AppColors.teal100,
      onSecondaryContainer: AppColors.teal700,

      // Tertiary / accent: indigo used in parent-portal features.
      tertiary: AppColors.indigo500,
      onTertiary: AppColors.white,

      // Not used for a container in v1; placeholder values follow M3 convention.
      tertiaryContainer: AppColors.indigo50,
      onTertiaryContainer: AppColors.indigo600,

      // Error state: red semantic badge colour (matches semanticHighBadge).
      error: AppColors.semanticHighBadge,
      onError: AppColors.white,
      errorContainer: AppColors.semanticHighBg,
      onErrorContainer: AppColors.semanticHighText,

      // Background: the page-level background colour.
      surface: AppColors.neutral50,       // M3 merged background→surface
      onSurface: AppColors.textPrimary,

      // Surface variant: used for dividers, outlines, alternate card fills.
      surfaceContainerHighest: AppColors.neutral200,
      onSurfaceVariant: AppColors.neutral600,

      // Outline colours for borders and dividers.
      outline: AppColors.neutral200,
      outlineVariant: AppColors.neutral300,

      // Inverse surface for snack-bars and tooltips.
      inverseSurface: AppColors.neutral800,
      onInverseSurface: AppColors.white,
      inversePrimary: AppColors.primary300,

      // Scrim overlay for modals / bottom sheets.
      scrim: const Color(0x80000000), // 50 % black
      shadow: AppColors.neutral900,
    );

    // ── Text theme ───────────────────────────────────────────────────────────
    // Maps Material3 TextTheme slots to AppTypography styles.
    // Only the slots actively used in Nutri360 are populated; the rest fall
    // back to Flutter defaults, which is perfectly fine for unused slots.
    final TextTheme textTheme = TextTheme(
      // Display scale — large hero numbers (BMI, calorie total).
      displayLarge: AppTypography.displayLarge,
      displayMedium: AppTypography.headlineLarge,
      displaySmall: AppTypography.headlineMedium,

      // Headline scale — screen and section titles.
      headlineLarge: AppTypography.headlineLarge,
      headlineMedium: AppTypography.headlineMedium,
      headlineSmall: AppTypography.titleLarge,

      // Title scale — card headers, modal headings.
      titleLarge: AppTypography.titleLarge,
      titleMedium: AppTypography.titleMedium,
      titleSmall: AppTypography.titleSmall,

      // Body scale — prose, descriptions, list items.
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.bodyMedium,
      bodySmall: AppTypography.bodySmall,

      // Label scale — buttons, chips, form labels.
      labelLarge: AppTypography.labelLarge,
      labelMedium: AppTypography.labelMedium,
      labelSmall: AppTypography.labelSmall,
    );

    // ── AppBar theme ─────────────────────────────────────────────────────────
    // Clean white bar with the brand primary as the title colour.
    // elevation: 0 gives a flat, modern look; a bottom border is added via
    // systemOverlayStyle or a custom PreferredSize widget if needed.
    const AppBarTheme appBarTheme = AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.primary500, // icons and back-arrow
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        // Inline here because AppBarTheme.titleTextStyle must be const.
        // Mirrors AppTypography.titleMedium (19 dp, semiBold, Inter).
        fontFamily: 'Inter',
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: AppColors.primary500,
        height: 1.2,
      ),
      iconTheme: IconThemeData(
        color: AppColors.primary500,
        size: 24,
      ),
      actionsIconTheme: IconThemeData(
        color: AppColors.primary500,
        size: 24,
      ),
    );

    // ── Elevated button theme ─────────────────────────────────────────────────
    // Primary action button: solid primary500 background, white label,
    // rounded corners (12 dp), and a fixed height of 52 dp for touch comfort.
    final ElevatedButtonThemeData elevatedButtonTheme = ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary500,   // fill colour
        foregroundColor: AppColors.white,         // label + icon colour
        disabledBackgroundColor: AppColors.neutral200,
        disabledForegroundColor: AppColors.neutral400,
        minimumSize: const Size.fromHeight(52),   // 52 dp tall, full width
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0, // flat; drop-shadow added via Container decoration if needed
        textStyle: AppTypography.labelLarge,
      ),
    );

    // ── Outlined button theme ─────────────────────────────────────────────────
    // Secondary action: transparent with a primary500 border.
    final OutlinedButtonThemeData outlinedButtonTheme = OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary500,
        disabledForegroundColor: AppColors.neutral400,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.primary500, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: AppTypography.labelLarge,
      ),
    );

    // ── Text button theme ─────────────────────────────────────────────────────
    // Inline / ghost action: no border or fill, just the brand colour.
    final TextButtonThemeData textButtonTheme = TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary500,
        disabledForegroundColor: AppColors.neutral400,
        textStyle: AppTypography.labelMedium,
      ),
    );

    // ── Input decoration theme ────────────────────────────────────────────────
    // Applies to every TextField / TextFormField / DropdownButtonFormField.
    // Filled neutral50, 12 dp radius, primary500 focus border.
    const InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
      filled: true,
      fillColor: AppColors.neutral50,

      // Default border (unfocused, no error).
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.neutral200, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.neutral200, width: 1),
      ),
      // Focused border: thicker primary500 ring to signal active state.
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.primary500, width: 1.5),
      ),
      // Error border: semantic red to match the status colour system.
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.semanticHighBadge, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.semanticHighBadge, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.neutral200, width: 1),
      ),

      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),

      hintStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        color: AppColors.textMuted,
        height: 1.5,
      ),
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      floatingLabelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.primary500, // floats to primary when focused
      ),
      errorStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        color: AppColors.semanticHighBadge,
      ),
    );

    // ── Card theme ────────────────────────────────────────────────────────────
    // All Cards in the app: white surface, 1 dp elevation, 16 dp corner
    // radius, and a subtle neutral200 border to delineate from the background.
    final CardThemeData cardTheme = CardThemeData(
      color: AppColors.white,
      elevation: 1,
      shadowColor: AppColors.neutral200,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.neutral200, width: 1),
      ),
      margin: EdgeInsets.zero, // let feature screens control card spacing
      clipBehavior: Clip.antiAlias, // child content respects rounded corners
    );

    // ── Bottom navigation bar theme ───────────────────────────────────────────
    // White bar, primary500 for the selected tab icon+label,
    // neutral400 for unselected tabs.
    const BottomNavigationBarThemeData bottomNavTheme =
        BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.primary500,
      unselectedItemColor: AppColors.neutral400,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed, // labels always visible
      elevation: 8,
    );

    // ── Navigation bar theme (Material3 NavigationBar widget) ─────────────────
    // Mirrors the BottomNavigationBar theme for apps that use NavigationBar.
    // Uses WidgetStateProperty.resolveWith for broad Flutter SDK compatibility.
    final NavigationBarThemeData navigationBarTheme = NavigationBarThemeData(
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.primary100, // pill behind selected icon

      // Icon colour: primary500 when selected, neutral400 otherwise.
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
        (states) => states.contains(WidgetState.selected)
            ? const IconThemeData(color: AppColors.primary500)
            : const IconThemeData(color: AppColors.neutral400),
      ),

      // Label text style: semiBold primary500 when selected, regular neutral400 otherwise.
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
        (states) => states.contains(WidgetState.selected)
            ? const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary500,
              )
            : const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.neutral400,
              ),
      ),
      elevation: 8,
    );

    // ── Chip theme ────────────────────────────────────────────────────────────
    // Filter chips and choice chips: neutral100 default background,
    // primary500 selected background (via selectedColor).
    final ChipThemeData chipTheme = ChipThemeData(
      backgroundColor: AppColors.neutral100,
      selectedColor: AppColors.primary500,       // fill when selected
      disabledColor: AppColors.neutral200,
      deleteIconColor: AppColors.neutral500,
      secondarySelectedColor: AppColors.primary100,
      labelStyle: AppTypography.labelSmall.copyWith(
        color: AppColors.textPrimary,
      ),
      secondaryLabelStyle: AppTypography.labelSmall.copyWith(
        color: AppColors.primary500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // pill shape
        side: const BorderSide(color: AppColors.neutral200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      showCheckmark: false, // design spec: no check icon inside chips
    );

    // ── Divider theme ─────────────────────────────────────────────────────────
    const DividerThemeData dividerTheme = DividerThemeData(
      color: AppColors.neutral200,
      thickness: 1,
      space: 1, // widget height; set to 1 so it doesn't add extra spacing
    );

    // ── Dialog theme ──────────────────────────────────────────────────────────
    final DialogThemeData dialogTheme = DialogThemeData(
      backgroundColor: AppColors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titleTextStyle: AppTypography.titleLarge,
      contentTextStyle: AppTypography.bodyMedium,
    );

    // ── Bottom sheet theme ────────────────────────────────────────────────────
    final BottomSheetThemeData bottomSheetTheme = BottomSheetThemeData(
      backgroundColor: AppColors.white,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      modalBackgroundColor: AppColors.white,
      modalElevation: 8,
      dragHandleColor: AppColors.neutral300,
      dragHandleSize: const Size(40, 4),
      showDragHandle: true,
    );

    // ── Floating action button theme ──────────────────────────────────────────
    const FloatingActionButtonThemeData fabTheme = FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary500,
      foregroundColor: AppColors.white,
      elevation: 2,
      shape: CircleBorder(),
    );

    // ── Switch / Checkbox / Radio theme ──────────────────────────────────────
    final SwitchThemeData switchTheme = SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.white
            : AppColors.neutral400,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primary500
            : AppColors.neutral200,
      ),
    );

    final CheckboxThemeData checkboxTheme = CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primary500
            : AppColors.white,
      ),
      checkColor: WidgetStateProperty.all(AppColors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: const BorderSide(color: AppColors.neutral300, width: 1.5),
    );

    final RadioThemeData radioTheme = RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primary500
            : AppColors.neutral300,
      ),
    );

    // ── Tooltip theme ─────────────────────────────────────────────────────────
    const TooltipThemeData tooltipTheme = TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.neutral800,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      textStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        color: AppColors.white,
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );

    // ── Assemble and return the full ThemeData ────────────────────────────────
    return ThemeData(
      // Material3 is the target design system for Nutri360.
      useMaterial3: true,

      colorScheme: colorScheme,
      textTheme: textTheme,

      // Component sub-themes wired above.
      appBarTheme: appBarTheme,
      elevatedButtonTheme: elevatedButtonTheme,
      outlinedButtonTheme: outlinedButtonTheme,
      textButtonTheme: textButtonTheme,
      inputDecorationTheme: inputDecorationTheme,
      cardTheme: cardTheme,
      bottomNavigationBarTheme: bottomNavTheme,
      navigationBarTheme: navigationBarTheme,
      chipTheme: chipTheme,
      dividerTheme: dividerTheme,
      dialogTheme: dialogTheme,
      bottomSheetTheme: bottomSheetTheme,
      floatingActionButtonTheme: fabTheme,
      switchTheme: switchTheme,
      checkboxTheme: checkboxTheme,
      radioTheme: radioTheme,
      tooltipTheme: tooltipTheme,

      // Global defaults.
      scaffoldBackgroundColor: AppColors.neutral50,
      canvasColor: AppColors.white,
      fontFamily: 'Inter',

      // Splash / highlight effects: subtle ink ripple tuned to brand colours.
      splashColor: AppColors.primary100,
      highlightColor: AppColors.primary50,
    );
  }
}
