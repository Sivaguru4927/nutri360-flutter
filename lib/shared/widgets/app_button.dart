// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/shared/widgets/app_button.dart
//
// WHAT THIS FILE DOES:
//   Reusable button widget used across every screen in the app.
//   Replaces the React Native Button.tsx component.
//
//   Has 3 visual variants:
//     • primary  → filled blue background (main CTAs like "Login", "Save")
//     • secondary → white with blue border (secondary actions like "Cancel")
//     • ghost    → transparent, text-only (subtle actions like "Forgot password?")
//
//   Features:
//     • Loading spinner state (shows CircularProgressIndicator while async op runs)
//     • Disabled state (auto-greys out when isDisabled=true or isLoading=true)
//     • Full-width by default, constrained by parent
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../lib/core/theme/app_colors.dart';
import '../../../lib/core/theme/app_typography.dart';

/// Variant controls the visual style of the button
enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  /// Text displayed on the button
  final String label;

  /// Called when the button is tapped (set null to disable automatically)
  final VoidCallback? onPressed;

  /// Visual style — defaults to primary (filled blue)
  final AppButtonVariant variant;

  /// When true, shows a spinner and disables taps — use during async operations
  final bool isLoading;

  /// Optional leading icon
  final IconData? icon;

  /// Override button height (default 52)
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    // Disable tap when loading or no callback provided
    final effectiveOnPressed = (isLoading || onPressed == null) ? null : onPressed;

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: variant == AppButtonVariant.primary
                  ? AppColors.white
                  : AppColors.primary500,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label, style: AppTypography.labelLarge),
            ],
          );

    switch (variant) {
      case AppButtonVariant.primary:
        return SizedBox(
          width: double.infinity,
          height: height,
          child: ElevatedButton(
            onPressed: effectiveOnPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.neutral300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: child,
          ),
        );

      case AppButtonVariant.secondary:
        return SizedBox(
          width: double.infinity,
          height: height,
          child: OutlinedButton(
            onPressed: effectiveOnPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary500,
              side: const BorderSide(color: AppColors.primary500, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: child,
          ),
        );

      case AppButtonVariant.ghost:
        return TextButton(
          onPressed: effectiveOnPressed,
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary600,
            ),
          ),
        );
    }
  }
}

