import '../core/result/result.dart';
import '../models/subscription_status.dart';
import '../models/plans/plan.dart';
import 'interfaces/subscription_service_interface.dart';
import 'interfaces/subscription_state_service_interface.dart';
import 'interfaces/ai_usage_service_interface.dart';
import 'interfaces/feature_access_service_interface.dart';
import 'interfaces/in_app_purchase_service_interface.dart';

/// SubscriptionService（Facade）
///
/// 後方互換性のためのFacade実装。
/// 内部的に4つの分割サービスへ委譲する。
///
/// - ISubscriptionStateService: 状態永続化、プラン情報取得
/// - IAiUsageService: AI生成使用量追跡
/// - IFeatureAccessService: 機能アクセス権限チェック
/// - IInAppPurchaseService: In-App Purchase処理
class SubscriptionService implements ISubscriptionService {
  final ISubscriptionStateService _stateService;
  final IAiUsageService _usageService;
  final IFeatureAccessService _accessService;
  final IInAppPurchaseService _purchaseService;

  SubscriptionService({
    required ISubscriptionStateService stateService,
    required IAiUsageService usageService,
    required IFeatureAccessService accessService,
    required IInAppPurchaseService purchaseService,
  }) : _stateService = stateService,
       _usageService = usageService,
       _accessService = accessService,
       _purchaseService = purchaseService;

  // ========================================
  // 基本的なサービスメソッド → ISubscriptionStateService
  // ========================================

  @override
  Future<Result<void>> initialize() async => const Success(null);

  @override
  bool get isInitialized => _stateService.isInitialized;

  @override
  Future<Result<SubscriptionStatus>> getCurrentStatus() =>
      _stateService.getCurrentStatus();

  @override
  Future<Result<void>> refreshStatus() => _stateService.refreshStatus();

  // ========================================
  // プラン管理メソッド → ISubscriptionStateService
  // ========================================

  @override
  Result<Plan> getPlanClass(String planId) =>
      _stateService.getPlanClass(planId);

  @override
  Future<Result<Plan>> getCurrentPlanClass() =>
      _stateService.getCurrentPlanClass();

  // ========================================
  // 使用量管理メソッド → IAiUsageService
  // ========================================

  @override
  Future<Result<bool>> canUseAiGeneration() =>
      _usageService.canUseAiGeneration();

  @override
  Future<Result<void>> incrementAiUsage() => _usageService.incrementAiUsage();

  @override
  Future<Result<int>> getRemainingGenerations() =>
      _usageService.getRemainingGenerations();

  @override
  Future<Result<int>> getMonthlyUsage() => _usageService.getMonthlyUsage();

  @override
  Future<Result<void>> resetUsage() => _usageService.resetUsage();

  @override
  Future<void> resetMonthlyUsageIfNeeded() =>
      _usageService.resetMonthlyUsageIfNeeded();

  @override
  Future<Result<DateTime>> getNextResetDate() =>
      _usageService.getNextResetDate();

  // ========================================
  // アクセス権限チェックメソッド → IFeatureAccessService
  // ========================================

  @override
  Future<Result<bool>> canAccessPremiumFeatures() =>
      _accessService.canAccessPremiumFeatures();

  @override
  Future<Result<bool>> canAccessWritingPrompts() =>
      _accessService.canAccessWritingPrompts();

  @override
  Future<Result<bool>> canAccessAdvancedFilters() =>
      _accessService.canAccessAdvancedFilters();

  @override
  Future<Result<bool>> canAccessAdvancedAnalytics() =>
      _accessService.canAccessAdvancedAnalytics();

  @override
  Future<Result<bool>> canAccessPrioritySupport() =>
      _accessService.canAccessPrioritySupport();

  // ========================================
  // 購入・復元メソッド → IInAppPurchaseService
  // ========================================

  @override
  Future<Result<List<PurchaseProduct>>> getProducts() =>
      _purchaseService.getProducts();

  @override
  Future<Result<PurchaseProduct?>> getProductPrice(String planId) =>
      _purchaseService.getProductPrice(planId);

  @override
  Future<Result<PurchaseResult>> purchasePlanClass(Plan plan) =>
      _purchaseService.purchasePlan(plan);

  @override
  Future<Result<List<PurchaseResult>>> restorePurchases() =>
      _purchaseService.restorePurchases();

  @override
  Future<Result<bool>> validatePurchase(String transactionId) =>
      _purchaseService.validatePurchase(transactionId);

  @override
  Future<Result<void>> changePlanClass(Plan newPlan) =>
      _purchaseService.changePlan(newPlan);

  @override
  Future<Result<void>> cancelSubscription() =>
      _purchaseService.cancelSubscription();

  // ========================================
  // 状態監視・通知
  // ========================================

  @override
  Stream<SubscriptionStatus> get statusStream => _stateService.statusStream;

  @override
  Stream<PurchaseResult> get purchaseStream => _purchaseService.purchaseStream;

  @override
  Future<void> dispose() async {
    await _stateService.dispose();
    await _purchaseService.dispose();
  }
}
