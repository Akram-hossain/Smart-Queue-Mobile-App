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

  Future<void> signOut() => _auth.signOut();
}
