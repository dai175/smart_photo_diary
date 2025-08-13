import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/models/plans/plan.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';
import 'common_test_utilities.dart';

/// 統合テスト用共通アサーション
///
/// ## 主な機能
/// - Result<T>パターンの複雑なアサーション
/// - サブスクリプション状態の包括的検証
/// - エラーハンドリングの統一検証
/// - 統合テストでの複合的な状態アサーション
///
/// ## 設計原則
/// - 高レベルなアサーションの提供
/// - テストの可読性向上
/// - 一貫性のある検証基準
/// - デバッグ情報の充実
class IntegrationTestAssertions {
  // =================================================================
  // Result<T> 高レベルアサーション
  // =================================================================

  /// Result<T>の連鎖操作をアサーション
  static Future<void> assertResultChain<T, U>(
    Future<Result<T>> operation,
    Result<U> Function(T) transform,
    U expectedFinalValue,
  ) async {
    final result = await operation;
    CommonTestUtilities.expectSuccess(result);
    
    final transformedResult = transform(result.value);
    CommonTestUtilities.expectSuccessValue(transformedResult, expectedFinalValue);
  }

  /// 複数のResult<T>操作の並行実行をアサーション
  static Future<void> assertParallelResults<T>(
    List<Future<Result<T>>> operations,
    List<T> expectedValues,
  ) async {
    expect(operations.length, equals(expectedValues.length));
    
    final results = await Future.wait(operations);
    
    for (int i = 0; i < results.length; i++) {
      CommonTestUtilities.expectSuccessValue(results[i], expectedValues[i]);
    }
  }

  /// Result<T>の条件付きアサーション
  static void assertConditionalResult<T>(
    Result<T> result,
    bool shouldSucceed,
    T? expectedValue,
    String? expectedErrorMessage,
  ) {
    if (shouldSucceed) {
      CommonTestUtilities.expectSuccess(result);
      if (expectedValue != null) {
        expect(result.value, equals(expectedValue));
      }
    } else {
      CommonTestUtilities.expectFailure(result);
      if (expectedErrorMessage != null) {
        CommonTestUtilities.expectFailureMessage(result, expectedErrorMessage);
      }
    }
  }

  /// Result<T>のエラー回復パターンをアサーション
  static Future<void> assertErrorRecoveryPattern<T>(
    Future<Result<T>> initialOperation,
    Future<Result<T>> recoveryOperation,
    T expectedRecoveryValue,
  ) async {
    // 最初の操作が失敗することを確認
    final initialResult = await initialOperation;
    CommonTestUtilities.expectFailure(initialResult);
    
    // 回復操作が成功することを確認
    final recoveryResult = await recoveryOperation;
    CommonTestUtilities.expectSuccessValue(recoveryResult, expectedRecoveryValue);
  }

  // =================================================================
  // サブスクリプション統合アサーション
  // =================================================================

  /// サブスクリプションサービスの完全な状態をアサーション
  static Future<void> assertSubscriptionServiceState(
    ISubscriptionService service,
    Plan expectedPlan,
    SubscriptionStatus expectedStatus,
    bool expectedCanUseAi,
    int expectedRemainingGenerations,
  ) async {
    // プラン取得の検証
    final planResult = await service.getCurrentPlanClass();
    CommonTestUtilities.expectSuccess(planResult);
    expect(planResult.value.id, equals(expectedPlan.id));
    expect(planResult.value.displayName, equals(expectedPlan.displayName));
    
    // 状態取得の検証
    final statusResult = await service.getCurrentStatus();
    CommonTestUtilities.expectSuccess(statusResult);
    expect(statusResult.value.planId, equals(expectedStatus.planId));
    expect(statusResult.value.isActive, equals(expectedStatus.isActive));
    expect(statusResult.value.monthlyUsageCount, equals(expectedStatus.monthlyUsageCount));
    
    // AI使用可能性の検証
    final canUseAiResult = await service.canUseAiGeneration();
    CommonTestUtilities.expectSuccessValue(canUseAiResult, expectedCanUseAi);
    
    // 残り生成回数の検証
    final remainingResult = await service.getRemainingGenerations();
    CommonTestUtilities.expectSuccessValue(remainingResult, expectedRemainingGenerations);
  }

