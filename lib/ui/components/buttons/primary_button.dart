import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../ui/design_system/app_colors.dart';
import 'animated_button_base.dart';
import 'button_content.dart';

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
    return AnimatedButton(
      onPressed: isLoading ? null : onPressed,
      width: width,
      backgroundColor: AppColors.accentDark,
      foregroundColor: Colors.white,
      shadowColor: AppColors.accentDark.withValues(alpha: 0.3),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: AppConstants.progressIndicatorStrokeWidth,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : ButtonContent(text: text, icon: icon),
    );
  }
}
