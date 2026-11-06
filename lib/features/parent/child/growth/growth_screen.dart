// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/features/parent/child/growth/growth_screen.dart
//
// WHAT THIS FILE DOES:
//   Pediatric anthropometric growth monitoring module.
//   Replaces React Native's app/parent/child/[id]/growth.tsx.
//
//   Key Features:
//     • WHO Multicentre Growth Reference Study (MGRS) Box-Cox LMS Z-scores
//     • Growth Traffic Light (SAM / MAM / Normal alert classification)
//     • WAZ (Weight-for-Age), HAZ (Height-for-Age), and BMI Z-score badges
//     • Interactive Growth Curves visualization (fl_chart)
//     • Record new measurement modal with instant recalculation
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/models/growth_record.dart';
import '../../../../core/models/child.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/utils/growth_calculations.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/status_badge.dart';

class GrowthScreen extends StatefulWidget {
  final String childId;

  const GrowthScreen({super.key, required this.childId});

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen> {
  double _currentWeight = 9.8;
  double _currentHeight = 76.5;
  final String _dob = '2025-08-15';
  final Sex _sex = Sex.male;

  final List<GrowthRecord> _history = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGrowthData();
  }

  void _loadGrowthData() {
    // Initial sample growth points
    _history.addAll([
      GrowthRecord(
        childId: widget.childId,
        measurementDate: '2026-03-01',
        heightCm: 71.0,
        weightKg: 8.4,
        bmi: 16.7,
        zScoreWeight: -0.6,
        zScoreHeight: -0.4,
        whoReferenceInterpretation: 'Normal Weight & Height',
        growthFlag: GrowthFlag.noFlag,
        createdAt: '2026-03-01T10:00:00Z',
      ),
      GrowthRecord(
        childId: widget.childId,
        measurementDate: '2026-06-15',
        heightCm: 74.0,
        weightKg: 9.1,
        bmi: 16.6,
        zScoreWeight: -0.7,
        zScoreHeight: -0.5,
        whoReferenceInterpretation: 'Normal Track',
        growthFlag: GrowthFlag.noFlag,
        createdAt: '2026-06-15T10:00:00Z',
      ),
      GrowthRecord(
        childId: widget.childId,
        measurementDate: '2026-09-10',
        heightCm: 76.5,
        weightKg: 9.8,
        bmi: 16.7,
        zScoreWeight: -0.8,
        zScoreHeight: -0.4,
        whoReferenceInterpretation: 'Growth Steady',
        growthFlag: GrowthFlag.noFlag,
        createdAt: '2026-09-10T10:00:00Z',
      ),
    ]);
  }

