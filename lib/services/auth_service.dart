// ---------------------------------------------------------------------------
// AuthService — wraps Supabase auth calls.
// In React Native this logic was scattered in login.tsx + _layout.tsx.
// Here we centralise it in one place so screens stay clean.
// ---------------------------------------------------------------------------

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Returns the Supabase client if initialized, otherwise null.
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Public helper to let UI check whether Supabase is available.
  bool get isSupabaseReady => _client != null;

  User? get currentUser {
    final c = _client;
    if (c == null) return null;
    return c.auth.currentUser;
  }

  bool get isLoggedIn => currentUser != null;

  // Stream that fires on every auth state change — used by the router
  Stream<AuthState>? get authStateChanges {
    final c = _client;
    if (c == null) return null;
    return c.auth.onAuthStateChange;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final c = _client;
    if (c == null) throw Exception('Supabase not initialized');

    final response = await c.auth.signInWithPassword(
      email: email,
      password: password,
    );
    // Profile sync temporarily disabled to avoid blocking login while backend
    // schema / RLS fixes are pending.
    // TODO: Re-enable profile sync after backend schema/RLS fixes
    if (response.user != null) {
      final userId = response.user!.id;
      debugPrint('AuthService.signIn: skipping profile sync for user $userId (temporary)');
    } else {
      debugPrint('AuthService.signIn: Supabase returned no user after sign-in');
      throw Exception('Login failed. Please try again.');
    }
    return response;
  }

  Future<void> signOut() async {
    final c = _client;
    if (c == null) return;
    await c.auth.signOut();
  }

  // Creates a session row in Supabase and returns its ID.
  // Replaces the supabase.from('sessions').insert() block in lesson screen.
  Future<String?> createSession() async {
    final user = currentUser;
    if (user == null) return null;
    final c = _client;
    if (c == null) return null;
    final res = await c.from('sessions').insert({'user_id': user.id}).select().single();
    return res['id'] as String?;
  }
}
