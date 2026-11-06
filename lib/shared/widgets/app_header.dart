// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/shared/widgets/app_header.dart
//
// WHAT THIS FILE DOES:
//   The top navigation header / AppBar used on most screens.
//   Replaces React Native's Header.tsx.
//
//   Features:
//     • App logo + screen title
//     • Optional back button (auto-shown when navigator can pop)
//     • Optional action button(s) on the right (e.g. language selector, logout)
//     • Language indicator chip (shows current language abbreviation)
//   
//   Implements PreferredSizeWidget so it can be used as Scaffold.appBar.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../lib/core/theme/app_colors.dart';
import '../../../lib/core/theme/app_typography.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  /// Screen title shown next to the logo
  final String title;

  /// If true, hides the back button even when navigator can pop
  final bool hideBackButton;

  /// Optional actions placed on the right side of the header
  final List<Widget>? actions;

  /// If true, shows the Nutri360 logo before the title
  final bool showLogo;

  const AppHeader({
    super.key,
    required this.title,
    this.hideBackButton = false,
    this.actions,
    this.showLogo = true,
  });

  @override
  // AppBar height = 56 + status bar inset
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      // Bottom border line
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
      // Show back button only when there's a route to pop to
      leading: (canPop && !hideBackButton)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: AppColors.textPrimary,
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      // Title row: optional logo + screen name
      title: Row(
        children: [
          if (showLogo) ...[
            // Small logo circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary500,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.child_care_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}

