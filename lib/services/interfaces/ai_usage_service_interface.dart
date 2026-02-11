import '../../core/result/result.dart';

/// AI使用量管理サービスのインターフェース
///
/// AI生成の使用量追跡、月次リセット、残回数計算を担当する。
abstract class IAiUsageService {
  /// AI生成を使用できるかどうかをチェック
  Future<Result<bool>> canUseAiGeneration();

  /// AI生成使用量をインクリメント
  Future<Result<void>> incrementAiUsage();

  /// 残りAI生成回数を取得
  Future<Result<int>> getRemainingGenerations();

  /// 今月の使用量を取得
  Future<Result<int>> getMonthlyUsage();

  /// 使用量を手動でリセット（管理者・テスト用）
  Future<Result<void>> resetUsage();

  /// 月次使用量を必要に応じてリセット（自動）
  Future<void> resetMonthlyUsageIfNeeded();

  /// 次の使用量リセット日を取得
  Future<Result<DateTime>> getNextResetDate();
}
