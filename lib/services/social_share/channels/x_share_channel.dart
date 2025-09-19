import 'dart:ui';

import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../../../constants/app_constants.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/result/result.dart';
import '../../../core/service_locator.dart';
import '../../../models/diary_entry.dart';
import '../../logging_service.dart';
import '../../../utils/x_share_text_builder.dart';

/// X（旧Twitter）共有チャネル実装
class XShareChannel {
  static const int _shareTimeoutSeconds = 10;
  static const Rect _defaultShareOrigin = Rect.fromLTWH(0, 0, 1, 1);

  LoggingService get _logger => serviceLocator.get<LoggingService>();

  Future<Result<void>> share({
    required DiaryEntry diary,
    List<AssetEntity>? photos,
    Rect? shareOrigin,
  }) async {
    try {
      _logger.info(
        'X共有開始',
        context: 'XShareChannel.share',
        data: 'diary_id: ${diary.id}',
      );

      // 画像の準備（最大3枚）
      final assets = photos ?? await diary.getPhotoAssets();
      final limited = assets.take(AppConstants.maxPhotosSelection).toList();
      final files = <XFile>[];
      for (final a in limited) {
        final f = await a.file;
        if (f != null && f.existsSync()) {
          files.add(XFile(f.path));
        }
      }

      // テキスト生成
      final text = XShareTextBuilder.build(
        title: diary.title,
        body: diary.content,
        appName: AppConstants.appTitle,
      );

      await Share.shareXFiles(
        files,
        text: text,
        sharePositionOrigin: shareOrigin ?? _defaultShareOrigin,
      ).timeout(
        const Duration(seconds: _shareTimeoutSeconds),
        onTimeout: () => throw Exception('共有がタイムアウトしました'),
      );

      _logger.info('X共有成功', context: 'XShareChannel.share');
      return const Success<void>(null);
    } catch (e, st) {
      _logger.error(
        'X共有エラー',
        context: 'XShareChannel.share',
        error: e,
        stackTrace: st,
      );
      return Failure<void>(
        XShareException('Xへの共有に失敗しました', originalError: e, stackTrace: st),
      );
    }
  }
}

class XShareException extends AppException {
  const XShareException(
    super.message, {
    super.details,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'X共有でエラーが発生しました: $message';
}
