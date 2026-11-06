// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/features/parent/child/development/development_screen.dart
//
// WHAT THIS FILE DOES:
//   Pediatric developmental milestones checklist module.
//   Replaces React Native's app/parent/child/[id]/development.tsx.
//
//   Based on CDC & AIIMS developmental surveillance standards:
//     • Gross Motor Skills (Walking backwards, kicking ball, running)
//     • Fine Motor Skills (Stacking blocks, holding spoon, scribbling)
//     • Language & Speech (2-word phrases, naming body parts, following instructions)
//     • Social & Cognitive (Pretend play, showing empathy, pointing to objects)
//     • Red-Flag early autism and developmental delay alerts
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/status_badge.dart';

class DevelopmentScreen extends StatefulWidget {
  final String childId;

  const DevelopmentScreen({super.key, required this.childId});

  @override
  State<DevelopmentScreen> createState() => _DevelopmentScreenState();
}

class _DevelopmentScreenState extends State<DevelopmentScreen> {
  final List<Map<String, dynamic>> _milestones = [
    {
      'domain': 'Gross Motor',
      'title': 'Walks up steps with or without help',
      'age': '15–18 Months',
      'isAchieved': true,
      'isRedFlag': false,
    },
    {
      'domain': 'Gross Motor',
      'title': 'Kicks a small ball forward without falling',
      'age': '18–24 Months',
      'isAchieved': true,
      'isRedFlag': false,
    },
    {
      'domain': 'Fine Motor',
      'title': 'Stacks 4 to 6 small wooden blocks',
      'age': '18–24 Months',
      'isAchieved': true,
      'isRedFlag': false,
    },
    {
      'domain': 'Fine Motor',
      'title': 'Drinks from an open cup with minimal spilling',
      'age': '15–18 Months',
      'isAchieved': true,
      'isRedFlag': false,
    },
    {
      'domain': 'Language & Speech',
      'title': 'Says at least 10–20 single words clearly',
      'age': '18–24 Months',
      'isAchieved': true,
      'isRedFlag': true,
    },
    {
      'domain': 'Language & Speech',
      'title': 'Points to 2 or more pictures when named',
      'age': '18–24 Months',
      'isAchieved': false,
      'isRedFlag': false,
    },
    {
      'domain': 'Social & Cognitive',
      'title': 'Points to show you something interesting (Joint Attention)',
      'age': '14–18 Months',
      'isAchieved': true,
      'isRedFlag': true,
    },
    {
      'domain': 'Social & Cognitive',
      'title': 'Engages in simple pretend play (e.g. feeds a doll)',
      'age': '18–24 Months',
      'isAchieved': false,
      'isRedFlag': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final achievedCount = _milestones.where((m) => m['isAchieved'] == true).length;
    final totalCount = _milestones.length;
    final percent = (achievedCount / totalCount * 100).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Developmental Milestones'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Progress Header Card ──────────────────────────────
            AppCard(
              accentColor: Colors.deepPurple,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.psychology_rounded, color: Colors.deepPurple),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$percent% Milestones Achieved', style: AppTypography.titleMedium),
                            Text(
                              '$achievedCount of $totalCount milestones confirmed for 18–24m bracket',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: achievedCount / totalCount,
                      minHeight: 8,
                      backgroundColor: AppColors.neutral200,
                      valueColor: const AlwaysStoppedAnimation(Colors.deepPurple),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text('Checklist (CDC & AIIMS Milestones)', style: AppTypography.titleMedium),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _milestones.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final m = _milestones[idx];
                final isAchieved = m['isAchieved'] as bool;
                final isRedFlag = m['isRedFlag'] as bool;

                return AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isAchieved,
                        activeColor: Colors.deepPurple,
                        onChanged: (val) {
                          setState(() {
                            m['isAchieved'] = val ?? false;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  m['domain'] as String,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isRedFlag) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.semanticHighBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Key Benchmark',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.semanticHighText,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m['title'] as String,
                              style: AppTypography.bodyMedium.copyWith(
                                decoration: isAchieved ? TextDecoration.lineThrough : null,
                                color: isAchieved ? AppColors.textMuted : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
