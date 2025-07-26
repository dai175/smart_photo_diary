import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/models/plans/plan.dart';
import 'package:smart_photo_diary/models/plans/plan_factory.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';

/// MockSubscriptionService
///
/// テスト用のSubscriptionServiceモック実装
///
/// ## 主な機能
/// - Hiveに依存しない完全なメモリベース実装
/// - テストシナリオ用の設定可能な状態管理
/// - 全インターフェースメソッドの完全実装
/// - エラーシミュレーション機能
///
/// ## Phase 1.5.1実装内容
/// - 1.5.1.1: インターフェース完全実装
/// - 1.5.1.2: テスト用データとシナリオ管理
/// - 1.5.1.3: 基本動作とエラーケースのモック実装
class MockSubscriptionService implements ISubscriptionService {
  // =================================================================
  // 内部状態管理（Phase 1.5.1.2: テスト用データ作成）
  // =================================================================

  bool _isInitialized = false;
  String _planId = 'basic';
  bool _isActive = true;
  int _monthlyUsageCount = 0;
  DateTime? _expiryDate;
  DateTime? _startDate;
  DateTime? _lastResetDate;
  bool _autoRenewal = false;
  String? _transactionId;
  DateTime? _lastPurchaseDate;

  // テスト設定用フラグ
  bool _shouldFailInitialization = false;
  bool _shouldFailStatusRetrieval = false;
  bool _shouldFailPurchase = false;
  String? _forcedErrorMessage;

  // 購入シミュレーション用
  List<PurchaseProduct> _availableProducts = [];
  final List<PurchaseResult> _purchaseHistory = [];

  // Stream コントローラー
  final List<SubscriptionStatus> _statusUpdates = [];
  final List<PurchaseResult> _purchaseUpdates = [];

  // =================================================================
  // コンストラクタとファクトリメソッド
  // =================================================================

  MockSubscriptionService({
    String? initialPlanId,
    bool? initialIsActive,
    int? initialUsageCount,
    DateTime? initialExpiryDate,
  }) {
    _planId = initialPlanId ?? 'basic';
    _isActive = initialIsActive ?? true;
    _monthlyUsageCount = initialUsageCount ?? 0;
    _expiryDate = initialExpiryDate;
    _startDate = DateTime.now();
    _lastResetDate = DateTime.now();

    _initializeTestData();
  }

  /// テストデータの初期化
  void _initializeTestData() {
    // 利用可能な商品を設定
    _availableProducts = [
      const PurchaseProduct(
        id: 'smart_photo_diary_premium_monthly',
        title: 'Premium Monthly',
        description: 'Smart Photo Diary Premium Monthly Plan',
        price: '¥300',
        priceAmount: 300.0,
        currencyCode: 'JPY',
        plan: PremiumMonthlyPlan(),
      ),
      const PurchaseProduct(
        id: 'smart_photo_diary_premium_yearly',
        title: 'Premium Yearly',
        description: 'Smart Photo Diary Premium Yearly Plan',
        price: '¥2,800',
        priceAmount: 2800.0,
        currencyCode: 'JPY',
        plan: PremiumYearlyPlan(),
      ),
    ];
  }

  // =================================================================
  // テスト設定メソッド（Phase 1.5.1.2: テスト用データ作成）
  // =================================================================

  /// テスト用: 初期化失敗を設定
  void setInitializationFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailInitialization = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: 状態取得失敗を設定
  void setStatusRetrievalFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailStatusRetrieval = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: 購入失敗を設定
  void setPurchaseFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailPurchase = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: プランを強制設定
  void setCurrentPlan(
    Plan plan, {
    bool? isActive,
    DateTime? expiryDate,
    int? usageCount,
  }) {
    _planId = plan.id;
    _isActive = isActive ?? (plan.isPremium ? true : _isActive);
    _expiryDate =
        expiryDate ??
        (plan.isPremium ? DateTime.now().add(const Duration(days: 365)) : null);
    _monthlyUsageCount = usageCount ?? _monthlyUsageCount;

    // 状態更新をストリームに通知
    _statusUpdates.add(_currentStatus);
  }

