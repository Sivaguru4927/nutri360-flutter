// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/shared/widgets/app_card.dart
//
// WHAT THIS FILE DOES:
//   The fundamental card container used for every panel/section in the app.
//   Replaces React Native's Card.tsx.
//
//   A simple white rounded box with:
//     • Optional title bar with an icon
//     • Optional colour accent strip on the left edge (used for status cards)
//     • Padding and shadow handled internally — just drop children inside
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../lib/core/theme/app_colors.dart';
import '../../../lib/core/theme/app_typography.dart';

class AppCard extends StatelessWidget {
  /// Children to render inside the card body
  final Widget child;

  /// Optional card title shown at top-left
  final String? title;

  /// Optional icon shown before the title
  final IconData? titleIcon;

  /// Optional colour for the icon and title (defaults to textPrimary)
  final Color? titleColor;

  /// Optional left-side accent strip colour (e.g. red for SAM alert)
  final Color? accentColor;

  /// Padding inside the card — defaults to 16 on all sides
  final EdgeInsets? padding;

  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.titleIcon,
    this.titleColor,
    this.accentColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        // If an accent colour is provided, draw a 4px left strip
        // by using a left-only border with extra thickness
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left accent strip (clinical status indicator)
            if (accentColor != null)
              Container(width: 4, color: accentColor),

            // Card content
            Expanded(
              child: Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Optional title row
                    if (title != null) ...[
                      Row(
                        children: [
                          if (titleIcon != null) ...[
                            Icon(
                              titleIcon,
                              size: 18,
                              color: titleColor ?? AppColors.textPrimary,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            title!,
                            style: AppTypography.titleSmall.copyWith(
                              color: titleColor ?? AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    child,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

