import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/models/plans/plan.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import '../mocks/mock_subscription_purchase_manager.dart';
import '../mocks/mock_subscription_status_manager.dart';
import '../mocks/mock_subscription_usage_tracker.dart';
import '../mocks/mock_subscription_access_control_manager.dart';

/// 共通テストユーティリティ
///
/// ## 主な機能
/// - マネージャー横断の共通テストパターン実装
/// - Result<T>テスト用ヘルパー・アサーション
/// - エラーハンドリングテスト統一パターン
/// - setUp/tearDown処理の標準化
/// - テスト間干渉防止とクリーンアップ強化
///
/// ## 設計原則
/// - 全テストタイプ（Unit/Widget/Integration）で使用可能
/// - 再利用可能な共通パターンの提供
/// - 統一された品質基準の維持
/// - テスト実行の高速化と安定化
class CommonTestUtilities {
  // =================================================================
  // Result<T>テスト用ヘルパー
  // =================================================================

  /// Result<T>が成功であることをアサーション
  static void expectSuccess<T>(Result<T> result) {
    expect(
      result.isSuccess,
      isTrue,
      reason: 'Expected Success but got Failure: ${result.error}',
    );
  }

  /// Result<T>が失敗であることをアサーション
  static void expectFailure<T>(Result<T> result) {
    expect(
      result.isFailure,
      isTrue,
      reason: 'Expected Failure but got Success: ${result.value}',
    );
  }

  /// Result<T>の成功値をアサーション
  static void expectSuccessValue<T>(Result<T> result, T expectedValue) {
    expectSuccess(result);
    expect(
      result.value,
      equals(expectedValue),
      reason: 'Success value does not match expected value',
    );
  }

  /// Result<T>の失敗エラーメッセージをアサーション
  static void expectFailureMessage<T>(
    Result<T> result,
    String expectedMessage,
  ) {
    expectFailure(result);
    expect(
      result.error.message,
      contains(expectedMessage),
      reason: 'Error message does not contain expected text',
    );
  }

  /// Result<T>の失敗エラータイプをアサーション
  static void expectFailureType<T, E extends AppException>(Result<T> result) {
    expectFailure(result);
    expect(
      result.error,
      isA<E>(),
      reason: 'Error type does not match expected type',
    );
  }

  /// Result<T>の成功・失敗に関わらず値の存在をアサーション
  static void expectResultHasValue<T>(Result<T> result) {
    if (result.isSuccess) {
      expect(
        result.value,
        isNotNull,
        reason: 'Success result should have non-null value',
      );
    } else {
      expect(
        result.error,
        isNotNull,
        reason: 'Failure result should have non-null error',
      );
    }
  }

  /// 非同期Result<T>のアサーション
  static Future<void> expectAsyncSuccess<T>(
    Future<Result<T>> futureResult,
  ) async {
    final result = await futureResult;
    expectSuccess(result);
  }

  /// 非同期Result<T>の失敗アサーション
  static Future<void> expectAsyncFailure<T>(
    Future<Result<T>> futureResult,
  ) async {
    final result = await futureResult;
    expectFailure(result);
  }

  /// 非同期Result<T>の成功値アサーション
  static Future<void> expectAsyncSuccessValue<T>(
    Future<Result<T>> futureResult,
    T expectedValue,
  ) async {
    final result = await futureResult;
    expectSuccessValue(result, expectedValue);
  }

  // =================================================================
  // エラーハンドリングテスト統一パターン
  // =================================================================

  /// 共通エラーシナリオテストパターン
  /// 指定した操作でエラーが発生することを検証
  static Future<void> testErrorScenario<T>({
    required String testName,
    required Future<Result<T>> Function() operation,
    required String expectedErrorMessage,
    Type? expectedErrorType,
  }) async {
    group('Error Scenario: $testName', () {
      test('should return failure with expected message', () async {
        final result = await operation();

        expectFailure(result);
        expectFailureMessage(result, expectedErrorMessage);

        if (expectedErrorType != null) {
          expect(result.error, isA<AppException>());
        }
      });
    });
  }

  /// 複数のエラーシナリオを一括テスト
  static void testMultipleErrorScenarios<T>(
    String operationName,
    List<
      ({
        String scenario,
        Future<Result<T>> Function() operation,
        String expectedMessage,
        Type? expectedType,
      })
    >
    scenarios,
  ) {
    group('$operationName Error Scenarios', () {
      for (final scenario in scenarios) {
        testErrorScenario<T>(
          testName: scenario.scenario,
          operation: scenario.operation,
          expectedErrorMessage: scenario.expectedMessage,
          expectedErrorType: scenario.expectedType,
        );
      }
    });
  }

