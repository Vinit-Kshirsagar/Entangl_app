/// Converts raw Supabase / Postgres error messages into
/// short, human-readable strings for display in the UI.
String humaniseAuthError(Object error) {
  final msg = error.toString().toLowerCase();

  // Username already taken (unique constraint on profiles.username)
  if (msg.contains('username') && msg.contains('unique') ||
      msg.contains('duplicate') && msg.contains('username') ||
      msg.contains('profiles_username_key')) {
    return 'That username is already taken. Please choose another.';
  }

  // Email already registered
  if (msg.contains('user already registered') ||
      msg.contains('email already') ||
      msg.contains('already been registered')) {
    return 'An account with that email already exists.';
  }

  // Wrong password / invalid credentials
  if (msg.contains('invalid login credentials') ||
      msg.contains('invalid credentials') ||
      msg.contains('wrong password')) {
    return 'Incorrect email or password.';
  }

  // Email not confirmed
  if (msg.contains('email not confirmed')) {
    return 'Please verify your email before signing in.';
  }

  // Too many requests
  if (msg.contains('too many requests') ||
      msg.contains('rate limit')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }

  // Weak password
  if (msg.contains('password') && msg.contains('weak') ||
      msg.contains('password should be at least')) {
    return 'Password must be at least 6 characters.';
  }

  // Network error
  if (msg.contains('socketexception') ||
      msg.contains('network') ||
      msg.contains('connection refused')) {
    return 'No internet connection. Please check your network.';
  }

  // Fallback — strip the raw Postgres prefix if present
  if (msg.contains('postgrest') || msg.contains('pgrst')) {
    return 'Something went wrong. Please try again.';
  }

  // Return a tidied version of the original if nothing matched
  return error
      .toString()
      .replaceAll('Exception: ', '')
      .replaceAll('AuthException: ', '')
      .replaceAll('PostgrestException: ', '');
}
