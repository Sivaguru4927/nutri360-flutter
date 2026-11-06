// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/features/auth/worker_login_screen.dart
//
// WHAT THIS FILE DOES:
//   The Anganwadi Health Worker sign-in screen.
//   Equivalent to React Native's app/auth/worker-login.tsx.
//
//   Workers do NOT use email+password — they use a 2-field system:
//     1. Worker ID    (e.g. HW-ANG-4019)
//     2. Centre Code  (e.g. ANG-4019) — the Anganwadi centre they belong to
//
//   This two-field system matches the ICDS field worker ID structure.
//   On success → navigates to /worker (WorkerDashboardScreen).
//
//   Demo credentials: Worker ID = HW-ANG-4019 / Centre Code = ANG-4019
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/app_button.dart';

class WorkerLoginScreen extends StatefulWidget {
  const WorkerLoginScreen({super.key});

  @override
  State<WorkerLoginScreen> createState() => _WorkerLoginScreenState();
}

class _WorkerLoginScreenState extends State<WorkerLoginScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _workerIdCtrl  = TextEditingController();
  final _centreCodeCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _workerIdCtrl.dispose();
    _centreCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await context.read<AuthService>().loginWorker(
        _workerIdCtrl.text.trim().toUpperCase(),
        _centreCodeCtrl.text.trim().toUpperCase(),
      );
      if (mounted) context.go('/worker');
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Login failed. Please check your credentials.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInAsDemo() async {
    _workerIdCtrl.text   = 'HW-ANG-4019';
    _centreCodeCtrl.text = 'ANG-4019';
    await _signIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => context.go('/'),
                  padding: EdgeInsets.zero,
                ),

                const SizedBox(height: 24),

                // ── Teal header accent ───────────────────────
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.teal500,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.medical_services_rounded,
                      color: Colors.white, size: 28),
                ),

                const SizedBox(height: 20),

                Text('Worker Login', style: AppTypography.headlineLarge),
                const SizedBox(height: 8),
                Text(
                  'Sign in with your Anganwadi Worker ID and Centre Code',
                  style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary),
                ),

                const SizedBox(height: 32),

                // ── Error Banner ─────────────────────────────
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.semanticHighBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.semanticHighBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.semanticHighText, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage!,
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.semanticHighText)),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _errorMessage = null),
                          child: const Icon(Icons.close_rounded,
                              color: AppColors.semanticHighText, size: 16),
                        ),
                      ],
                    ),
                  ),

                // ── Worker ID field ──────────────────────────
                TextFormField(
                  controller: _workerIdCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Worker ID',
                    hintText: 'e.g. HW-ANG-4019',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Worker ID is required' : null,
                ),

                const SizedBox(height: 16),

                // ── Centre Code field ────────────────────────
                TextFormField(
                  controller: _centreCodeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Anganwadi Centre Code',
                    hintText: 'e.g. ANG-4019',
                    prefixIcon: Icon(Icons.location_city_rounded),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Centre Code is required' : null,
                ),

                const SizedBox(height: 28),

                // ── Sign In Button (teal for worker) ─────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal500,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : Text('Sign In', style: AppTypography.labelLarge),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Divider & Demo ───────────────────────────
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted)),
                  ),
                  const Expanded(child: Divider()),
                ]),

                const SizedBox(height: 12),

                AppButton(
                  label: 'Try Demo Worker Account',
                  onPressed: _signInAsDemo,
                  variant: AppButtonVariant.secondary,
                  icon: Icons.play_circle_outline_rounded,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 24),

                // ── Help text ────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.semanticInfoBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.semanticInfoBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.semanticInfoBadge, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your Worker ID and Centre Code were provided by your ICDS supervisor. Contact your supervisor if you need assistance.',
                          style: AppTypography.bodySmall.copyWith(
                              color: AppColors.semanticInfoText),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

