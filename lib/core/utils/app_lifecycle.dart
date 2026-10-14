import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/services/push_notification_service.dart';
import '../../data/services/supabase_service.dart';
import '../theme/app_colors.dart';
import 'session_lifecycle.dart';

class AppLifecycleWrapper extends StatefulWidget {
  final Widget child;
  const AppLifecycleWrapper({super.key, required this.child});

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper>
    with WidgetsBindingObserver {
  bool _isOnline = true;
  bool _checked = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(const Duration(seconds: 3), () {
      _checkConnectivity();
      _pollTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _checkConnectivity(),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkConnectivity();
      unawaited(_refreshSessionSilently());
      unawaited(PushNotificationService.instance.syncWithPreferences());
    }
  }

  Future<void> _checkConnectivity() async {
    final hosts = ['8.8.8.8', '1.1.1.1', '208.67.222.222'];
    var online = false;

    for (final host in hosts) {
      try {
        final result = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 5));
        if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
          online = true;
          break;
        }
      } catch (_) {
        continue;
      }
    }

    if (mounted && (online != _isOnline || !_checked)) {
      setState(() {
        _isOnline = online;
        _checked = true;
      });
    }
  }

  /// Refresh near-expiry tokens. On hard auth failure, sign out so
  /// [GoRouter] refreshListenable sends the user to login.
  Future<void> _refreshSessionSilently() async {
    try {
      final ok = await SessionLifecycle.ensureFreshSession();
      if (!ok && SupabaseService.currentSession == null) {
        // Router refresh stream will notice signedOut.
        return;
      }
    } catch (e) {
      if (SessionLifecycle.isAuthFailure(e)) {
        try {
          await SupabaseService.client.auth.signOut();
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBanner = _checked && !_isOnline;

    return Column(
      children: [
        Expanded(child: widget.child),
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          height: showBanner ? 36 : 0,
          child: showBanner
              ? Container(
                  color: AppColors.errorContainer,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          color: Colors.white, size: 14),
                      SizedBox(width: 8),
                      Text(
                        'No internet connection',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
