import 'package:flutter/material.dart';
import '../../design_system/app_spacing.dart';
import 'animated_button_base.dart';

/// 小さなボタン
class SmallButton extends StatelessWidget {
  const SmallButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
      foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
      padding: AppSpacing.buttonPaddingSmall,
      height: AppSpacing.buttonHeightSm,
      elevation: AppSpacing.elevationXs,
      child: child,
    );
  }
}
