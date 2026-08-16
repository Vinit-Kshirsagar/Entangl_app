import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/theme_provider.dart';
import 'core/utils/app_lifecycle.dart';
import 'core/secrets.dart';
import 'data/services/push_notification_service.dart';
import 'features/notifications/utils/notification_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Background FCM isolate (Android). Must be registered before runApp.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Supabase
  await Supabase.initialize(
    url: Secrets.supabaseUrl,
    anonKey: Secrets.supabaseAnonKey,
  );

  // FCM permission + token → device_tokens (Android only; no-op elsewhere).
  await PushNotificationService.instance.initialize();

  runApp(
    const ProviderScope(
      child: EntanglApp(),
    ),
  );
}

class EntanglApp extends ConsumerStatefulWidget {
  const EntanglApp({super.key});

  @override
  ConsumerState<EntanglApp> createState() => _EntanglAppState();
}

class _EntanglAppState extends ConsumerState<EntanglApp> {
  var _openHandlerAttached = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    if (!_openHandlerAttached) {
      _openHandlerAttached = true;
      // After first frame so GoRouter is ready for cold-start taps.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PushNotificationService.instance.attachOpenHandler((payload) {
          NotificationRouter.navigate(router, payload);
        });
      });
    }

    return MaterialApp.router(
      title: 'Entangl',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => AppLifecycleWrapper(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}