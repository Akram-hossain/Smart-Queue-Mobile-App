import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/env.dart';

class SupabaseNotConfiguredException implements Exception {
  @override
  String toString() =>
      'Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY as '
      'repository secrets and rebuild the APK.';
}

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool get isReady => Env.isConfigured;

  SupabaseClient get client {
    if (!Env.isConfigured) throw SupabaseNotConfiguredException();
    return Supabase.instance.client;
  }

  GoTrueClient get auth => client.auth;

  String? get currentUserId => isReady ? auth.currentUser?.id : null;
}
