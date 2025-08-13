import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/models/plans/plan.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';
import '../integration/mocks/mock_services.dart';
import '../mocks/mock_subscription_purchase_manager.dart';
import '../mocks/mock_subscription_status_manager.dart';
import '../mocks/mock_subscription_usage_tracker.dart';
import '../mocks/mock_subscription_access_control_manager.dart';

/// サブスクリプション関連テスト専用ヘルパー
///
/// ## 主な機能
/// - サブスクリプション状態の簡易セットアップ
/// - プラン固有のテストシナリオ設定
/// - サブスクリプション関連アサーション
/// - 使用量・権限テスト用ヘルパー
///
/// ## 設計原則
/// - サブスクリプションテストの標準化
/// - 複雑なセットアップの簡略化
/// - テストシナリオの再利用促進
class SubscriptionTestHelpers {
  // =================================================================
  // 基本的なプラン・状態作成
  // =================================================================

  /// Basicプランの状態を作成
  static SubscriptionStatus createBasicPlanStatus({
    int usageCount = 0,
    DateTime? lastResetDate,
    bool isActive = true,
  }) {
    final now = DateTime.now();
    return SubscriptionStatus(
      planId: SubscriptionConstants.basicPlanId,
      isActive: isActive,
      startDate: now,
      expiryDate: null,
      autoRenewal: false,
      monthlyUsageCount: usageCount,
      lastResetDate: lastResetDate ?? now,
      transactionId: '',
      lastPurchaseDate: null,
    );
  }

  /// Premium Monthly プランの状態を作成
  static SubscriptionStatus createPremiumMonthlyStatus({
    int usageCount = 0,
    DateTime? startDate,
    DateTime? expiryDate,
    bool isActive = true,
    bool autoRenewal = true,
    String? transactionId,
  }) {
    final now = DateTime.now();
    final start = startDate ?? now;
    final expiry = expiryDate ?? start.add(const Duration(days: 30));

    return SubscriptionStatus(
      planId: SubscriptionConstants.premiumMonthlyPlanId,
      isActive: isActive,
      startDate: start,
      expiryDate: expiry,
      autoRenewal: autoRenewal,
      monthlyUsageCount: usageCount,
      lastResetDate: start,
      transactionId:
          transactionId ?? 'premium_monthly_${now.millisecondsSinceEpoch}',
      lastPurchaseDate: start,
    );
  }

  /// Premium Yearly プランの状態を作成
  static SubscriptionStatus createPremiumYearlyStatus({
    int usageCount = 0,
    DateTime? startDate,
    DateTime? expiryDate,
    bool isActive = true,
    bool autoRenewal = true,
    String? transactionId,
  }) {
    final now = DateTime.now();
    final start = startDate ?? now;
    final expiry = expiryDate ?? start.add(const Duration(days: 365));

    return SubscriptionStatus(
      planId: SubscriptionConstants.premiumYearlyPlanId,
      isActive: isActive,
      startDate: start,
      expiryDate: expiry,
      autoRenewal: autoRenewal,
      monthlyUsageCount: usageCount,
      lastResetDate: start,
      transactionId:
          transactionId ?? 'premium_yearly_${now.millisecondsSinceEpoch}',
      lastPurchaseDate: start,
    );
  }

  // =================================================================
  // 特定シナリオの状態作成
  // =================================================================

  /// 有効期限切れのプレミアム状態を作成
  static SubscriptionStatus createExpiredPremiumStatus({
    String planId = SubscriptionConstants.premiumMonthlyPlanId,
    int daysExpired = 1,
  }) {
    final now = DateTime.now();
    final expiredDate = now.subtract(Duration(days: daysExpired));
    final startDate = expiredDate.subtract(const Duration(days: 30));

    return SubscriptionStatus(
      planId: planId,
      isActive: true,
      startDate: startDate,
      expiryDate: expiredDate,
      autoRenewal: true,
      monthlyUsageCount: 5,
      lastResetDate: startDate,
      transactionId: 'expired_transaction',
      lastPurchaseDate: startDate,
    );
  }

