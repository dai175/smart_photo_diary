import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_constants.dart';
import '../core/errors/app_exceptions.dart';
import '../core/result/result.dart';
import '../core/service_locator.dart';
import '../models/diary_entry.dart';
import '../services/logging_service.dart';
import '../utils/x_share_text_builder.dart';
import 'interfaces/x_share_service_interface.dart';

/// X（旧Twitter）向け共有サービス
class XShareService implements IXShareService {
  static const int _shareTimeoutSeconds = 10;
  static XShareService? _instance;

  XShareService._();

  static XShareService getInstance() {
    _instance ??= XShareService._();
    return _instance!;
  }

  LoggingService get _logger => serviceLocator.get<LoggingService>();

  @override
  Future<Result<void>> shareToX({
    required DiaryEntry diary,
    List<AssetEntity>? photos,
  }) async {
    try {
      _logger.info(
        'X共有開始',
        context: 'XShareService.shareToX',
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

      // テキスト生成（タイトル+本文+アプリ名）
      final text = XShareTextBuilder.build(
        title: diary.title,
        body: diary.content,
        appName: AppConstants.appTitle,
      );

      // 共有（システム共有シート）
      await Share.shareXFiles(files, text: text).timeout(
        const Duration(seconds: _shareTimeoutSeconds),
        onTimeout: () => throw Exception('共有がタイムアウトしました'),
      );

      _logger.info('X共有成功', context: 'XShareService.shareToX');
      return const Success<void>(null);
    } catch (e, st) {
      _logger.error(
        'X共有エラー',
        context: 'XShareService.shareToX',
        error: e,
        stackTrace: st,
      );
      return Failure<void>(
        XShareException('Xへの共有に失敗しました', originalError: e, stackTrace: st),
      );
    }
  }
}

/// X共有関連の例外
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
