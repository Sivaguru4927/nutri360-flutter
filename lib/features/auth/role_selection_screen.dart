// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/features/auth/role_selection_screen.dart
//
// WHAT THIS FILE DOES:
//   The landing screen shown when the app first opens (or after logout).
//   User chooses whether they are a Parent or an Anganwadi Worker.
//   Equivalent to the React Native app/index.tsx (role selector).
//
//   UX:
//     • Nutri360 logo + tagline at the top
//     • Two large tappable portal cards side by side:
//         LEFT  → "Parent Portal"  (blue card)  → navigates to /auth/parent-login
//         RIGHT → "Worker Portal"  (teal card)  → navigates to /auth/worker-login
//     • Language selector button at the bottom
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const Spacer(),

              // ── Logo & Branding ─────────────────────────────
              _Logo().animate().fadeIn(duration: 600.ms).slideY(begin: -0.3),

              const SizedBox(height: 48),

              // ── Title ───────────────────────────────────────
              Text(
                'Welcome to Nutri360',
                style: AppTypography.headlineMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 8),

              Text(
                'Pediatric health tracking for parents\n& Anganwadi health workers',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 48),

              // ── Portal Selection Cards ───────────────────────
              Row(
                children: [
                  Expanded(
                    child: _PortalCard(
                      icon: Icons.family_restroom_rounded,
                      title: 'Parent\nPortal',
                      subtitle: 'Track your child\'s health',
                      gradientColors: [AppColors.primary500, AppColors.primary700],
                      onTap: () => context.go('/auth/parent-login'),
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.3),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _PortalCard(
                      icon: Icons.medical_services_rounded,
                      title: 'Worker\nPortal',
                      subtitle: 'Anganwadi health workers',
                      gradientColors: [AppColors.teal500, AppColors.teal700],
                      onTap: () => context.go('/auth/worker-login'),
                    ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.3),
                  ),
                ],
              ),

              const Spacer(),

              // ── Language Selector ────────────────────────────
              _LanguageButton().animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 8),
              Text(
                'Version 1.0.0',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widget: Logo ──────────────────────────────────────────
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary400, AppColors.primary700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary500.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.child_care_rounded,
            color: Colors.white,
            size: 44,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Nutri360',
          style: AppTypography.displayLarge.copyWith(
            color: AppColors.primary700,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Sub-widget: Portal Card ───────────────────────────────────
class _PortalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _PortalCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.9), size: 36),
              const Spacer(),
              Text(
                title,
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widget: Language Selector Button ─────────────────────
class _LanguageButton extends StatelessWidget {
  const _LanguageButton();

  static const _languages = {
    'en': '🇬🇧 English',
    'hi': '🇮🇳 हिंदी',
    'te': 'తెలుగు',
    'ta': 'தமிழ்',
    'kn': 'ಕನ್ನಡ',
    'bn': 'বাংলা',
    'mr': 'मराठी',
  };

  @override
  Widget build(BuildContext context) {
    final currentLang = context.locale.languageCode;
    return OutlinedButton.icon(
      onPressed: () => _showLanguagePicker(context),
      icon: const Icon(Icons.language_rounded, size: 18),
      label: Text(_languages[currentLang] ?? 'English'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Language', style: AppTypography.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _languages.entries.map((e) {
                final isSelected = context.locale.languageCode == e.key;
                return ActionChip(
                  label: Text(e.value),
                  backgroundColor: isSelected
                      ? AppColors.primary100
                      : AppColors.neutral100,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.primary700
                        : AppColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  onPressed: () {
                    // Fix: persist language selection across restarts
                    context.setLocale(Locale(e.key));
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