  /// 非アクティブなサブスクリプション状態を作成
  static SubscriptionStatus createInactiveStatus({
    String planId = SubscriptionConstants.premiumMonthlyPlanId,
  }) {
    final now = DateTime.now();

    return SubscriptionStatus(
      planId: planId,
      isActive: false,
      startDate: now.subtract(const Duration(days: 31)),
      expiryDate: now.add(const Duration(days: 30)),
      autoRenewal: false,
      monthlyUsageCount: 0,
      lastResetDate: now,
      transactionId: 'inactive_transaction',
      lastPurchaseDate: null,
    );
  }

  /// 使用制限に達した状態を作成
  static SubscriptionStatus createUsageLimitReachedStatus(Plan plan) {
    if (plan.id == SubscriptionConstants.basicPlanId) {
      return createBasicPlanStatus(usageCount: plan.monthlyAiGenerationLimit);
    } else if (plan.id == SubscriptionConstants.premiumMonthlyPlanId) {
      return createPremiumMonthlyStatus(
        usageCount: plan.monthlyAiGenerationLimit,
      );
    } else if (plan.id == SubscriptionConstants.premiumYearlyPlanId) {
      return createPremiumYearlyStatus(
        usageCount: plan.monthlyAiGenerationLimit,
      );
    }
    throw ArgumentError('Unsupported plan: ${plan.id}');
  }

  // =================================================================
  // Mock Serviceの簡易セットアップ
  // =================================================================

  /// SubscriptionServiceをBasicプランでセットアップ
  static MockSubscriptionServiceInterface setupBasicPlanService({
    int usageCount = 0,
  }) {
    final mock = TestServiceSetup.getBasicPlanSubscriptionService(
      usageCount: usageCount,
    );
    return mock;
  }

  /// SubscriptionServiceをPremiumプランでセットアップ
  static MockSubscriptionServiceInterface setupPremiumPlanService({
    bool isYearly = true,
    int usageCount = 0,
  }) {
    final mock = TestServiceSetup.getPremiumPlanSubscriptionService(
      isYearly: isYearly,
      usageCount: usageCount,
    );
    return mock;
  }

  /// 使用制限に達したSubscriptionServiceをセットアップ
  static MockSubscriptionServiceInterface setupUsageLimitReachedService(
    Plan plan,
  ) {
    final mock = MockSubscriptionServiceInterface();
    TestServiceSetup.configureSubscriptionServiceForPlan(
      mock,
      plan,
      usageCount: plan.monthlyAiGenerationLimit,
    );
    return mock;
  }

  // =================================================================
  // Manager統合セットアップ
  // =================================================================

  /// Basicプラン用のマネージャー統合セットアップ
  static ManagerIntegratedSetup setupBasicPlanManagers({
    int usageCount = 0,
    bool enableErrors = false,
  }) {
    final plan = BasicPlan();
    final status = createBasicPlanStatus(usageCount: usageCount);

    return _createManagerSetup(plan, status, enableErrors);
  }

  /// Premiumプラン用のマネージャー統合セットアップ
  static ManagerIntegratedSetup setupPremiumPlanManagers({
    bool isYearly = true,
    int usageCount = 0,
    bool enableErrors = false,
  }) {
    final plan = isYearly ? PremiumYearlyPlan() : PremiumMonthlyPlan();
    final status = isYearly
        ? createPremiumYearlyStatus(usageCount: usageCount)
        : createPremiumMonthlyStatus(usageCount: usageCount);

    return _createManagerSetup(plan, status, enableErrors);
  }

