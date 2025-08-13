import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/models/plans/plan_factory.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';

/// MockSubscriptionUsageTracker
///
/// テスト用のSubscriptionUsageTrackerモック実装
///
/// ## 主な機能
/// - 完全なメモリベース実装でHive依存を排除
/// - テストシナリオ用の設定可能な状態管理
/// - 全公開メソッドの完全実装
/// - エラーシミュレーション機能
/// - AI使用量追跡の完全模倣
///
/// ## 設計原則
/// - SubscriptionUsageTrackerの公開APIを完全に模倣
/// - 各メソッドの成功・失敗パターンを設定可能
/// - 使用量管理とリセット機能の完全実装
/// - テスト用のヘルパーメソッドを豊富に提供
class MockSubscriptionUsageTracker {
  // =================================================================
  // 内部状態管理
  // =================================================================

  bool _isInitialized = false;
  SubscriptionStatus? _currentStatus;
  int _monthlyUsage = 0;
  DateTime _lastResetDate = DateTime.now();

  // エラーシミュレーション設定
  bool _shouldFailGetMonthlyUsage = false;
  bool _shouldFailGetRemainingGenerations = false;
  bool _shouldFailCanUseAiGeneration = false;
  bool _shouldFailIncrementAiUsage = false;
  bool _shouldFailResetUsage = false;
  bool _shouldFailGetNextResetDate = false;
  bool _shouldFailResetMonthlyUsageIfNeeded = false;
  String? _forcedErrorMessage;

  // =================================================================
  // コンストラクタ
  // =================================================================

  MockSubscriptionUsageTracker({
    SubscriptionStatus? initialStatus,
    int initialUsage = 0,
  }) : _monthlyUsage = initialUsage {
    _isInitialized = true;
    _initializeDefaultState(initialStatus);
  }

  /// デフォルト状態の初期化
  void _initializeDefaultState(SubscriptionStatus? initialStatus) {
    if (initialStatus != null) {
      _currentStatus = initialStatus;
      _monthlyUsage = initialStatus.monthlyUsageCount;
      _lastResetDate = initialStatus.lastResetDate ?? DateTime.now();
    } else {
      final now = DateTime.now();
      _currentStatus = SubscriptionStatus(
        planId: SubscriptionConstants.basicPlanId,
        isActive: true,
        startDate: now,
        expiryDate: null,
        autoRenewal: false,
        monthlyUsageCount: _monthlyUsage,
        lastResetDate: _lastResetDate,
        transactionId: '',
        lastPurchaseDate: null,
      );
    }
  }

  // =================================================================
  // テスト設定メソッド
  // =================================================================

