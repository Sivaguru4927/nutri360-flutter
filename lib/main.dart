// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/main.dart
//
// WHAT THIS FILE DOES:
//   The single entry point of the entire Flutter application.
//   Runs first when the app launches. Responsible for:
//
//   1. INITIALISATION (before the first frame is drawn):
//      a. Load .env file  → reads SUPABASE_URL, SUPABASE_ANON_KEY, ATLAS_APP_ID
//      b. Init Supabase   → connects to the backend DB (same project as React Native)
//      c. Init Hive       → opens local offline database boxes
//      d. Init AuthService → restores saved login session (fixes "language resets" bug)
//      e. Init StitchService → connects MongoDB Atlas App Services
//
//   2. PROVIDER SETUP:
//      Wraps the app in MultiProvider so any widget can access:
//        • AuthService  → current user, login/logout
//        • (more providers added in later phases: ChildProvider, NutritionProvider, etc.)
//
//   3. LOCALISATION:
//      Wraps app in EasyLocalization with 7 supported languages:
//        EN (English), HI (Hindi), TE (Telugu), TA (Tamil),
//        KN (Kannada), BN (Bengali), MR (Marathi)
//      Fixes the React Native bug where selected language reset on app restart.
//
//   4. ROUTER:
//      Passes the GoRouter (from router.dart) to MaterialApp.router
//      so navigation works declaratively across all screens.
//
//   5. THEME:
//      Applies AppTheme.light() so the entire app uses Nutri360 colours
//      and typography without per-widget styling.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/offline_store.dart';
import 'core/services/stitch_service.dart';
import 'core/router.dart';

Future<void> main() async {
  // Required before any async work in main()
  WidgetsFlutterBinding.ensureInitialized();

  // ── Step 1: Load environment variables ───────────────────
  await dotenv.load(fileName: 'assets/app.env');

  // ── Step 2: Initialise Supabase ──────────────────────────
  // Uses the same project credentials from the React Native app:
  //   SUPABASE_URL = https://advcgnnredvobprwulqv.supabase.co
  //   SUPABASE_ANON_KEY = loaded from .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    debug: dotenv.env['APP_ENV'] == 'development',
  );

  // ── Step 3: Initialise Hive (offline local database) ─────
  // Hive stores child data and queued sync records so the app
  // works fully without internet (critical for Anganwadi workers in rural areas).
  await Hive.initFlutter();
  await OfflineStore.instance.init();

  // ── Step 4: Initialise EasyLocalization ──────────────────
  // Translation JSON files live in assets/translations/
  // e.g. assets/translations/en.json, hi.json, te.json ...
  await EasyLocalization.ensureInitialized();

  // ── Step 5: Initialise AuthService → restore saved session ─
  // Fixes the React Native bug: saved login (rememberMe) now persists
  // across app restarts using SharedPreferences.
  final authService = AuthService.instance;
  await authService.init();

  // ── Step 6: Initialise MongoDB Atlas Stitch ───────────────
  final stitchService = StitchService.instance;
  await stitchService.init();

  // ── Step 7: Lock screen to portrait mode ─────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Step 8: Run the app ───────────────────────────────────
  runApp(
    // EasyLocalization wraps everything so all descendant widgets
    // can call context.tr('key') for translated strings
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),  // English
        Locale('hi'),  // Hindi
        Locale('te'),  // Telugu
        Locale('ta'),  // Tamil
        Locale('kn'),  // Kannada
        Locale('bn'),  // Bengali
        Locale('mr'),  // Marathi
      ],
      path: 'assets/translations',    // folder with JSON locale files
      fallbackLocale: const Locale('en'), // default to English
      child: MultiProvider(
        providers: [
          // AuthService is a ChangeNotifier — widgets rebuild on login/logout
          ChangeNotifierProvider<AuthService>.value(value: authService),
          // More providers added in Phase 3 (ChildProvider, NutritionProvider, etc.)
        ],
        child: Nutri360App(authService: authService),
      ),
    ),
  );
}

/// Root widget of the Nutri360 application
class Nutri360App extends StatelessWidget {
  final AuthService authService;

  const Nutri360App({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    // Build the GoRouter — needs authService to enforce navigation guards
    final router = buildRouter(authService);

    return MaterialApp.router(
      title: 'Nutri360',
      debugShowCheckedModeBanner: false,

      // ── Theme ─────────────────────────────────────────────
      // All Nutri360 colours, fonts, button styles loaded from app_theme.dart
      theme: AppTheme.light(),

      // ── Localisation ───────────────────────────────────────
      // EasyLocalization provides these delegates to the MaterialApp
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // ── Router ─────────────────────────────────────────────
      routerConfig: router,
    );
  }
}

