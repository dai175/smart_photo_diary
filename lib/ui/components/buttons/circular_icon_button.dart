import 'package:flutter/material.dart';
import 'animated_button_base.dart';

/// アイコンボタン（丸型）
class CircularIconButton extends StatelessWidget {
  const CircularIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 48.0,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
      foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
      borderRadius: BorderRadius.circular(size / 2),
      width: size,
      height: size,
      padding: EdgeInsets.zero,
      child: Icon(icon, size: size * 0.5),
    );
  }
}
