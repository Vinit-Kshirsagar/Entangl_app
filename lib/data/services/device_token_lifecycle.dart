/// Pure helpers for FCM device-token lifecycle (testable without plugins).
class DeviceTokenLifecycle {
  DeviceTokenLifecycle._();

  /// Whether an FCM HTTP error body means the token should be deleted.
  static bool shouldDropToken(String fcmErrorBody) {
    final t = fcmErrorBody.toUpperCase();
    return t.contains('UNREGISTERED') ||
        t.contains('NOT_FOUND') ||
        t.contains('INVALID_ARGUMENT') ||
        t.contains('REGISTRATION-TOKEN-NOT-REGISTERED') ||
        t.contains('INVALID_REGISTRATION');
  }

  /// When the install gets a new token, the previous row should be removed.
  static bool shouldReplacePrevious({
    required String? previousToken,
    required String newToken,
  }) {
    if (previousToken == null || previousToken.isEmpty) return false;
    return previousToken != newToken;
  }
}
