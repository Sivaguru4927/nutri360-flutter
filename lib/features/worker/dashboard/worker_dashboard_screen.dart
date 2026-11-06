// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/features/worker/dashboard/worker_dashboard_screen.dart
//
// WHAT THIS FILE DOES:
//   High-efficiency community caseload & clinical surveillance dashboard
//   for Anganwadi Health Workers (ICDS).
//   Replaces React Native's app/worker/index.tsx.
//
//   Key Features:
//     • Caseload Roster with SAM/MAM priority triage filters (All, High Priority, Monitor)
//     • Share Code Redemption dialog (enter NTR-XXXXXX from parents to add child)
//     • Community center statistics (Total Screened, Severe Malnutrition flags)
//     • One-tap navigation to comprehensive Worker Child Clinical Evaluation
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/child.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/status_badge.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  final _db = DatabaseService.instance;
  int _selectedFilter = 0; // 0 = All, 1 = High Priority (SAM), 2 = Monitor (MAM)

  final List<Child> _caseload = [
    Child(
      id: 'w-chd-001',
      childId: 'CHD-2024-001',
      name: 'Aarav Sharma',
      dob: '2025-08-15',
      sex: Sex.male,
      birthWeight: 3.1,
      heightCm: 76.5,
      weightKg: 9.8,
      screeningLocation: 'Anganwadi Center 12',
      parentName: 'Pooja Sharma',
      createdAt: '2026-01-10T10:00:00Z',
      updatedAt: '2026-09-15T10:00:00Z',
    ),
    Child(
      id: 'w-chd-002',
      childId: 'CHD-2024-004',
      name: 'Priya Patel',
      dob: '2025-04-10',
      sex: Sex.female,
      birthWeight: 2.7,
      heightCm: 72.0,
      weightKg: 7.8, // Low weight -> SAM/MAM concern
      screeningLocation: 'Anganwadi Center 12',
      parentName: 'Anita Patel',
      createdAt: '2026-01-12T10:00:00Z',
      updatedAt: '2026-09-12T10:00:00Z',
    ),
    Child(
      id: 'w-chd-003',
      childId: 'CHD-2024-008',
      name: 'Rohan Verma',
      dob: '2025-11-20',
      sex: Sex.male,
      birthWeight: 3.3,
      heightCm: 71.0,
      weightKg: 8.7,
      screeningLocation: 'Anganwadi Center 12',
      parentName: 'Sunita Verma',
      createdAt: '2026-02-01T10:00:00Z',
      updatedAt: '2026-09-10T10:00:00Z',
    ),
  ];

  void _showRedeemCodeDialog() {
    final codeCtrl = TextEditingController();
    bool isRedeeming = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.key_rounded, color: AppColors.teal500),
              const SizedBox(width: 8),
              const Text('Enter Share Code'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter the 6-digit access code (e.g. NTR-K3X9PW) provided by the parent:',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Access Code',
                  hintText: 'NTR-XXXXXX',
                  prefixIcon: Icon(Icons.qr_code_2_rounded),
                ),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 8),
                Text(errorMsg!, style: const TextStyle(color: AppColors.samRed, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isRedeeming
                  ? null
                  : () async {
                      final code = codeCtrl.text.trim().toUpperCase();
                      if (code.isEmpty) return;

                      setDialogState(() {
                        isRedeeming = true;
                        errorMsg = null;
                      });

                      try {
                        final user = context.read<AuthService>().currentUser;
                        final child = await _db.redeemShareCode(code, user?.id ?? 'worker-demo');
                        if (child != null) {
                          setState(() => _caseload.insert(0, child));
                        }
                        if (mounted) Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Child successfully added to your caseload!')),
                        );
                      } catch (e) {
                        setDialogState(() {
                          errorMsg = e.toString().replaceAll('Exception: ', '');
                          isRedeeming = false;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal500,
                foregroundColor: Colors.white,
              ),
              child: isRedeeming
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Redeem'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Anganwadi Caseload',
        hideBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.semanticHighBadge),
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AuthService>().logout();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Worker Info Banner ────────────────────────────────
            _buildWorkerBanner(user?.name ?? 'Health Worker', user?.workerId ?? 'HW-ANG-4019'),

            const SizedBox(height: 20),

            // ── Caseload Stats ────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _CaseloadStat(
                    label: 'Total Children',
                    value: '${_caseload.length}',
                    icon: Icons.people_outline_rounded,
                    color: AppColors.teal600,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _CaseloadStat(
                    label: 'SAM / MAM Flags',
                    value: '1 Child',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.samRed,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _CaseloadStat(
                    label: 'Due Checkup',
                    value: '2 Today',
                    icon: Icons.calendar_today_rounded,
                    color: AppColors.amber600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Triage Filters ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Caseload Triage', style: AppTypography.titleMedium),
                ElevatedButton.icon(
                  onPressed: _showRedeemCodeDialog,
                  icon: const Icon(Icons.add_link_rounded, size: 16),
                  label: const Text('Redeem Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                _TriageFilterChip(
                  label: 'All (${_caseload.length})',
                  isSelected: _selectedFilter == 0,
                  onTap: () => setState(() => _selectedFilter = 0),
                ),
                const SizedBox(width: 8),
                _TriageFilterChip(
                  label: 'High Priority (SAM)',
                  isSelected: _selectedFilter == 1,
                  activeColor: AppColors.samRed,
                  onTap: () => setState(() => _selectedFilter = 1),
                ),
                const SizedBox(width: 8),
                _TriageFilterChip(
                  label: 'Monitor (MAM)',
                  isSelected: _selectedFilter == 2,
                  activeColor: AppColors.amber600,
                  onTap: () => setState(() => _selectedFilter = 2),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Caseload List ─────────────────────────────────────
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _caseload.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, idx) {
                final child = _caseload[idx];
                final isConcern = child.weightKg < 8.0;

                return InkWell(
                  onTap: () => context.go('/worker/child/${child.id}'),
                  borderRadius: BorderRadius.circular(16),
                  child: AppCard(
                    accentColor: isConcern ? AppColors.samRed : AppColors.teal500,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isConcern ? AppColors.semanticHighBg : AppColors.teal50,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  child.name[0],
                                  style: AppTypography.titleLarge.copyWith(
                                    color: isConcern ? AppColors.samRed : AppColors.teal700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(child.name, style: AppTypography.titleMedium),
                                  Text(
                                    'ID: ${child.childId} • Parent: ${child.parentName ?? "N/A"}',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(
                              label: isConcern ? 'SAM Alert' : 'Normal',
                              variant: isConcern ? StatusBadgeVariant.highPriority : StatusBadgeVariant.normal,
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Age: ${child.ageDisplay}', style: AppTypography.bodySmall),
                            Text('Weight: ${child.weightKg} kg', style: AppTypography.labelMedium),
                            Text('Height: ${child.heightCm} cm', style: AppTypography.labelMedium),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                          ],
                        ),
                      ],
                    ),
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

  Widget _buildWorkerBanner(String name, String workerId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.teal600, AppColors.teal700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal500.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Anganwadi Center 12', style: AppTypography.labelSmall.copyWith(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(name, style: AppTypography.titleLarge.copyWith(color: Colors.white)),
          Text('Worker ID: $workerId', style: AppTypography.bodySmall.copyWith(color: Colors.white.withOpacity(0.9))),
        ],
      ),
    );
  }
}

class _CaseloadStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _CaseloadStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _TriageFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? activeColor;
  final VoidCallback onTap;

  const _TriageFilterChip({
    required this.label,
    required this.isSelected,
    this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final col = activeColor ?? AppColors.teal600;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? col.withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? col : AppColors.border),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? col : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

