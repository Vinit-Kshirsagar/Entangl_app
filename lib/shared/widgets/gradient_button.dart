import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

// The full-width pill gradient CTA button used throughout the app
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final double height;
  final Widget? leadingIcon;
  final Widget? trailingIcon;

  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.height = 60,
    this.leadingIcon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        decoration: BoxDecoration(
          gradient: onTap == null || isLoading
              ? null
              : AppColors.primaryGradient,
          color: onTap == null || isLoading
              ? AppColors.surfaceContainerHigh
              : null,
          borderRadius: BorderRadius.circular(100),
          boxShadow: onTap != null && !isLoading
              ? [
                  BoxShadow(
                    color: AppColors.violetGlowStrong,
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              leadingIcon!,
              const SizedBox(width: 8),
            ],
            if (isLoading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            else
              Text(
                label,
                style: AppTextStyles.buttonLarge.copyWith(
                  color: onTap != null
                      ? Colors.white
                      : AppColors.onSurfaceVariantDark,
                ),
              ),
            if (trailingIcon != null && !isLoading) ...[
              const SizedBox(width: 8),
              trailingIcon!,
            ],
          ],
        ),
      ),
    );
  }
}
