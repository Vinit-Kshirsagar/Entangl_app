/// Pure field validators for auth forms (no Flutter UI deps beyond String).
class AuthValidators {
  AuthValidators._();

  static final _emailPattern = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < minLength) {
      return 'At least $minLength characters required';
    }
    return null;
  }

  static String? username(String? value, {int minLength = 3}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Username is required';
    if (v.length < minLength) {
      return 'Username must be at least $minLength characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
      return 'Only letters, numbers and underscores';
    }
    return null;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    return null;
  }
}
