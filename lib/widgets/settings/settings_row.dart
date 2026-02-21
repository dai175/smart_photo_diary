import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../ui/animations/micro_interactions.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';

/// Reusable settings row widget used across all settings sections.
class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? semanticLabel;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final row = Container(
      padding: AppSpacing.cardPadding,
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: AppSpacing.iconMd,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // ignore: use_null_aware_elements, build_runner analyzer does not yet support this syntax
          if (trailing != null) trailing!,
          if (trailing == null && onTap != null)
            Icon(
              AppIcons.actionForward,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: AppSpacing.iconSm,
            ),
        ],
      ),
    );

    Widget result = onTap != null
        ? MicroInteractions.bounceOnTap(onTap: onTap!, child: row)
        : row;

    if (semanticLabel != null) {
      result = Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: result,
      );
    }

    return result;
  }
}
