// =============================================================================
// FILE: auth_service.dart
// PURPOSE: Handles all authentication flows for the Nutri360 app — parent login
//          via email/password (backed by Supabase Auth), health-worker login via
//          worker-ID + centre-code (backed by a Supabase Postgres query), demo
//          mode for both roles, session restore on cold-start, logout, and
//          password reset.
//
// WHY IT EXISTS: The original React Native implementation had a critical bug where
//   "rememberMe" state was written to AsyncStorage but never read back during
//   cold-start, so users were logged out every time the app restarted.  This
//   Dart rewrite explicitly restores the session inside `init()`, which is called
//   from main.dart before the first frame is rendered, guaranteeing that a
//   remembered user is never shown the login screen unnecessarily.
//
// PATTERN: Singleton via factory constructor — a single instance is shared across
//   the entire widget tree.  Obtain it with `AuthService()`.
// =============================================================================

import 'dart:convert'; // json encode/decode for SharedPreferences persistence

import 'package:flutter/foundation.dart'; // ChangeNotifier
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user.dart'; // Our own User model (not Supabase's User type)

// ---------------------------------------------------------------------------
// Custom exception — thrown instead of letting raw Supabase/network exceptions
// bubble up to the UI layer, so every screen only needs to catch one type.
// ---------------------------------------------------------------------------
class AuthException implements Exception {
  /// Human-readable explanation of what went wrong.
  final String message;

  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

// ---------------------------------------------------------------------------
// AuthService — singleton + ChangeNotifier for reactive UI updates
// ---------------------------------------------------------------------------
class AuthService extends ChangeNotifier {
  // ---- Singleton plumbing --------------------------------------------------
  static final AuthService _instance = AuthService._internal();

  /// Factory constructor returns the same instance every time.
  factory AuthService() => _instance;
  static AuthService get instance => _instance;

  AuthService._internal();
  // -------------------------------------------------------------------------

  // The SharedPreferences key under which we serialise the logged-in user.
  // Using a namespaced key avoids collisions with other packages that also
  // write to SharedPreferences.
  static const String _userStorageKey = '@nutri360_active_user';

  /// Convenience accessor for the Supabase client singleton.
  final SupabaseClient _supabase = Supabase.instance.client;

  /// In-memory cache of the currently authenticated user.
  /// Null means "not logged in".
  User? _currentUser;

  // =========================================================================
  // LIFECYCLE
  // =========================================================================

  /// Restores a previously saved session on app launch.
  ///
  /// Call this once from `main()` (after `Supabase.initialize`) before
  /// `runApp()`.  It reads the user JSON that was written by `loginParent` (or
  /// `loginWorker`) when rememberMe was true and re-hydrates `_currentUser` so
  /// that the router can decide whether to show Home or Login without any
  /// network round-trip.
  ///
  /// For Supabase-backed parent sessions the native Supabase SDK also persists
  /// the JWT internally; calling `_supabase.auth.currentSession` here lets us
  /// detect if the token has expired and clear our own storage accordingly,
  /// keeping both sources in sync.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userStorageKey);

    if (raw == null) return; // Nothing stored → stay logged out.

    try {
      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
      final restoredUser = User.fromJson(json);

      // For real parent accounts, cross-check that the Supabase JWT is still
      // valid.  Demo users and health-worker users bypass this check because
      // they don't have Supabase Auth sessions.
      if (restoredUser.role == UserRole.parent && !restoredUser.isDemo) {
        final session = _supabase.auth.currentSession;
        if (session == null) {
          // Token has expired or been revoked — clear stale storage.
          await prefs.remove(_userStorageKey);
          return;
        }
      }

      _currentUser = restoredUser;
    } catch (_) {
      // Corrupted JSON — wipe and start fresh.
      await prefs.remove(_userStorageKey);
    }
  }

  // =========================================================================
  // GETTERS
  // =========================================================================

  /// Returns the currently authenticated user, or `null` if not logged in.
  ///
  /// Callers should treat `null` as "redirect to login".  This is a synchronous
  /// getter backed by the in-memory cache; it does NOT hit the network.
  User? get currentUser => _currentUser;

  // =========================================================================
  // PARENT LOGIN
  // =========================================================================