  /// サブスクリプション権限の包括的検証
  static Future<void> assertSubscriptionPermissions(
    ISubscriptionService service,
    Plan plan,
  ) async {
    // プレミアム機能アクセス権
    final premiumAccessResult = await service.canAccessPremiumFeatures();
    CommonTestUtilities.expectSuccessValue(premiumAccessResult, plan.isPremium);
    
    // ライティングプロンプトアクセス権
    final writingPromptsResult = await service.canAccessWritingPrompts();
    CommonTestUtilities.expectSuccessValue(writingPromptsResult, plan.hasWritingPrompts);
    
    // 高度なフィルターアクセス権
    final advancedFiltersResult = await service.canAccessAdvancedFilters();
    CommonTestUtilities.expectSuccessValue(advancedFiltersResult, plan.hasAdvancedFilters);
    
    // 高度な分析アクセス権
    final advancedAnalyticsResult = await service.canAccessAdvancedAnalytics();
    CommonTestUtilities.expectSuccessValue(advancedAnalyticsResult, plan.hasAdvancedAnalytics);
    
    // 優先サポートアクセス権
    final prioritySupportResult = await service.canAccessPrioritySupport();
    CommonTestUtilities.expectSuccessValue(prioritySupportResult, plan.hasPrioritySupport);
  }

  /// プラン変更の統合検証
  static Future<void> assertPlanChange(
    ISubscriptionService service,
    Plan fromPlan,
    Plan toPlan,
    Future<void> Function() planChangeOperation,
  ) async {
    // 変更前の状態確認
    final initialPlanResult = await service.getCurrentPlanClass();
    CommonTestUtilities.expectSuccessValue(initialPlanResult, fromPlan);
    
    // プラン変更実行
    await planChangeOperation();
    
    // 変更後の状態確認
    final finalPlanResult = await service.getCurrentPlanClass();
    CommonTestUtilities.expectSuccessValue(finalPlanResult, toPlan);
    
    // 権限の更新確認
    await assertSubscriptionPermissions(service, toPlan);
  }

  /// 使用量制限の統合検証
  static Future<void> assertUsageLimitBehavior(
    ISubscriptionService service,
    Plan plan,
    int initialUsage,
    Future<void> Function() usageIncrementOperation,
  ) async {
    // 初期使用量の確認
    final initialUsageResult = await service.getMonthlyUsage();
    CommonTestUtilities.expectSuccessValue(initialUsageResult, initialUsage);
    
    final initialCanUseResult = await service.canUseAiGeneration();
    final expectedCanUse = initialUsage < plan.monthlyAiGenerationLimit;
    CommonTestUtilities.expectSuccessValue(initialCanUseResult, expectedCanUse);
    
    // 使用量増加操作
    await usageIncrementOperation();
    
    // 使用量増加後の確認
    final finalUsageResult = await service.getMonthlyUsage();
    CommonTestUtilities.expectSuccessValue(finalUsageResult, initialUsage + 1);
    
    final finalCanUseResult = await service.canUseAiGeneration();
    final expectedFinalCanUse = (initialUsage + 1) < plan.monthlyAiGenerationLimit;
    CommonTestUtilities.expectSuccessValue(finalCanUseResult, expectedFinalCanUse);
  }

  // =================================================================
  // 複合的な統合アサーション
  // =================================================================

  /// サービス間の連携をアサーション
  static Future<void> assertServiceIntegration(
    Map<String, dynamic> services,
    Map<String, Future<Result<dynamic>> Function()> operations,
    Map<String, dynamic> expectedResults,
  ) async {
    expect(services.keys, containsAll(operations.keys));
    expect(operations.keys, containsAll(expectedResults.keys));
    
    for (final key in operations.keys) {
      final result = await operations[key]!();
      final expectedResult = expectedResults[key];
      
      CommonTestUtilities.expectSuccess(result);
      expect(result.value, equals(expectedResult));
    }
  }

  /// データ一貫性の検証
  static Future<void> assertDataConsistency(
    List<Future<Result<dynamic>> Function()> queries,
    bool Function(List<dynamic>) consistencyChecker,
    String consistencyDescription,
  ) async {
    final results = <dynamic>[];
    
    for (final query in queries) {
      final result = await query();
      CommonTestUtilities.expectSuccess(result);
      results.add(result.value);
    }
    
    expect(
      consistencyChecker(results),
      isTrue,
      reason: 'Data consistency check failed: $consistencyDescription',
    );
  }

  /// トランザクション的な操作の検証
  static Future<void> assertTransactionalOperation(
    Future<void> Function() operation,
    List<Future<dynamic> Function()> stateQueries,
    List<dynamic> expectedFinalStates,
  ) async {
    expect(stateQueries.length, equals(expectedFinalStates.length));
    
    // 操作実行
    await operation();
    
    // 最終状態の確認
    for (int i = 0; i < stateQueries.length; i++) {
      final actualState = await stateQueries[i]();
      expect(actualState, equals(expectedFinalStates[i]),
          reason: 'State $i does not match expected value after transactional operation');
    }
  }

