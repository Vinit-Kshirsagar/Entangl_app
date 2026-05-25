import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/router/app_router.dart';
import '../../../data/repositories/users_repository.dart';
import '../../../data/repositories/auth_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 1800), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final hasSession =
        Supabase.instance.client.auth.currentSession != null;

    if (!hasSession) {
      context.go(AppRoutes.login);
      return;
    }

    // Check profile status for pending/rejected users
    try {
      final profile = await UsersRepository().getOwnProfile();
      if (!mounted) return;

      if (profile == null) {
        context.go(AppRoutes.login);
        return;
      }

      // Handle approved email change — auto-process it
      if (profile.status.startsWith('email_change_approved:')) {
        final newEmail =
            profile.status.replaceFirst('email_change_approved:', '');
        try {
          await AuthRepository().updateEmail(newEmail);
          await UsersRepository().processApprovedEmailChange(newEmail);
        } catch (_) {
          // Continue even if processing fails
        }
      }

      if (profile.isApproved) {
        context.go(AppRoutes.home);
      } else {
        context.go(AppRoutes.approvalStatus);
      }
    } catch (_) {
      if (mounted) context.go(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Image.asset(
              'assets/icon.png',
              width:  180,
              height: 180,
            ),
          ),
        ),
      ),
    );
  }
}
