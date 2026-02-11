import '../../core/result/result.dart';
import '../../models/plans/plan.dart';
import '../../models/subscription_status.dart';
import 'in_app_purchase_service_interface.dart';

// データクラスを再エクスポート（後方互換性のため）
export 'in_app_purchase_service_interface.dart'
    show PurchaseProduct, PurchaseResult, PurchaseStatus, SubscriptionException;

/// サブスクリプションサービスのインターフェース（Facade）
///
/// 後方互換性のために維持されるFacadeインターフェース。
/// 内部的にはISubscriptionStateService、IAiUsageService、
/// IFeatureAccessService、IInAppPurchaseServiceに委譲される。
///
/// Result<T>パターンを使用して型安全なエラーハンドリングを実現します。
abstract class ISubscriptionService {
  // ========================================
  // 基本的なサービスメソッド
  // ========================================

  /// サービスを初期化
  Future<Result<void>> initialize();

  /// 現在のサブスクリプション状態を取得
  /// デバッグモードでプラン強制設定がある場合、実際のデータは変更せずに返り値のみプレミアムプランとして返します
  Future<Result<SubscriptionStatus>> getCurrentStatus();

  /// サブスクリプション状態をリロード
  Future<Result<void>> refreshStatus();

  /// サービスが初期化済みかどうか
  bool get isInitialized;

  // ========================================
  // プラン管理メソッド
  // ========================================

  /// 特定のプラン情報を取得（新Planクラス）
  Result<Plan> getPlanClass(String planId);

  /// 現在のプランを取得（新Planクラス）
  Future<Result<Plan>> getCurrentPlanClass();

  // ========================================
  // 使用量管理メソッド
  // ========================================

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
  /// AiService統合で使用
  Future<void> resetMonthlyUsageIfNeeded();

  /// 次の使用量リセット日を取得
  Future<Result<DateTime>> getNextResetDate();

  // ========================================
  // アクセス権限チェックメソッド
  // ========================================

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

  // ========================================
  // 購入・復元メソッド
  // ========================================

  /// In-App Purchase商品情報を取得
  Future<Result<List<PurchaseProduct>>> getProducts();

  /// 指定プランの実際の価格情報を取得
  Future<Result<PurchaseProduct?>> getProductPrice(String planId);

  /// プランを購入（新Planクラス）
  Future<Result<PurchaseResult>> purchasePlanClass(Plan plan);

  /// 購入を復元
  Future<Result<List<PurchaseResult>>> restorePurchases();

  /// 購入状態を検証
  Future<Result<bool>> validatePurchase(String transactionId);

  /// プランを変更（新Planクラス）
  Future<Result<void>> changePlanClass(Plan newPlan);

  /// サブスクリプションをキャンセル
  Future<Result<void>> cancelSubscription();

  // ========================================
  // 状態監視・通知
  // ========================================

  /// サブスクリプション状態変更を監視
  Stream<SubscriptionStatus> get statusStream;

  /// 購入状態変更を監視
  Stream<PurchaseResult> get purchaseStream;

  /// サービスを破棄
  Future<void> dispose();
}
