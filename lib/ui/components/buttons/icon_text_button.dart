import 'package:flutter/material.dart';
import '../../design_system/app_spacing.dart';
import 'animated_button_base.dart';

/// アイコンとテキストボタン（横並び）
class IconTextButton extends StatelessWidget {
  const IconTextButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.text,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.isCompact = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String text;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedButton(
      onPressed: onPressed,
      width: width,
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
      foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
      padding: isCompact
          ? AppSpacing.buttonPaddingSmall
          : AppSpacing.buttonPadding,
      height: isCompact ? AppSpacing.buttonHeightSm : AppSpacing.buttonHeightMd,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isCompact ? AppSpacing.iconXs : AppSpacing.iconSm),
          SizedBox(width: isCompact ? AppSpacing.xs : AppSpacing.sm),
          Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