  /// 初期化失敗テストパターン
  static void testInitializationFailure(
    String componentName,
    Future<Result<void>> Function() initOperation,
  ) {
    test(
      '$componentName initialization should fail when not properly configured',
      () async {
        final result = await initOperation();
        expectFailure(result);
        expect(result.error.message, contains('initialization'));
      },
    );
  }

  // =================================================================
  // マネージャー横断の共通テストパターン
  // =================================================================

  /// 購入マネージャーの標準テストセットアップ
  static MockSubscriptionPurchaseManager setupPurchaseManager({
    bool shouldFailInitialization = false,
    bool shouldFailPurchase = false,
    String? customErrorMessage,
  }) {
    final manager = MockSubscriptionPurchaseManager();

    if (shouldFailInitialization) {
      manager.setInitializationFailure(
        true,
        customErrorMessage ?? 'Test initialization failure',
      );
    }
    if (shouldFailPurchase) {
      manager.setPurchaseFailure(
        true,
        customErrorMessage ?? 'Test purchase failure',
      );
    }

    return manager;
  }

  /// ステータスマネージャーの標準テストセットアップ
  static MockSubscriptionStatusManager setupStatusManager({
    Plan? initialPlan,
    bool shouldFailGetStatus = false,
    String? customErrorMessage,
  }) {
    final manager = MockSubscriptionStatusManager();

    if (initialPlan != null) {
      manager.setCurrentPlan(initialPlan);
    }
    if (shouldFailGetStatus) {
      manager.setGetCurrentStatusFailure(
        true,
        customErrorMessage ?? 'Test status failure',
      );
    }

    return manager;
  }

  /// 使用量トラッカーの標準テストセットアップ
  static MockSubscriptionUsageTracker setupUsageTracker({
    SubscriptionStatus? initialStatus,
    bool shouldFailUsageCheck = false,
    String? customErrorMessage,
  }) {
    final manager = MockSubscriptionUsageTracker();

    if (initialStatus != null) {
      manager.setCurrentStatus(initialStatus);
    }
    if (shouldFailUsageCheck) {
      manager.setCanUseAiGenerationFailure(
        true,
        customErrorMessage ?? 'Test usage failure',
      );
    }

    return manager;
  }

  /// アクセス制御マネージャーの標準テストセットアップ
  static MockSubscriptionAccessControlManager setupAccessControlManager({
    bool isPremium = false,
    bool shouldFailAccessCheck = false,
    String? customErrorMessage,
  }) {
    final manager = MockSubscriptionAccessControlManager();

    if (isPremium) {
      manager.createPremiumFullAccessState();
    } else {
      manager.createBasicRestrictedState();
    }

    if (shouldFailAccessCheck) {
      manager.setCanAccessPremiumFeaturesFailure(
        true,
        customErrorMessage ?? 'Test access failure',
      );
    }

    return manager;
  }

  /// 全マネージャーの統合セットアップ
  static ManagerSetup setupAllManagers({
    Plan? plan,
    int usageCount = 0,
    bool enableErrors = false,
  }) {
    final selectedPlan = plan ?? BasicPlan();

    final purchaseManager = setupPurchaseManager(
      shouldFailPurchase: enableErrors,
    );

    final statusManager = setupStatusManager(
      initialPlan: selectedPlan,
      shouldFailGetStatus: enableErrors,
    );

    final now = DateTime.now();
    final status = SubscriptionStatus(
      planId: selectedPlan.id,
      isActive: true,
      startDate: now,
      expiryDate: selectedPlan.isPremium
          ? now.add(const Duration(days: 30))
          : null,
      autoRenewal: selectedPlan.isPremium,
      monthlyUsageCount: usageCount,
      lastResetDate: now,
      transactionId: selectedPlan.isPremium ? 'test_transaction' : '',
      lastPurchaseDate: selectedPlan.isPremium ? now : null,
    );

    final usageTracker = setupUsageTracker(
      initialStatus: status,
      shouldFailUsageCheck: enableErrors,
    );

    final accessControlManager = setupAccessControlManager(
      isPremium: selectedPlan.isPremium,
      shouldFailAccessCheck: enableErrors,
    );

    return ManagerSetup(
      purchaseManager: purchaseManager,
      statusManager: statusManager,
      usageTracker: usageTracker,
      accessControlManager: accessControlManager,
    );
  }

  // =================================================================
  // プランクラステスト用共通ヘルパー
  // =================================================================

  /// Basicプランでのマネージャー状態設定
  static ManagerSetup setupBasicPlanScenario({int usageCount = 0}) {
    return setupAllManagers(plan: BasicPlan(), usageCount: usageCount);
  }

  /// Premiumプランでのマネージャー状態設定
  static ManagerSetup setupPremiumPlanScenario({
    bool isYearly = true,
    int usageCount = 0,
  }) {
    final plan = isYearly ? PremiumYearlyPlan() : PremiumMonthlyPlan();
    return setupAllManagers(plan: plan, usageCount: usageCount);
  }

