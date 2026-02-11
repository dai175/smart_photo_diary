import 'package:flutter/material.dart';
import '../../design_system/app_spacing.dart';
import 'animated_button_base.dart';

/// サーフェスボタン（Material Design 3 Surface Tint）
class SurfaceButton extends StatelessWidget {
  const SurfaceButton({
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
      backgroundColor: theme.brightness == Brightness.light
          ? const Color(0xFFE8E8E8) // ライトモードでより濃いグレー
          : theme.colorScheme.surfaceContainerHighest,
      foregroundColor: theme.colorScheme.onSurface,
      elevation: AppSpacing.elevationXs,
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
