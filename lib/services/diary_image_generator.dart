import 'dart:io';
import 'dart:math' as math;
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

      // キャンバスサイズを設定（スケール対応）
      final actualWidth = format.isHD ? format.scaledWidth : format.width;
      final actualHeight = format.isHD ? format.scaledHeight : format.height;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, actualWidth.toDouble(), actualHeight.toDouble()),
      );

      // 画像を描画
      await _drawCompositeImage(canvas, diary, format, photos);

      // Pictureからイメージに変換（スケール対応）
      final picture = recorder.endRecording();
      final image = await picture.toImage(actualWidth, actualHeight);
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
    final actualWidth = format.isHD ? format.scaledWidth : format.width;
    final actualHeight = format.isHD ? format.scaledHeight : format.height;

    // まず単色背景を描画
    final backgroundGradient = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(actualWidth.toDouble(), actualHeight.toDouble()),
      [
        const Color(0xFF667eea), // 美しいグラデーション
        const Color(0xFF764ba2),
      ],
    );

    final backgroundPaint = Paint()..shader = backgroundGradient;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, actualWidth.toDouble(), actualHeight.toDouble()),
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
      // 複数写真の場合、カルーセル風レイアウトを適用
      if (photos.length > 1) {
        await _drawMultiplePhotos(canvas, photos, format);
      } else {
        // 単一写真の場合、従来通り背景として描画
        await _drawSinglePhotoBackground(canvas, photos.first, format);
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

  /// 単一写真の背景描画
  Future<void> _drawSinglePhotoBackground(
    Canvas canvas,
    AssetEntity photo,
    ShareFormat format,
  ) async {
    final imageData = await photo.originBytes;
    if (imageData == null) return;

    final codec = await ui.instantiateImageCodec(imageData);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final actualWidth = format.isHD ? format.scaledWidth : format.width;
    final actualHeight = format.isHD ? format.scaledHeight : format.height;

    // 画像を適切にスケール・トリミング
    final imageRect = _calculateImageRect(
      image.width.toDouble(),
      image.height.toDouble(),
      actualWidth.toDouble(),
      actualHeight.toDouble(),
    );

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      imageRect,
      Paint(),
    );

    // 写真の上にオーバーレイを追加
    _drawPhotoOverlay(canvas, format);
  }

  /// 複数写真のカルーセル風描画
  Future<void> _drawMultiplePhotos(
    Canvas canvas,
    List<AssetEntity> photos,
    ShareFormat format,
  ) async {
    final actualWidth = format.isHD ? format.scaledWidth : format.width;
    final actualHeight = format.isHD ? format.scaledHeight : format.height;
    final scaleMultiplier = format.isHD ? format.scale : 1.0;

    final photoCount = math.min(photos.length, format.isStories ? 3 : 2);
    final photoWidth = actualWidth / photoCount;
    final photoSpacing = 6.0 * scaleMultiplier;

    for (int i = 0; i < photoCount; i++) {
      final photo = photos[i];
      final imageData = await photo.originBytes;
      if (imageData == null) continue;

      final codec = await ui.instantiateImageCodec(imageData);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // 各写真の配置位置を計算
      final startX = i * (photoWidth - photoSpacing);
      final photoRect = Rect.fromLTWH(
        startX,
        0,
        photoWidth - photoSpacing,
        actualHeight.toDouble(),
      );

      // 写真をクロップして描画
      final sourceRect = _calculateCropRect(
        image.width.toDouble(),
        image.height.toDouble(),
        photoRect.width,
        photoRect.height,
      );

      canvas.drawImageRect(image, sourceRect, photoRect, Paint());

      // 写真間のエレガントな境界線
      if (i < photoCount - 1) {
        final borderPaint = Paint()
          ..color = Colors.white.withOpacity(0.4)
          ..strokeWidth = 2 * scaleMultiplier
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(startX + photoRect.width, 0),
          Offset(startX + photoRect.width, actualHeight.toDouble()),
          borderPaint,
        );
      }
    }

    // 複数写真の上にオーバーレイを追加
    _drawPhotoOverlay(canvas, format);
  }

  /// 写真用オーバーレイ描画
  void _drawPhotoOverlay(Canvas canvas, ShareFormat format) {
    final actualWidth = format.isHD ? format.scaledWidth : format.width;
    final actualHeight = format.isHD ? format.scaledHeight : format.height;

    final overlayGradient = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(0, actualHeight.toDouble()),
      [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.6)],
    );

    final overlayPaint = Paint()..shader = overlayGradient;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, actualWidth.toDouble(), actualHeight.toDouble()),
      overlayPaint,
    );
  }

  /// クロップ用の矩形を計算
  Rect _calculateCropRect(
    double imageWidth,
    double imageHeight,
    double targetWidth,
    double targetHeight,
  ) {
    final imageAspect = imageWidth / imageHeight;
    final targetAspect = targetWidth / targetHeight;

    double cropWidth, cropHeight;
    double offsetX = 0, offsetY = 0;

    if (imageAspect > targetAspect) {
      // 画像が横長 - 高さに合わせて幅をクロップ
      cropHeight = imageHeight;
      cropWidth = cropHeight * targetAspect;
      offsetX = (imageWidth - cropWidth) / 2;
    } else {
      // 画像が縦長 - 幅に合わせて高さをクロップ
      cropWidth = imageWidth;
      cropHeight = cropWidth / targetAspect;
      offsetY = (imageHeight - cropHeight) / 2;
    }

    return Rect.fromLTWH(offsetX, offsetY, cropWidth, cropHeight);
  }

  /// コンテンツオーバーレイを描画
  void _drawContentOverlay(Canvas canvas, ShareFormat format) {
    final scaleMultiplier = format.isHD ? format.scale : 1.0;

    // コンテンツエリアに半透明の背景を追加
    final contentArea = _getContentArea(format);
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      contentArea,
      Radius.circular(20 * scaleMultiplier),
    );
    canvas.drawRRect(rrect, overlayPaint);

    // コンテンツエリアの縁に美しいボーダーを追加
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.5 * scaleMultiplier
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rrect, borderPaint);
  }

  /// テキスト要素を描画
  Future<void> _drawTextElements(
    Canvas canvas,
    DiaryEntry diary,
    ShareFormat format,
  ) async {
    final contentArea = _getContentArea(format);
    final textArea = contentArea.deflate(format.isStories ? 32 : 24);
    double currentY = textArea.top;

    // 動的フォントサイズとレイアウト調整
    final textSizes = _calculateTextSizes(format, diary);
    final spacing = _calculateSpacing(format);

    // 日付を描画
    final dateText = _formatDate(diary.date);
    final dateSpan = TextSpan(
      text: dateText,
      style: TextStyle(
        color: Colors.white.withOpacity(0.9),
        fontSize: textSizes.dateSize,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
    );

    final datePainter = TextPainter(
      text: dateSpan,
      textDirection: TextDirection.ltr,
    );
    datePainter.layout(maxWidth: textArea.width);
    datePainter.paint(canvas, Offset(textArea.left, currentY));
    currentY += datePainter.height + spacing.afterDate;

    // タイトルを描画
    if (diary.title.isNotEmpty) {
      final titleText = _optimizeTextForFormat(
        diary.title,
        format,
        isTitle: true,
      );
      final titleSpan = TextSpan(
        text: titleText,
        style: TextStyle(
          color: Colors.white,
          fontSize: textSizes.titleSize,
          fontWeight: FontWeight.bold,
          height: 1.25,
          letterSpacing: 0.2,
        ),
      );

      final titlePainter = TextPainter(
        text: titleSpan,
        textDirection: TextDirection.ltr,
        maxLines: textSizes.titleMaxLines,
      );
      titlePainter.layout(maxWidth: textArea.width);
      titlePainter.paint(canvas, Offset(textArea.left, currentY));
      currentY += titlePainter.height + spacing.afterTitle;
    }

    // 本文を描画
    if (diary.content.isNotEmpty) {
      final contentText = _optimizeTextForFormat(diary.content, format);
      final remainingHeight = textArea.bottom - currentY;
      final availableLines = (remainingHeight / (textSizes.contentSize * 1.5))
          .floor();
      final maxLines = math.min(availableLines, textSizes.contentMaxLines);

      final contentSpan = TextSpan(
        text: contentText,
        style: TextStyle(
          color: Colors.white.withOpacity(0.95),
          fontSize: textSizes.contentSize,
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

  /// フォーマットに応じたテキストサイズを計算
  _TextSizes _calculateTextSizes(ShareFormat format, DiaryEntry diary) {
    if (format.isStories) {
      // Stories用のサイズ調整
      final titleLength = diary.title.length;
      final contentLength = diary.content.length;

      return _TextSizes(
        dateSize: 18,
        titleSize: titleLength > 20 ? 26 : 30,
        titleMaxLines: titleLength > 30 ? 4 : 3,
        contentSize: contentLength > 200 ? 16 : 18,
        contentMaxLines: 15,
      );
    } else {
      // Feed用のサイズ調整
      final titleLength = diary.title.length;
      final contentLength = diary.content.length;

      return _TextSizes(
        dateSize: 14,
        titleSize: titleLength > 15 ? 22 : 26,
        titleMaxLines: 2,
        contentSize: contentLength > 150 ? 14 : 16,
        contentMaxLines: 10,
      );
    }
  }

  /// スペーシングを計算
  _Spacing _calculateSpacing(ShareFormat format) {
    if (format.isStories) {
      return _Spacing(afterDate: 20, afterTitle: 24);
    } else {
      return _Spacing(afterDate: 16, afterTitle: 20);
    }
  }

  /// フォーマットに最適化されたテキストを取得
  String _optimizeTextForFormat(
    String text,
    ShareFormat format, {
    bool isTitle = false,
  }) {
    final maxLength = format.isStories
        ? (isTitle ? 80 : 300)
        : (isTitle ? 50 : 200);

    if (text.length <= maxLength) return text;

    // 文章の区切りで切りたいので、句点や改行で適切に切断
    final sentences = text.split(RegExp(r'[。！？\n]'));
    final buffer = StringBuffer();

    for (final sentence in sentences) {
      if (buffer.length + sentence.length > maxLength - 3) break;
      if (buffer.isNotEmpty) buffer.write('。');
      buffer.write(sentence);
    }

    final result = buffer.toString();
    return result.length < text.length ? '$result...' : result;
  }

  /// ブランディング要素を描画
  void _drawBrandingElements(Canvas canvas, ShareFormat format) {
    final actualWidth = format.isHD ? format.scaledWidth : format.width;
    final actualHeight = format.isHD ? format.scaledHeight : format.height;
    final scaleMultiplier = format.isHD ? format.scale : 1.0;

    // アプリ名ロゴ
    final brandText = 'Smart Photo Diary';
    final brandSpan = TextSpan(
      text: brandText,
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: (format.isStories ? 16 : 14) * scaleMultiplier,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );

    final brandPainter = TextPainter(
      text: brandSpan,
      textDirection: TextDirection.ltr,
    );
    brandPainter.layout();

    // 右下に配置
    final margin = 24 * scaleMultiplier;
    final brandX = actualWidth - brandPainter.width - margin;
    final brandY = actualHeight - brandPainter.height - margin;

    // ブランド背景
    final brandBgPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final brandBgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        brandX - 12 * scaleMultiplier,
        brandY - 8 * scaleMultiplier,
        brandPainter.width + 24 * scaleMultiplier,
        brandPainter.height + 16 * scaleMultiplier,
      ),
      Radius.circular(8 * scaleMultiplier),
    );
    canvas.drawRRect(brandBgRect, brandBgPaint);

    brandPainter.paint(canvas, Offset(brandX, brandY));

    // アクセントライン（より美しく）
    final accentPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 3 * scaleMultiplier
      ..strokeCap = StrokeCap.round;

    final lineStartX = brandX - 40 * scaleMultiplier;
    final lineEndX = brandX - 16 * scaleMultiplier;
    final lineY = brandY + brandPainter.height / 2;

    canvas.drawLine(
      Offset(lineStartX, lineY),
      Offset(lineEndX, lineY),
      accentPaint,
    );

    // 小さなドット装飾
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(lineStartX - 8 * scaleMultiplier, lineY),
      2 * scaleMultiplier,
      dotPaint,
    );
  }

  /// 装飾要素を描画
  void _drawDecorationElements(Canvas canvas, ShareFormat format) {
    final actualWidth = format.isHD ? format.scaledWidth : format.width;
    final actualHeight = format.isHD ? format.scaledHeight : format.height;
    final scaleMultiplier = format.isHD ? format.scale : 1.0;

    // 改善された装飾デザイン
    final decorPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 2.5 * scaleMultiplier
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cornerSize = (format.isStories ? 50.0 : 40.0) * scaleMultiplier;
    final margin = 30.0 * scaleMultiplier;

    // 左上のエレガントなコーナー
    final cornerPath = Path()
      ..moveTo(margin, margin + cornerSize)
      ..lineTo(margin, margin + 10 * scaleMultiplier)
      ..quadraticBezierTo(margin, margin, margin + 10 * scaleMultiplier, margin)
      ..lineTo(margin + cornerSize, margin);

    canvas.drawPath(cornerPath, decorPaint);

    // 右上のコーナー
    final rightCornerPath = Path()
      ..moveTo(actualWidth - margin, margin + cornerSize)
      ..lineTo(actualWidth - margin, margin + 10 * scaleMultiplier)
      ..quadraticBezierTo(
        actualWidth - margin,
        margin,
        actualWidth - margin - 10 * scaleMultiplier,
        margin,
      )
      ..lineTo(actualWidth - margin - cornerSize, margin);

    canvas.drawPath(rightCornerPath, decorPaint);

    // 中央上部に小さなアクセント
    final centerAccentPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final accentRect = Rect.fromCenter(
      center: Offset(actualWidth / 2, margin),
      width: 60 * scaleMultiplier,
      height: 3 * scaleMultiplier,
    );

    final accentRRect = RRect.fromRectAndRadius(
      accentRect,
      Radius.circular(1.5 * scaleMultiplier),
    );

    canvas.drawRRect(accentRRect, centerAccentPaint);
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
    final actualWidth = format.isHD ? format.scaledWidth : format.width;
    final actualHeight = format.isHD ? format.scaledHeight : format.height;
    final scaleMultiplier = format.isHD ? format.scale : 1.0;

    if (format.isStories) {
      // Stories用の縦長レイアウト
      final margin = 70.0 * scaleMultiplier;
      final topMargin = 120.0 * scaleMultiplier; // 上部により多くのスペース
      final bottomSpace = 180.0 * scaleMultiplier; // ブランディング用スペース

      return Rect.fromLTWH(
        margin,
        topMargin,
        actualWidth - (margin * 2),
        actualHeight - topMargin - bottomSpace,
      );
    } else {
      // Feed用の正方形レイアウト
      final margin = 60.0 * scaleMultiplier;
      final topMargin = 80.0 * scaleMultiplier;
      final bottomSpace = 120.0 * scaleMultiplier;

      return Rect.fromLTWH(
        margin,
        topMargin,
        actualWidth - (margin * 2),
        actualHeight - topMargin - bottomSpace,
      );
    }
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

/// テキストサイズ設定
class _TextSizes {
  final double dateSize;
  final double titleSize;
  final int titleMaxLines;
  final double contentSize;
  final int contentMaxLines;

  _TextSizes({
    required this.dateSize,
    required this.titleSize,
    required this.titleMaxLines,
    required this.contentSize,
    required this.contentMaxLines,
  });
}

/// スペーシング設定
class _Spacing {
  final double afterDate;
  final double afterTitle;

  _Spacing({required this.afterDate, required this.afterTitle});
}
