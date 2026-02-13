import 'dart:io';
import 'dart:ui';
import 'package:photo_manager/photo_manager.dart';

import '../models/diary_entry.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../core/service_locator.dart';
import 'interfaces/social_share_service_interface.dart';
import 'diary_image_generator.dart';
import 'social_share/channels/x_share_channel.dart';
import 'social_share/channels/instagram_share_channel.dart';

/// ソーシャル共有サービスの実装クラス
class SocialShareService implements ISocialShareService {
  /// DI用の公開コンストラクタ
  SocialShareService();

  /// ログサービスを取得
  ILoggingService get _logger => serviceLocator.get<ILoggingService>();

  /// 画像生成サービス
  DiaryImageGenerator get _imageGenerator =>
      serviceLocator.get<DiaryImageGenerator>();

  /// チャネル実装
  final XShareChannel _xChannel = XShareChannel();
  final InstagramShareChannel _igChannel = InstagramShareChannel();

  @override
  Future<Result<void>> shareToSocialMedia({
    required DiaryEntry diary,
    required ShareFormat format,
    List<AssetEntity>? photos,
    Rect? shareOrigin,
  }) async {
    try {
      _logger.info(
        'Starting social share: ${format.displayName}',
        context: 'SocialShareService.shareToSocialMedia',
        data: 'diary_id: ${diary.id}',
      );

      // チャネルへ委譲（Instagram系）
      final result = await _igChannel.share(
        diary: diary,
        format: format,
        photos: photos,
        shareOrigin: shareOrigin,
      );
      return result;
    } catch (e) {
      _logger.error(
        'Unexpected error',
        context: 'SocialShareService.shareToSocialMedia',
        error: e,
      );
      return Failure<void>(
        SocialShareException(
          'An unexpected error occurred during sharing',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> shareToX({
    required DiaryEntry diary,
    List<AssetEntity>? photos,
    Rect? shareOrigin,
  }) async {
    return _xChannel.share(
      diary: diary,
      photos: photos,
      shareOrigin: shareOrigin,
    );
  }

  @override
  Future<Result<File>> generateShareImage({
    required DiaryEntry diary,
    required ShareFormat format,
    List<AssetEntity>? photos,
  }) async {
    _logger.info(
      'Starting share image generation: ${format.displayName}',
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
      case ShareFormat.portrait:
        return ShareFormat.portraitHD;
      default:
        return baseFormat;
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
  String get userMessage => 'Social sharing error: $message';
}
