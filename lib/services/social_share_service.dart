import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../models/diary_entry.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../services/logging_service.dart';
import '../core/service_locator.dart';
import 'interfaces/social_share_service_interface.dart';

/// ソーシャル共有サービスの実装クラス
class SocialShareService implements ISocialShareService {
  // シングルトンパターン
  static SocialShareService? _instance;

  SocialShareService._();

  static SocialShareService getInstance() {
    _instance ??= SocialShareService._();
    return _instance!;
  }

  /// ログサービスを取得
  LoggingService get _logger => serviceLocator.get<LoggingService>();

  @override
  Future<Result<void>> shareToSocialMedia({
    required DiaryEntry diary,
    required ShareFormat format,
    List<AssetEntity>? photos,
  }) async {
    try {
      _logger.info(
        'SNS共有開始: ${format.displayName}',
        context: 'SocialShareService.shareToSocialMedia',
        data: 'diary_id: ${diary.id}',
      );

      // 共有用画像を生成
      final imageResult = await generateShareImage(
        diary: diary,
        format: format,
        photos: photos,
      );

      return imageResult.fold((imageFile) async {
        try {
          // Share Plus を使用してファイルを共有
          await Share.shareXFiles([
            XFile(imageFile.path),
          ], text: '${diary.title}\n\n#SmartPhotoDiary で生成');

          _logger.info(
            'SNS共有成功',
            context: 'SocialShareService.shareToSocialMedia',
          );

          return const Success<void>(null);
        } catch (e) {
          _logger.error(
            'SNS共有エラー',
            context: 'SocialShareService.shareToSocialMedia',
            error: e,
          );
          return Failure<void>(
            SocialShareException(
              'SNSへの共有に失敗しました',
              details: e.toString(),
              originalError: e,
            ),
          );
        }
      }, (error) => Failure<void>(error));
    } catch (e) {
      _logger.error(
        '予期しないエラー',
        context: 'SocialShareService.shareToSocialMedia',
        error: e,
      );
      return Failure<void>(
        SocialShareException('共有処理中に予期しないエラーが発生しました', originalError: e),
      );
    }
  }

  @override
  Future<Result<File>> generateShareImage({
    required DiaryEntry diary,
    required ShareFormat format,
    List<AssetEntity>? photos,
  }) async {
    try {
      _logger.info(
        '共有画像生成開始: ${format.displayName}',
        context: 'SocialShareService.generateShareImage',
      );

      // 一時ディレクトリを取得
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'share_${diary.id}_${format.name}_$timestamp.png';
      final outputFile = File('${tempDir.path}/$fileName');

      // キャンバスサイズを設定
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, format.width.toDouble(), format.height.toDouble()),
      );

      // 画像を描画
      await _drawShareImage(canvas, diary, format, photos);

