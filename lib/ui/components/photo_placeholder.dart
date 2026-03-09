import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../design_system/app_spacing.dart';

/// 写真サムネイルのプレースホルダーウィジェット
///
/// エラー状態（壊れた画像アイコン）またはローディング状態
/// （プログレスインジケーター）を表示する。
class PhotoPlaceholder extends StatelessWidget {
  const PhotoPlaceholder({super.key, required this.size, this.isError = false});

  /// プレースホルダーのサイズ（幅・高さ）
  final double size;

  /// true: エラー状態, false: ローディング状態
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppSpacing.photoRadius,
      ),
      child: Center(
        child: isError
            ? Icon(
                Icons.broken_image_outlined,
                color: colorScheme.onSurfaceVariant,
              )
            : const CircularProgressIndicator(
                strokeWidth: AppConstants.progressIndicatorStrokeWidth,
              ),
      ),
    );
  }
}
