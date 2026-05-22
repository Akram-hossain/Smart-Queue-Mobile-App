import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/profile.dart';
import '../repositories/profile_repository.dart';
import 'auth_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
    (ref) => ProfileRepository(ref.watch(supabaseServiceProvider)));

final profileProvider = FutureProvider<Profile?>((ref) async {
  // re-fetch whenever the user changes
  ref.watch(currentUserProvider);
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getCurrentProfile();
});