  /// テスト用: プランクラスを直接設定（Planクラス版）
  void setCurrentPlanClass(Plan plan) {
    setCurrentPlan(plan);
  }

  /// テスト用: 使用量を設定
  void setUsageCount(int count) {
    _monthlyUsageCount = count;
    _statusUpdates.add(_currentStatus);
  }

  /// テスト用: 有効期限を設定
  void setExpiryDate(DateTime? date) {
    _expiryDate = date;
    _statusUpdates.add(_currentStatus);
  }

  /// テスト用: サブスクリプション状態を直接設定
  void setCurrentStatus(SubscriptionStatus status) {
    _planId = status.planId;
    _isActive = status.isActive;
    _monthlyUsageCount = status.monthlyUsageCount;
    _expiryDate = status.expiryDate;
    _startDate = status.startDate;
    _lastResetDate = status.lastResetDate;
    _autoRenewal = status.autoRenewal ?? false;
    _transactionId = status.transactionId;
    _lastPurchaseDate = status.lastPurchaseDate;

    // 状態更新をストリームに通知
    _statusUpdates.add(_currentStatus);
  }

  /// テスト用: 自動更新設定
  void setAutoRenewal(bool autoRenewal) {
    _autoRenewal = autoRenewal;
    _statusUpdates.add(_currentStatus);
  }

  /// テスト用: 全状態をリセット
  void resetToDefaults() {
    _isInitialized = false;
    _planId = 'basic';
    _isActive = true;
    _monthlyUsageCount = 0;
    _expiryDate = null;
    _startDate = DateTime.now();
    _lastResetDate = DateTime.now();
    _autoRenewal = false;
    _transactionId = null;
    _lastPurchaseDate = null;

    _shouldFailInitialization = false;
    _shouldFailStatusRetrieval = false;
    _shouldFailPurchase = false;
    _forcedErrorMessage = null;

    _purchaseHistory.clear();
    _statusUpdates.clear();
    _purchaseUpdates.clear();
  }

  // =================================================================
  // プライベートヘルパー
  // =================================================================

  SubscriptionStatus get _currentStatus {
    return SubscriptionStatus(
      planId: _planId,
      isActive: _isActive,
      startDate: _startDate,
      expiryDate: _expiryDate,
      monthlyUsageCount: _monthlyUsageCount,
      lastResetDate: _lastResetDate,
      autoRenewal: _autoRenewal,
      transactionId: _transactionId,
      lastPurchaseDate: _lastPurchaseDate,
    );
  }

  Result<T> _simulateError<T>(String operation) {
    final message = _forcedErrorMessage ?? 'Mock error in $operation';
    return Failure(
      ServiceException(message, details: 'Simulated error for testing'),
    );
  }

  // =================================================================
  // ISubscriptionService実装（Phase 1.5.1.1: インターフェース実装）
  // =================================================================

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<Result<void>> initialize() async {
    if (_shouldFailInitialization) {
      return _simulateError('initialize');
    }

    _isInitialized = true;
    return const Success(null);
  }

