import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Reusable settings card container — pure layout widget.
class SettingsSection extends StatelessWidget {
  final String       label;
  final List<Widget> rows;
  final Color?       labelColor;

  const SettingsSection({
    super.key,
    required this.label,
    required this.rows,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
                color: labelColor ?? AppColors.onSurfaceVariantDark,
                letterSpacing: 1.3)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }
}

class SettingsToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggleRow({
    super.key, required this.icon, required this.label,
    required this.subtitle, required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(label,
            style: AppTextStyles.labelLarge
                .copyWith(color: AppColors.onSurfaceDark)),
        subtitle: Text(subtitle,
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.onSurfaceVariantDark)),
        trailing: Switch(value: value, onChanged: onChanged),
      );
}

class SettingsSubToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSubToggle({
    super.key, required this.label,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 56, right: 16),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariantDark)),
          ),
          Switch(value: value, onChanged: onChanged),
        ]),
      );
}

class SettingsChevronRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const SettingsChevronRow({
    super.key, required this.icon,
    required this.label, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(label,
            style: AppTextStyles.labelLarge
                .copyWith(color: AppColors.onSurfaceDark)),
        trailing: const Icon(Icons.chevron_right,
            color: AppColors.outlineVariant),
        onTap: onTap,
      );
}

class SettingsDangerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool muted;

  const SettingsDangerRow({
    super.key, required this.icon,
    required this.label, required this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon,
            color: muted
                ? AppColors.error.withOpacity(0.5)
                : AppColors.error,
            size: 22),
        title: Text(label,
            style: AppTextStyles.labelLarge.copyWith(
                color: muted
                    ? AppColors.error.withOpacity(0.5)
                    : AppColors.error)),
        onTap: onTap,
      );
}
