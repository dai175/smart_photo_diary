import 'package:flutter/material.dart';
import '../../design_system/app_spacing.dart';
import 'animated_button_base.dart';

/// アクセントボタン
class AccentButton extends StatelessWidget {
  const AccentButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.width,
  });

  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedButton(
      onPressed: onPressed,
      width: width,
      backgroundColor: theme.colorScheme.secondary,
      foregroundColor: theme.colorScheme.onSecondary,
      shadowColor: theme.colorScheme.secondary.withValues(alpha: 0.3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSpacing.iconSm),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Text(text, overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
        ],
      ),
    );
  }
}
