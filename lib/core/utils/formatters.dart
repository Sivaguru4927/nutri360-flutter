// =============================================================================
// formatters.dart
// =============================================================================
//
// WHAT: Shared display-formatting utilities for the Nutri360 Flutter app.
//       Converts raw data types (DateTime, doubles, strings) into the
//       human-readable formats used throughout all Nutri360 screens:
//         • Age display in years/months/days (compact and verbose forms)
//         • Localised date and 12-hour time strings
//         • Nutrient value strings with units (auto-precision)
//         • Z-score strings with explicit sign (always prefixed + or -)
//         • Share code formatting (NTR-XXXXXX canonical form)
//
// WHY:  Centralising formatting logic prevents duplication across widgets,
//       ensures consistent output (e.g. sign convention for Z-scores is
//       defined in exactly one place), and makes it trivial to update locale
//       or precision requirements without touching individual widgets.
//
// PORT: Direct port of formatters.ts from the Nutri360 React Native codebase.
//       All format rules are preserved and annotated.
//
// USAGE:
//   import 'package:nutri360/core/utils/formatters.dart';
//
//   Text(Formatters.ageDisplay('2024-03-15'))          // "1y 7m"
//   Text(Formatters.zScoreDisplay(-2.47))              // "-2.5"
//   Text(Formatters.nutrientDisplay(400, 'IU'))        // "400 IU"
// =============================================================================

// ---------------------------------------------------------------------------
// Formatters — pure-static utility class
// ---------------------------------------------------------------------------

/// Central formatting utility class for Nutri360.
///
/// All methods are `static` — no instance is required.  Pure functions that
/// take values and return formatted strings with no side-effects.
class Formatters {
  // Prevent instantiation.
  Formatters._();

  // -------------------------------------------------------------------------
  // Age formatting
  // -------------------------------------------------------------------------

  /// Returns a compact age string derived from [dob] (ISO-8601 date string)
  /// to today's date.
  ///
  /// Format rules (matching the React Native source):
  ///   • ≥ 12 months  →  "Xy Ym"   e.g. "1y 3m"
  ///   • 1–11 months  →  "Xm"      e.g. "8m"
  ///   • < 1 month    →  "Xd"      e.g. "12d"
  ///
  /// The year/month/day components are computed using calendar arithmetic
  /// (not simply dividing total days) to give accurate whole-unit counts.
  ///
  /// Returns "Unknown" when [dob] is empty or cannot be parsed.
  static String ageDisplay(String dob) {
    if (dob.isEmpty) return 'Unknown';

    final DateTime? birth = _tryParse(dob);
    if (birth == null) return 'Unknown';

    final DateTime now = DateTime.now();
    final _AgeParts parts = _computeAge(birth, now);

    if (parts.years >= 1) {
      // Show years + months (omit months if exactly 0 for clean display).
      return parts.months > 0
          ? '${parts.years}y ${parts.months}m'
          : '${parts.years}y';
    } else if (parts.months >= 1) {
      return '${parts.months}m';
    } else {
      return '${parts.days}d';
    }
  }

  /// Returns a detailed, verbose age string derived from [dob].
  ///
  /// Format: "X year(s), Y month(s), Z day(s)"
  /// Examples:
  ///   "1 year, 3 months, 7 days"
  ///   "0 years, 8 months, 14 days"
  ///   "0 years, 0 months, 5 days"
  ///
  /// Uses grammatically correct singular/plural (year vs years, etc.).
  /// Returns "Unknown" when [dob] is empty or unparseable.
  static String ageDetailed(String dob) {
    if (dob.isEmpty) return 'Unknown';

    final DateTime? birth = _tryParse(dob);
    if (birth == null) return 'Unknown';

    final DateTime now = DateTime.now();
    final _AgeParts parts = _computeAge(birth, now);

    final String yearLabel  = parts.years  == 1 ? 'year'  : 'years';
    final String monthLabel = parts.months == 1 ? 'month' : 'months';
    final String dayLabel   = parts.days   == 1 ? 'day'   : 'days';

    return '${parts.years} $yearLabel, ${parts.months} $monthLabel, ${parts.days} $dayLabel';
  }

  // -------------------------------------------------------------------------
  // Date & time formatting
  // -------------------------------------------------------------------------

  /// Formats [d] as a localised date string: "14 Sep 2026".
  ///
  /// Uses abbreviated English month names to avoid a heavy intl dependency.
  /// The day is zero-padded to 2 digits (matching the React Native source).
  static String dateDisplay(DateTime d) {
    final String day   = d.day.toString().padLeft(2, '0');
    final String month = _monthAbbr[d.month - 1]; // month is 1-indexed
    final String year  = d.year.toString();
    return '$day $month $year';
  }

  /// Formats [d] as a 12-hour time string with AM/PM: "11:45 AM".
  ///
  /// Hours are NOT zero-padded (standard 12-hour clock convention).
  /// Minutes are zero-padded to 2 digits.
  static String timeDisplay(DateTime d) {
    final int hour24 = d.hour;
    final int minute = d.minute;

    // Determine AM/PM and convert to 12-hour.
    final String period = hour24 < 12 ? 'AM' : 'PM';
    int hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12; // midnight and noon display as 12

    final String minuteStr = minute.toString().padLeft(2, '0');
    return '$hour12:$minuteStr $period';
  }

