import 'package:flutter/material.dart';
import '../../design_system/app_spacing.dart';
import 'animated_button_base.dart';

/// プライマリーボタン
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.width,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final double? width;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedButton(
      onPressed: isLoading ? null : onPressed,
      width: width,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.onPrimary,
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppSpacing.iconSm),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
    );
  }
}