  /// 期限切れプレミアムプラン用のマネージャーセットアップ
  static ManagerIntegratedSetup setupExpiredPremiumManagers({
    bool isYearly = true,
    int daysExpired = 1,
  }) {
    final plan = isYearly ? PremiumYearlyPlan() : PremiumMonthlyPlan();
    final status = createExpiredPremiumStatus(
      planId: plan.id,
      daysExpired: daysExpired,
    );

    return _createManagerSetup(plan, status, false);
  }

  static ManagerIntegratedSetup _createManagerSetup(
    Plan plan,
    SubscriptionStatus status,
    bool enableErrors,
  ) {
    // Purchase Manager
    final purchaseManager = MockSubscriptionPurchaseManager();
    if (enableErrors) {
      purchaseManager.setPurchaseFailure(true, 'Test purchase error');
    }

    // Status Manager
    final statusManager = MockSubscriptionStatusManager();
    statusManager.setCurrentPlan(plan);
    if (enableErrors) {
      statusManager.setGetCurrentStatusFailure(true, 'Test status error');
    }

    // Usage Tracker
    final usageTracker = MockSubscriptionUsageTracker();
    usageTracker.setCurrentStatus(status);
    if (enableErrors) {
      usageTracker.setCanUseAiGenerationFailure(true, 'Test usage error');
    }

    // Access Control Manager
    final accessControlManager = MockSubscriptionAccessControlManager();
    if (plan.isPremium) {
      accessControlManager.createPremiumFullAccessState();
    } else {
      accessControlManager.createBasicRestrictedState();
    }
    if (enableErrors) {
      accessControlManager.setCanAccessPremiumFeaturesFailure(
        true,
        'Test access error',
      );
    }

    return ManagerIntegratedSetup(
      plan: plan,
      status: status,
      purchaseManager: purchaseManager,
      statusManager: statusManager,
      usageTracker: usageTracker,
      accessControlManager: accessControlManager,
    );
  }

  // =================================================================
  // サブスクリプション関連アサーション
  // =================================================================

  /// サブスクリプション状態の基本情報をアサーション
  static void assertSubscriptionStatus(
    SubscriptionStatus actual,
    SubscriptionStatus expected,
  ) {
    expect(actual.planId, equals(expected.planId));
    expect(actual.isActive, equals(expected.isActive));
    expect(actual.autoRenewal, equals(expected.autoRenewal));
    expect(actual.monthlyUsageCount, equals(expected.monthlyUsageCount));
  }

  /// プランの使用可能AI生成回数をアサーション
  static void assertAiGenerationLimits(
    Plan plan,
    int currentUsage,
    int expectedRemaining,
  ) {
    final actualRemaining = plan.monthlyAiGenerationLimit - currentUsage;
    expect(actualRemaining, equals(expectedRemaining));
    expect(
      actualRemaining >= 0,
      isTrue,
      reason: 'Remaining generations should not be negative',
    );
  }

  /// プレミアム機能へのアクセス権をアサーション
  static void assertPremiumFeatureAccess(
    Plan plan,
    bool expectedWritingPrompts,
    bool expectedAdvancedFilters,
    bool expectedAdvancedAnalytics,
  ) {
    expect(plan.hasWritingPrompts, equals(expectedWritingPrompts));
    expect(plan.hasAdvancedFilters, equals(expectedAdvancedFilters));
    expect(plan.hasAdvancedAnalytics, equals(expectedAdvancedAnalytics));
  }

  /// サブスクリプションの有効性をアサーション
  static void assertSubscriptionValidity(
    SubscriptionStatus status,
    bool expectedValid,
  ) {
    bool isValid = status.isActive;

    if (status.expiryDate != null) {
      isValid = isValid && DateTime.now().isBefore(status.expiryDate!);
    }

    expect(isValid, equals(expectedValid));
  }

  // =================================================================
  // テスト用データファクトリ
  // =================================================================