  // -------------------------------------------------------------------------
  // Nutrient value formatting
  // -------------------------------------------------------------------------

  /// Formats a nutrient [value] with its [unit] for display in the diary
  /// and report screens.
  ///
  /// Precision rules (matching React Native source):
  ///   • For IU values (Vitamin D, Vitamin A IU): show as integer.
  ///   • For values ≥ 100: show 0 decimal places (e.g. "400 IU", "120 mg").
  ///   • For values ≥ 10:  show 1 decimal place  (e.g. "12.4 mg").
  ///   • For values <  10: show 2 decimal places  (e.g. "2.47 mg").
  ///
  /// The [unit] string is appended after a single space.
  static String nutrientDisplay(double value, String unit) {
    final String formatted;

    // Integer display for IU (Vitamin D, A retinol equivalents in IU).
    if (unit.toUpperCase() == 'IU') {
      formatted = value.round().toString();
    } else if (value >= 100) {
      formatted = value.toStringAsFixed(0);
    } else if (value >= 10) {
      formatted = value.toStringAsFixed(1);
    } else {
      formatted = value.toStringAsFixed(2);
    }

    return '$formatted $unit';
  }

  // -------------------------------------------------------------------------
  // Z-score formatting
  // -------------------------------------------------------------------------

  /// Formats a WHO Z-score with an explicit sign prefix and 1 decimal place.
  ///
  /// The sign is always rendered — positive values get a leading "+", negative
  /// values get a leading "-".  This matches the React Native source and WHO
  /// reporting conventions where the sign is semantically meaningful.
  ///
  /// Examples:
  ///   zScoreDisplay(1.23)   → "+1.2"
  ///   zScoreDisplay(-2.47)  → "-2.5"   (rounded to 1 d.p.)
  ///   zScoreDisplay(0.0)    → "+0.0"
  static String zScoreDisplay(double z) {
    // Format to 1 decimal place first.
    final String absStr = z.abs().toStringAsFixed(1);

    // Prepend the explicit sign.
    return z >= 0 ? '+$absStr' : '-$absStr';
  }

  // -------------------------------------------------------------------------
  // Share code formatting
  // -------------------------------------------------------------------------

  /// Normalises a Nutri360 share code to the canonical "NTR-XXXXXX" format.
  ///
  /// Rules (matching the React Native source):
  ///   1. Strip all whitespace.
  ///   2. Uppercase the entire string.
  ///   3. If the uppercased string does not already start with "NTR-",
  ///      prepend it.  This handles legacy codes stored without the prefix
  ///      and codes entered by ASHA workers without the prefix.
  ///
  /// Examples:
  ///   shareCodeFormat("abc123")     → "NTR-ABC123"
  ///   shareCodeFormat("NTR-abc123") → "NTR-ABC123"
  ///   shareCodeFormat("  ntr-XYZ ") → "NTR-XYZ"
  static String shareCodeFormat(String code) {
    // Step 1: Remove all whitespace.
    final String stripped = code.replaceAll(RegExp(r'\s+'), '');

    // Step 2: Uppercase.
    final String upper = stripped.toUpperCase();

    // Step 3: Ensure the canonical prefix.
    if (upper.startsWith('NTR-')) {
      return upper;
    }
    return 'NTR-$upper';
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  /// Abbreviated English month names (index 0 = January).
  static const List<String> _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Attempts to parse [s] as an ISO-8601 date/datetime string.
  /// Returns null on parse failure rather than throwing.
  static DateTime? _tryParse(String s) {
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  /// Computes the calendar-accurate age difference between [birth] and [now]
  /// in complete years, months (after subtracting whole years), and days
  /// (after subtracting whole years and months).
  ///
  /// Algorithm:
  ///   1. Start with raw year/month/day differences.
  ///   2. If the day-of-month has not yet been reached, borrow a month.
  ///   3. If the month has not yet been reached (but day is fine), borrow
  ///      a year.
  ///
  /// This avoids the imprecision of simply dividing total days by 30.4375.
  static _AgeParts _computeAge(DateTime birth, DateTime now) {
    int years  = now.year  - birth.year;
    int months = now.month - birth.month;
    int days   = now.day   - birth.day;

    // Borrow from months when the current day is before the birth day.
    if (days < 0) {
      months -= 1;
      // Add the number of days in the previous month.
      final DateTime prevMonth = DateTime(now.year, now.month - 1, 1);
      final int daysInPrevMonth = DateTime(prevMonth.year, prevMonth.month + 1, 0).day;
      days += daysInPrevMonth;
    }

    // Borrow from years when the current month-day hasn't reached birth month-day.
    if (months < 0) {
      years  -= 1;
      months += 12;
    }

    return _AgeParts(
      years:  years.clamp(0, 999),
      months: months.clamp(0, 11),
      days:   days.clamp(0, 31),
    );
  }
}

// ---------------------------------------------------------------------------
// Private value object — not part of the public API
// ---------------------------------------------------------------------------

/// Simple data carrier for the three integer components of a calendar age.
class _AgeParts {
  final int years;
  final int months;
  final int days;

  const _AgeParts({
    required this.years,
    required this.months,
    required this.days,
  });
}

