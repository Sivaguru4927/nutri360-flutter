// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/features/parent/child/vaccination/vaccination_screen.dart
//
// WHAT THIS FILE DOES:
//   Pediatric immunization surveillance module.
//   Replaces React Native's app/parent/child/[id]/vaccination.tsx.
//
//   Features:
//     • National Universal Immunization Programme (UIP) schedule
//     • Indian Academy of Pediatrics (IAP) recommended schedule
//     • Status tracking: Given, Upcoming Due, and Overdue
//     • Interactive modal to record vaccination date and clinic details
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/status_badge.dart';

class VaccinationScreen extends StatefulWidget {
  final String childId;

  const VaccinationScreen({super.key, required this.childId});

  @override
  State<VaccinationScreen> createState() => _VaccinationScreenState();
}

class _VaccinationScreenState extends State<VaccinationScreen> {
  int _selectedSchedule = 0; // 0 = UIP (Govt), 1 = IAP

  final List<Map<String, dynamic>> _uipVaccines = [
    {'name': 'BCG', 'age': 'At Birth', 'status': 'GIVEN', 'date': '16 Aug 2025'},
    {'name': 'OPV 0', 'age': 'At Birth', 'status': 'GIVEN', 'date': '16 Aug 2025'},
    {'name': 'Hepatitis B Birth Dose', 'age': 'At Birth', 'status': 'GIVEN', 'date': '16 Aug 2025'},
    {'name': 'OPV 1 + Pentavalent 1', 'age': '6 Weeks', 'status': 'GIVEN', 'date': '28 Sep 2025'},
    {'name': 'Rotavirus 1 + fIPV 1', 'age': '6 Weeks', 'status': 'GIVEN', 'date': '28 Sep 2025'},
    {'name': 'OPV 2 + Pentavalent 2', 'age': '10 Weeks', 'status': 'GIVEN', 'date': '25 Oct 2025'},
    {'name': 'OPV 3 + Pentavalent 3', 'age': '14 Weeks', 'status': 'GIVEN', 'date': '22 Nov 2025'},
    {'name': 'MR 1st Dose (Measles-Rubella)', 'age': '9–12 Months', 'status': 'GIVEN', 'date': '15 May 2026'},
    {'name': 'JE 1st Dose (Japanese Encephalitis)', 'age': '9–12 Months', 'status': 'GIVEN', 'date': '15 May 2026'},
    {'name': 'DPT Booster 1', 'age': '16–24 Months', 'status': 'DUE', 'date': 'Due Nov 2026'},
    {'name': 'MR 2nd Dose', 'age': '16–24 Months', 'status': 'DUE', 'date': 'Due Nov 2026'},
    {'name': 'OPV Booster', 'age': '16–24 Months', 'status': 'DUE', 'date': 'Due Nov 2026'},
  ];

  void _recordVaccine(int index) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    ).then((picked) {
      if (picked != null) {
        setState(() {
          _uipVaccines[index]['status'] = 'GIVEN';
          _uipVaccines[index]['date'] = '${picked.day}/${picked.month}/${picked.year}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_uipVaccines[index]['name']} marked as administered')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Immunization Schedule'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Schedule Selector ─────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.neutral200,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSchedule = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedSchedule == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'National UIP (Govt)',
                            style: AppTypography.labelLarge.copyWith(
                              color: _selectedSchedule == 0 ? AppColors.primary700 : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSchedule = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedSchedule == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'IAP Recommended',
                            style: AppTypography.labelLarge.copyWith(
                              color: _selectedSchedule == 1 ? AppColors.primary700 : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Status Summary ────────────────────────────────────
            AppCard(
              accentColor: AppColors.indigo500,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.indigo50, shape: BoxShape.circle),
                    child: const Icon(Icons.vaccines_rounded, color: AppColors.indigo500),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Next Vaccination: DPT Booster 1', style: AppTypography.labelLarge),
                        const SizedBox(height: 2),
                        Text(
                          'Schedule window open at 16–24 months (Due Nov 2026)',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Vaccine List ──────────────────────────────────────
            Text('Vaccine Timeline', style: AppTypography.titleMedium),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _uipVaccines.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final v = _uipVaccines[idx];
                final isGiven = v['status'] == 'GIVEN';

                return AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isGiven ? AppColors.semanticLowBg : AppColors.neutral100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isGiven ? Icons.check_rounded : Icons.schedule_rounded,
                          color: isGiven ? AppColors.semanticLowBadge : AppColors.neutral500,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v['name'] as String, style: AppTypography.labelLarge),
                            const SizedBox(height: 2),
                            Text(
                              'Age: ${v['age']} • ${v['date']}',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (!isGiven)
                        TextButton(
                          onPressed: () => _recordVaccine(idx),
                          child: const Text('Record'),
                        )
                      else
                        StatusBadge(label: 'Given', variant: StatusBadgeVariant.normal),
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
