import 'package:flutter/material.dart';
import '../../constants/app_icons.dart';
import '../../ui/animations/micro_interactions.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? semanticLabel;
  final bool showDivider;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.semanticLabel,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final row = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isDark ? AppColors.accentLight : AppColors.accentMuted,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // ignore: use_null_aware_elements, build_runner analyzer does not yet support this syntax
              if (trailing != null) trailing!,
              if (trailing == null && onTap != null)
                Icon(
                  AppIcons.actionForward,
                  color: cs.onSurfaceVariant,
                  size: AppSpacing.iconSm,
                ),
            ],
          ),
        ),
        if (showDivider)
          Container(
            height: 0.5,
            margin: const EdgeInsets.only(left: 66),
            color: cs.outlineVariant,
          ),
      ],
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
