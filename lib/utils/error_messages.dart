/// Translates raw exception text from Supabase / Dart's networking layer into
/// short, plain-language messages safe to surface to end users.
///
/// Always returns *something* — never echoes a stack trace or class name.
String friendlyAuthError(Object error) {
  final raw = error.toString();
  final lower = raw.toLowerCase();

  // ----- Network / connectivity -----
  if (lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('no address associated') ||
      lower.contains('network is unreachable') ||
      lower.contains('connection refused') ||
      lower.contains('connection failed') ||
      lower.contains('connection closed') ||
      lower.contains('connection reset') ||
      lower.contains('handshakeexception') ||
      lower.contains('certificateexception') ||
      lower.contains('clientexception with socketexception')) {
    return 'No internet connection. Check your network and try again.';
  }
  if (lower.contains('timeout') || lower.contains('timed out')) {
    return 'The server took too long to respond. Please try again.';
  }

  // ----- Supabase / Auth specific -----
  if (lower.contains('invalid login') ||
      lower.contains('invalid credentials') ||
      lower.contains('invalid_credentials')) {
    return 'Wrong email or password.';
  }
  if (lower.contains('email not confirmed') ||
      lower.contains('email_not_confirmed')) {
    return 'Please confirm your email first — check your inbox.';
  }
  if (lower.contains('already registered') ||
      lower.contains('user_already_exists') ||
      lower.contains('user already')) {
    return 'An account with that email already exists. Try signing in instead.';
  }
  if (lower.contains('rate limit') ||
      lower.contains('over_email_send_rate_limit') ||
      lower.contains('too many requests')) {
    return 'Too many attempts. Please wait a minute and try again.';
  }
  if (lower.contains('weak_password') ||
      lower.contains('password should be at least')) {
    return 'Password is too weak. Use at least 6 characters.';
  }
  if (lower.contains('invalid email') ||
      lower.contains('unable to validate email')) {
    return 'That email address looks invalid.';
  }
  if (lower.contains('signup is disabled') ||
      lower.contains('signups not allowed')) {
    return 'New sign-ups are temporarily disabled.';
  }

  // ----- App-level wiring -----
  if (lower.contains('not configured') ||
      lower.contains('supabase_url')) {
    return 'The app isn\'t connected to the server. Reinstall the latest version.';
  }

  // ----- Last resort -----
  return 'Something went wrong. Please try again.';
}

/// For non-auth screens (CRUD, fetching lists, etc.) — slightly different
/// fallback copy that fits "couldn't save / load" contexts better.
String friendlyDataError(Object error) {
  final raw = error.toString();
  final lower = raw.toLowerCase();

  if (lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('connection') ||
      lower.contains('network is unreachable')) {
    return 'You appear to be offline. Check your connection and try again.';
  }
  if (lower.contains('timeout') || lower.contains('timed out')) {
    return 'The server took too long. Please try again.';
  }
  if (lower.contains('not signed in') || lower.contains('not authenticated')) {
    return 'Your session expired. Please sign in again.';
  }
  return 'Something went wrong. Please try again.';
}
