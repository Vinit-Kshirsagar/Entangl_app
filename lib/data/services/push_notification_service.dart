import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/notifications/models/notification_route_payload.dart';
import 'device_token_lifecycle.dart';
import 'supabase_service.dart';

typedef NotificationOpenHandler = void Function(NotificationRoutePayload payload);

/// Registers this device with FCM and stores the token in Supabase
/// `device_tokens` (and optionally `profiles.fcm_token`).
///
/// Android-first: iOS / web / desktop no-op until APNs is configured.
/// Supabase remains the source of truth for notification *content*;
/// this service only enables FCM *delivery* + open events.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const _prefsPushKey = 'notif_push';
  static const _androidChannelId = 'entangl_push';
  static const _androidChannelName = 'Entangl notifications';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  bool _initialized = false;
  bool _openHandlersBound = false;
  String? _currentToken;

  NotificationOpenHandler? _onOpen;
  NotificationRoutePayload? _pendingOpen;

  /// Whether this platform should register for FCM device tokens.
  bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  String? get currentToken => _currentToken;

  /// Wire navigation after [GoRouter] exists. Flushes any cold-start payload.
  void attachOpenHandler(NotificationOpenHandler handler) {
    _onOpen = handler;
    final pending = _pendingOpen;
    if (pending != null) {
      _pendingOpen = null;
      // Defer so the first frame / router can settle.
      scheduleMicrotask(() => handler(pending));
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!isSupported) {
      _log('skip init (platform not supported for push)');
      return;
    }

    await _initLocalNotifications();

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    _log('permission: ${settings.authorizationStatus}');

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) async {
      _log('token refreshed');
      if (await _isPushEnabledInPrefs()) {
        await _replaceAndUpsertToken(token);
      } else {
        _currentToken = token;
      }
    });

    _foregroundSub?.cancel();
    _foregroundSub =
        FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    await bindOpenHandlers();

    if (SupabaseService.currentUserId != null &&
        await _isPushEnabledInPrefs()) {
      await registerToken();
    }
  }

  /// Background / terminated / local-notification open paths.
  Future<void> bindOpenHandlers() async {
    if (!isSupported || _openHandlersBound) return;
    _openHandlersBound = true;

    _openedSub?.cancel();
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _emitOpen(NotificationRoutePayload.fromRemoteData(
        Map<String, dynamic>.from(message.data),
      ));
    });

    try {
      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        _emitOpen(NotificationRoutePayload.fromRemoteData(
          Map<String, dynamic>.from(initial.data),
        ));
      }
    } catch (e) {
      _log('getInitialMessage failed: $e');
    }
  }

  Future<void> registerToken() async {
    if (!isSupported) {
      _log('registerToken skipped (unsupported platform)');
      return;
    }

    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      _log('registerToken skipped (no session)');
      return;
    }

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _log('registerToken aborted (permission denied)');
        return;
      }

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        _log('registerToken failed (null token)');
        return;
      }

      await _replaceAndUpsertToken(token);
      _log(
          'token registered (${token.substring(0, token.length.clamp(0, 12))}…)');
    } catch (e, st) {
      _log('registerToken error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  /// Upsert new token; remove previous install token if it rotated.
  Future<void> _replaceAndUpsertToken(String token) async {
    final previous = _currentToken;
    if (DeviceTokenLifecycle.shouldReplacePrevious(
      previousToken: previous,
      newToken: token,
    )) {
      try {
        await SupabaseService.client
            .from('device_tokens')
            .delete()
            .eq('token', previous!);
        _log('removed previous token row');
      } catch (e) {
        _log('previous token delete skipped: $e');
      }
    }
    _currentToken = token;
    await _upsertToken(token);
  }

  Future<void> unregisterToken() async {
    if (!isSupported) return;

    final userId = SupabaseService.currentUserId;
    final token = _currentToken ?? await _messaging.getToken();

    try {
      if (userId != null && token != null && token.isNotEmpty) {
        await SupabaseService.client
            .from('device_tokens')
            .delete()
            .eq('user_id', userId)
            .eq('token', token);
        _log('token row deleted');
      }

      if (userId != null && token != null) {
        try {
          final row = await SupabaseService.client
              .from('profiles')
              .select('fcm_token')
              .eq('id', userId)
              .maybeSingle();
          if (row != null && row['fcm_token'] == token) {
            await SupabaseService.client
                .from('profiles')
                .update({'fcm_token': null}).eq('id', userId);
          }
        } catch (e) {
          _log('profiles.fcm_token clear skipped: $e');
        }
      }

      try {
        await _messaging.deleteToken();
      } catch (e) {
        _log('deleteToken skipped: $e');
      }
      _currentToken = null;
    } catch (e, st) {
      _log('unregisterToken error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> syncWithPreferences() async {
    if (!isSupported) return;
    if (SupabaseService.currentUserId == null) return;

    if (await _isPushEnabledInPrefs()) {
      await registerToken();
    }
  }

  Future<void> _upsertToken(String token) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    final now = DateTime.now().toUtc().toIso8601String();

    await SupabaseService.client.from('device_tokens').upsert(
      {
        'user_id': userId,
        'token': token,
        'platform': 'android',
        'updated_at': now,
      },
      onConflict: 'token',
    );

    try {
      await SupabaseService.client
          .from('profiles')
          .update({'fcm_token': token}).eq('id', userId);
    } catch (e) {
      _log('profiles.fcm_token update skipped: $e');
    }
  }

  Future<bool> _isPushEnabledInPrefs() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_prefsPushKey) ?? true;
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationResponse,
    );

    const channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: 'Likes, follows, comments, and other activity',
      importance: Importance.high,
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onLocalNotificationResponse(NotificationResponse response) {
    final payload = NotificationRoutePayload.fromPayloadString(response.payload);
    _emitOpen(payload);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String?;
    final body = notification?.body ?? message.data['body'] as String?;
    if (title == null && body == null) return;

    final routePayload = NotificationRoutePayload.fromRemoteData(
      Map<String, dynamic>.from(message.data),
    );

    await _local.show(
      id: notification?.hashCode ?? message.hashCode,
      title: title ?? 'Entangl',
      body: body ?? '',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: 'Likes, follows, comments, and other activity',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: routePayload.toPayloadString(),
    );
  }

  void _emitOpen(NotificationRoutePayload payload) {
    _log('open notification type=${payload.type} post=${payload.postId}');
    final handler = _onOpen;
    if (handler == null) {
      _pendingOpen = payload;
      return;
    }
    handler(payload);
  }

  void _log(String msg) {
    debugPrint('[FCM] $msg');
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] background message: ${message.messageId}');
}
