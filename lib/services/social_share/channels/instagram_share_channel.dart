import 'dart:io';

import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/result/result.dart';
import '../../../core/service_locator.dart';
import '../../../models/diary_entry.dart';
import '../../logging_service.dart';
import '../../diary_image_generator.dart';
import '../../interfaces/social_share_service_interface.dart';

/// Instagram系（埋め込み画像を生成して共有）チャネル実装
class InstagramShareChannel {
  static const int _shareTimeoutSeconds = 10;

  LoggingService get _logger => serviceLocator.get<LoggingService>();
  DiaryImageGenerator get _imageGenerator => DiaryImageGenerator.getInstance();

  Future<Result<void>> share({
    required DiaryEntry diary,
    required ShareFormat format,
    List<AssetEntity>? photos,
  }) async {
    try {
      _logger.info(
        'Instagram共有開始: ${format.displayName}',
        context: 'InstagramShareChannel.share',
        data: 'diary_id: ${diary.id}',
      );

      final imageResult = await _imageGenerator.generateImage(
        diary: diary,
        format: format,
        photos: photos,
      );
      if (imageResult.isFailure) {
        return Failure<void>(imageResult.error);
      }

      final File imageFile = imageResult.value;

      await Share.shareXFiles([
        XFile(imageFile.path),
      ], text: '${diary.title}\n\n#SmartPhotoDiary で生成').timeout(
        const Duration(seconds: _shareTimeoutSeconds),
        onTimeout: () => throw Exception('共有がタイムアウトしました'),
      );

      _logger.info('Instagram共有成功', context: 'InstagramShareChannel.share');
      return const Success<void>(null);
    } catch (e, st) {
      _logger.error(
        'Instagram共有エラー',
        context: 'InstagramShareChannel.share',
        error: e,
        stackTrace: st,
      );
      return Failure<void>(
        InstagramShareException('共有に失敗しました', originalError: e, stackTrace: st),
      );
    }
  }
}

class InstagramShareException extends AppException {
  const InstagramShareException(
    super.message, {
    super.details,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'SNS共有でエラーが発生しました: $message';
}
