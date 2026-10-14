import 'package:entangl_app/core/utils/auth_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthValidators.email', () {
    test('requires non-empty', () {
      expect(AuthValidators.email(null), 'Email is required');
      expect(AuthValidators.email(''), 'Email is required');
      expect(AuthValidators.email('   '), 'Email is required');
    });

    test('rejects invalid formats', () {
      expect(AuthValidators.email('not-an-email'), 'Enter a valid email');
      expect(AuthValidators.email('a@'), 'Enter a valid email');
      expect(AuthValidators.email('@b.com'), 'Enter a valid email');
    });

    test('accepts normal emails', () {
      expect(AuthValidators.email('user@example.com'), isNull);
      expect(AuthValidators.email('  user@example.com  '), isNull);
    });
  });

  group('AuthValidators.password', () {
    test('requires value', () {
      expect(AuthValidators.password(null), 'Password is required');
      expect(AuthValidators.password(''), 'Password is required');
    });

    test('enforces min length for register', () {
      expect(
        AuthValidators.password('12345'),
        'At least 6 characters required',
      );
      expect(AuthValidators.password('123456'), isNull);
    });

    test('login can allow short non-empty (server validates)', () {
      expect(AuthValidators.password('x', minLength: 1), isNull);
    });
  });

  group('AuthValidators.username', () {
    test('rules', () {
      expect(AuthValidators.username(''), 'Username is required');
      expect(
        AuthValidators.username('ab'),
        'Username must be at least 3 characters',
      );
      expect(
        AuthValidators.username('bad name'),
        'Only letters, numbers and underscores',
      );
      expect(AuthValidators.username('good_user1'), isNull);
    });
  });

  group('AuthValidators.fullName', () {
    test('required', () {
      expect(AuthValidators.fullName('  '), 'Name is required');
      expect(AuthValidators.fullName('Ada'), isNull);
    });
  });
}