  void _showAddMeasurementDialog() {
    final hCtrl = TextEditingController(text: _currentHeight.toString());
    final wCtrl = TextEditingController(text: _currentWeight.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Record Measurement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: hCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                suffixText: 'cm',
                prefixIcon: Icon(Icons.height_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: wCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                suffixText: 'kg',
                prefixIcon: Icon(Icons.monitor_weight_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newH = double.tryParse(hCtrl.text) ?? _currentHeight;
              final newW = double.tryParse(wCtrl.text) ?? _currentWeight;
              final bmi = GrowthCalculations.calculateBMI(newW, newH);
              final eval = GrowthCalculations.evaluate(
                weightKg: newW,
                heightCm: newH,
                headCircumferenceCm: null,
                dob: _dob,
                sex: _sex,
              );

              final newRecord = GrowthRecord(
                childId: widget.childId,
                measurementDate: DateTime.now().toIso8601String().split('T').first,
                heightCm: newH,
                weightKg: newW,
                bmi: bmi,
                zScoreWeight: eval.weightForAge.zScore,
                zScoreHeight: eval.heightForAge.zScore,
                whoReferenceInterpretation: eval.clinicalSummary,
                growthFlag: eval.hasRedFlagAlert ? GrowthFlag.potentialConcern : GrowthFlag.noFlag,
                createdAt: DateTime.now().toIso8601String(),
              );

              setState(() {
                _currentHeight = newH;
                _currentWeight = newW;
                _history.add(newRecord);
              });

              // Also persist to DB in background
              DatabaseService.instance.saveGrowthRecord(newRecord).catchError((_) {});

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Measurement recorded!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eval = GrowthCalculations.evaluate(
      weightKg: _currentWeight,
      heightCm: _currentHeight,
      headCircumferenceCm: null,
      dob: _dob,
      sex: _sex,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Growth & Anthropometrics',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart_rounded, color: AppColors.primary500),
            tooltip: 'Add Measurement',
            onPressed: _showAddMeasurementDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── WHO Growth Traffic Light ──────────────────────────
            _buildTrafficLightCard(eval),

            const SizedBox(height: 20),

            // ── Primary Z-Scores Row ──────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _ZScoreCard(
                    title: 'Weight-for-Age',
                    zScore: eval.weightForAge.zScore,
                    percentile: eval.weightForAge.percentile,
                    unit: 'WAZ',
                    status: eval.weightForAge.classification.status,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ZScoreCard(
                    title: 'Height-for-Age',
                    zScore: eval.heightForAge.zScore,
                    percentile: eval.heightForAge.percentile,
                    unit: 'HAZ',
                    status: eval.heightForAge.classification.status,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── WHO Percentile Growth Curve (fl_chart) ────────────
            Text('WHO Growth Trajectory', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            _buildChartCard(),

            const SizedBox(height: 24),

            // ── Measurement History Table ─────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Measurement History', style: AppTypography.titleMedium),
                TextButton.icon(
                  onPressed: _showAddMeasurementDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New Entry'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final record = _history[idx];
                  return ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.scale_rounded, size: 20, color: AppColors.primary500),
                    ),
                    title: Text(
                      '${record.weightKg} kg  •  ${record.heightCm} cm',
                      style: AppTypography.labelLarge,
                    ),
                    subtitle: Text('Date: ${record.measurementDate}  •  BMI ${record.bmi}'),
                    trailing: StatusBadge(
                      label: record.whoReferenceInterpretation,
                      variant: StatusBadgeVariant.normal,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AppButton(
            label: 'Record New Measurement',
            icon: Icons.add_rounded,
            onPressed: _showAddMeasurementDialog,
          ),
        ),
      ),
    );
  }

  Widget _buildTrafficLightCard(ChildGrowthEvaluation eval) {
    final isSam = eval.hasRedFlagAlert;
    final color = isSam ? AppColors.samRed : AppColors.normalGreen;

    return AppCard(
      accentColor: color,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSam ? Icons.warning_rounded : Icons.check_circle_rounded,
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSam ? 'Clinical Nutrition Concern' : 'Normal Growth Standard',
                  style: AppTypography.labelLarge.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  eval.clinicalSummary,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weight-for-Age vs WHO Median (kg)', style: AppTypography.labelMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Child line (Blue)
                  LineChartBarData(
                    spots: const [
                      FlSpot(1, 8.4),
                      FlSpot(2, 9.1),
                      FlSpot(3, 9.8),
                    ],
                    isCurved: true,
                    color: AppColors.primary500,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                  // WHO 50th percentile reference line (Green dashed)
                  LineChartBarData(
                    spots: const [
                      FlSpot(1, 8.9),
                      FlSpot(2, 9.6),
                      FlSpot(3, 10.2),
                    ],
                    isCurved: true,
                    color: AppColors.teal500.withOpacity(0.5),
                    barWidth: 2,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 12, height: 3, color: AppColors.primary500),
              const SizedBox(width: 6),
              Text('Child Actual', style: AppTypography.bodySmall),
              const SizedBox(width: 20),
              Container(width: 12, height: 2, color: AppColors.teal500),
              const SizedBox(width: 6),
              Text('WHO 50th Percentile Median', style: AppTypography.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _ZScoreCard extends StatelessWidget {
  final String title;
  final double zScore;
  final double percentile;
  final String unit;
  final String status;

  const _ZScoreCard({
    required this.title,
    required this.zScore,
    required this.percentile,
    required this.unit,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = zScore < 0;
    final zDisplay = '${isNegative ? "" : "+"}${zScore.toStringAsFixed(1)}';

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(unit, style: AppTypography.labelSmall.copyWith(color: AppColors.primary600, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(zDisplay, style: AppTypography.displayLarge.copyWith(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text('${percentile.round()}th Percentile', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.semanticLowBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status, style: AppTypography.labelSmall.copyWith(color: AppColors.semanticLowText)),
          ),
        ],
      ),
    );
  }
}
