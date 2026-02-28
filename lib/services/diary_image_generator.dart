import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../models/diary_entry.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../services/interfaces/logging_service_interface.dart';
import 'interfaces/social_share_service_interface.dart';
import 'diary_image/image_layout_calculator.dart';
import 'diary_image/image_photo_renderer.dart';
import 'diary_image/image_text_renderer.dart';

/// 日記画像生成専用クラス
///
/// Canvas描画システムを使用して、日記の内容と写真を組み合わせた
/// 美しいシェア用画像を生成します。
class DiaryImageGenerator {
  final ILoggingService _logger;

  DiaryImageGenerator({required ILoggingService logger}) : _logger = logger;

  /// 共有用画像を生成
  Future<Result<File>> generateImage({
    required DiaryEntry diary,
    required ShareFormat format,
    List<AssetEntity>? photos,
  }) async {
    try {
      _logger.info(
        'Starting image generation: ${format.name}',
        context: 'DiaryImageGenerator.generateImage',
        data: 'diary_id: ${diary.id}',
      );

      // 一時ディレクトリを取得
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'diary_${diary.id}_${format.name}_$timestamp.png';
      final outputFile = File('${tempDir.path}/$fileName');

      // キャンバスサイズを設定（スケール対応）
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(
          0,
          0,
          format.actualWidth.toDouble(),
          format.actualHeight.toDouble(),
        ),
      );

      // 画像を描画（分離レイアウト既定）
      await _drawCompositeImageSplit(canvas, diary, format, photos);

      // Pictureからイメージに変換（スケール対応）
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        format.actualWidth,
        format.actualHeight,
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        return const Failure<File>(
          ImageGenerationException('Failed to convert image data'),
        );
      }

      // ファイルに保存
      await outputFile.writeAsBytes(byteData.buffer.asUint8List());

      _logger.info(
        'Image generation completed',
        context: 'DiaryImageGenerator.generateImage',
        data:
            'file_path: ${outputFile.path}, size: ${(await outputFile.length())} bytes',
      );

      return Success<File>(outputFile);
    } catch (e) {
      _logger.error(
        'Image generation error',
        context: 'DiaryImageGenerator.generateImage',
        error: e,
      );
      return Failure<File>(
        ImageGenerationException('Failed to generate image', originalError: e),
      );
    }
  }

  /// 新: 分離レイアウト（写真とテキストを重ねない）
  Future<void> _drawCompositeImageSplit(
    Canvas canvas,
    DiaryEntry diary,
    ShareFormat format,
    List<AssetEntity>? photos,
  ) async {
    // ベース背景（ごく薄いグラデ）
    final w = format.actualWidth.toDouble();
    final h = format.actualHeight.toDouble();
    final baseBg = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(w, h),
      [const Color(0xFF0E0F12), const Color(0xFF151821)],
      [0.0, 1.0],
    );
    final bgPaint = Paint()..shader = baseBg;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // レイアウト領域を決定
    final split = ImageLayoutCalculator.getSplitLayout(format);

    // 写真領域に描画（なければスキップ）
    if (photos != null && photos.isNotEmpty) {
      await ImagePhotoRenderer.drawPhotosIntoArea(
        canvas,
        photos,
        split.photoRect,
        format,
      );
    } else {
      // 写真が無い場合、写真領域も背景色で塗りつぶし（少し明るめ）
      final photoFill = Paint()..color = const Color(0xFF232632);
      canvas.drawRect(split.photoRect, photoFill);
    }

    // テキストパネル（ソリッド）
    ImageTextRenderer.fillTextPanel(canvas, split.textRect, format);

    // テキスト描画
    ImageTextRenderer.drawTextElementsInArea(
      canvas,
      diary,
      format,
      split.textRect,
    );

    // 最小ブランドはテキストパネル右下に
    ImageTextRenderer.drawBrandingInArea(canvas, format, split.textRect);
  }
}
