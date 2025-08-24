import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/diary_entry.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../services/logging_service.dart';
import '../core/service_locator.dart';
import 'interfaces/social_share_service_interface.dart';
import 'diary_image_generator.dart';

/// ソーシャル共有サービスの実装クラス
class SocialShareService implements ISocialShareService {
  // ============= 定数定義 =============

  /// Instagram URL Schemes
  static const String _instagramCameraScheme = 'instagram://camera';

  /// 共有待機時間（ミリ秒）
  static const int _shareDelayMs = 500;

  // シングルトンパターン
  static SocialShareService? _instance;

  SocialShareService._();

  static SocialShareService getInstance() {
    _instance ??= SocialShareService._();
    return _instance!;
  }

  /// ログサービスを取得
  LoggingService get _logger => serviceLocator.get<LoggingService>();

  /// 画像生成サービスを取得
  DiaryImageGenerator get _imageGenerator => DiaryImageGenerator.getInstance();

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

      if (imageResult.isFailure) {
        return Failure<void>(imageResult.error);
      }

      final imageFile = imageResult.value;

      try {
        // Instagram アプリを直接起動して共有
        final success = await _shareToInstagram(imageFile, diary);

        if (success) {
          _logger.info(
            'Instagram共有成功',
            context: 'SocialShareService.shareToSocialMedia',
          );
          return const Success<void>(null);
        } else {
          // Instagram起動失敗時は通常の共有にフォールバック
          await Share.shareXFiles([
            XFile(imageFile.path),
          ], text: '${diary.title}\n\n#SmartPhotoDiary で生成');

          _logger.info(
            'SNS共有成功（フォールバック）',
            context: 'SocialShareService.shareToSocialMedia',
          );
          return const Success<void>(null);
        }
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
    _logger.info(
      '共有画像生成開始: ${format.displayName}',
      context: 'SocialShareService.generateShareImage',
      data: 'diary_id: ${diary.id}',
    );

    // DiaryImageGeneratorに委譲
    return await _imageGenerator.generateImage(
      diary: diary,
      format: format,
      photos: photos,
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

  @override
  ShareFormat getRecommendedFormat(
    ShareFormat baseFormat, {
    bool useHD = true,
  }) {
    if (!useHD) return baseFormat;

    // デバイス情報を取得してHDフォーマットを推奨
    switch (baseFormat) {
      case ShareFormat.instagramStories:
        return ShareFormat.instagramStoriesHD;
      default:
        return baseFormat;
    }
  }

  /// Instagramアプリを直接起動して共有
  Future<bool> _shareToInstagram(File imageFile, DiaryEntry diary) async {
    try {
      // まず Instagram アプリを直接起動を試行
      final instagramUri = Uri.parse(_instagramCameraScheme);

      if (await canLaunchUrl(instagramUri)) {
        // Instagram アプリを直接起動
        await launchUrl(instagramUri);

        _logger.info(
          'Instagramアプリを直接起動しました',
          context: 'SocialShareService._shareToInstagram',
        );

        // 少し待ってから共有シートを表示（Instagramアプリが開いた後）
        await Future.delayed(const Duration(milliseconds: _shareDelayMs));

        // 画像を共有
        await Share.shareXFiles([
          XFile(imageFile.path),
        ], text: '${diary.title}\n\n#SmartPhotoDiary で生成');

        return true;
      } else {
        _logger.info(
          'Instagramアプリが見つかりません - 通常の共有を使用',
          context: 'SocialShareService._shareToInstagram',
        );
        return false;
      }
    } catch (e) {
      _logger.error(
        'Instagram起動エラー',
        context: 'SocialShareService._shareToInstagram',
        error: e,
      );
      return false;
    }
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
