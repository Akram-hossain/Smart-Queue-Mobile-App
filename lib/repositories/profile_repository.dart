import '../models/profile.dart';
import '../services/supabase_service.dart';

class ProfileRepository {
  ProfileRepository(this._supabase);
  final SupabaseService _supabase;

  Future<Profile?> getCurrentProfile() async {
    final uid = _supabase.currentUserId;
    if (uid == null) return null;
    final row = await _supabase.client
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();
    if (row == null) return null;
    return Profile.fromMap(row);
  }

  Future<Profile> updateProfile(Profile profile) async {
    final updated = await _supabase.client
        .from('profiles')
        .update(profile.toUpdateMap())
        .eq('id', profile.id)
        .select()
        .single();
    return Profile.fromMap(updated);
  }
}
