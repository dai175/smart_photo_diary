import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../design_system/app_spacing.dart';
import 'photo_thumbnail_widget.dart';

/// 写真ギャラリーウィジェット
///
/// 1枚: アスペクト比に応じた表示（BoxFit.contain）
/// 複数: 正方形サムネイルで水平スクロール（BoxFit.cover）
class PhotoGallery extends StatelessWidget {
  const PhotoGallery({
    super.key,
    required this.assets,
    this.onPhotoTap,
    this.multiplePhotoSize = 200,
    this.heroTagPrefix,
  });

  final List<AssetEntity> assets;

  /// 写真タップ時のコールバック
  final void Function(
    BuildContext context,
    AssetEntity asset,
    Uint8List imageData,
  )?
  onPhotoTap;

  /// 複数写真表示時の正方形サイズ
  final double multiplePhotoSize;

  /// Hero アニメーション用タグのプレフィックス（指定時に各サムネイルを Hero でラップ）
  final String? heroTagPrefix;

  /// 写真の表示高さを計算する（幅に応じたアスペクト比計算）
  double _calcPhotoHeight(AssetEntity asset, double displayWidth) {
    if (asset.width == 0 || asset.height == 0) return displayWidth;
    return displayWidth * asset.height / asset.width;
  }

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) return const SizedBox.shrink();

    if (assets.length == 1) {
      return _buildSinglePhoto(context);
    }
    return _buildMultiplePhotos(context);
  }

  /// Hero タグを生成（プレフィックスが指定されている場合のみ）
  String? _heroTag(AssetEntity asset) {
    if (heroTagPrefix == null) return null;
    return '$heroTagPrefix-${asset.id}';
  }

  /// 写真1枚: アスペクト比に応じた表示
  Widget _buildSinglePhoto(BuildContext context) {
    final asset = assets.first;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final height = _calcPhotoHeight(asset, cardWidth).clamp(120.0, 240.0);
        final actualWidth = (asset.width > 0 && asset.height > 0)
            ? math.min(cardWidth, height * asset.width / asset.height)
            : cardWidth;
        return Center(
          child: SizedBox(
            height: height,
            child: PhotoThumbnailWidget(
              asset: asset,
              onTap: onPhotoTap,
              size: actualWidth,
              fit: BoxFit.contain,
              heroTag: _heroTag(asset),
            ),
          ),
        );
      },
    );
  }

  /// 複数写真: 正方形サムネイルで水平スクロール
  Widget _buildMultiplePhotos(BuildContext context) {
    return SizedBox(
      height: multiplePhotoSize,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: assets.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index == assets.length - 1 ? 0 : AppSpacing.md,
            ),
            child: PhotoThumbnailWidget(
              asset: assets[index],
              onTap: onPhotoTap,
              size: multiplePhotoSize,
              fit: BoxFit.cover,
              heroTag: _heroTag(assets[index]),
            ),
          );
        },
      ),
    );
  }
}
