import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/auth_errors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/users_repository.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/gradient_text.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email    = TextEditingController();
  final _password = TextEditingController();
  final _formKey  = GlobalKey<FormState>();
  bool _obscure   = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref.read(authNotifierProvider.notifier).signIn(
          email:    _email.text.trim(),
          password: _password.text,
        );
    if (!mounted) return;
    final authState = ref.read(authNotifierProvider);
    if (authState is AsyncError) {
      _showError(humaniseAuthError(authState.error!));
    } else {
      // Check profile status before navigating
      try {
        final repo = UsersRepository();
        final profile = await repo.getOwnProfile();
        if (!mounted) return;
        if (profile != null && !profile.isApproved) {
          context.go(AppRoutes.approvalStatus);
          return;
        }
        // Auto-process approved email change
        if (profile != null &&
            profile.status.startsWith('email_change_approved:')) {
          final newEmail =
              profile.status.replaceFirst('email_change_approved:', '');
          try {
            await AuthRepository().updateEmail(newEmail);
            await repo.processApprovedEmailChange(newEmail);
          } catch (_) {}
        }
      } catch (_) {}
      if (mounted) context.go(AppRoutes.home);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: const TextStyle(color: Colors.white))),
        ]),
        backgroundColor: AppColors.errorContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        ref.watch(authNotifierProvider) is AsyncLoading;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(children: [
        Positioned(
          top: -80, right: -80,
          child: Container(
            width: 300, height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gradientStart.withOpacity(0.05),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: 28, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  GradientText('Welcome\nback',
                      style: AppTextStyles.heroTitle),
                  const SizedBox(height: 8),
                  Text('Sign in to continue',
                      style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.onSurfaceVariantDark)),
                  const SizedBox(height: 48),

                  AuthField(
                    label: 'Email',
                    controller: _email,
                    hint: 'you@example.com',
                    type: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  AuthField(
                    label: 'Password',
                    controller: _password,
                    hint: '••••••••',
                    obscure: _obscure,
                    onToggleObscure: () =>
                        setState(() => _obscure = !_obscure),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 36),

                  GradientButton(
                    label: 'Sign In',
                    onTap: isLoading ? null : _submit,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: GestureDetector(
                      onTap: () => context.push(AppRoutes.forgotPassword),
                      child: Text('Forgot Password?',
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ",
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.onSurfaceVariantDark)),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.register),
                        child: Text('Sign up',
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
