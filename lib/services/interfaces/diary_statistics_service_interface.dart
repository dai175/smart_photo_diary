import '../../core/result/result.dart';

/// 日記統計サービスのインターフェース
///
/// 日記の件数・期間別カウントなどの統計情報を提供。
abstract class IDiaryStatisticsService {
  /// 日記の総数を取得
  Future<Result<int>> getTotalDiaryCount();

  /// 指定期間の日記数を取得
  Future<Result<int>> getDiaryCountInPeriod(DateTime start, DateTime end);
}
