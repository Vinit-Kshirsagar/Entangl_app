import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/auth_errors.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/gradient_text.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name     = TextEditingController();
  final _username = TextEditingController();
  final _email    = TextEditingController();
  final _password = TextEditingController();
  final _formKey  = GlobalKey<FormState>();
  bool _obscure   = true;

  @override
  void dispose() {
    _name.dispose(); _username.dispose();
    _email.dispose(); _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref.read(authNotifierProvider.notifier).signUp(
          email:    _email.text.trim(),
          password: _password.text,
          fullName: _name.text.trim(),
          username: _username.text.trim().toLowerCase(),
        );
    if (!mounted) return;
    final authState = ref.read(authNotifierProvider);
    if (authState is AsyncError) {
      _showError(humaniseAuthError(authState.error!));
    } else {
      context.go(AppRoutes.home);
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
    final isLoading = ref.watch(authNotifierProvider) is AsyncLoading;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(children: [
        Positioned(
          bottom: -100, left: -100,
          child: Container(
            width: 350, height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gradientEnd.withOpacity(0.05),
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
                  const SizedBox(height: 16),
                  GradientText('Create\nAccount',
                      style: AppTextStyles.heroTitle),
                  const SizedBox(height: 8),
                  Text('Join Entangl today',
                      style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.onSurfaceVariantDark)),
                  const SizedBox(height: 40),

                  AuthField(
                    label: 'Full name',
                    controller: _name,
                    hint: 'Your name',
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 20),

                  AuthField(
                    label: 'Username',
                    controller: _username,
                    hint: 'e.g. janedoe',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Username is required';
                      }
                      if (v.trim().length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                        return 'Only letters, numbers and underscores';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  AuthField(
                    label: 'Email',
                    controller: _email,
                    hint: 'you@example.com',
                    type: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!v.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  AuthField(
                    label: 'Password',
                    controller: _password,
                    hint: 'Min 6 characters',
                    obscure: _obscure,
                    onToggleObscure: () =>
                        setState(() => _obscure = !_obscure),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Password is required';
                      }
                      if (v.length < 6) {
                        return 'At least 6 characters required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 36),

                  GradientButton(
                    label: 'Create Account',
                    onTap: isLoading ? null : _submit,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ',
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.onSurfaceVariantDark)),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.login),
                        child: Text('Sign in',
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
