import 'package:photo_manager/photo_manager.dart';

import '../core/result/result.dart';
import '../core/errors/error_handler.dart';
import '../core/service_registration.dart';
import '../services/interfaces/diary_crud_service_interface.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../services/interfaces/prompt_service_interface.dart';

/// 日記保存・プロンプト使用記録を担当する内部委譲クラス
class DiaryPreviewSaveDelegate {
  IDiaryCrudService? _diaryCrudService;
  IPromptService? _promptService;
  final ILoggingService _logger;

  DiaryPreviewSaveDelegate({
    IDiaryCrudService? diaryCrudService,
    IPromptService? promptService,
    required ILoggingService logger,
  }) : _diaryCrudService = diaryCrudService,
       _promptService = promptService,
       _logger = logger;

  /// 日記を保存し、保存された日記IDを返す
  Future<Result<String>> saveDiary({
    required DateTime photoDateTime,
    required String title,
    required String content,
    required List<AssetEntity> assets,
  }) async {
    try {
      _logger.info(
        'Starting diary save: photoCount=${assets.length}',
        context: 'DiaryPreviewSaveDelegate',
      );

      _diaryCrudService ??=
          await ServiceRegistration.getAsync<IDiaryCrudService>();
      final saveResult = await _diaryCrudService!.saveDiaryEntryWithPhotos(
        date: photoDateTime,
        title: title,
        content: content,
        photos: assets,
      );

      if (saveResult.isFailure) {
        return Failure(saveResult.error);
      }

      final savedDiary = saveResult.value;
      _logger.info('Diary save succeeded', context: 'DiaryPreviewSaveDelegate');

      return Success(savedDiary.id);
    } catch (e, stackTrace) {
      final appError = ErrorHandler.handleError(e, context: 'diary-save');
      _logger.error(
        'Diary save failed',
        context: 'DiaryPreviewSaveDelegate.saveDiary',
        error: appError,
        stackTrace: stackTrace,
      );

      return Failure(appError);
    }
  }

  /// プロンプト使用履歴を記録（非クリティカル）
  Future<void> recordPromptUsage({required String promptId}) async {
    try {
      _promptService ??= await ServiceRegistration.getAsync<IPromptService>();
      final result = await _promptService!.recordPromptUsage(
        promptId: promptId,
      );
      if (result case Failure(:final exception)) {
        _logger.error(
          'Prompt usage history recording failed',
          error: exception,
          context: 'DiaryPreviewSaveDelegate',
        );
      }
    } catch (e) {
      _logger.error(
        'Prompt usage history recording error',
        error: e,
        context: 'DiaryPreviewSaveDelegate',
      );
    }
  }
}
