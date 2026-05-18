// ---------------------------------------------------------------------------
// AuthService — wraps Supabase auth calls.
// In React Native this logic was scattered in login.tsx + _layout.tsx.
// Here we centralise it in one place so screens stay clean.
// ---------------------------------------------------------------------------

import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  // Stream that fires on every auth state change — used by the router
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    // Mirror the React Native logic: sync profile to backend after sign-in
    if (response.user != null) {
      await ApiService().syncUserProfile(
        userId: response.user!.id,
        email: response.user!.email ?? '',
        displayName: response.user!.email?.split('@').first ?? 'User',
      );
    }
    return response;
  }

  Future<void> signOut() => _supabase.auth.signOut();

  // Creates a session row in Supabase and returns its ID.
  // Replaces the supabase.from('sessions').insert() block in lesson screen.
  Future<String?> createSession() async {
    final user = currentUser;
    if (user == null) return null;
    final res = await _supabase
        .from('sessions')
        .insert({'user_id': user.id})
        .select()
        .single();
    return res['id'] as String?;
  }
}
