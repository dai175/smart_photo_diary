import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/models/plans/plan.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/plan_factory.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import 'package:smart_photo_diary/services/logging_service.dart';

/// MockSubscriptionStatusManager
///
/// テスト用のSubscriptionStatusManagerモック実装
///
/// ## 主な機能
/// - 完全なメモリベース実装でHive依存を排除
/// - テストシナリオ用の設定可能な状態管理
/// - 全公開メソッドの完全実装
/// - エラーシミュレーション機能
/// - サブスクリプション状態の追跡
///
/// ## 設計原則
/// - SubscriptionStatusManagerの公開APIを完全に模倣
/// - 各メソッドの成功・失敗パターンを設定可能
/// - テスト用のヘルパーメソッドを豊富に提供
class MockSubscriptionStatusManager {
  // =================================================================
  // 内部状態管理
  // =================================================================

  bool _isInitialized = false;
  SubscriptionStatus? _currentStatus;
  // ignore: unused_field
  LoggingService? _loggingService; // APIの互換性のため保持、モック内では実際のログ出力は行わない

  // エラーシミュレーション設定
  bool _shouldFailGetCurrentStatus = false;
  bool _shouldFailUpdateStatus = false;
  bool _shouldFailRefreshStatus = false;
  bool _shouldFailCreateStatus = false;
  bool _shouldFailClearStatus = false;
  bool _shouldFailGetPlanClass = false;
  bool _shouldFailGetCurrentPlanClass = false;
  bool _shouldFailCanAccessPremiumFeatures = false;
  String? _forcedErrorMessage;

  // =================================================================
  // コンストラクタ
  // =================================================================

  MockSubscriptionStatusManager({
    SubscriptionStatus? initialStatus,
  }) : _currentStatus = initialStatus {
    _isInitialized = true;
    _initializeDefaultState();
  }

  /// デフォルト状態の初期化
  void _initializeDefaultState() {
    if (_currentStatus == null) {
      final basicPlan = BasicPlan();
      final now = DateTime.now();
      
      _currentStatus = SubscriptionStatus(
        planId: basicPlan.id,
        isActive: true,
        startDate: now,
        expiryDate: null,
        autoRenewal: false,
        monthlyUsageCount: 0,
        lastResetDate: now,
        transactionId: '',
        lastPurchaseDate: null,
      );
    }
  }

  // =================================================================
  // テスト設定メソッド
  // =================================================================

  /// テスト用: getCurrentStatus失敗を設定
  void setGetCurrentStatusFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailGetCurrentStatus = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: updateStatus失敗を設定
  void setUpdateStatusFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailUpdateStatus = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: refreshStatus失敗を設定
  void setRefreshStatusFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailRefreshStatus = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: createStatus失敗を設定
  void setCreateStatusFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailCreateStatus = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: clearStatus失敗を設定
  void setClearStatusFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailClearStatus = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: getPlanClass失敗を設定
  void setGetPlanClassFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailGetPlanClass = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: getCurrentPlanClass失敗を設定
  void setGetCurrentPlanClassFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailGetCurrentPlanClass = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: canAccessPremiumFeatures失敗を設定
  void setCanAccessPremiumFeaturesFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailCanAccessPremiumFeatures = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: 現在の状態を設定
  void setCurrentStatus(SubscriptionStatus status) {
    _currentStatus = status;
  }

  /// テスト用: プランを設定
  void setCurrentPlan(Plan plan) {
    final now = DateTime.now();
    
    DateTime? expiryDate;
    if (plan.id == SubscriptionConstants.premiumMonthlyPlanId) {
      expiryDate = now.add(const Duration(days: 30));
    } else if (plan.id == SubscriptionConstants.premiumYearlyPlanId) {
      expiryDate = now.add(const Duration(days: 365));
    }

    _currentStatus = SubscriptionStatus(
      planId: plan.id,
      isActive: true,
      startDate: now,
      expiryDate: expiryDate,
      autoRenewal: plan.id != SubscriptionConstants.basicPlanId,
      monthlyUsageCount: _currentStatus?.monthlyUsageCount ?? 0,
      lastResetDate: _currentStatus?.lastResetDate ?? now,
      transactionId: plan.id == SubscriptionConstants.basicPlanId
          ? ''
          : 'mock_transaction_${now.millisecondsSinceEpoch}',
      lastPurchaseDate: plan.id == SubscriptionConstants.basicPlanId 
          ? null 
          : now,
    );
  }

  /// テスト用: 初期化状態を設定
  void setInitialized(bool isInitialized) {
    _isInitialized = isInitialized;
  }

  /// テスト用: 状態をリセット
  void resetToDefaults() {
    _isInitialized = true;
    _currentStatus = null;
    _loggingService = null;
    _shouldFailGetCurrentStatus = false;
    _shouldFailUpdateStatus = false;
    _shouldFailRefreshStatus = false;
    _shouldFailCreateStatus = false;
    _shouldFailClearStatus = false;
    _shouldFailGetPlanClass = false;
    _shouldFailGetCurrentPlanClass = false;
    _shouldFailCanAccessPremiumFeatures = false;
    _forcedErrorMessage = null;
    _initializeDefaultState();
  }

