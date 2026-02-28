import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../interfaces/logging_service_interface.dart';
import '../interfaces/social_share_service_interface.dart';
import 'image_layout_calculator.dart';

/// シェア画像用JPEG品質（色空間変換の精度を保つため高品質）
const _shareImageQuality = 95;

/// 写真描画ユーティリティ
class ImagePhotoRenderer {
  ImagePhotoRenderer._();

  /// 分離レイアウト用：領域に写真を描画
  static Future<void> drawPhotosIntoArea(
    Canvas canvas,
    List<AssetEntity> photos,
    Rect area,
    ShareFormat format, {
    required ILoggingService logger,
  }) async {
    final gap =
        ImageLayoutCalculator.photoSpacing * (format.isHD ? format.scale : 1.0);
    if (photos.length == 1) {
      await _drawAssetIntoRect(canvas, photos.first, area, logger: logger);
      return;
    }

    if (photos.length == 2) {
      if (format.isSquare) {
        final cellW = (area.width - gap) / 2;
        final rects = [
          Rect.fromLTWH(area.left, area.top, cellW, area.height),
          Rect.fromLTWH(area.left + cellW + gap, area.top, cellW, area.height),
        ];
        await _drawAssetsIntoRects(canvas, photos, rects, logger: logger);
      } else {
        final cellH = (area.height - gap) / 2;
        final rects = [
          Rect.fromLTWH(area.left, area.top, area.width, cellH),
          Rect.fromLTWH(area.left, area.top + cellH + gap, area.width, cellH),
        ];
        await _drawAssetsIntoRects(canvas, photos, rects, logger: logger);
      }
      return;
    }

    // 3枚（上2/下1）
    final topH = (area.height - gap) * 0.55;
    final bottomH = (area.height - gap) - topH;
    final topCellW = (area.width - gap) / 2;
    final rects = [
      Rect.fromLTWH(area.left, area.top, topCellW, topH),
      Rect.fromLTWH(area.left + topCellW + gap, area.top, topCellW, topH),
      Rect.fromLTWH(area.left, area.top + topH + gap, area.width, bottomH),
    ];
    await _drawAssetsIntoRects(canvas, photos, rects, logger: logger);
  }

  /// プラットフォームネイティブのJPEG変換で画像バイト列を取得する。
  ///
  /// [originBytes] ではなく [thumbnailDataWithOption] を使うことで、
  /// iOS の Display P3 → sRGB 色空間変換がプラットフォーム側で正しく行われる。
  static Future<Uint8List?> _getImageBytes(
    AssetEntity asset,
    Rect targetRect,
  ) async {
    // 後段で calculateCropRect によるトリミングを行うため、
    // 幅・高さそれぞれ描画領域以上のピクセル数を確保する。
    final w = targetRect.width.ceil();
    final h = targetRect.height.ceil();
    final size = ThumbnailSize(w, h);
    final option = Platform.isIOS || Platform.isMacOS
        ? ThumbnailOption.ios(
            size: size,
            format: ThumbnailFormat.jpeg,
            quality: _shareImageQuality,
            // fit だと短辺が不足するため fill で両辺を満たす
            resizeContentMode: ResizeContentMode.fill,
          )
        : ThumbnailOption(
            size: size,
            format: ThumbnailFormat.jpeg,
            quality: _shareImageQuality,
          );
    return asset.thumbnailDataWithOption(option);
  }

  static final _drawPaint = Paint()..filterQuality = FilterQuality.high;

  /// 単一アセットを指定矩形に描画
  static Future<void> _drawAssetIntoRect(
    Canvas canvas,
    AssetEntity asset,
    Rect rect, {
    required ILoggingService logger,
  }) async {
    final bytes = await _getImageBytes(asset, rect);
    if (bytes == null) {
      logger.warning(
        'Failed to obtain thumbnail bytes for asset',
        context: 'ImagePhotoRenderer._drawAssetIntoRect',
        data: 'asset_id: ${asset.id}',
      );
      return;
    }
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        final src = ImageLayoutCalculator.calculateCropRect(
          image.width.toDouble(),
          image.height.toDouble(),
          rect.width,
          rect.height,
        );
        canvas.drawImageRect(image, src, rect, _drawPaint);
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  /// 個々のアセットを指定矩形に描画
  static Future<void> _drawAssetsIntoRects(
    Canvas canvas,
    List<AssetEntity> assets,
    List<Rect> rects, {
    required ILoggingService logger,
  }) async {
    for (int i = 0; i < rects.length && i < assets.length; i++) {
      await _drawAssetIntoRect(canvas, assets[i], rects[i], logger: logger);
    }
  }
}
