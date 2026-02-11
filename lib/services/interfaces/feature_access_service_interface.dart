import '../../core/result/result.dart';

/// 機能アクセス制御サービスのインターフェース
///
/// プラン別の機能アクセス権限チェックを担当する。
abstract class IFeatureAccessService {
  /// プレミアム機能にアクセスできるかどうか
  Future<Result<bool>> canAccessPremiumFeatures();

  /// ライティングプロンプトにアクセスできるかどうか
  Future<Result<bool>> canAccessWritingPrompts();

  /// 高度なフィルタにアクセスできるかどうか
  Future<Result<bool>> canAccessAdvancedFilters();

  /// 高度な分析にアクセスできるかどうか
  Future<Result<bool>> canAccessAdvancedAnalytics();

  /// 優先サポートにアクセスできるかどうか
  Future<Result<bool>> canAccessPrioritySupport();

  /// データエクスポート機能にアクセスできるかどうか
  Future<Result<bool>> canAccessDataExport();

  /// 統計ダッシュボード機能にアクセスできるかどうか
  Future<Result<bool>> canAccessStatsDashboard();

  /// プラン別の機能制限情報を取得
  Future<Result<Map<String, bool>>> getFeatureAccess();
}
