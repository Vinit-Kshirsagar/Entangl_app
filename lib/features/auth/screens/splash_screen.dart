import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/session_lifecycle.dart';
import '../../../data/services/push_notification_service.dart';
import '../../../shared/widgets/mascot_widgets.dart';
import '../utils/auth_landing.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;

    // Refresh near-expiry tokens before deciding destination.
    final sessionOk = await SessionLifecycle.ensureFreshSession();
    if (!mounted) return;

    if (!sessionOk) {
      context.go(AppRoutes.login);
      return;
    }

    // Cold-start with session: keep device_tokens fresh (Android).
    await PushNotificationService.instance.syncWithPreferences();
    if (!mounted) return;

    final dest = await landingRouteAfterAuth();
    if (mounted) context.go(dest);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Subtle ambient glow in the center
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandGradient.colors[0].withOpacity(0.08),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandGradient.colors[1].withOpacity(0.06),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mascots floating side-by-side (representing the connection / high-five)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Animate(
                      child: const GhostMascot(
                        expression: GhostExpression.floating,
                        size: 88,
                      ),
                    )
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1.0, 1.0),
                          duration: 800.ms,
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(duration: 400.ms),
                    const SizedBox(width: 16),
                    Animate(
                      child: const FrogMascot(
                        expression: FrogExpression.happy,
                        size: 88,
                      ),
                    )
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1.0, 1.0),
                          duration: 800.ms,
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(duration: 400.ms),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'entangl',
                  style: AppTextStyles.brandName,
                )
                    .animate(delay: 800.ms)
                    .fadeIn(duration: 600.ms)
                    .moveY(begin: 10, end: 0, duration: 400.ms, curve: Curves.easeOut),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
