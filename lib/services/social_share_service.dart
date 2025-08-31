import 'dart:io';
import 'package:photo_manager/photo_manager.dart';

import '../models/diary_entry.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../services/logging_service.dart';
import '../core/service_locator.dart';
import 'interfaces/social_share_service_interface.dart';
import 'diary_image_generator.dart';
import 'social_share/channels/x_share_channel.dart';
import 'social_share/channels/instagram_share_channel.dart';

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

  /// 画像生成サービス（後方互換で保持）
  DiaryImageGenerator get _imageGenerator => DiaryImageGenerator.getInstance();

  /// チャネル実装
  final XShareChannel _xChannel = XShareChannel();
  final InstagramShareChannel _igChannel = InstagramShareChannel();

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

      // チャネルへ委譲（Instagram系）
      final result = await _igChannel.share(
        diary: diary,
        format: format,
        photos: photos,
      );
      return result;
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
  Future<Result<void>> shareToX({
    required DiaryEntry diary,
    List<AssetEntity>? photos,
  }) async {
    return _xChannel.share(diary: diary, photos: photos);
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
  String get userMessage => 'SNS共有でエラーが発生しました: $message';
}
