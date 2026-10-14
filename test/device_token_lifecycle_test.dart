import 'package:entangl_app/data/services/device_token_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeviceTokenLifecycle.shouldDropToken', () {
    test('drops UNREGISTERED and invalid registration', () {
      expect(
        DeviceTokenLifecycle.shouldDropToken(
          '{"error":{"status":"NOT_FOUND","details":"UNREGISTERED"}}',
        ),
        isTrue,
      );
      expect(
        DeviceTokenLifecycle.shouldDropToken(
          'REGISTRATION-TOKEN-NOT-REGISTERED',
        ),
        isTrue,
      );
      expect(
        DeviceTokenLifecycle.shouldDropToken('INVALID_ARGUMENT'),
        isTrue,
      );
    });

    test('keeps transient server errors', () {
      expect(
        DeviceTokenLifecycle.shouldDropToken('INTERNAL 500'),
        isFalse,
      );
      expect(
        DeviceTokenLifecycle.shouldDropToken('QUOTA_EXCEEDED'),
        isFalse,
      );
    });
  });

  group('DeviceTokenLifecycle.shouldReplacePrevious', () {
    test('replaces only when previous differs', () {
      expect(
        DeviceTokenLifecycle.shouldReplacePrevious(
          previousToken: null,
          newToken: 'a',
        ),
        isFalse,
      );
      expect(
        DeviceTokenLifecycle.shouldReplacePrevious(
          previousToken: 'a',
          newToken: 'a',
        ),
        isFalse,
      );
      expect(
        DeviceTokenLifecycle.shouldReplacePrevious(
          previousToken: 'old',
          newToken: 'new',
        ),
        isTrue,
      );
    });
  });
}
