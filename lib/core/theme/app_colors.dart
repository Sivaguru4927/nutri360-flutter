// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/core/theme/app_colors.dart
//
// WHAT THIS FILE DOES:
//   Defines every colour used in the entire app.
//   Directly ported from the React Native `src/constants/colors.ts`.
//   Using a single source of truth here means changing one value here
//   automatically updates every screen that references it.
//
//   Colour groups:
//     • primary  → Sky blue brand colour (buttons, links, active states)
//     • teal     → Health accent (worker screens, clinical indicators)
//     • amber    → Warning states, sunlight tracker
//     • indigo   → Parent portal accent
//     • semantic → Traffic-light colours for clinical status flags
//     • neutral  → Grey scale (text, borders, backgrounds)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // prevent instantiation — use static members only

  // ── Brand / Primary (Sky Blue) ──────────────────────────────
  static const Color primary50  = Color(0xFFF0F9FF);
  static const Color primary100 = Color(0xFFE0F2FE);
  static const Color primary200 = Color(0xFFBAE6FD);
  static const Color primary300 = Color(0xFF7DD3FC);
  static const Color primary400 = Color(0xFF38BDF8);
  static const Color primary500 = Color(0xFF0EA5E9); // ← main CTA colour
  static const Color primary600 = Color(0xFF0284C7);
  static const Color primary700 = Color(0xFF0369A1);
  static const Color primary800 = Color(0xFF075985);
  static const Color primary900 = Color(0xFF0C4A6E);

  // ── Teal (Health Worker Accent) ──────────────────────────────
  static const Color teal50  = Color(0xFFF0FDFA);
  static const Color teal100 = Color(0xFFCCFBF1);
  static const Color teal500 = Color(0xFF14B8A6);
  static const Color teal600 = Color(0xFF0D9488);
  static const Color teal700 = Color(0xFF0F766E);

  // ── Amber (Sunlight Tracker, Warnings) ───────────────────────
  static const Color amber300 = Color(0xFFFCD34D);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);

  // ── Indigo (Parent Portal Accent) ───────────────────────────
  static const Color indigo50  = Color(0xFFEEF2FF);
  static const Color indigo500 = Color(0xFF6366F1);
  static const Color indigo600 = Color(0xFF4F46E5);

  // ── Semantic Status Colours ──────────────────────────────────
  // Used for: growth flags, nutrition flags, vaccination status
  static const Color semanticLowBg      = Color(0xFFECFDF5); // green background
  static const Color semanticLowBorder  = Color(0xFFA7F3D0);
  static const Color semanticLowText    = Color(0xFF065F46);
  static const Color semanticLowBadge   = Color(0xFF10B981);

  static const Color semanticMonitorBg      = Color(0xFFFFFBEB); // amber background
  static const Color semanticMonitorBorder  = Color(0xFFFDE68A);
  static const Color semanticMonitorText    = Color(0xFF92400E);
  static const Color semanticMonitorBadge   = Color(0xFFF59E0B);

  static const Color semanticHighBg      = Color(0xFFFEF2F2); // red background
  static const Color semanticHighBorder  = Color(0xFFFECACA);
  static const Color semanticHighText    = Color(0xFF991B1B);
  static const Color semanticHighBadge   = Color(0xFFEF4444);

  static const Color semanticInfoBg      = Color(0xFFEFF6FF); // blue background
  static const Color semanticInfoBorder  = Color(0xFFBFDBFE);
  static const Color semanticInfoText    = Color(0xFF1E40AF);
  static const Color semanticInfoBadge   = Color(0xFF3B82F6);

  // ── Neutral / Grey Scale ────────────────────────────────────
  static const Color white       = Color(0xFFFFFFFF);
  static const Color neutral50   = Color(0xFFF8FAFC);
  static const Color neutral100  = Color(0xFFF1F5F9);
  static const Color neutral200  = Color(0xFFE2E8F0);
  static const Color neutral300  = Color(0xFFCBD5E1);
  static const Color neutral400  = Color(0xFF94A3B8);
  static const Color neutral500  = Color(0xFF64748B);
  static const Color neutral600  = Color(0xFF475569);
  static const Color neutral700  = Color(0xFF334155);
  static const Color neutral800  = Color(0xFF1E293B);
  static const Color neutral900  = Color(0xFF0F172A);

  // ── Semantic Convenience Aliases ────────────────────────────
  static const Color surface     = white;
  static const Color background  = neutral50;
  static const Color border      = neutral200;
  static const Color textPrimary   = neutral900;
  static const Color textSecondary = neutral500;
  static const Color textMuted     = neutral400;

  // ── Vitamin D Dual-Bar Colours ──────────────────────────────
  static const Color vitaminDDietary  = primary500;   // blue  → dietary intake
  static const Color vitaminDSunlight = amber500;     // amber → sunlight synthesis

  // ── SAM / MAM Clinical Flags ────────────────────────────────
  static const Color samRed    = Color(0xFFEF4444); // Severe Acute Malnutrition
  static const Color mamOrange = Color(0xFFF97316); // Moderate Acute Malnutrition
  static const Color normalGreen = Color(0xFF22C55E);
}
