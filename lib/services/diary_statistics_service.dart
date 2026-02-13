import 'package:hive/hive.dart';
import '../models/diary_entry.dart';
import 'interfaces/diary_statistics_service_interface.dart';
import 'interfaces/logging_service_interface.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';

/// 日記統計サービス
///
/// 日記の総数・期間別カウントなどの統計情報を提供。
/// Hiveボックスは遅延取得（DiaryServiceが先にオープン済みを前提）。
class DiaryStatisticsService implements IDiaryStatisticsService {
  static const String _boxName = 'diary_entries';

  final ILoggingService _logger;

  DiaryStatisticsService({required ILoggingService logger}) : _logger = logger;

  /// Hiveボックスを遅延取得
  Box<DiaryEntry>? get _diaryBox {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        return Hive.box<DiaryEntry>(_boxName);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Result<int>> getTotalDiaryCount() async {
    try {
      final box = _diaryBox;
      if (box == null) {
        return const Success(0);
      }
      return Success(box.length);
    } catch (e) {
      _logger.error('Total diary count retrieval error', error: e);
      return Failure(
        ServiceException(
          'Failed to retrieve total diary count',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<int>> getDiaryCountInPeriod(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final box = _diaryBox;
      if (box == null) {
        return const Success(0);
      }
      final count = box.values
          .where(
            (entry) => !entry.date.isBefore(start) && !entry.date.isAfter(end),
          )
          .length;
      return Success(count);
    } catch (e) {
      _logger.error('Period diary count retrieval error', error: e);
      return Failure(
        ServiceException(
          'Failed to retrieve period diary count',
          originalError: e,
        ),
      );
    }
  }
}
