import '../../core/result/result.dart';

/// AI使用量管理サービスのインターフェース
///
/// AI生成の使用量追跡、月次リセット、残回数計算を担当する。
abstract class IAiUsageService {
  /// AI生成を使用できるかどうかをチェック
  ///
  /// Returns:
  /// - Success: 使用可能な場合true、上限到達時はfalse
  /// - Failure: [ServiceException] 状態取得中にエラーが発生した場合
  Future<Result<bool>> canUseAiGeneration();

  /// AI生成使用量をインクリメント
  ///
  /// Returns:
  /// - Success: 使用量の記録に成功
  /// - Failure: [ServiceException] 使用量の更新中にエラーが発生した場合
  Future<Result<void>> incrementAiUsage();

  /// 残りAI生成回数を取得
  ///
  /// Returns:
  /// - Success: 残りの生成可能回数（0以上）
  /// - Failure: [ServiceException] 状態取得中にエラーが発生した場合
  Future<Result<int>> getRemainingGenerations();

  /// 今月の使用量を取得
  ///
  /// Returns:
  /// - Success: 今月のAI生成使用回数
  /// - Failure: [ServiceException] 状態取得中にエラーが発生した場合
  Future<Result<int>> getMonthlyUsage();

  /// 使用量を手動でリセット（管理者・テスト用）
  ///
  /// Returns:
  /// - Success: リセットに成功
  /// - Failure: [ServiceException] リセット処理中にエラーが発生した場合
  Future<Result<void>> resetUsage();

  /// 月次使用量を必要に応じてリセット（自動）
  ///
  /// 月が変わった場合に使用量カウンターを自動リセットする。
  ///
  /// Returns:
  /// - Success: リセット処理完了（リセット不要の場合も含む）
  /// - Failure: [ServiceException] 状態取得・更新中にエラーが発生した場合
  Future<Result<void>> resetMonthlyUsageIfNeeded();

  /// 次の使用量リセット日を取得
  ///
  /// Returns:
  /// - Success: 次回の月次リセット日時
  /// - Failure: [ServiceException] 日付計算中にエラーが発生した場合
  Future<Result<DateTime>> getNextResetDate();
}