  /// テスト用の購入履歴を作成
  static List<PurchaseResult> createPurchaseHistory(int count) {
    return List.generate(count, (index) {
      final now = DateTime.now().subtract(Duration(days: index));
      return PurchaseResult(
        status: PurchaseStatus.purchased,
        productId: 'test_product_$index',
        transactionId: 'test_transaction_$index',
        purchaseDate: now,
      );
    });
  }

  /// テスト用の商品リストを作成
  static List<PurchaseProduct> createTestProducts() {
    return [
      PurchaseProduct(
        id: SubscriptionConstants.premiumMonthlyProductId,
        title: 'Premium Monthly Test',
        description: 'Test Premium Monthly Plan',
        price: '¥300',
        priceAmount: 300.0,
        currencyCode: 'JPY',
        plan: PremiumMonthlyPlan(),
      ),
      PurchaseProduct(
        id: SubscriptionConstants.premiumYearlyProductId,
        title: 'Premium Yearly Test',
        description: 'Test Premium Yearly Plan',
        price: '¥2,800',
        priceAmount: 2800.0,
        currencyCode: 'JPY',
        plan: PremiumYearlyPlan(),
      ),
    ];
  }

  // =================================================================
  // 統合テスト用便利メソッド
  // =================================================================

  /// プラン変更シナリオのテスト
  static Future<void> testPlanChangeScenario({
    required Plan fromPlan,
    required Plan toPlan,
    required Future<void> Function(Plan from, Plan to) testOperation,
  }) async {
    await testOperation(fromPlan, toPlan);
  }

  /// 使用量リセットシナリオのテスト
  static Future<void> testUsageResetScenario({
    required Plan plan,
    required int initialUsage,
    required Future<void> Function(Plan plan, int usage) testOperation,
  }) async {
    await testOperation(plan, initialUsage);
  }

  /// エラーリカバリシナリオのテスト
  static Future<void> testErrorRecoveryScenario({
    required String errorType,
    required Future<void> Function() setupError,
    required Future<void> Function() testRecovery,
  }) async {
    await setupError();
    await testRecovery();
  }
}

/// マネージャー統合セットアップ用のデータクラス
class ManagerIntegratedSetup {
  final Plan plan;
  final SubscriptionStatus status;
  final MockSubscriptionPurchaseManager purchaseManager;
  final MockSubscriptionStatusManager statusManager;
  final MockSubscriptionUsageTracker usageTracker;
  final MockSubscriptionAccessControlManager accessControlManager;

  const ManagerIntegratedSetup({
    required this.plan,
    required this.status,
    required this.purchaseManager,
    required this.statusManager,
    required this.usageTracker,
    required this.accessControlManager,
  });

  /// 全マネージャーをリセット
  void resetAll() {
    purchaseManager.resetToDefaults();
    statusManager.resetToDefaults();
    usageTracker.resetToDefaults();
    accessControlManager.resetToDefaults();
  }

  /// 全マネージャーのリソースを破棄
  Future<void> dispose() async {
    await purchaseManager.dispose();
    statusManager.dispose();
    usageTracker.dispose();
    accessControlManager.dispose();
  }

  /// エラーシナリオを有効化
  void enableAllErrors([String? errorMessage]) {
    final message = errorMessage ?? 'Integrated test error';
    purchaseManager.setPurchaseFailure(true, message);
    statusManager.setGetCurrentStatusFailure(true, message);
    usageTracker.setCanUseAiGenerationFailure(true, message);
    accessControlManager.setCanAccessPremiumFeaturesFailure(true, message);
  }

  /// エラーシナリオを無効化
  void disableAllErrors() {
    purchaseManager.resetToDefaults();
    statusManager.resetToDefaults();
    usageTracker.resetToDefaults();
    accessControlManager.resetToDefaults();

    // 再度プランと状態を設定
    statusManager.setCurrentPlan(plan);
    usageTracker.setCurrentStatus(status);
    if (plan.isPremium) {
      accessControlManager.createPremiumFullAccessState();
    } else {
      accessControlManager.createBasicRestrictedState();
    }
  }
}
