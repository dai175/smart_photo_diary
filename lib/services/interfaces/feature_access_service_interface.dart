import '../../core/result/result.dart';

/// 機能アクセス制御（内部）。公開呼び出しは [ISubscriptionService] を使う。
/// FORCE_PLAN は [ISubscriptionStateService.getCurrentStatus] 側で適用済み。
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
}
