import 'package:flutter/material.dart';
import '../../design_system/app_spacing.dart';
import '../../component_constants.dart';
import 'animated_button_base.dart';
import 'button_content.dart';

/// セカンダリーボタン
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
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
      backgroundColor: Colors.transparent,
      foregroundColor: theme.colorScheme.primary,
      border: Border.fromBorderSide(
        BorderSide(
          color: theme.colorScheme.primary,
          width: ButtonConstants.borderWidth,
        ),
      ),
      elevation: 0,
      child: ButtonContent(
        text: text,
        icon: icon,
        iconSpacing: AppSpacing.xs,
        maxLines: null,
      ),
    );
  }
}
