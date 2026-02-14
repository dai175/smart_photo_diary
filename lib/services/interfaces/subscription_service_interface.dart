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
/// `Result<T>`パターンを使用して型安全なエラーハンドリングを実現します。
/// 委譲先サービスが返すエラーがそのまま伝播されます。
abstract class ISubscriptionService {
  // ========================================
  // 基本的なサービスメソッド
  // ========================================

  /// サービスを初期化
  ///
  /// Returns:
  /// - Success: void（初期化完了。既に初期化済みでも成功を返す）
  Future<Result<void>> initialize();

  /// 現在のサブスクリプション状態を取得
  ///
  /// デバッグモードでプラン強制設定がある場合、実際のデータは変更せずに
  /// 返り値のみプレミアムプランとして返します。
  ///
  /// Returns:
  /// - Success: 現在の [SubscriptionStatus]
  /// - Failure: [ServiceException] 状態サービスが未初期化、または読み取り失敗時
  Future<Result<SubscriptionStatus>> getCurrentStatus();

  /// サブスクリプション状態をリロード
  ///
  /// Returns:
  /// - Success: void（リロード完了）
  /// - Failure: [ServiceException] 状態サービスが未初期化の場合
  Future<Result<void>> refreshStatus();

  /// サービスが初期化済みかどうか
  bool get isInitialized;

  // ========================================
  // プラン管理メソッド
  // ========================================

  /// 特定のプラン情報を取得
  ///
  /// Returns:
  /// - Success: [planId] に対応する [Plan] オブジェクト
  /// - Failure: [ServiceException] 不明なplanIdの場合
  Result<Plan> getPlanClass(String planId);

  /// 現在のプランを取得
  ///
  /// Returns:
  /// - Success: 現在適用中の [Plan] オブジェクト
  /// - Failure: [ServiceException] 状態サービスが未初期化、またはステータス取得失敗時
  Future<Result<Plan>> getCurrentPlanClass();

  // ========================================
  // 使用量管理メソッド
  // ========================================

  /// AI生成を使用できるかどうかをチェック
  ///
  /// Returns:
  /// - Success: 使用可能な場合 true、制限超過時 false
  /// - Failure: [ServiceException] 状態サービスが未初期化の場合
  Future<Result<bool>> canUseAiGeneration();

  /// AI生成使用量をインクリメント
  ///
  /// Returns:
  /// - Success: void（カウント更新完了）
  /// - Failure: [ServiceException] 未初期化、サブスクリプション無効、
  ///   または月間制限超過時
  Future<Result<void>> incrementAiUsage();

  /// 残りAI生成回数を取得
  ///
  /// Returns:
  /// - Success: 今月の残りAI生成可能回数
  /// - Failure: [ServiceException] 状態サービスが未初期化の場合
  Future<Result<int>> getRemainingGenerations();

  /// 今月の使用量を取得
  ///
  /// Returns:
  /// - Success: 今月のAI生成使用回数
  /// - Failure: [ServiceException] 状態サービスが未初期化の場合
  Future<Result<int>> getMonthlyUsage();

  /// 使用量を手動でリセット（管理者・テスト用）
  ///
  /// Returns:
  /// - Success: void（リセット完了）
  /// - Failure: [ServiceException] 状態サービスが未初期化の場合
  Future<Result<void>> resetUsage();

  /// 月次使用量を必要に応じてリセット（自動）
  ///
  /// AiService統合で生成前に呼び出される。
  ///
  /// Returns:
  /// - Success: リセット処理完了（リセット不要の場合も含む）
  /// - Failure: [ServiceException] 状態取得・更新中にエラーが発生した場合
  Future<Result<void>> resetMonthlyUsageIfNeeded();

  /// 次の使用量リセット日を取得
  ///
  /// Returns:
  /// - Success: 次の月次リセット日時
  /// - Failure: [ServiceException] 状態サービスが未初期化の場合
  Future<Result<DateTime>> getNextResetDate();

  // ========================================
  // アクセス権限チェックメソッド
  // ========================================

  /// プレミアム機能にアクセスできるかどうか
  ///
  /// Returns:
  /// - Success: Premiumプランかつ有効な場合 true
  /// - Failure: [ServiceException] 状態サービスが未初期化の場合
  Future<Result<bool>> canAccessPremiumFeatures();

  /// ライティングプロンプトにアクセスできるかどうか
  ///
  /// Returns:
  /// - Success: 全プランでアクセス可能（常に true）
  /// - Failure: [ServiceException] アクセスチェック失敗時
  Future<Result<bool>> canAccessWritingPrompts();

  /// 高度なフィルタにアクセスできるかどうか
  ///
  /// Returns:
  /// - Success: Premiumプランかつ有効な場合 true
  /// - Failure: [ServiceException] 状態サービスが未初期化の場合
  Future<Result<bool>> canAccessAdvancedFilters();

  /// 高度な分析にアクセスできるかどうか
  ///
  /// Returns:
  /// - Success: Premiumプランかつ有効な場合 true
  /// - Failure: [ServiceException] 状態サービスが未初期化の場合
  Future<Result<bool>> canAccessAdvancedAnalytics();

  /// 優先サポートにアクセスできるかどうか
  ///
  /// Returns:
  /// - Success: Premiumプランかつ有効な場合 true
  /// - Failure: [ServiceException] 状態サービスが未初期化の場合
  Future<Result<bool>> canAccessPrioritySupport();

  // ========================================
  // 購入・復元メソッド
  // ========================================

  /// In-App Purchase商品情報を取得
  ///
  /// Returns:
  /// - Success: [PurchaseProduct] リスト
  /// - Failure: [ServiceException] IAP未初期化、IAP利用不可、API取得失敗時
  Future<Result<List<PurchaseProduct>>> getProducts();

  /// 指定プランの実際の価格情報を取得
  ///
  /// Returns:
  /// - Success: [PurchaseProduct]。該当プランがない場合は null
  /// - Failure: [ServiceException] IAP未初期化、IAP利用不可、API取得失敗時
  Future<Result<PurchaseProduct?>> getProductPrice(String planId);

  /// プランを購入
  ///
  /// Returns:
  /// - Success: [PurchaseResult]（購入結果ステータス）
  /// - Failure: [ServiceException] IAP未初期化、購入処理中の重複呼び出し、
  ///   Basicプランの購入試行、購入処理失敗時
  Future<Result<PurchaseResult>> purchasePlanClass(Plan plan);

  /// 購入を復元
  ///
  /// Returns:
  /// - Success: [PurchaseResult] リスト（復元された購入情報）
  /// - Failure: [ServiceException] IAP未初期化、IAP利用不可時
  Future<Result<List<PurchaseResult>>> restorePurchases();

  /// 購入状態を検証
  ///
  /// Returns:
  /// - Success: 有効な購入の場合 true
  /// - Failure: [ServiceException] IAP未初期化、ステータス取得失敗時
  Future<Result<bool>> validatePurchase(String transactionId);

  /// プランを変更
  ///
  /// Returns:
  /// - Success: void（変更完了）
  /// - Failure: [ServiceException] 未実装機能のため常にFailure
  Future<Result<void>> changePlanClass(Plan newPlan);

  /// サブスクリプションをキャンセル
  ///
  /// Returns:
  /// - Success: void（キャンセル完了）
  /// - Failure: [ServiceException] IAP未初期化、ステータス更新失敗時
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