  /// テスト用: getMonthlyUsage失敗を設定
  void setGetMonthlyUsageFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailGetMonthlyUsage = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: getRemainingGenerations失敗を設定
  void setGetRemainingGenerationsFailure(
    bool shouldFail, [
    String? errorMessage,
  ]) {
    _shouldFailGetRemainingGenerations = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: canUseAiGeneration失敗を設定
  void setCanUseAiGenerationFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailCanUseAiGeneration = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: incrementAiUsage失敗を設定
  void setIncrementAiUsageFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailIncrementAiUsage = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: resetUsage失敗を設定
  void setResetUsageFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailResetUsage = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: getNextResetDate失敗を設定
  void setGetNextResetDateFailure(bool shouldFail, [String? errorMessage]) {
    _shouldFailGetNextResetDate = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: resetMonthlyUsageIfNeeded失敗を設定
  void setResetMonthlyUsageIfNeededFailure(
    bool shouldFail, [
    String? errorMessage,
  ]) {
    _shouldFailResetMonthlyUsageIfNeeded = shouldFail;
    _forcedErrorMessage = errorMessage;
  }

  /// テスト用: 現在の状態を設定
  void setCurrentStatus(SubscriptionStatus status) {
    _currentStatus = status;
    _monthlyUsage = status.monthlyUsageCount;
    _lastResetDate = status.lastResetDate ?? DateTime.now();
  }

  /// テスト用: 初期化状態を設定
  void setInitialized(bool isInitialized) {
    _isInitialized = isInitialized;
  }

  /// テスト用: 状態をリセット
  void resetToDefaults() {
    _isInitialized = true;
    _currentStatus = null;
    _monthlyUsage = 0;
    _lastResetDate = DateTime.now();
    _shouldFailGetMonthlyUsage = false;
    _shouldFailGetRemainingGenerations = false;
    _shouldFailCanUseAiGeneration = false;
    _shouldFailIncrementAiUsage = false;
    _shouldFailResetUsage = false;
    _shouldFailGetNextResetDate = false;
    _shouldFailResetMonthlyUsageIfNeeded = false;
    _forcedErrorMessage = null;
    _initializeDefaultState(null);
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

  /// 現在のサブスクリプション状態を更新（内部用）
  void _updateCurrentStatus(SubscriptionStatus status) {
    _currentStatus = status;
    _monthlyUsage = status.monthlyUsageCount;
    _lastResetDate = status.lastResetDate ?? DateTime.now();
  }

  // =================================================================
  // プロパティアクセサー
  // =================================================================

  /// 初期化済みかどうか
  bool get isInitialized => _isInitialized;

  // =================================================================
  // 公開API実装
  // =================================================================

  /// 今月の使用量を取得
  Future<Result<int>> getMonthlyUsage() async {
    if (!_isInitialized) {
      return Failure(ServiceException('UsageTracker is not initialized'));
    }

    if (_shouldFailGetMonthlyUsage) {
      return _simulateError('getMonthlyUsage');
    }

    await Future.delayed(const Duration(milliseconds: 50)); // 非同期処理をシミュレート

    // 月次リセットをチェック
    _checkAndResetIfNeeded();

    return Success(_monthlyUsage);
  }

  /// 残りAI生成回数を取得
  Future<Result<int>> getRemainingGenerations(
    bool Function(SubscriptionStatus) isValidSubscription,
  ) async {
    if (!_isInitialized) {
      return Failure(ServiceException('UsageTracker is not initialized'));
    }

    if (_shouldFailGetRemainingGenerations) {
      return _simulateError('getRemainingGenerations');
    }

    await Future.delayed(const Duration(milliseconds: 50)); // 非同期処理をシミュレート

    if (_currentStatus == null) {
      return Failure(ServiceException('Subscription status not found'));
    }

    // サブスクリプションが有効でない場合は0
    if (!isValidSubscription(_currentStatus!)) {
      return const Success(0);
    }

    // 月次リセットをチェック
    _checkAndResetIfNeeded();

    // 残り回数を計算
    final currentPlan = PlanFactory.createPlan(_currentStatus!.planId);
    final monthlyLimit = currentPlan.monthlyAiGenerationLimit;
    final remaining = monthlyLimit - _monthlyUsage;

    return Success(remaining > 0 ? remaining : 0);
  }

  /// AI生成を使用できるかどうかをチェック
  Future<Result<bool>> canUseAiGeneration(
    SubscriptionStatus status,
    bool Function(SubscriptionStatus) isValidSubscription,
  ) async {
    if (!_isInitialized) {
      return Failure(ServiceException('UsageTracker is not initialized'));
    }

    if (_shouldFailCanUseAiGeneration) {
      return _simulateError('canUseAiGeneration');
    }

    await Future.delayed(const Duration(milliseconds: 30)); // 非同期処理をシミュレート

    // サブスクリプションが有効でない場合は使用不可
    if (!isValidSubscription(status)) {
      return const Success(false);
    }

    // 月次リセットをチェック
    _checkAndResetIfNeeded();

    // 制限チェック
    final currentPlan = PlanFactory.createPlan(status.planId);
    final monthlyLimit = currentPlan.monthlyAiGenerationLimit;

    return Success(_monthlyUsage < monthlyLimit);
  }

  /// AI生成使用量をインクリメント
  Future<Result<void>> incrementAiUsage(
    SubscriptionStatus status,
    bool Function(SubscriptionStatus) isValidSubscription,
  ) async {
    if (!_isInitialized) {
      return Failure(ServiceException('UsageTracker is not initialized'));
    }

    if (_shouldFailIncrementAiUsage) {
      return _simulateError('incrementAiUsage');
    }

    await Future.delayed(const Duration(milliseconds: 30)); // 非同期処理をシミュレート

    // サブスクリプションが有効でない場合はインクリメント不可
    if (!isValidSubscription(status)) {
      return Failure(
        ServiceException('Cannot increment usage: subscription is not valid'),
      );
    }

    // 月次リセットをチェック
    _checkAndResetIfNeeded();

    // 制限チェック
    final currentPlan = PlanFactory.createPlan(status.planId);
    final monthlyLimit = currentPlan.monthlyAiGenerationLimit;

    if (_monthlyUsage >= monthlyLimit) {
      return Failure(
        ServiceException(
          'Monthly AI generation limit reached: $_monthlyUsage/$monthlyLimit',
        ),
      );
    }

    // 使用量をインクリメント
    _monthlyUsage++;

    // 現在の状態を更新
    final updatedStatus = SubscriptionStatus(
      planId: status.planId,
      isActive: status.isActive,
      startDate: status.startDate,
      expiryDate: status.expiryDate,
      autoRenewal: status.autoRenewal,
      monthlyUsageCount: _monthlyUsage,
      lastResetDate: _lastResetDate,
      transactionId: status.transactionId,
      lastPurchaseDate: status.lastPurchaseDate,
    );

    _updateCurrentStatus(updatedStatus);

    return const Success(null);
  }

  /// 使用量を手動でリセット（管理者・テスト用）
  Future<Result<void>> resetUsage() async {
    if (!_isInitialized) {
      return Failure(ServiceException('UsageTracker is not initialized'));
    }

    if (_shouldFailResetUsage) {
      return _simulateError('resetUsage');
    }

    await Future.delayed(const Duration(milliseconds: 30)); // 非同期処理をシミュレート

    if (_currentStatus == null) {
      return Failure(ServiceException('Subscription status not found'));
    }

    // 使用量とリセット日を更新
    _monthlyUsage = 0;
    _lastResetDate = DateTime.now();

    // 現在の状態を更新
    final resetStatus = SubscriptionStatus(
      planId: _currentStatus!.planId,
      isActive: _currentStatus!.isActive,
      startDate: _currentStatus!.startDate,
      expiryDate: _currentStatus!.expiryDate,
      autoRenewal: _currentStatus!.autoRenewal,
      monthlyUsageCount: _monthlyUsage,
      lastResetDate: _lastResetDate,
      transactionId: _currentStatus!.transactionId,
      lastPurchaseDate: _currentStatus!.lastPurchaseDate,
    );

    _updateCurrentStatus(resetStatus);

    return const Success(null);
  }

  /// 次の使用量リセット日を取得
  Future<Result<DateTime>> getNextResetDate() async {
    if (!_isInitialized) {
      return Failure(ServiceException('UsageTracker is not initialized'));
    }

    if (_shouldFailGetNextResetDate) {
      return _simulateError('getNextResetDate');
    }

    await Future.delayed(const Duration(milliseconds: 30)); // 非同期処理をシミュレート

    final nextResetDate = _calculateNextResetDate(_lastResetDate);
    return Success(nextResetDate);
  }

  /// 月次使用量リセットが必要かチェックしてリセット
  Future<Result<void>> resetMonthlyUsageIfNeeded() async {
    if (!_isInitialized) {
      return Failure(ServiceException('UsageTracker is not initialized'));
    }

    if (_shouldFailResetMonthlyUsageIfNeeded) {
      return _simulateError('resetMonthlyUsageIfNeeded');
    }

    await Future.delayed(const Duration(milliseconds: 30)); // 非同期処理をシミュレート

    _checkAndResetIfNeeded();

    return const Success(null);
  }

  // =================================================================
  // 内部ヘルパーメソッド
  // =================================================================

  /// 月次リセットが必要かチェックしてリセット（内部用）
  void _checkAndResetIfNeeded() {
    final currentMonth = _getCurrentMonth();
    final resetMonth = _getUsageMonth(_lastResetDate);

    if (resetMonth != currentMonth) {
      _monthlyUsage = 0;
      _lastResetDate = DateTime.now();

      // 現在の状態も更新
      if (_currentStatus != null) {
        final updatedStatus = SubscriptionStatus(
          planId: _currentStatus!.planId,
          isActive: _currentStatus!.isActive,
          startDate: _currentStatus!.startDate,
          expiryDate: _currentStatus!.expiryDate,
          autoRenewal: _currentStatus!.autoRenewal,
          monthlyUsageCount: _monthlyUsage,
          lastResetDate: _lastResetDate,
          transactionId: _currentStatus!.transactionId,
          lastPurchaseDate: _currentStatus!.lastPurchaseDate,
        );
        _updateCurrentStatus(updatedStatus);
      }
    }
  }

  /// 現在の月を YYYY-MM 形式で取得
  String _getCurrentMonth() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
  }

  /// 指定日から使用量月を取得
  String _getUsageMonth(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
  }

  /// 次のリセット日を計算
  DateTime _calculateNextResetDate(DateTime lastResetDate) {
    final currentYear = lastResetDate.year;
    final currentMonth = lastResetDate.month;

    // 翌月の1日を計算
    if (currentMonth == 12) {
      return DateTime(currentYear + 1, 1, 1);
    } else {
      return DateTime(currentYear, currentMonth + 1, 1);
    }
  }

  // =================================================================
  // テスト用ヘルパーメソッド
  // =================================================================

  /// テスト用: 月次使用量を直接設定
  void setMonthlyUsage(int usage) {
    _monthlyUsage = usage;
    if (_currentStatus != null) {
      final updatedStatus = SubscriptionStatus(
        planId: _currentStatus!.planId,
        isActive: _currentStatus!.isActive,
        startDate: _currentStatus!.startDate,
        expiryDate: _currentStatus!.expiryDate,
        autoRenewal: _currentStatus!.autoRenewal,
        monthlyUsageCount: _monthlyUsage,
        lastResetDate: _currentStatus!.lastResetDate,
        transactionId: _currentStatus!.transactionId,
        lastPurchaseDate: _currentStatus!.lastPurchaseDate,
      );
      _updateCurrentStatus(updatedStatus);
    }
  }

  /// テスト用: カスタムリセット日を設定
  void setLastResetDate(DateTime resetDate) {
    _lastResetDate = resetDate;
    if (_currentStatus != null) {
      final updatedStatus = SubscriptionStatus(
        planId: _currentStatus!.planId,
        isActive: _currentStatus!.isActive,
        startDate: _currentStatus!.startDate,
        expiryDate: _currentStatus!.expiryDate,
        autoRenewal: _currentStatus!.autoRenewal,
        monthlyUsageCount: _currentStatus!.monthlyUsageCount,
        lastResetDate: _lastResetDate,
        transactionId: _currentStatus!.transactionId,
        lastPurchaseDate: _currentStatus!.lastPurchaseDate,
      );
      _updateCurrentStatus(updatedStatus);
    }
  }

  /// テスト用: 制限に達した状態を作成
  void createLimitReachedState() {
    if (_currentStatus != null) {
      final currentPlan = PlanFactory.createPlan(_currentStatus!.planId);
      setMonthlyUsage(currentPlan.monthlyAiGenerationLimit);
    }
  }

  /// テスト用: 月次リセットが必要な状態を作成
  void createMonthlyResetNeededState() {
    // 前月の日付を設定
    final previousMonth = DateTime.now().month == 1
        ? DateTime(DateTime.now().year - 1, 12, 15)
        : DateTime(DateTime.now().year, DateTime.now().month - 1, 15);

    setLastResetDate(previousMonth);
    setMonthlyUsage(5); // 何らかの使用量を設定
  }

  /// テスト用: Premium状態を作成
  void createPremiumState() {
    final now = DateTime.now();
    final premiumStatus = SubscriptionStatus(
      planId: SubscriptionConstants.premiumMonthlyPlanId,
      isActive: true,
      startDate: now,
      expiryDate: now.add(const Duration(days: 30)),
      autoRenewal: true,
      monthlyUsageCount: _monthlyUsage,
      lastResetDate: _lastResetDate,
      transactionId: 'mock_premium_transaction',
      lastPurchaseDate: now,
    );
    setCurrentStatus(premiumStatus);
  }

  // =================================================================
  // 破棄処理
  // =================================================================

  /// リソースを破棄
  void dispose() {
    _isInitialized = false;
    _currentStatus = null;
    _monthlyUsage = 0;
    _lastResetDate = DateTime.now();
  }
}
