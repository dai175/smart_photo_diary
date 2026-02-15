import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../constants/app_constants.dart';
import '../../core/result/result.dart';
import '../../localization/localization_extensions.dart';

/// パフォーマンス最適化された写真サムネイルウィジェット
class TimelinePhotoThumbnail extends StatelessWidget {
  const TimelinePhotoThumbnail({
    super.key,
    required this.photo,
    required this.future,
    required this.thumbnailSize,
    required this.thumbnailQuality,
    required this.borderRadius,
    required this.strokeWidth,
  });

  final AssetEntity photo;
  final Future<Result<Uint8List>> future;
  final int thumbnailSize;
  final int thumbnailQuality;
  final double borderRadius;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result<Uint8List>>(
      // メモ化されたFutureを使用して再描画時の待機→ローディング表示を防止
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFBDBDBD),
              borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
            ),
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: Color(0xFF9E9E9E),
              ),
            ),
          );
        } else if (snapshot.hasData && snapshot.data!.isSuccess) {
          final thumbnailData = snapshot.data!.value;
          final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
          return RepaintBoundary(
            child: Image.memory(
              thumbnailData,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              // デコードサイズを端末密度に合わせて固定（キャッシュヒット向上）
              cacheWidth: (thumbnailSize * devicePixelRatio).round(),
              cacheHeight: (thumbnailSize * devicePixelRatio).round(),
              gaplessPlayback: true, // 再描画間のちらつきを防止
              isAntiAlias: false,
              filterQuality: FilterQuality.low,
              frameBuilder: (context, child, frame, wasSync) {
                if (wasSync || frame != null) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: AppConstants.shortAnimationDuration,
                  curve: Curves.easeOut,
                  child: child,
                );
              },
            ),
          );
        } else if (!snapshot.hasData) {
          // ローディング中は軽量なプレースホルダーのみ（アニメーションなし）
          // SliverGridの遅延構築でオフスクリーンに大量生成される可能性があるため
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
            ),
          );
        } else {
          // Failure case
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFBDBDBD),
              borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
            ),
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: Color(0xFF9E9E9E),
              ),
            ),
          );
        }
      },
    );
  }
}

/// パフォーマンス最適化された選択インジケーター
class TimelineSelectionIndicator extends StatelessWidget {
  const TimelineSelectionIndicator({
    super.key,
    required this.isSelected,
    required this.isUsed,
    required this.shouldDimPhoto,
    required this.primaryColor,
    required this.indicatorSize,
    required this.iconSize,
    required this.borderWidth,
  });

  final bool isSelected;
  final bool isUsed;
  final bool shouldDimPhoto;
  final Color primaryColor;
  final double indicatorSize;
  final double iconSize;
  final double borderWidth;

  // 選択インジケーターの色とスタイル定数
  static const Color _borderColor = Color(0xB3FFFFFF); // 境界線の色（透明度70%白色）
  static const Color _shadowColor = Color(0x1A000000); // 影の色（透明度10%黒色）
  static const double _shadowBlurRadius = 2.0; // 影のぼかし半径
  static const Offset _shadowOffset = Offset(0, 1); // 影のオフセット

  @override
  Widget build(BuildContext context) {
    if (!isSelected && !isUsed) {
      // 未選択時は完全透明な境界線のみ
      return Container(
        width: indicatorSize,
        height: indicatorSize,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: !shouldDimPhoto
              ? Border.all(color: _borderColor, width: borderWidth)
              : null,
          boxShadow: null, // 未選択時は影なし
        ),
      );
    }

    // 選択済み/使用済み時は白背景とアイコン
    return Container(
      width: indicatorSize,
      height: indicatorSize,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: shouldDimPhoto
            ? null
            : [
                const BoxShadow(
                  color: _shadowColor,
                  blurRadius: _shadowBlurRadius,
                  offset: _shadowOffset,
                ),
              ],
      ),
      child: Icon(
        isUsed ? Icons.done : Icons.check_circle,
        size: iconSize,
        color: isUsed ? Colors.orange : primaryColor,
      ),
    );
  }
}

/// 読み込み中に表示するスケルトンタイル（軽量）
class TimelineSkeletonTile extends StatelessWidget {
  const TimelineSkeletonTile({
    super.key,
    required this.borderRadius,
    required this.strokeWidth,
    required this.indicatorSize,
  });

  final double borderRadius;
  final double strokeWidth;
  final double indicatorSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.timelineLoadingPhotosLabel,
      container: true,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE6E6E6),
          borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        ),
      ),
    );
  }
}

/// パフォーマンス最適化された使用済みラベル
class TimelineUsedLabel extends StatelessWidget {
  const TimelineUsedLabel({
    super.key,
    required this.bottom,
    required this.left,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.borderRadius,
  });

  final double bottom;
  final double left;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;

  // 使用済みラベルの色とスタイル定数
  static const Color _backgroundColor = Color(0xE6FF9800); // 背景色（オレンジ、透明度90%）
  static const double _fontSize = 10.0; // フォントサイズ

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      left: left,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Text(
          context.l10n.photoUsedLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: _fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
