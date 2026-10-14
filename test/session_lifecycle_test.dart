import 'package:entangl_app/core/utils/session_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SessionLifecycle.isAuthFailure', () {
    test('detects jwt and unauthorized shapes', () {
      expect(
        SessionLifecycle.isAuthFailure(Exception('JWT expired')),
        isTrue,
      );
      expect(
        SessionLifecycle.isAuthFailure('AuthApiException: invalid claim'),
        isTrue,
      );
      expect(
        SessionLifecycle.isAuthFailure('PostgrestException: 401'),
        isTrue,
      );
      expect(
        SessionLifecycle.isAuthFailure('refresh_token not found'),
        isTrue,
      );
    });

    test('does not flag normal app errors', () {
      expect(
        SessionLifecycle.isAuthFailure(Exception('username taken')),
        isFalse,
      );
    });
  });

  group('SessionLifecycle.isMissingProfileError', () {
    test('detects PGRST116', () {
      expect(
        SessionLifecycle.isMissingProfileError(
          Exception('PostgrestException: PGRST116 0 rows'),
        ),
        isTrue,
      );
    });
  });

  group('SessionLifecycle.isNetworkFailure', () {
    test('detects transport errors but not auth', () {
      expect(
        SessionLifecycle.isNetworkFailure(
          Exception('SocketException: Connection refused'),
        ),
        isTrue,
      );
      expect(
        SessionLifecycle.isNetworkFailure(Exception('JWT expired')),
        isFalse,
      );
    });
  });

  group('SessionLifecycle.isExpiringSoon / isExpired', () {
    test('null session is expired for isExpired', () {
      expect(SessionLifecycle.isExpired(null), isTrue);
      expect(SessionLifecycle.isExpiringSoon(null), isFalse);
    });
  });
}
