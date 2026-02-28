import 'package:flutter/material.dart';
import '../../design_system/app_spacing.dart';
import 'animated_button_base.dart';
import 'button_content.dart';

/// テキストのみボタン
class TextOnlyButton extends StatelessWidget {
  const TextOnlyButton({
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
      elevation: 0,
      padding: AppSpacing.buttonPaddingSmall,
      enableScaleAnimation: false, // テキストボタンはスケールアニメーションなし
      child: ButtonContent(text: text, icon: icon, iconSpacing: AppSpacing.xs),
    );
  }
}