  /// 使用制限到達シナリオの設定
  static ManagerSetup setupUsageLimitReachedScenario(Plan plan) {
    return setupAllManagers(
      plan: plan,
      usageCount: plan.monthlyAiGenerationLimit,
    );
  }

  /// プランの基本情報をアサーション
  static void assertPlanBasics(
    Plan plan, {
    required String expectedId,
    required String expectedDisplayName,
    required int expectedGenerationLimit,
    required bool expectedIsPremium,
  }) {
    expect(plan.id, equals(expectedId));
    expect(plan.displayName, equals(expectedDisplayName));
    expect(plan.monthlyAiGenerationLimit, equals(expectedGenerationLimit));
    expect(plan.isPremium, equals(expectedIsPremium));
  }

  /// プランの機能をアサーション
  static void assertPlanFeatures(
    Plan plan, {
    required bool expectedHasWritingPrompts,
    required bool expectedHasAdvancedFilters,
    required bool expectedHasAdvancedAnalytics,
    required bool expectedHasPrioritySupport,
  }) {
    expect(plan.hasWritingPrompts, equals(expectedHasWritingPrompts));
    expect(plan.hasAdvancedFilters, equals(expectedHasAdvancedFilters));
    expect(plan.hasAdvancedAnalytics, equals(expectedHasAdvancedAnalytics));
    expect(plan.hasPrioritySupport, equals(expectedHasPrioritySupport));
  }

  // =================================================================
  // setUp/tearDown処理の標準化
  // =================================================================

  /// 標準的なsetUp処理
  static void standardSetUp() {
    setUp(() {
      // テスト間の状態をクリア
      _clearTestState();
    });
  }

  /// 標準的なsetUpAll処理
  static void standardSetUpAll() {
    setUpAll(() {
      // グローバル設定の初期化
      _initializeGlobalTestSettings();
    });
  }

  /// 標準的なtearDown処理
  static void standardTearDown() {
    tearDown(() {
      // リソースのクリーンアップ
      _cleanupTestResources();
    });
  }

  /// 標準的なtearDownAll処理
  static void standardTearDownAll() {
    tearDownAll(() {
      // グローバルリソースのクリーンアップ
      _cleanupGlobalTestResources();
    });
  }

  /// 完全なテストセットアップ（推奨）
  static void completeTestSetup() {
    standardSetUpAll();
    standardSetUp();
    standardTearDown();
    standardTearDownAll();
  }

  // =================================================================
  // 内部ヘルパーメソッド
  // =================================================================

  static void _clearTestState() {
    // 個別テスト用の状態クリア処理
    // モックマネージャーの状態リセットなど
  }

  static void _initializeGlobalTestSettings() {
    // グローバルテスト設定の初期化
    // タイムゾーン、ロケール設定など
  }

  static void _cleanupTestResources() {
    // 個別テスト用のリソースクリーンアップ
    // 一時ファイルの削除、ストリームの閉鎖など
  }

  static void _cleanupGlobalTestResources() {
    // グローバルリソースのクリーンアップ
    // 静的変数のリセット、キャッシュクリアなど
  }

  // =================================================================
  // 非同期操作テストユーティリティ
  // =================================================================

  /// タイムアウト付き非同期操作のテスト
  static Future<T> expectAsyncCompletes<T>(
    Future<T> operation, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    return await operation.timeout(timeout);
  }

  /// 複数の非同期操作の並行実行テスト
  static Future<List<T>> expectAllAsyncComplete<T>(
    List<Future<T>> operations, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return await Future.wait(operations).timeout(timeout);
  }

  /// Stream操作のテスト
  static Future<List<T>> expectStreamEmits<T>(
    Stream<T> stream,
    List<T> expectedValues, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final actualValues = <T>[];
    final completer = Completer<List<T>>();

    late StreamSubscription<T> subscription;
    subscription = stream.listen(
      (value) {
        actualValues.add(value);
        if (actualValues.length >= expectedValues.length) {
          subscription.cancel();
          completer.complete(actualValues);
        }
      },
      onError: (error) {
        subscription.cancel();
        completer.completeError(error);
      },
    );

    final result = await completer.future.timeout(timeout);
    expect(result, equals(expectedValues));
    return result;
  }
}

/// マネージャーセットアップ用のデータクラス
class ManagerSetup {
  final MockSubscriptionPurchaseManager purchaseManager;
  final MockSubscriptionStatusManager statusManager;
  final MockSubscriptionUsageTracker usageTracker;
  final MockSubscriptionAccessControlManager accessControlManager;

  const ManagerSetup({
    required this.purchaseManager,
    required this.statusManager,
    required this.usageTracker,
    required this.accessControlManager,
  });

  /// 全マネージャーをデフォルト状態にリセット
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
}
