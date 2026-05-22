import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository.dart';
import '../services/supabase_service.dart';

final supabaseServiceProvider =
    Provider<SupabaseService>((ref) => SupabaseService.instance);

final authRepositoryProvider = Provider<AuthRepository>(
    (ref) => AuthRepository(ref.watch(supabaseServiceProvider)));

/// Streams auth-state changes. Emits whatever the current session is initially,
/// then any sign-in / sign-out / token-refresh event.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authChanges();
});

/// Convenience: current Supabase User or null.
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).currentUser;
});
