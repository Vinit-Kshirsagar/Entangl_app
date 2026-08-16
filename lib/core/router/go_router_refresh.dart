import 'dart:async';

import 'package:flutter/foundation.dart';

/// Notifies [GoRouter] when an auth stream emits so redirects re-run
/// (e.g. logout clears protected routes without a manual `context.go`).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
