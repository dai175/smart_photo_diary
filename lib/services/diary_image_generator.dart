import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../models/diary_entry.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../services/logging_service.dart';
import '../core/service_locator.dart';
import 'interfaces/social_share_service_interface.dart';

/// 日記画像生成専用クラス
///
/// Canvas描画システムを使用して、日記の内容と写真を組み合わせた
/// 美しいシェア用画像を生成します。
class DiaryImageGenerator {
  // シングルトンパターン
  static DiaryImageGenerator? _instance;

  DiaryImageGenerator._();

  static DiaryImageGenerator getInstance() {
    _instance ??= DiaryImageGenerator._();
    return _instance!;
  }

  /// ログサービスを取得
  LoggingService get _logger => serviceLocator.get<LoggingService>();

  /// 共有用画像を生成
  Future<Result<File>> generateImage({
    required DiaryEntry diary,
    required ShareFormat format,
    List<AssetEntity>? photos,
  }) async {
    try {
      _logger.info(
        '画像生成開始: ${format.displayName}',
        context: 'DiaryImageGenerator.generateImage',
        data: 'diary_id: ${diary.id}',
      );

      // 一時ディレクトリを取得
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'diary_${diary.id}_${format.name}_$timestamp.png';
      final outputFile = File('${tempDir.path}/$fileName');

      // キャンバスサイズを設定
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, format.width.toDouble(), format.height.toDouble()),
      );

      // 画像を描画
      await _drawCompositeImage(canvas, diary, format, photos);

