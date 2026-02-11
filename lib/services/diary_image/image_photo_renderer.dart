import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../interfaces/social_share_service_interface.dart';
import 'image_layout_calculator.dart';

/// 写真描画ユーティリティ
class ImagePhotoRenderer {
  ImagePhotoRenderer._();

  /// 分離レイアウト用：領域に写真を描画
  static Future<void> drawPhotosIntoArea(
    Canvas canvas,
    List<AssetEntity> photos,
    Rect area,
    ShareFormat format,
  ) async {
    final gap =
        ImageLayoutCalculator.photoSpacing * (format.isHD ? format.scale : 1.0);
    if (photos.length == 1) {
      final bytes = await photos.first.originBytes;
      if (bytes != null) {
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final image = frame.image;
        final src = ImageLayoutCalculator.calculateCropRect(
          image.width.toDouble(),
          image.height.toDouble(),
          area.width,
          area.height,
        );
        canvas.drawImageRect(image, src, area, Paint());
        image.dispose();
        codec.dispose();
      }
      return;
    }

    if (photos.length == 2) {
      if (format.isSquare) {
        final cellW = (area.width - gap) / 2;
        final rects = [
          Rect.fromLTWH(area.left, area.top, cellW, area.height),
          Rect.fromLTWH(area.left + cellW + gap, area.top, cellW, area.height),
        ];
        await drawAssetsIntoRects(canvas, photos, rects);
      } else {
        final cellH = (area.height - gap) / 2;
        final rects = [
          Rect.fromLTWH(area.left, area.top, area.width, cellH),
          Rect.fromLTWH(area.left, area.top + cellH + gap, area.width, cellH),
        ];
        await drawAssetsIntoRects(canvas, photos, rects);
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
    await drawAssetsIntoRects(canvas, photos, rects);
  }

  /// 個々のアセットを指定矩形に描画
  static Future<void> drawAssetsIntoRects(
    Canvas canvas,
    List<AssetEntity> assets,
    List<Rect> rects,
  ) async {
    for (int i = 0; i < rects.length && i < assets.length; i++) {
      final bytes = await assets[i].originBytes;
      if (bytes == null) continue;
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final src = ImageLayoutCalculator.calculateCropRect(
        image.width.toDouble(),
        image.height.toDouble(),
        rects[i].width,
        rects[i].height,
      );
      canvas.drawImageRect(image, src, rects[i], Paint());
      image.dispose();
      codec.dispose();
    }
  }
}