      // Pictureからイメージに変換
      final picture = recorder.endRecording();
      final image = await picture.toImage(format.width, format.height);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        return const Failure<File>(SocialShareException('画像データの変換に失敗しました'));
      }

      // ファイルに保存
      await outputFile.writeAsBytes(byteData.buffer.asUint8List());

      _logger.info(
        '共有画像生成完了',
        context: 'SocialShareService.generateShareImage',
        data: 'file_path: ${outputFile.path}',
      );

      return Success<File>(outputFile);
    } catch (e) {
      _logger.error(
        '画像生成エラー',
        context: 'SocialShareService.generateShareImage',
        error: e,
      );
      return Failure<File>(
        SocialShareException('共有用画像の生成に失敗しました', originalError: e),
      );
    }
  }

  /// 共有画像をキャンバスに描画
  Future<void> _drawShareImage(
    Canvas canvas,
    DiaryEntry diary,
    ShareFormat format,
    List<AssetEntity>? photos,
  ) async {
    // 背景色を設定
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, format.width.toDouble(), format.height.toDouble()),
      backgroundPaint,
    );

    // 写真がある場合は背景として描画
    if (photos != null && photos.isNotEmpty) {
      await _drawBackgroundPhoto(canvas, photos.first, format);
    }

    // オーバーレイ背景を描画
    await _drawOverlay(canvas, format);

    // テキストコンテンツを描画
    await _drawTextContent(canvas, diary, format);

    // ブランドロゴ・アプリ名を描画
    _drawBranding(canvas, format);
  }

  /// 背景写真を描画
  Future<void> _drawBackgroundPhoto(
    Canvas canvas,
    AssetEntity photo,
    ShareFormat format,
  ) async {
    try {
      final imageData = await photo.originBytes;
      if (imageData != null) {
        final codec = await ui.instantiateImageCodec(imageData);
        final frame = await codec.getNextFrame();
        final image = frame.image;

        // 画像を画面サイズに合わせてスケール
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromLTWH(
            0,
            0,
            format.width.toDouble(),
            format.height.toDouble(),
          ),
          Paint(),
        );
      }
    } catch (e) {
      _logger.error(
        '背景写真描画エラー',
        context: 'SocialShareService._drawBackgroundPhoto',
        error: e,
      );
    }
  }

  /// オーバーレイ背景を描画
  Future<void> _drawOverlay(Canvas canvas, ShareFormat format) async {
    // グラデーションオーバーレイ
    final gradient = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(0, format.height.toDouble()),
      [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.7)],
    );

    final gradientPaint = Paint()..shader = gradient;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, format.width.toDouble(), format.height.toDouble()),
      gradientPaint,
    );
  }

  /// テキストコンテンツを描画
  Future<void> _drawTextContent(
    Canvas canvas,
    DiaryEntry diary,
    ShareFormat format,
  ) async {
    final contentArea = _getContentArea(format);
    double currentY = contentArea.top;

    // タイトルを描画
    if (diary.title.isNotEmpty) {
      final titleSpan = TextSpan(
        text: diary.title,
        style: TextStyle(
          color: Colors.white,
          fontSize: format.isStories ? 32 : 28,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      );

      final titlePainter = TextPainter(
        text: titleSpan,
        textDirection: TextDirection.ltr,
        maxLines: 2,
      );
      titlePainter.layout(maxWidth: contentArea.width);
      titlePainter.paint(canvas, Offset(contentArea.left, currentY));
      currentY += titlePainter.height + 20;
    }

    // 本文を描画
    if (diary.content.isNotEmpty) {
      final contentSpan = TextSpan(
        text: diary.content,
        style: TextStyle(
          color: Colors.white,
          fontSize: format.isStories ? 18 : 16,
          height: 1.4,
        ),
      );

      final contentPainter = TextPainter(
        text: contentSpan,
        textDirection: TextDirection.ltr,
        maxLines: format.isStories ? 15 : 8,
      );
      contentPainter.layout(maxWidth: contentArea.width);
      contentPainter.paint(canvas, Offset(contentArea.left, currentY));
    }
  }

  /// ブランディングを描画
  void _drawBranding(Canvas canvas, ShareFormat format) {
    final brandSpan = TextSpan(
      text: 'Smart Photo Diary',
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: 14,
        fontWeight: FontWeight.w500,
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
  }

  /// コンテンツエリアを取得
  Rect _getContentArea(ShareFormat format) {
    const margin = 40.0;
    const bottomSpace = 60.0;

    return Rect.fromLTWH(
      margin,
      margin,
      format.width - (margin * 2),
      format.height - margin - bottomSpace,
    );
  }

  @override
  List<ShareFormat> getSupportedFormats() {
    return ShareFormat.values;
  }

  @override
  bool isFormatSupported(ShareFormat format) {
    return ShareFormat.values.contains(format);
  }
}

/// ソーシャル共有関連のエラー
class SocialShareException extends AppException {
  const SocialShareException(
    super.message, {
    super.details,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'SNS共有でエラーが発生しました: $message';
}
