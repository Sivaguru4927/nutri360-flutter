// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/features/parent/add_child/add_child_screen.dart
//
// WHAT THIS FILE DOES:
//   Registration screen to add a new child record.
//   Replaces React Native's app/parent/add-child.tsx.
//
//   Key Features:
//     • Real-time WHO BMI calculation preview as user types height & weight
//     • Date of birth calendar picker with automatic age calculation
//     • Boy / Girl toggle chips
//     • Birth status options (Term vs Preterm)
//     • Direct persistence to Supabase via DatabaseService
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/child.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/utils/growth_calculations.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _heightCtrl = TextEditingController(text: '75.0');
  final _weightCtrl = TextEditingController(text: '9.5');
  final _locationCtrl = TextEditingController(text: 'Home');

  Sex _selectedSex = Sex.male;
  DateTime _selectedDob = DateTime.now().subtract(const Duration(days: 365));
  String _birthStatus = 'Term (37-42 weeks)';
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  // Real-time BMI calculation
  double get _currentBmi {
    final h = double.tryParse(_heightCtrl.text) ?? 0;
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    return GrowthCalculations.calculateBMI(w, h);
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 6)), // up to 6 yrs
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary500,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  Future<void> _saveChild() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      context.go('/');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final h = double.parse(_heightCtrl.text.trim());
      final w = double.parse(_weightCtrl.text.trim());
      final childIdNum = (DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
      final newChildId = 'CHD-${DateTime.now().year}-$childIdNum';

      final child = Child(
        id: '', // Supabase auto-generates UUID
        childId: newChildId,
        name: _nameCtrl.text.trim(),
        dob: DateFormat('yyyy-MM-dd').format(_selectedDob),
        sex: _selectedSex,
        birthStatus: _birthStatus,
        heightCm: h,
        weightKg: w,
        screeningLocation: _locationCtrl.text.trim(),
        parentName: user.name,
        createdAt: DateTime.now().toUtc().toIso8601String(),
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );

      await DatabaseService.instance.addChild(user.id, child);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${child.name} successfully registered!'),
            backgroundColor: AppColors.primary600,
          ),
        );
        context.go('/parent');
      }
    } catch (e) {
      setState(() => _error = 'Failed to register child: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bmi = _currentBmi;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Register Child'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Child Information', style: AppTypography.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Enter primary measurements for WHO growth tracking',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),

              const SizedBox(height: 20),

              if (_error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.semanticHighBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.semanticHighBorder),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppColors.semanticHighText)),
                ),

              // ── Child Name ──────────────────────────────────────
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Child Full Name *',
                  hintText: 'e.g. Aarav Sharma',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter child name' : null,
              ),

              const SizedBox(height: 16),

              // ── Gender Toggle ───────────────────────────────────
              Text('Gender *', style: AppTypography.labelMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.male_rounded, size: 18),
                          SizedBox(width: 6),
                          Text('Boy'),
                        ],
                      ),
                      selected: _selectedSex == Sex.male,
                      selectedColor: AppColors.primary100,
                      onSelected: (_) => setState(() => _selectedSex = Sex.male),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.female_rounded, size: 18),
                          SizedBox(width: 6),
                          Text('Girl'),
                        ],
                      ),
                      selected: _selectedSex == Sex.female,
                      selectedColor: Colors.pink.shade100,
                      onSelected: (_) => setState(() => _selectedSex = Sex.female),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Date of Birth ───────────────────────────────────
              Text('Date of Birth *', style: AppTypography.labelMedium),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDob,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.neutral50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: AppColors.primary500),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd MMMM yyyy').format(_selectedDob),
                        style: AppTypography.bodyMedium,
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Anthropometrics Row (Height & Weight) ───────────
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Height (cm) *',
                        suffixText: 'cm',
                        prefixIcon: Icon(Icons.height_rounded),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val <= 0) return 'Invalid height';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg) *',
                        suffixText: 'kg',
                        prefixIcon: Icon(Icons.monitor_weight_outlined),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val <= 0) return 'Invalid weight';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Real-time BMI Indicator ─────────────────────────
              AppCard(
                accentColor: bmi > 0 && bmi < 14
                    ? AppColors.amber500
                    : bmi >= 14 && bmi <= 18
                        ? AppColors.teal500
                        : AppColors.primary500,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.speed_rounded, color: AppColors.primary500),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Calculated BMI', style: AppTypography.labelSmall),
                          Text(
                            bmi > 0 ? '$bmi kg/m²' : 'Enter height & weight',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.primary700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      bmi > 0 && bmi < 14
                          ? 'Low'
                          : bmi >= 14 && bmi <= 18
                              ? 'Normal'
                              : 'Review',
                      style: AppTypography.labelMedium.copyWith(
                        color: bmi > 0 && bmi < 14
                            ? AppColors.amber600
                            : AppColors.teal600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Birth Status ────────────────────────────────────
              DropdownButtonFormField<String>(
                value: _birthStatus,
                decoration: const InputDecoration(
                  labelText: 'Gestational Birth Status',
                  prefixIcon: Icon(Icons.medical_information_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'Term (37-42 weeks)', child: Text('Term (37-42 weeks)')),
                  DropdownMenuItem(value: 'Preterm (<37 weeks)', child: Text('Preterm (<37 weeks)')),
                  DropdownMenuItem(value: 'Post-term (>42 weeks)', child: Text('Post-term (>42 weeks)')),
                ],
                onChanged: (v) => setState(() => _birthStatus = v ?? _birthStatus),
              ),

              const SizedBox(height: 28),

              // ── Submit Button ───────────────────────────────────
              AppButton(
                label: 'Save & Register Child',
                icon: Icons.check_rounded,
                isLoading: _isSaving,
                onPressed: _saveChild,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