  // =================================================================
  // エラーシナリオの統合検証
  // =================================================================

  /// カスケードエラーの検証
  static Future<void> assertCascadingErrors(
    Future<Result<dynamic>> Function() triggerOperation,
    List<Future<Result<dynamic>> Function()> dependentOperations,
    List<String> expectedErrorMessages,
  ) async {
    expect(dependentOperations.length, equals(expectedErrorMessages.length));
    
    // トリガー操作の失敗確認
    final triggerResult = await triggerOperation();
    CommonTestUtilities.expectFailure(triggerResult);
    
    // 依存操作の失敗確認
    for (int i = 0; i < dependentOperations.length; i++) {
      final dependentResult = await dependentOperations[i]();
      CommonTestUtilities.expectFailure(dependentResult);
      CommonTestUtilities.expectFailureMessage(dependentResult, expectedErrorMessages[i]);
    }
  }

  /// エラー後の状態回復検証
  static Future<void> assertErrorRecovery(
    Future<Result<dynamic>> Function() errorOperation,
    Future<void> Function() recoveryOperation,
    List<Future<Result<dynamic>> Function()> healthCheckOperations,
    List<dynamic> expectedHealthyStates,
  ) async {
    expect(healthCheckOperations.length, equals(expectedHealthyStates.length));
    
    // エラー発生確認
    final errorResult = await errorOperation();
    CommonTestUtilities.expectFailure(errorResult);
    
    // 回復操作実行
    await recoveryOperation();
    
    // ヘルスチェック
    for (int i = 0; i < healthCheckOperations.length; i++) {
      final healthResult = await healthCheckOperations[i]();
      CommonTestUtilities.expectSuccessValue(healthResult, expectedHealthyStates[i]);
    }
  }

  // =================================================================
  // パフォーマンス・タイミング検証
  // =================================================================

  /// 操作のタイミング制約を検証
  static Future<void> assertTimingConstraints(
    Future<Result<dynamic>> Function() operation,
    Duration maxDuration,
    Duration minDuration,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    final result = await operation();
    stopwatch.stop();
    
    CommonTestUtilities.expectSuccess(result);
    
    expect(
      stopwatch.elapsed,
      lessThan(maxDuration),
      reason: 'Operation took longer than expected: ${stopwatch.elapsed}',
    );
    
    expect(
      stopwatch.elapsed,
      greaterThan(minDuration),
      reason: 'Operation completed too quickly: ${stopwatch.elapsed}',
    );
  }

  /// 並行操作の競合状態を検証
  static Future<void> assertConcurrencyBehavior(
    List<Future<Result<dynamic>> Function()> concurrentOperations,
    bool Function(List<dynamic>) resultValidator,
    String validationDescription,
  ) async {
    final futures = concurrentOperations.map((op) => op()).toList();
    final results = await Future.wait(futures);
    
    // 全て成功することを確認
    for (final result in results) {
      CommonTestUtilities.expectSuccess(result);
    }
    
    // 結果の妥当性を確認
    final values = results.map((r) => r.value).toList();
    expect(
      resultValidator(values),
      isTrue,
      reason: 'Concurrency validation failed: $validationDescription',
    );
  }

  // =================================================================
  // デバッグ・ログ検証
  // =================================================================

  /// 詳細なアサーション結果をログ出力
  static void logAssertionResult(
    String testName,
    Map<String, dynamic> actualValues,
    Map<String, dynamic> expectedValues,
    bool success,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('=== Assertion Result: $testName ===');
    buffer.writeln('Success: $success');
    
    if (!success) {
      buffer.writeln('\nActual Values:');
      actualValues.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
      
      buffer.writeln('\nExpected Values:');
      expectedValues.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    
    buffer.writeln('=====================================');
    // デバッグ情報の出力（テスト環境では許可）
    // ignore: avoid_print
    print(buffer.toString());
  }

  /// 複雑なオブジェクト階層の比較・ログ出力
  static void assertComplexObjectEquality<T>(
    T actual,
    T expected,
    String Function(T) serializer,
    String objectName,
  ) {
    final actualStr = serializer(actual);
    final expectedStr = serializer(expected);
    
    if (actualStr != expectedStr) {
      logAssertionResult(
        objectName,
        {'serialized': actualStr, 'object': actual},
        {'serialized': expectedStr, 'object': expected},
        false,
      );
    }
    
    expect(actual, equals(expected), reason: '$objectName objects do not match');
  }
}