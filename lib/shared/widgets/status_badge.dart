// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/shared/widgets/status_badge.dart
//
// WHAT THIS FILE DOES:
//   Small coloured pill/badge that shows clinical status labels.
//   Replaces React Native's StatusBadge.tsx.
//
//   Four status variants matching the screening system:
//     • normal       → green  "Normal"
//     • monitor      → amber  "Monitor"
//     • highPriority → red    "High Priority"
//     • info         → blue   "Info"
//
//   Used on: child list cards, growth records, referral cards, vaccination rows.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../lib/core/theme/app_colors.dart';
import '../../../lib/core/theme/app_typography.dart';

enum StatusBadgeVariant { normal, monitor, highPriority, info }

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeVariant variant;

  const StatusBadge({
    super.key,
    required this.label,
    required this.variant,
  });

  /// Convenience factory from a string flag (matches StatusFlag enum from types)
  factory StatusBadge.fromFlag(String flag) {
    switch (flag.toUpperCase()) {
      case 'NO_FLAG':
        return StatusBadge(label: 'Normal', variant: StatusBadgeVariant.normal);
      case 'POTENTIAL_CONCERN':
        return StatusBadge(label: 'Monitor', variant: StatusBadgeVariant.monitor);
      case 'REVIEW_DUE':
        return StatusBadge(label: 'Review Due', variant: StatusBadgeVariant.highPriority);
      default:
        return StatusBadge(label: 'No Data', variant: StatusBadgeVariant.info);
    }
  }

  // Returns background, text, and dot colours for each variant
  _BadgeColors get _colors {
    switch (variant) {
      case StatusBadgeVariant.normal:
        return _BadgeColors(
          bg: AppColors.semanticLowBg,
          text: AppColors.semanticLowText,
          dot: AppColors.semanticLowBadge,
        );
      case StatusBadgeVariant.monitor:
        return _BadgeColors(
          bg: AppColors.semanticMonitorBg,
          text: AppColors.semanticMonitorText,
          dot: AppColors.semanticMonitorBadge,
        );
      case StatusBadgeVariant.highPriority:
        return _BadgeColors(
          bg: AppColors.semanticHighBg,
          text: AppColors.semanticHighText,
          dot: AppColors.semanticHighBadge,
        );
      case StatusBadgeVariant.info:
        return _BadgeColors(
          bg: AppColors.semanticInfoBg,
          text: AppColors.semanticInfoText,
          dot: AppColors.semanticInfoBadge,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Coloured dot indicator
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: c.text),
          ),
        ],
      ),
    );
  }
}

class _BadgeColors {
  final Color bg, text, dot;
  const _BadgeColors({required this.bg, required this.text, required this.dot});
}

