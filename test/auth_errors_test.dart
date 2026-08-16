import 'package:entangl_app/core/utils/auth_errors.dart';
import 'package:entangl_app/data/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('humaniseAuthError', () {
    test('maps invalid credentials', () {
      expect(
        humaniseAuthError(Exception('Invalid login credentials')),
        'Incorrect email or password.',
      );
      expect(
        humaniseAuthError('AuthException: invalid_credentials'),
        'Incorrect email or password.',
      );
    });

    test('maps duplicate username and email', () {
      expect(
        humaniseAuthError('duplicate key value violates profiles_username_key'),
        'That username is already taken. Please choose another.',
      );
      expect(
        humaniseAuthError('User already registered'),
        'An account with that email already exists.',
      );
    });

    test('maps network and host failures distinctly', () {
      expect(
        humaniseAuthError(Exception('SocketException: Failed host lookup')),
        'Cannot reach the server. Check the app configuration or try again.',
      );
      expect(
        humaniseAuthError(Exception('ClientException: Connection refused')),
        'No internet connection. Please check your network.',
      );
      expect(
        humaniseAuthError(Exception('Connection timed out')),
        'No internet connection. Please check your network.',
      );
    });

    test('maps rate limit and weak password', () {
      expect(
        humaniseAuthError('Too many requests'),
        'Too many attempts. Please wait a moment and try again.',
      );
      expect(
        humaniseAuthError('Password should be at least 6 characters'),
        'Password must be at least 6 characters.',
      );
    });

    test('maps email not confirmed', () {
      expect(
        humaniseAuthError('Email not confirmed'),
        'Please verify your email before signing in.',
      );
    });

    test('Google cancellation is silent', () {
      expect(isAuthCancellation(GoogleSignInCancelled()), isTrue);
      expect(humaniseAuthError(GoogleSignInCancelled()), isEmpty);
    });

    test('truncates oversized raw messages', () {
      final huge = Exception('x' * 200);
      expect(humaniseAuthError(huge), 'Something went wrong. Please try again.');
    });

    test('null is safe', () {
      expect(
        humaniseAuthError(null),
        'Something went wrong. Please try again.',
      );
    });
  });
}
