import '../../data/repositories/auth_repository.dart';

/// Whether [error] means the user closed OAuth (not a failure to show).
bool isAuthCancellation(Object? error) {
  if (error == null) return false;
  if (error is GoogleSignInCancelled) return true;
  final msg = error.toString().toLowerCase();
  return msg.contains('googlesignincancelled') ||
      msg.contains('sign in cancelled') ||
      msg.contains('signin cancelled');
}

/// Converts raw Supabase / Postgres error messages into
/// short, human-readable strings for display in the UI.
///
/// Returns an empty string for user cancellation (caller should not snackbar).
String humaniseAuthError(Object? error) {
  if (error == null) return 'Something went wrong. Please try again.';
  if (isAuthCancellation(error)) return '';

  final msg = error.toString().toLowerCase();

  // Username already taken (unique constraint on profiles.username)
  if ((msg.contains('username') && msg.contains('unique')) ||
      (msg.contains('duplicate') && msg.contains('username')) ||
      msg.contains('profiles_username_key')) {
    return 'That username is already taken. Please choose another.';
  }

  // Email already registered
  if (msg.contains('user already registered') ||
      msg.contains('email already') ||
      msg.contains('already been registered') ||
      msg.contains('already registered')) {
    return 'An account with that email already exists.';
  }

  // Wrong password / invalid credentials
  if (msg.contains('invalid login credentials') ||
      msg.contains('invalid credentials') ||
      msg.contains('invalid_credentials') ||
      msg.contains('wrong password') ||
      msg.contains('invalid email or password')) {
    return 'Incorrect email or password.';
  }

  // Email not confirmed
  if (msg.contains('email not confirmed') ||
      msg.contains('email_not_confirmed')) {
    return 'Please verify your email before signing in.';
  }

  // Too many requests
  if (msg.contains('too many requests') ||
      msg.contains('rate limit') ||
      msg.contains('over_request_rate_limit')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }

  if (msg.contains('could not open google') ||
      msg.contains('disallowed_useragent') ||
      msg.contains('access_denied') ||
      (msg.contains('google') &&
          (msg.contains('sign-in') ||
              msg.contains('signin') ||
              msg.contains('oauth')))) {
    return 'Google sign-in could not complete. Please try again.';
  }

  // Weak password
  if ((msg.contains('password') && msg.contains('weak')) ||
      msg.contains('password should be at least') ||
      msg.contains('password_too_short')) {
    return 'Password must be at least 6 characters.';
  }

  // DNS / wrong API host (often mislabeled as "no internet")
  if (msg.contains('failed host lookup') ||
      msg.contains('name or service not known') ||
      msg.contains('nodename nor servname') ||
      msg.contains('xmlhttprequest error')) {
    return 'Cannot reach the server. Check the app configuration or try again.';
  }

  // Network error
  if (msg.contains('socketexception') ||
      msg.contains('clientexception') ||
      msg.contains('connection refused') ||
      msg.contains('connection reset') ||
      msg.contains('network is unreachable') ||
      msg.contains('failed to fetch') ||
      msg.contains('timed out') ||
      msg.contains('timeout')) {
    return 'No internet connection. Please check your network.';
  }

  // User banned / disabled
  if (msg.contains('user_banned') || msg.contains('banned')) {
    return 'This account is not allowed to sign in.';
  }

  // Fallback — strip the raw Postgres prefix if present
  if (msg.contains('postgrest') || msg.contains('pgrst')) {
    return 'Something went wrong. Please try again.';
  }

  // Return a tidied version of the original if nothing matched
  final cleaned = error
      .toString()
      .replaceAll('Exception: ', '')
      .replaceAll('AuthException: ', '')
      .replaceAll('AuthApiException: ', '')
      .replaceAll('PostgrestException: ', '')
      .trim();

  // Avoid dumping huge stack-like strings into snackbars
  if (cleaned.length > 140) {
    return 'Something went wrong. Please try again.';
  }
  return cleaned.isEmpty
      ? 'Something went wrong. Please try again.'
      : cleaned;
}