  /// Authenticates a parent user with email and password.
  ///
  /// Flow:
  ///   1. Demo shortcut — if the credentials match the demo account, we skip
  ///      Supabase entirely and return a hard-coded demo User.  This lets QA /
  ///      reviewers test the app without a real internet connection.
  ///   2. Real login — delegates to `supabase.auth.signInWithPassword`.
  ///   3. Maps the Supabase `User` object to our own `User` model so the rest
  ///      of the app is decoupled from the Supabase SDK types.
  ///   4. If [rememberMe] is true, serialises the user to SharedPreferences so
  ///      `init()` can restore it on the next cold-start.
  ///
  /// Throws [AuthException] on any failure (bad credentials, network error,
  /// etc.) with a message suitable for display in a Snackbar.
  Future<User> loginParent(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    // ------------------------------------------------------------------
    // 1. Demo shortcut
    // ------------------------------------------------------------------
    if (email.trim().toLowerCase() == 'pooja.parent@nutri360.org' &&
        password == 'demo12345') {
      _currentUser = User.demoParent;
      // Always persist demo session so users exploring the app aren't
      // kicked back to login after a background kill.
      await _persistUser(_currentUser!);
      return _currentUser!;
    }

    // ------------------------------------------------------------------
    // 2. Real Supabase Auth login
    // ------------------------------------------------------------------
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final supabaseUser = response.user;
      if (supabaseUser == null) {
        // Should not happen when signIn succeeds, but guard anyway.
        throw const AuthException('Login failed — no user returned.');
      }

      // ------------------------------------------------------------------
      // 3. Map Supabase user → our User model
      //    We pull `full_name` from user_metadata which is populated during
      //    sign-up.  Fall back to the email prefix if the field is absent.
      // ------------------------------------------------------------------
      final meta = supabaseUser.userMetadata ?? {};
      _currentUser = User(
        id: supabaseUser.id,
        email: supabaseUser.email ?? email,
        fullName: (meta['full_name'] as String?)?.trim() ??
            email.split('@').first,
        role: UserRole.parent,
        isDemo: false,
      );

      // ------------------------------------------------------------------
      // 4. Persist if requested
      // ------------------------------------------------------------------
      if (rememberMe) {
        await _persistUser(_currentUser!);
      }

      return _currentUser!;
    } on AuthException {
      rethrow; // Already the right type — let it propagate.
    } on AuthApiException catch (e) {
      // Supabase wraps HTTP 400 / 422 errors here.
      throw AuthException(_friendlySupabaseError(e.message));
    } catch (e) {
      throw AuthException('Unexpected error during login: $e');
    }
  }

  // =========================================================================
  // HEALTH-WORKER LOGIN
  // =========================================================================

  /// Authenticates a health-worker via their Worker ID and assigned Centre Code.
  ///
  /// Health workers do NOT use Supabase Auth (they don't have email accounts in
  /// the system).  Instead we query the `health_workers` Postgres table directly.
  /// The match must be exact for both fields — no fuzzy matching.
  ///
  /// Demo shortcut: worker ID `HW-ANG-4019` + centre `ANG-4019` bypasses the
  /// database entirely for offline demos and App Store review.
  ///
  /// Throws [AuthException('Invalid Worker ID or Centre Code')] when no row is
  /// found, so the UI can display a single consistent error message.
  Future<User> loginWorker(String workerId, String centreCode) async {
    // ------------------------------------------------------------------
    // Demo shortcut
    // ------------------------------------------------------------------
    if (workerId.trim().toUpperCase() == 'HW-ANG-4019' &&
        centreCode.trim().toUpperCase() == 'ANG-4019') {
      _currentUser = User.demoWorker;
      await _persistUser(_currentUser!);
      return _currentUser!;
    }

    // ------------------------------------------------------------------
    // Real database lookup
    // ------------------------------------------------------------------
    try {
      // We expect exactly one row; `maybeSingle()` returns null instead of
      // throwing when no rows match, letting us give a clean error message.
      final row = await _supabase
          .from('health_workers')
          .select()
          .eq('worker_id', workerId.trim().toUpperCase())
          .eq('centre_code', centreCode.trim().toUpperCase())
          .maybeSingle();

      if (row == null) {
        throw const AuthException('Invalid Worker ID or Centre Code');
      }

      _currentUser = User(
        id: row['id'] as String,
        email: row['email'] as String? ?? '',
        fullName: row['full_name'] as String? ?? 'Health Worker',
        role: UserRole.healthWorker,
        isDemo: false,
        workerId: workerId.trim().toUpperCase(),
        centreCode: centreCode.trim().toUpperCase(),
      );

      // Health-worker sessions are always remembered; they typically share
      // a device and re-entering credentials is a friction point.
      await _persistUser(_currentUser!);

      return _currentUser!;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Could not verify worker credentials: $e');
    }
  }

  // =========================================================================
  // LOGOUT
  // =========================================================================

  /// Signs the current user out of Supabase Auth (if applicable) and wipes the
  /// locally persisted session from SharedPreferences.
  ///
  /// Safe to call even if the user is a demo user or a health-worker who doesn't
  /// have a Supabase Auth session — `signOut()` is a no-op in those cases
  /// (Supabase SDK handles it gracefully).
  Future<void> logout() async {
    // Clear server-side session for real parent accounts.
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // Network failure during sign-out is non-fatal — we still clear local
      // state.  The JWT will expire naturally on the server.
    }

    // Clear in-memory user.
    _currentUser = null;

    // Wipe from SharedPreferences so `init()` starts fresh next launch.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userStorageKey);
  }

  // =========================================================================
  // PASSWORD RESET
  // =========================================================================

  /// Sends a password-reset email via Supabase Auth.
  ///
  /// The email contains a magic link that opens the app (via deep link) on the
  /// password-reset screen.  Configure the redirect URL in the Supabase
  /// dashboard under Auth → URL Configuration.
  ///
  /// We deliberately do NOT throw on failure when the email is unrecognised —
  /// Supabase returns a 200 regardless to prevent user enumeration attacks, so
  /// the UI should always show "if that address is registered, we've sent a
  /// link".
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
    } on AuthApiException catch (e) {
      throw AuthException(_friendlySupabaseError(e.message));
    } catch (e) {
      throw AuthException('Could not send reset email: $e');
    }
  }

  // =========================================================================
  // PRIVATE HELPERS
  // =========================================================================

  /// Serialises [user] to JSON and stores it under [_userStorageKey].
  Future<void> _persistUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userStorageKey, jsonEncode(user.toJson()));
  }

  /// Converts raw Supabase error messages into friendlier UI copy.
  String _friendlySupabaseError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please verify your email address before logging in.';
    }
    if (lower.contains('too many requests')) {
      return 'Too many login attempts. Please wait a moment and try again.';
    }
    return raw; // Fall back to the raw message if we don't recognise it.
  }
}
