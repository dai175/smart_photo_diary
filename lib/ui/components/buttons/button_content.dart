import 'package:flutter/material.dart';
import '../../design_system/app_spacing.dart';

/// ボタン内のアイコン＋テキストの共通レイアウト
class ButtonContent extends StatelessWidget {
  const ButtonContent({
    super.key,
    required this.text,
    this.icon,
    this.iconSpacing = AppSpacing.sm,
    this.maxLines = 1,
  });

  final String text;
  final IconData? icon;
  final double iconSpacing;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppSpacing.iconSm),
          SizedBox(width: iconSpacing),
        ],
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: maxLines,
          ),
        ),
      ],
    );
  }
}
