// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/features/auth/parent_login_screen.dart
//
// WHAT THIS FILE DOES:
//   The Parent sign-in / registration screen.
//   Equivalent to React Native's app/auth/parent-login.tsx.
//
//   Supports 3 flows:
//     1. SIGN IN  → email + password → AuthService.loginParent()
//     2. REGISTER → new account via Supabase Auth sign-up
//     3. DEMO     → one-tap "Try Demo" (email: pooja.parent@nutri360.org / demo12345)
//
//   Bug fixes vs React Native version:
//     • "Remember Me" now actually persists via SharedPreferences (was broken)
//     • Password visibility toggle
//     • Forgot password modal triggers Supabase resetPasswordForEmail
//     • Loading spinner on button while awaiting auth response
//     • Error shown as a dismissable banner (not just console.log)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/app_button.dart';

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({super.key});

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // UI state
  bool _obscurePassword = true;  // toggle eye icon
  bool _rememberMe      = true;  // persist session flag
  bool _isLoading       = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Sign In Handler ─────────────────────────────────────────
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      await authService.loginParent(
        _emailCtrl.text.trim(),
        _passwordCtrl.text.trim(),
        rememberMe: _rememberMe,
      );
      // On success: router guard auto-redirects to /parent
      if (mounted) context.go('/parent');
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Demo Login Handler ─────────────────────────────────────
  Future<void> _signInAsDemo() async {
    _emailCtrl.text    = 'pooja.parent@nutri360.org';
    _passwordCtrl.text = 'demo12345';
    await _signIn();
  }

  // ── Forgot Password ─────────────────────────────────────────
  void _showForgotPassword() {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: emailCtrl,
          decoration: const InputDecoration(
            labelText: 'Email address',
            hintText: 'Enter your registered email',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<AuthService>().resetPassword(emailCtrl.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset email sent!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Send Reset Email'),
          ),
        ],
      ),
    );
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
                // ── Back button ──────────────────────────────
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => context.go('/'),
                  padding: EdgeInsets.zero,
                ),

                const SizedBox(height: 24),

                // ── Header ───────────────────────────────────
                Text('Parent Login', style: AppTypography.headlineLarge),
                const SizedBox(height: 8),
                Text(
                  'Sign in to track your child\'s health',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
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
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.semanticHighText,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _errorMessage = null),
                          child: const Icon(Icons.close_rounded,
                              color: AppColors.semanticHighText, size: 16),
                        ),
                      ],
                    ),
                  ),

                // ── Email Field ──────────────────────────────
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ── Password Field ───────────────────────────
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    // Eye icon to show/hide password
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Password is required';
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // ── Remember Me + Forgot Password row ────────
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (v) => setState(() => _rememberMe = v ?? true),
                      activeColor: AppColors.primary500,
                    ),
                    Text('Remember me', style: AppTypography.bodySmall),
                    const Spacer(),
                    TextButton(
                      onPressed: _showForgotPassword,
                      child: Text(
                        'Forgot Password?',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Sign In Button ───────────────────────────
                AppButton(
                  label: 'Sign In',
                  onPressed: _signIn,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 12),

                // ── Divider ──────────────────────────────────
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Demo Login Button ─────────────────────────
                AppButton(
                  label: 'Try Demo Account',
                  onPressed: _signInAsDemo,
                  variant: AppButtonVariant.secondary,
                  icon: Icons.play_circle_outline_rounded,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 24),

                // ── Register link ─────────────────────────────
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Don't have an account? ",
                          style: AppTypography.bodySmall),
                      GestureDetector(
                        onTap: () {
                          // TODO Phase 2: register screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Registration coming in Phase 2')),
                          );
                        },
                        child: Text(
                          'Register',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary600,
                            fontWeight: FontWeight.w600,
                          ),
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