  @override
  Future<Result<SubscriptionStatus>> getCurrentStatus() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('MockSubscriptionService is not initialized'),
      );
    }

    if (_shouldFailStatusRetrieval) {
      return _simulateError('getCurrentStatus');
    }

    return Success(_currentStatus);
  }

  @override
  Future<Result<void>> refreshStatus() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('MockSubscriptionService is not initialized'),
      );
    }

    // モックでは状態をリフレッシュするだけ
    return const Success(null);
  }


  @override
  Result<List<Plan>> getAvailablePlansClass() {
    return Success([
      BasicPlan(),
      PremiumMonthlyPlan(),
      PremiumYearlyPlan(),
    ]);
  }



  @override
  Result<Plan> getPlanClass(String planId) {
    try {
      final plan = PlanFactory.createPlan(planId);
      return Success(plan);
    } catch (e) {
      return Failure(ServiceException('Invalid plan ID: $planId'));
    }
  }

  @override
  Future<Result<Plan>> getCurrentPlanClass() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('MockSubscriptionService is not initialized'),
      );
    }

    final statusResult = await getCurrentStatus();
    if (statusResult.isFailure) {
      return Failure(statusResult.error);
    }

    try {
      final plan = PlanFactory.createPlan(statusResult.value.planId);
      return Success(plan);
    } catch (e) {
      return Failure(
        ServiceException('Invalid plan ID: ${statusResult.value.planId}'),
      );
    }
  }

  // =================================================================
  // 使用量管理メソッド（Phase 1.5.1.3: 基本動作モック実装）
  // =================================================================

  @override
  Future<Result<bool>> canUseAiGeneration() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('MockSubscriptionService is not initialized'),
      );
    }

    final statusResult = await getCurrentStatus();
    if (statusResult.isFailure) {
      return Failure(statusResult.error);
    }

    final status = statusResult.value;
    return Success(status.canUseAiGeneration);
  }

  @override
  Future<Result<void>> incrementAiUsage() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('MockSubscriptionService is not initialized'),
      );
    }

    _monthlyUsageCount++;
    _statusUpdates.add(_currentStatus);
    return const Success(null);
  }

  @override
  Future<Result<int>> getRemainingGenerations() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('MockSubscriptionService is not initialized'),
      );
    }

    final statusResult = await getCurrentStatus();
    if (statusResult.isFailure) {
      return Failure(statusResult.error);
    }

    final status = statusResult.value;
    return Success(status.remainingGenerations);
  }

  @override
  Future<Result<int>> getMonthlyUsage() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('MockSubscriptionService is not initialized'),
      );
    }

    return Success(_monthlyUsageCount);
  }

  @override
  Future<Result<void>> resetUsage() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('MockSubscriptionService is not initialized'),
      );
    }

    _monthlyUsageCount = 0;
    _lastResetDate = DateTime.now();
    _statusUpdates.add(_currentStatus);
    return const Success(null);
  }

  @override
  Future<void> resetMonthlyUsageIfNeeded() async {
    // Phase 1.7.1.4: 月次リセット処理統合（モック実装）
    if (!_isInitialized) {
      return; // エラーは無視（内部メソッドのため）
    }

    final now = DateTime.now();
    if (_lastResetDate == null) {
      _lastResetDate = DateTime(now.year, now.month, 1);
      return;
    }

    // 月が変わっていたらリセット
    if (_lastResetDate!.month != now.month ||
        _lastResetDate!.year != now.year) {
      _monthlyUsageCount = 0;
      _lastResetDate = DateTime(now.year, now.month, 1);
      _statusUpdates.add(_currentStatus);
    }
  }

  @override
  Future<Result<DateTime>> getNextResetDate() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('MockSubscriptionService is not initialized'),
      );
    }

    final statusResult = await getCurrentStatus();
    if (statusResult.isFailure) {
      return Failure(statusResult.error);
    }

    final status = statusResult.value;
    return Success(status.nextResetDate);
  }

  // =================================================================
  // アクセス権限チェックメソッド
  // =================================================================

  @override
  Future<Result<bool>> canAccessPremiumFeatures() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('MockSubscriptionService is not initialized'),
      );
    }

    final statusResult = await getCurrentStatus();
    if (statusResult.isFailure) {
      return Failure(statusResult.error);
    }

    final status = statusResult.value;
    return Success(status.canAccessPremiumFeatures);
  }

  @override
  Future<Result<bool>> canAccessWritingPrompts() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('MockSubscriptionService is not initialized'),
      );
    }

    final statusResult = await getCurrentStatus();
    if (statusResult.isFailure) {
      return Failure(statusResult.error);
    }

    final status = statusResult.value;
    return Success(status.canAccessWritingPrompts);
  }

  @override
  Future<Result<bool>> canAccessAdvancedFilters() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('MockSubscriptionService is not initialized'),
      );
    }

    final statusResult = await getCurrentStatus();
    if (statusResult.isFailure) {
      return Failure(statusResult.error);
    }

    final status = statusResult.value;
    return Success(status.canAccessAdvancedFilters);
  }

  @override
  Future<Result<bool>> canAccessAdvancedAnalytics() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('MockSubscriptionService is not initialized'),
      );
    }

    final statusResult = await getCurrentStatus();
    if (statusResult.isFailure) {
      return Failure(statusResult.error);
    }

    final status = statusResult.value;
    return Success(status.canAccessAdvancedAnalytics);
  }

  @override
  Future<Result<bool>> canAccessPrioritySupport() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('MockSubscriptionService is not initialized'),
      );
    }

    final statusResult = await getCurrentStatus();
    if (statusResult.isFailure) {
      return Failure(statusResult.error);
    }

    final status = statusResult.value;
    final planResult = getPlanClass(status.planId);
    if (planResult.isFailure) {
      return Failure(planResult.error);
    }
    return Success(planResult.value.hasPrioritySupport);
  }

  // =================================================================
  // 購入・復元メソッド（Phase 1.6機能のモック実装）
  // =================================================================

  @override
  Future<Result<List<PurchaseProduct>>> getProducts() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('MockSubscriptionService is not initialized'),
      );
    }

    return Success(_availableProducts);
  }


  @override
  Future<Result<List<PurchaseResult>>> restorePurchases() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('MockSubscriptionService is not initialized'),
      );
    }

    return Success(_purchaseHistory);
  }

  @override
  Future<Result<bool>> validatePurchase(String transactionId) async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('MockSubscriptionService is not initialized'),
      );
    }

    // トランザクションIDが履歴に存在するかチェック
    final isValid = _purchaseHistory.any(
      (purchase) => purchase.transactionId == transactionId,
    );

    return Success(isValid);
  }


  @override
  Future<Result<PurchaseResult>> purchasePlanClass(Plan plan) async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('MockSubscriptionService is not initialized'),
      );
    }

    if (_shouldFailPurchase) {
      final result = PurchaseResult(
        status: PurchaseStatus.error,
        errorMessage: _forcedErrorMessage ?? 'Mock purchase failure',
      );
      _purchaseUpdates.add(result);
      return Success(result);
    }

    // 成功した購入をシミュレート
    final transactionId =
        'mock_transaction_${DateTime.now().millisecondsSinceEpoch}';
    final purchaseDate = DateTime.now();

    final result = PurchaseResult(
      status: PurchaseStatus.purchased,
      productId: plan.productId,
      transactionId: transactionId,
      purchaseDate: purchaseDate,
      plan: null, // V2では使用しない
    );

    // 状態を更新
    _planId = plan.id;
    _isActive = true;
    _autoRenewal = true;
    _transactionId = transactionId;
    _lastPurchaseDate = purchaseDate;

    if (plan.isPremium) {
      _expiryDate = plan.isYearly
          ? purchaseDate.add(const Duration(days: 365))
          : purchaseDate.add(const Duration(days: 30));
    }

    // 履歴に記録
    _purchaseHistory.add(result);
    _purchaseUpdates.add(result);
    _statusUpdates.add(_currentStatus);

    return Success(result);
  }

  @override
  Future<Result<void>> changePlanClass(Plan newPlan) async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('MockSubscriptionService is not initialized'),
      );
    }

    // プラン変更をシミュレート
    setCurrentPlan(newPlan);

    return const Success(null);
  }

  @override
  Future<Result<void>> cancelSubscription() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('MockSubscriptionService is not initialized'),
      );
    }

    // キャンセル処理をシミュレート
    _planId = 'basic';
    _isActive = false;
    _expiryDate = null;
    _autoRenewal = false;
    _transactionId = null;

    _statusUpdates.add(_currentStatus);

    return const Success(null);
  }

  // =================================================================
  // 状態監視・通知
  // =================================================================

  @override
  Stream<SubscriptionStatus> get statusStream {
    return Stream.fromIterable(_statusUpdates);
  }

  @override
  Stream<PurchaseResult> get purchaseStream {
    return Stream.fromIterable(_purchaseUpdates);
  }

  @override
  Future<void> dispose() async {
    _statusUpdates.clear();
    _purchaseUpdates.clear();
    _isInitialized = false;
  }
}
