import 'dart:io';
import 'dart:ui';
import 'package:photo_manager/photo_manager.dart';

import '../models/diary_entry.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../services/interfaces/logging_service_interface.dart';
import 'interfaces/photo_service_interface.dart';
import 'interfaces/social_share_service_interface.dart';
import 'diary_image_generator.dart';
import 'social_share/channels/x_share_channel.dart';
import 'social_share/channels/instagram_share_channel.dart';

/// ソーシャル共有サービスの実装クラス
class SocialShareService implements ISocialShareService {
  final ILoggingService _logger;
  final DiaryImageGenerator _imageGenerator;
  final XShareChannel _xChannel;
  final InstagramShareChannel _igChannel;

  SocialShareService({
    required ILoggingService logger,
    required DiaryImageGenerator imageGenerator,
    required IPhotoService photoService,
    XShareChannel? xChannel,
    InstagramShareChannel? igChannel,
  }) : _logger = logger,
       _imageGenerator = imageGenerator,
       _xChannel =
           xChannel ??
           XShareChannel(logger: logger, photoService: photoService),
       _igChannel =
           igChannel ??
           InstagramShareChannel(
             logger: logger,
             imageGenerator: imageGenerator,
           );

  @override
  Future<Result<void>> shareToSocialMedia({
    required DiaryEntry diary,
    required ShareFormat format,
    List<AssetEntity>? photos,
    Rect? shareOrigin,
  }) async {
    try {
      _logger.info(
        'Starting social share: ${format.name}',
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
      'Starting share image generation: ${format.name}',
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
