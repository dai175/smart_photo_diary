import 'package:flutter/material.dart';
import 'animated_button_base.dart';
import 'button_content.dart';

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
      child: ButtonContent(text: text, icon: icon),
    );
  }
}
