import '../../core/result/result.dart';

/// 機能アクセス制御サービスのインターフェース
///
/// プラン別の機能アクセス権限チェックを担当する。
abstract class IFeatureAccessService {
  /// プレミアム機能にアクセスできるかどうか
  ///
  /// Returns:
  /// - Success: アクセス可能な場合true、不可の場合false
  /// - Failure: [ServiceException] 状態サービスが未初期化の場合
  Future<Result<bool>> canAccessPremiumFeatures();

  /// ライティングプロンプトにアクセスできるかどうか
  ///
  /// Returns:
  /// - Success: アクセス可能な場合true、不可の場合false
  /// - Failure: [ServiceException] 状態サービスが未初期化の場合
  Future<Result<bool>> canAccessWritingPrompts();

  /// 高度なフィルタにアクセスできるかどうか
  ///
  /// Returns:
  /// - Success: アクセス可能な場合true、不可の場合false
  /// - Failure: [ServiceException] 状態サービスが未初期化の場合
  Future<Result<bool>> canAccessAdvancedFilters();

  /// 高度な分析にアクセスできるかどうか
  ///
  /// Returns:
  /// - Success: アクセス可能な場合true、不可の場合false
  /// - Failure: [ServiceException] 状態サービスが未初期化の場合
  Future<Result<bool>> canAccessAdvancedAnalytics();

  /// 優先サポートにアクセスできるかどうか
  ///
  /// Returns:
  /// - Success: アクセス可能な場合true、不可の場合false
  /// - Failure: [ServiceException] 状態サービスが未初期化の場合
  Future<Result<bool>> canAccessPrioritySupport();

  /// データエクスポート機能にアクセスできるかどうか
  ///
  /// Returns:
  /// - Success: アクセス可能な場合true、不可の場合false
  /// - Failure: [ServiceException] 状態サービスが未初期化の場合
  Future<Result<bool>> canAccessDataExport();

  /// 統計ダッシュボード機能にアクセスできるかどうか
  ///
  /// Returns:
  /// - Success: アクセス可能な場合true、不可の場合false
  /// - Failure: [ServiceException] 状態サービスが未初期化の場合
  Future<Result<bool>> canAccessStatsDashboard();

  /// プラン別の機能制限情報を取得
  ///
  /// Returns:
  /// - Success: 機能名をキー、アクセス可否をバリューとするMap
  /// - Failure: [ServiceException] 状態サービスが未初期化の場合
  Future<Result<Map<String, bool>>> getFeatureAccess();
}
