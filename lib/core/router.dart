// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/core/router.dart
//
// WHAT THIS FILE DOES:
//   Declares every screen/route in the app using go_router (declarative routing).
//   This is the Flutter equivalent of Expo Router's file-based routing.
//
//   Route tree:
//     /                    → RoleSelectionScreen (choose Parent or Worker)
//     /auth/parent-login   → ParentLoginScreen
//     /auth/worker-login   → WorkerLoginScreen
//
//     /parent              → ParentDashboardScreen (child list)
//     /parent/add-child    → AddChildScreen
//     /parent/child/:id    → ChildProfileScreen (tab scaffold)
//       /parent/child/:id/nutrition   → NutritionScreen
//       /parent/child/:id/growth      → GrowthScreen
//       /parent/child/:id/vaccination → VaccinationScreen
//       /parent/child/:id/development → DevelopmentScreen
//       /parent/child/:id/attention   → AttentionAssessmentScreen
//
//     /worker              → WorkerDashboardScreen
//     /worker/child/:id    → WorkerChildProfileScreen
//       /worker/child/:id/screening  → ScreeningScreen
//       /worker/child/:id/referral   → ReferralScreen
//       /worker/child/:id/nutrition  → WorkerNutritionScreen
//       /worker/child/:id/growth     → WorkerGrowthScreen
//
//   Navigation guards:
//     • If user is not logged in → redirect to /
//     • If logged-in user is a parent and tries /worker → redirect to /parent
//     • Vice versa for worker
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/role_selection_screen.dart';
import '../features/auth/parent_login_screen.dart';
import '../features/auth/worker_login_screen.dart';
import '../features/parent/dashboard/parent_dashboard_screen.dart';
import '../features/parent/add_child/add_child_screen.dart';
import '../features/parent/child/child_profile_screen.dart';
import '../features/parent/child/nutrition/nutrition_screen.dart';
import '../features/parent/child/growth/growth_screen.dart';
import '../features/parent/child/vaccination/vaccination_screen.dart';
import '../features/parent/child/development/development_screen.dart';
import '../features/parent/child/attention/attention_screen.dart';
import '../features/worker/dashboard/worker_dashboard_screen.dart';
import '../features/worker/child/worker_child_screen.dart';
import 'models/user.dart';
import 'services/auth_service.dart';

/// Creates and returns the GoRouter instance for the entire app.
/// Called once in main.dart.
GoRouter buildRouter(AuthService authService) {
  return GoRouter(
    // Start at role selection screen
    initialLocation: '/',

    // ── Navigation Guard ─────────────────────────────────────
    // Runs before every navigation — checks if user is logged in
    redirect: (BuildContext context, GoRouterState state) {
      final user = authService.currentUser;
      final isLoggedIn = user != null;
      final isAuthRoute = state.matchedLocation == '/' ||
          state.matchedLocation.startsWith('/auth');

      // Not logged in and trying to access protected route → back to home
      if (!isLoggedIn && !isAuthRoute) return '/';

      // Logged in parent trying to access worker screens → redirect
      if (isLoggedIn && user!.role == UserRole.parent &&
          state.matchedLocation.startsWith('/worker')) {
        return '/parent';
      }

      // Logged in worker trying to access parent screens → redirect
      if (isLoggedIn && user.role == UserRole.healthWorker &&
          state.matchedLocation.startsWith('/parent')) {
        return '/worker';
      }

      return null; // allow navigation
    },

    routes: [
      // ── Public / Auth Routes ────────────────────────────────
      GoRoute(
        path: '/',
        builder: (_, __) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/auth/parent-login',
        builder: (_, __) => const ParentLoginScreen(),
      ),
      GoRoute(
        path: '/auth/worker-login',
        builder: (_, __) => const WorkerLoginScreen(),
      ),

      // ── Parent Routes ───────────────────────────────────────
      GoRoute(
        path: '/parent',
        builder: (_, __) => const ParentDashboardScreen(),
        routes: [
          GoRoute(
            path: 'add-child',
            builder: (_, __) => const AddChildScreen(),
          ),
          GoRoute(
            path: 'child/:id',
            builder: (_, state) => ChildProfileScreen(
              childId: state.pathParameters['id']!,
            ),
            routes: [
              GoRoute(
                path: 'nutrition',
                builder: (_, state) => NutritionScreen(
                  childId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'growth',
                builder: (_, state) => GrowthScreen(
                  childId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'vaccination',
                builder: (_, state) => VaccinationScreen(
                  childId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'development',
                builder: (_, state) => DevelopmentScreen(
                  childId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'attention',
                builder: (_, state) => AttentionScreen(
                  childId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),

      // ── Worker Routes ───────────────────────────────────────
      GoRoute(
        path: '/worker',
        builder: (_, __) => const WorkerDashboardScreen(),
        routes: [
          GoRoute(
            path: 'child/:id',
            builder: (_, state) => WorkerChildScreen(
              childId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],

    // 404 error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Page not found: ${state.uri}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    ),
  );
}

