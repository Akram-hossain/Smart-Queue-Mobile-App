/// Compile-time Supabase configuration.
///
/// Pass via `--dart-define=SUPABASE_URL=...` and
/// `--dart-define=SUPABASE_ANON_KEY=...`. The CI workflow wires these from
/// repository secrets, so the actual values never sit in source.
class Env {
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  /// True only when both credentials look like real Supabase values.
  static bool get isConfigured =>
      supabaseUrl.startsWith('http') && supabaseAnonKey.length > 20;
}