      // Pictureからイメージに変換
      final picture = recorder.endRecording();
      final image = await picture.toImage(format.width, format.height);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        return const Failure<File>(ImageGenerationException('画像データの変換に失敗しました'));
      }

      // ファイルに保存
      await outputFile.writeAsBytes(byteData.buffer.asUint8List());

      _logger.info(
        '画像生成完了',
        context: 'DiaryImageGenerator.generateImage',
        data:
            'file_path: ${outputFile.path}, size: ${(await outputFile.length())} bytes',
      );

      return Success<File>(outputFile);
    } catch (e) {
      _logger.error(
        '画像生成エラー',
        context: 'DiaryImageGenerator.generateImage',
        error: e,
      );
      return Failure<File>(
        ImageGenerationException('画像の生成に失敗しました', originalError: e),
      );
    }
  }

  /// 複合画像をキャンバスに描画
  Future<void> _drawCompositeImage(
    Canvas canvas,
    DiaryEntry diary,
    ShareFormat format,
    List<AssetEntity>? photos,
  ) async {
    // 1. 背景描画
    await _drawBackground(canvas, format, photos);

    // 2. コンテンツオーバーレイ描画
    _drawContentOverlay(canvas, format);

    // 3. テキストコンテンツ描画
    await _drawTextElements(canvas, diary, format);

    // 4. ブランディング要素描画
    _drawBrandingElements(canvas, format);

    // 5. 装飾要素描画
    _drawDecorationElements(canvas, format);
  }

  /// 背景を描画（写真または単色）
  Future<void> _drawBackground(
    Canvas canvas,
    ShareFormat format,
    List<AssetEntity>? photos,
  ) async {
    // まず単色背景を描画
    final backgroundGradient = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(format.width.toDouble(), format.height.toDouble()),
      [
        const Color(0xFF667eea), // 美しいグラデーション
        const Color(0xFF764ba2),
      ],
    );

    final backgroundPaint = Paint()..shader = backgroundGradient;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, format.width.toDouble(), format.height.toDouble()),
      backgroundPaint,
    );

    // 写真がある場合は背景として描画
    if (photos != null && photos.isNotEmpty) {
      await _drawPhotoBackground(canvas, photos, format);
    }
  }

  /// 写真背景を描画
  Future<void> _drawPhotoBackground(
    Canvas canvas,
    List<AssetEntity> photos,
    ShareFormat format,
  ) async {
    try {
      // メイン写真を背景として使用
      final mainPhoto = photos.first;
      final imageData = await mainPhoto.originBytes;

      if (imageData != null) {
        final codec = await ui.instantiateImageCodec(imageData);
        final frame = await codec.getNextFrame();
        final image = frame.image;

        // 画像を適切にスケール・トリミング
        final imageRect = _calculateImageRect(
          image.width.toDouble(),
          image.height.toDouble(),
          format.width.toDouble(),
          format.height.toDouble(),
        );

        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          imageRect,
          Paint(),
        );

        // 写真の上にオーバーレイを追加
        final overlayGradient = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(0, format.height.toDouble()),
          [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.6)],
        );

        final overlayPaint = Paint()..shader = overlayGradient;
        canvas.drawRect(
          Rect.fromLTWH(
            0,
            0,
            format.width.toDouble(),
            format.height.toDouble(),
          ),
          overlayPaint,
        );
      }
    } catch (e) {
      _logger.error(
        '写真背景描画エラー',
        context: 'DiaryImageGenerator._drawPhotoBackground',
        error: e,
      );
      // エラーが発生してもグラデーション背景は残る
    }
  }

  /// コンテンツオーバーレイを描画
  void _drawContentOverlay(Canvas canvas, ShareFormat format) {
    // コンテンツエリアに半透明の背景を追加
    final contentArea = _getContentArea(format);
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      contentArea,
      const Radius.circular(16),
    );
    canvas.drawRRect(rrect, overlayPaint);
  }

  /// テキスト要素を描画
  Future<void> _drawTextElements(
    Canvas canvas,
    DiaryEntry diary,
    ShareFormat format,
  ) async {
    final contentArea = _getContentArea(format);
    final textArea = contentArea.deflate(24); // パディング
    double currentY = textArea.top;

    // 日付を描画
    final dateText = _formatDate(diary.date);
    final dateSpan = TextSpan(
      text: dateText,
      style: TextStyle(
        color: Colors.white.withOpacity(0.9),
        fontSize: format.isStories ? 16 : 14,
        fontWeight: FontWeight.w400,
      ),
    );

    final datePainter = TextPainter(
      text: dateSpan,
      textDirection: TextDirection.ltr,
    );
    datePainter.layout(maxWidth: textArea.width);
    datePainter.paint(canvas, Offset(textArea.left, currentY));
    currentY += datePainter.height + 16;

    // タイトルを描画
    if (diary.title.isNotEmpty) {
      final titleSpan = TextSpan(
        text: diary.title,
        style: TextStyle(
          color: Colors.white,
          fontSize: format.isStories ? 28 : 24,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
      );

      final titlePainter = TextPainter(
        text: titleSpan,
        textDirection: TextDirection.ltr,
        maxLines: format.isStories ? 3 : 2,
      );
      titlePainter.layout(maxWidth: textArea.width);
      titlePainter.paint(canvas, Offset(textArea.left, currentY));
      currentY += titlePainter.height + 20;
    }

    // 本文を描画
    if (diary.content.isNotEmpty) {
      final maxLines = format.isStories ? 12 : 8;
      final contentText = _truncateText(diary.content, maxLines * 40); // 概算

      final contentSpan = TextSpan(
        text: contentText,
        style: TextStyle(
          color: Colors.white.withOpacity(0.95),
          fontSize: format.isStories ? 16 : 14,
          height: 1.5,
          letterSpacing: 0.3,
        ),
      );

      final contentPainter = TextPainter(
        text: contentSpan,
        textDirection: TextDirection.ltr,
        maxLines: maxLines,
      );
      contentPainter.layout(maxWidth: textArea.width);
      contentPainter.paint(canvas, Offset(textArea.left, currentY));
    }
  }

  /// ブランディング要素を描画
  void _drawBrandingElements(Canvas canvas, ShareFormat format) {
    // アプリ名ロゴ
    final brandText = 'Smart Photo Diary';
    final brandSpan = TextSpan(
      text: brandText,
      style: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: format.isStories ? 14 : 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
      ),
    );

    final brandPainter = TextPainter(
      text: brandSpan,
      textDirection: TextDirection.ltr,
    );
    brandPainter.layout();

    // 右下に配置
    final brandX = format.width - brandPainter.width - 20;
    final brandY = format.height - brandPainter.height - 20;
    brandPainter.paint(canvas, Offset(brandX, brandY));

    // 小さなアクセントライン
    final accentPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(brandX - 30, brandY + brandPainter.height / 2),
      Offset(brandX - 10, brandY + brandPainter.height / 2),
      accentPaint,
    );
  }

  /// 装飾要素を描画
  void _drawDecorationElements(Canvas canvas, ShareFormat format) {
    // 左上のアクセント装飾
    final decorPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // 角装飾
    final cornerSize = format.isStories ? 40.0 : 30.0;
    const margin = 20.0;

    // 左上
    canvas.drawLine(
      const Offset(margin, margin),
      Offset(margin + cornerSize, margin),
      decorPaint,
    );
    canvas.drawLine(
      const Offset(margin, margin),
      Offset(margin, margin + cornerSize),
      decorPaint,
    );

    // 右上
    canvas.drawLine(
      Offset(format.width - margin, margin),
      Offset(format.width - margin - cornerSize, margin),
      decorPaint,
    );
    canvas.drawLine(
      Offset(format.width - margin, margin),
      Offset(format.width - margin, margin + cornerSize),
      decorPaint,
    );
  }

  /// 画像の適切な配置矩形を計算
  Rect _calculateImageRect(
    double imageWidth,
    double imageHeight,
    double canvasWidth,
    double canvasHeight,
  ) {
    final imageAspect = imageWidth / imageHeight;
    final canvasAspect = canvasWidth / canvasHeight;

    double drawWidth, drawHeight;
    double offsetX = 0, offsetY = 0;

    if (imageAspect > canvasAspect) {
      // 画像が横長 - 高さに合わせる
      drawHeight = canvasHeight;
      drawWidth = drawHeight * imageAspect;
      offsetX = (canvasWidth - drawWidth) / 2;
    } else {
      // 画像が縦長 - 幅に合わせる
      drawWidth = canvasWidth;
      drawHeight = drawWidth / imageAspect;
      offsetY = (canvasHeight - drawHeight) / 2;
    }

    return Rect.fromLTWH(offsetX, offsetY, drawWidth, drawHeight);
  }

  /// コンテンツエリアを取得
  Rect _getContentArea(ShareFormat format) {
    final margin = format.isStories ? 50.0 : 40.0;
    final bottomSpace = format.isStories ? 120.0 : 80.0;

    return Rect.fromLTWH(
      margin,
      margin * 2,
      format.width - (margin * 2),
      format.height - (margin * 2) - bottomSpace,
    );
  }

  /// 日付をフォーマット
  String _formatDate(DateTime date) {
    final months = [
      '1月',
      '2月',
      '3月',
      '4月',
      '5月',
      '6月',
      '7月',
      '8月',
      '9月',
      '10月',
      '11月',
      '12月',
    ];

    return '${date.year}年 ${months[date.month - 1]} ${date.day}日';
  }

  /// テキストを指定長で切り詰める
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
}
