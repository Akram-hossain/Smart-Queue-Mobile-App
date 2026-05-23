import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

class AuthRepository {
  AuthRepository(this._supabase);
  final SupabaseService _supabase;

  GoTrueClient get _auth => _supabase.auth;

  User? get currentUser =>
      _supabase.isReady ? _auth.currentUser : null;

  Stream<AuthState> authChanges() {
    if (!_supabase.isReady) return const Stream.empty();
    return _auth.onAuthStateChange;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(email: email.trim(), password: password);
  }

  Future<AuthResponse> signUp({
    required String fullName,
    required String email,
    required String password,
    required String department,
    required String semester,
    required String university,
  }) {
    return _auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'department': department.trim(),
        'semester': semester.trim(),
        'university': university.trim(),
      },
    );
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.resetPasswordForEmail(email.trim());

  /// Sign out defensively:
  /// 1. Ask Supabase to clear its session (may throw on network error — ignore).
  /// 2. As belt-and-braces, manually remove any cached supabase auth tokens
  ///    from SharedPreferences. This stops "log in again after reopening" if
  ///    the SDK ever leaves a stale token behind.
  Future<void> signOut() async {
    try {
      if (_supabase.isReady) {
        await _auth.signOut();
      }
    } catch (_) {
      // best-effort — we still want to clear local storage below
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) {
        final lower = k.toLowerCase();
        return lower.contains('supabase') ||
            lower.startsWith('sb-') ||
            lower.contains('gotrue');
      }).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {
      // best-effort
    }
  }
}
