import '../../core/result/result.dart';

/// 日記統計サービスのインターフェース
///
/// 日記の件数・期間別カウントなどの統計情報を提供。
abstract class IDiaryStatisticsService {
  /// 日記の総数を取得
  ///
  /// Returns:
  /// - Success: 保存されている日記の総件数
  /// - Failure: [ServiceException] データ取得中にエラーが発生した場合
  Future<Result<int>> getTotalDiaryCount();

  /// 指定期間の日記数を取得
  ///
  /// [start]: 集計開始日時
  /// [end]: 集計終了日時
  ///
  /// Returns:
  /// - Success: 指定期間内の日記件数
  /// - Failure: [ServiceException] データ取得中にエラーが発生した場合
  Future<Result<int>> getDiaryCountInPeriod(DateTime start, DateTime end);
}