  // =================================================================
  // エラーハンドリングヘルパー
  // =================================================================

  Result<T> _simulateError<T>(String operation) {
    final message = _forcedErrorMessage ?? 'Mock error in $operation';
    return Failure(
      ServiceException(message, details: 'Simulated error for testing'),
    );
  }

  // =================================================================
  // 公開API実装
  // =================================================================

  /// 初期化済みかどうか
  bool get isInitialized => _isInitialized;

  /// 現在のサブスクリプション状態を取得
  Future<Result<SubscriptionStatus>> getCurrentStatus() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('StatusManager is not initialized'),
      );
    }

    if (_shouldFailGetCurrentStatus) {
      return _simulateError('getCurrentStatus');
    }

    await Future.delayed(const Duration(milliseconds: 50)); // 非同期処理をシミュレート

    if (_currentStatus == null) {
      _initializeDefaultState();
    }

    return Success(_currentStatus!);
  }

  /// サブスクリプション状態を更新
  Future<Result<void>> updateStatus(SubscriptionStatus status) async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('StatusManager is not initialized'),
      );
    }

    if (_shouldFailUpdateStatus) {
      return _simulateError('updateStatus');
    }

    await Future.delayed(const Duration(milliseconds: 30)); // 更新処理をシミュレート

    _currentStatus = status;
    return const Success(null);
  }

  /// サブスクリプション状態をリロード
  Future<Result<void>> refreshStatus() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('StatusManager is not initialized'),
      );
    }

    if (_shouldFailRefreshStatus) {
      return _simulateError('refreshStatus');
    }

    await Future.delayed(const Duration(milliseconds: 30)); // リフレッシュ処理をシミュレート

    // 現在の状態を再取得（モックでは何もしない）
    return const Success(null);
  }

  /// 指定されたプランでサブスクリプション状態を作成
  Future<Result<SubscriptionStatus>> createStatus(Plan plan) async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('StatusManager is not initialized'),
      );
    }

    if (_shouldFailCreateStatus) {
      return _simulateError('createStatus');
    }

    await Future.delayed(const Duration(milliseconds: 50)); // 作成処理をシミュレート

    final now = DateTime.now();

    // プランに応じた有効期限を設定
    DateTime? expiryDate;
    if (plan.id == SubscriptionConstants.premiumMonthlyPlanId) {
      expiryDate = now.add(const Duration(days: 30));
    } else if (plan.id == SubscriptionConstants.premiumYearlyPlanId) {
      expiryDate = now.add(const Duration(days: 365));
    }

    // 新しいサブスクリプション状態を作成
    final newStatus = SubscriptionStatus(
      planId: plan.id,
      isActive: true,
      startDate: now,
      expiryDate: expiryDate,
      autoRenewal: plan.id != SubscriptionConstants.basicPlanId,
      monthlyUsageCount: 0,
      lastResetDate: now,
      transactionId: plan.id == SubscriptionConstants.basicPlanId
          ? ''
          : 'created_${now.millisecondsSinceEpoch}',
      lastPurchaseDate: plan.id == SubscriptionConstants.basicPlanId 
          ? null 
          : now,
    );

    _currentStatus = newStatus;
    return Success(newStatus);
  }

  /// サブスクリプション状態を削除
  Future<Result<void>> clearStatus() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('StatusManager is not initialized'),
      );
    }

    if (_shouldFailClearStatus) {
      return _simulateError('clearStatus');
    }

    await Future.delayed(const Duration(milliseconds: 30)); // 削除処理をシミュレート

    _currentStatus = null;
    return const Success(null);
  }

  /// 特定のプラン情報を取得
  Result<Plan> getPlanClass(String planId) {
    if (_shouldFailGetPlanClass) {
      return _simulateError('getPlanClass');
    }

    try {
      final plan = PlanFactory.createPlan(planId);
      return Success(plan);
    } catch (e) {
      return Failure(ServiceException('Invalid plan ID: $planId'));
    }
  }

  /// 現在のプランを取得
  Future<Result<Plan>> getCurrentPlanClass() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('StatusManager is not initialized'),
      );
    }

    if (_shouldFailGetCurrentPlanClass) {
      return _simulateError('getCurrentPlanClass');
    }

    await Future.delayed(const Duration(milliseconds: 30)); // プラン取得処理をシミュレート

    // 現在の状態を取得
    final statusResult = await getCurrentStatus();
    if (statusResult.isFailure) {
      return Failure(statusResult.error);
    }

    final status = statusResult.value;
    
    // プラン情報を取得
    final planResult = getPlanClass(status.planId);
    if (planResult.isFailure) {
      return Failure(planResult.error);
    }

    return Success(planResult.value);
  }

  /// 強制プラン名からプランIDを取得（デバッグ用）
  String getForcedPlanId(String forcePlan) {
    switch (forcePlan.toLowerCase()) {
      case 'premium':
      case 'premium_monthly':
        return SubscriptionConstants.premiumMonthlyPlanId;
      case 'premium_yearly':
        return SubscriptionConstants.premiumYearlyPlanId;
      case 'basic':
      default:
        return SubscriptionConstants.basicPlanId;
    }
  }

  /// サブスクリプションが有効かどうかをチェック
  bool isSubscriptionValid(SubscriptionStatus status) {
    if (!status.isActive) return false;

    // Basicプランは常に有効
    if (status.planId == SubscriptionConstants.basicPlanId) return true;

    // Premiumプランは有効期限をチェック
    if (status.expiryDate == null) return false;
    return DateTime.now().isBefore(status.expiryDate!);
  }

  /// プレミアム機能にアクセスできるかどうか
  Future<Result<bool>> canAccessPremiumFeatures() async {
    if (!_isInitialized) {
      return Failure(
        ServiceException('StatusManager is not initialized'),
      );
    }

    if (_shouldFailCanAccessPremiumFeatures) {
      return _simulateError('canAccessPremiumFeatures');
    }

    await Future.delayed(const Duration(milliseconds: 30)); // アクセス権限チェック処理をシミュレート

    // 現在の状態を取得
    final statusResult = await getCurrentStatus();
    if (statusResult.isFailure) {
      return Failure(statusResult.error);
    }

    final status = statusResult.value;

    // サブスクリプションの有効性をチェック
    if (!isSubscriptionValid(status)) {
      return const Success(false);
    }

    // プレミアムプランかどうかをチェック
    final isPremium = status.planId == SubscriptionConstants.premiumMonthlyPlanId ||
                     status.planId == SubscriptionConstants.premiumYearlyPlanId;

    return Success(isPremium);
  }

  // =================================================================
  // テスト用ヘルパーメソッド
  // =================================================================

  /// テスト用: 有効期限切れの状態を作成
  void createExpiredPremiumStatus() {
    final now = DateTime.now();
    final expiredDate = now.subtract(const Duration(days: 1)); // 1日前に期限切れ

    _currentStatus = SubscriptionStatus(
      planId: SubscriptionConstants.premiumMonthlyPlanId,
      isActive: true,
      startDate: now.subtract(const Duration(days: 31)),
      expiryDate: expiredDate,
      autoRenewal: true,
      monthlyUsageCount: 5,
      lastResetDate: now.subtract(const Duration(days: 31)),
      transactionId: 'expired_transaction',
      lastPurchaseDate: now.subtract(const Duration(days: 31)),
    );
  }

  /// テスト用: 非アクティブな状態を作成
  void createInactiveStatus() {
    final now = DateTime.now();

    _currentStatus = SubscriptionStatus(
      planId: SubscriptionConstants.premiumMonthlyPlanId,
      isActive: false, // 非アクティブ
      startDate: now.subtract(const Duration(days: 31)),
      expiryDate: now.add(const Duration(days: 30)),
      autoRenewal: false,
      monthlyUsageCount: 0,
      lastResetDate: now,
      transactionId: 'inactive_transaction',
      lastPurchaseDate: null,
    );
  }

  /// テスト用: カスタム使用量を設定
  void setUsageCount(int count) {
    if (_currentStatus != null) {
      _currentStatus = SubscriptionStatus(
        planId: _currentStatus!.planId,
        isActive: _currentStatus!.isActive,
        startDate: _currentStatus!.startDate,
        expiryDate: _currentStatus!.expiryDate,
        autoRenewal: _currentStatus!.autoRenewal,
        monthlyUsageCount: count,
        lastResetDate: _currentStatus!.lastResetDate,
        transactionId: _currentStatus!.transactionId,
        lastPurchaseDate: _currentStatus!.lastPurchaseDate,
      );
    }
  }

  /// テスト用: カスタム有効期限を設定
  void setExpiryDate(DateTime? expiryDate) {
    if (_currentStatus != null) {
      _currentStatus = SubscriptionStatus(
        planId: _currentStatus!.planId,
        isActive: _currentStatus!.isActive,
        startDate: _currentStatus!.startDate,
        expiryDate: expiryDate,
        autoRenewal: _currentStatus!.autoRenewal,
        monthlyUsageCount: _currentStatus!.monthlyUsageCount,
        lastResetDate: _currentStatus!.lastResetDate,
        transactionId: _currentStatus!.transactionId,
        lastPurchaseDate: _currentStatus!.lastPurchaseDate,
      );
    }
  }

  // =================================================================
  // 破棄処理
  // =================================================================

  /// リソースを破棄
  void dispose() {
    _isInitialized = false;
    _currentStatus = null;
    _loggingService = null;
  }
}