import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'gradient_text.dart';

class EntanglAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSettingsTap;
  final Widget? trailing;
  final Widget? leading;
  final String? title;

  const EntanglAppBar({
    super.key,
    this.onSettingsTap,
    this.trailing,
    this.leading,
    this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: preferredSize.height + MediaQuery.of(context).padding.top,
          decoration: BoxDecoration(
            color: AppColors.backgroundDark.withOpacity(0.85),
            border: Border(
              bottom: BorderSide(
                color: AppColors.outlineVariant.withOpacity(0.08),
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 20,
            right: 8,
          ),
          child: Row(
            children: [
              if (leading != null) leading!,
              if (title != null)
                Text(title!,
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.onSurfaceDark,
                      fontSize: 22,
                    ))
              else
                GradientText(
                  'Entangl',
                  style: AppTextStyles.brandName.copyWith(fontSize: 24),
                ),
              const Spacer(),
              if (trailing != null)
                trailing!
              else if (onSettingsTap != null)
                IconButton(
                  onPressed: onSettingsTap,
                  icon: const Icon(Icons.settings_outlined,
                      color: AppColors.primary, size: 22),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
