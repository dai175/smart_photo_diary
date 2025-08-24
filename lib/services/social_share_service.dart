import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../models/diary_entry.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../services/logging_service.dart';
import '../core/service_locator.dart';
import 'interfaces/social_share_service_interface.dart';
import 'diary_image_generator.dart';

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
