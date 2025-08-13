import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import '../../mocks/mock_subscription_usage_tracker.dart';

void main() {
  group('MockSubscriptionUsageTracker', () {
    late MockSubscriptionUsageTracker mockTracker;

    setUp(() {
      mockTracker = MockSubscriptionUsageTracker();
    });

    tearDown(() {
      mockTracker.dispose();
    });

    group('初期化とセットアップ', () {
      test('初期状態では初期化済み', () {
        expect(mockTracker.isInitialized, true);
      });

      test('初期化状態を設定できる', () {
        // Act
        mockTracker.setInitialized(false);

        // Assert
        expect(mockTracker.isInitialized, false);
      });

      test('デフォルトで使用量0の状態が設定される', () async {
        // Act
        final result = await mockTracker.getMonthlyUsage();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, equals(0));
      });

      test('カスタム初期状態を設定できる', () async {
        // Arrange
        final customStatus = SubscriptionStatus(
          planId: 'premium_monthly',
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          autoRenewal: true,
          monthlyUsageCount: 15,
          lastResetDate: DateTime.now(),
          transactionId: 'test_transaction',
          lastPurchaseDate: DateTime.now(),
        );

        // Act
        final mockTrackerWithCustomState = MockSubscriptionUsageTracker(
          initialStatus: customStatus,
          initialUsage: 15,
        );

        final result = await mockTrackerWithCustomState.getMonthlyUsage();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, equals(15));

        mockTrackerWithCustomState.dispose();
      });
    });

    group('月次使用量管理', () {
      test('未初期化時はエラーを返す', () async {
        // Arrange
        mockTracker.setInitialized(false);

        // Act
        final result = await mockTracker.getMonthlyUsage();

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('not initialized'));
      });

      test('月次使用量を正常に取得できる', () async {
        // Arrange
        mockTracker.setMonthlyUsage(5);

        // Act
        final result = await mockTracker.getMonthlyUsage();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, equals(5));
      });

      test('月次使用量取得失敗を設定できる', () async {
        // Arrange
        mockTracker.setGetMonthlyUsageFailure(
          true,
          'Test getMonthlyUsage error',
        );

        // Act
        final result = await mockTracker.getMonthlyUsage();

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test getMonthlyUsage error'));
      });

      test('月次使用量を直接設定できる', () async {
        // Act
        mockTracker.setMonthlyUsage(10);
        final result = await mockTracker.getMonthlyUsage();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, equals(10));
      });
    });

    group('残りAI生成回数取得', () {
      test('Basicプランで正しい残り回数が取得できる', () async {
        // Arrange
        mockTracker.setMonthlyUsage(3);

        // Act
        final result = await mockTracker.getRemainingGenerations(
          _isValidBasicSubscription,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, equals(7)); // BasicPlan制限10 - 使用3 = 7
      });

      test('Premiumプランで正しい残り回数が取得できる', () async {
        // Arrange
        mockTracker.createPremiumState();
        mockTracker.setMonthlyUsage(25);

        // Act
        final result = await mockTracker.getRemainingGenerations(
          _isValidPremiumSubscription,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, equals(75)); // PremiumPlan制限100 - 使用25 = 75
      });

      test('制限に達した場合は0が返される', () async {
        // Arrange
        mockTracker.createLimitReachedState();

        // Act
        final result = await mockTracker.getRemainingGenerations(
          _isValidBasicSubscription,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, equals(0));
      });

      test('制限を超えた場合でも0が返される（負にならない）', () async {
        // Arrange
        mockTracker.setMonthlyUsage(15); // BasicPlan制限10を超過

        // Act
        final result = await mockTracker.getRemainingGenerations(
          _isValidBasicSubscription,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, equals(0)); // 負にならない
      });

      test('無効なサブスクリプションでは0が返される', () async {
        // Act
        final result = await mockTracker.getRemainingGenerations(
          _isInvalidSubscription,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, equals(0));
      });

      test('残り回数取得失敗を設定できる', () async {
        // Arrange
        mockTracker.setGetRemainingGenerationsFailure(
          true,
          'Test getRemainingGenerations error',
        );

        // Act
        final result = await mockTracker.getRemainingGenerations(
          _isValidBasicSubscription,
        );

        // Assert
        expect(result.isFailure, true);
        expect(
          result.error.message,
          contains('Test getRemainingGenerations error'),
        );
      });
    });

    group('AI生成使用可否判定', () {
      test('Basicプラン初期状態で使用可能', () async {
        // Arrange
        final status = _createBasicStatus();

        // Act
        final result = await mockTracker.canUseAiGeneration(
          status,
          _isValidBasicSubscription,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, true);
      });

      test('制限内では使用可能', () async {
        // Arrange
        mockTracker.setMonthlyUsage(9); // BasicPlan制限10の1回前
        final status = _createBasicStatus();

        // Act
        final result = await mockTracker.canUseAiGeneration(
          status,
          _isValidBasicSubscription,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, true);
      });

      test('制限に達すると使用不可', () async {
        // Arrange
        mockTracker.createLimitReachedState();
        final status = _createBasicStatus();

        // Act
        final result = await mockTracker.canUseAiGeneration(
          status,
          _isValidBasicSubscription,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, false);
      });

      test('Premiumプランで高い制限まで使用可能', () async {
        // Arrange
        mockTracker.createPremiumState();
        mockTracker.setMonthlyUsage(50);
        final status = _createPremiumMonthlyStatus();

        // Act
        final result = await mockTracker.canUseAiGeneration(
          status,
          _isValidPremiumSubscription,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, true);
      });

      test('無効なサブスクリプションでは使用不可', () async {
        // Arrange
        final status = _createBasicStatus();

        // Act
        final result = await mockTracker.canUseAiGeneration(
          status,
          _isInvalidSubscription,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, false);
      });

      test('使用可否判定失敗を設定できる', () async {
        // Arrange
        mockTracker.setCanUseAiGenerationFailure(
          true,
          'Test canUseAiGeneration error',
        );
        final status = _createBasicStatus();

        // Act
        final result = await mockTracker.canUseAiGeneration(
          status,
          _isValidBasicSubscription,
        );

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test canUseAiGeneration error'));
      });
    });

    group('AI使用量インクリメント', () {
      test('有効なBasicプランで使用量がインクリメントされる', () async {
        // Arrange
        final status = _createBasicStatus();

        // Act
        final result = await mockTracker.incrementAiUsage(
          status,
          _isValidBasicSubscription,
        );

        // Assert
        expect(result.isSuccess, true);

        // 使用量が1増加していることを確認
        final updatedUsage = await mockTracker.getMonthlyUsage();
        expect(updatedUsage.value, equals(1));
      });

      test('複数回のインクリメントが正しく処理される', () async {
        // Arrange
        final status = _createBasicStatus();

        // Act
        for (int i = 0; i < 3; i++) {
          final result = await mockTracker.incrementAiUsage(
            status,
            _isValidBasicSubscription,
          );
          expect(result.isSuccess, true);
        }

        // Assert
        final usage = await mockTracker.getMonthlyUsage();
        expect(usage.value, equals(3));
      });

      test('制限に達した場合、インクリメントが失敗する', () async {
        // Arrange
        mockTracker.createLimitReachedState();
        final status = _createBasicStatus();

        // Act
        final result = await mockTracker.incrementAiUsage(
          status,
          _isValidBasicSubscription,
        );

        // Assert
        expect(result.isFailure, true);
        expect(
          result.error.message,
          contains('Monthly AI generation limit reached'),
        );
      });

      test('無効なサブスクリプションではインクリメント失敗', () async {
        // Arrange
        final status = _createBasicStatus();

        // Act
        final result = await mockTracker.incrementAiUsage(
          status,
          _isInvalidSubscription,
        );

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('subscription is not valid'));
      });

      test('インクリメント失敗を設定できる', () async {
        // Arrange
        mockTracker.setIncrementAiUsageFailure(
          true,
          'Test incrementAiUsage error',
        );
        final status = _createBasicStatus();

        // Act
        final result = await mockTracker.incrementAiUsage(
          status,
          _isValidBasicSubscription,
        );

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test incrementAiUsage error'));
      });
    });

    group('使用量リセット', () {
      test('手動リセットで使用量がクリアされる', () async {
        // Arrange
        mockTracker.setMonthlyUsage(5);

        // Act
        final result = await mockTracker.resetUsage();

        // Assert
        expect(result.isSuccess, true);

        final usage = await mockTracker.getMonthlyUsage();
        expect(usage.value, equals(0));
      });

      test('制限に達した状態からリセットで再び使用可能になる', () async {
        // Arrange
        mockTracker.createLimitReachedState();
        final status = _createBasicStatus();

        // リセット前は使用不可
        final beforeReset = await mockTracker.canUseAiGeneration(
          status,
          _isValidBasicSubscription,
        );
        expect(beforeReset.value, false);

        // Act
        await mockTracker.resetUsage();

        // Assert
        final afterReset = await mockTracker.canUseAiGeneration(
          status,
          _isValidBasicSubscription,
        );
        expect(afterReset.value, true);
      });

      test('リセット失敗を設定できる', () async {
        // Arrange
        mockTracker.setResetUsageFailure(true, 'Test resetUsage error');

        // Act
        final result = await mockTracker.resetUsage();

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test resetUsage error'));
      });
    });

    group('次回リセット日計算', () {
      test('次回リセット日が正しく計算される', () async {
        // Act
        final result = await mockTracker.getNextResetDate();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, isA<DateTime>());

        final now = DateTime.now();
        final nextMonth = now.month == 12
            ? DateTime(now.year + 1, 1, 1)
            : DateTime(now.year, now.month + 1, 1);

        expect(result.value.year, equals(nextMonth.year));
        expect(result.value.month, equals(nextMonth.month));
        expect(result.value.day, equals(1));
      });

      test('12月の場合、翌年1月がリセット日になる', () async {
        // Arrange
        mockTracker.setLastResetDate(DateTime(2023, 12, 15));

        // Act
        final result = await mockTracker.getNextResetDate();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value.year, equals(2024));
        expect(result.value.month, equals(1));
        expect(result.value.day, equals(1));
      });

      test('次回リセット日取得失敗を設定できる', () async {
        // Arrange
        mockTracker.setGetNextResetDateFailure(
          true,
          'Test getNextResetDate error',
        );

        // Act
        final result = await mockTracker.getNextResetDate();

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test getNextResetDate error'));
      });
    });

    group('月次自動リセット', () {
      test('月次リセットが正常に実行される', () async {
        // Arrange
        mockTracker.setMonthlyUsage(5);

        // Act
        final result = await mockTracker.resetMonthlyUsageIfNeeded();

        // Assert
        expect(result.isSuccess, true);
      });

      test('月次リセットが必要な場合、使用量がリセットされる', () async {
        // Arrange - 前月の状態を作成し、使用量を設定
        mockTracker.setMonthlyUsage(8);
        final previousMonth = DateTime.now().month == 1
            ? DateTime(DateTime.now().year - 1, 12, 15)
            : DateTime(DateTime.now().year, DateTime.now().month - 1, 15);
        mockTracker.setLastResetDate(previousMonth);

        // Act
        final result = await mockTracker.resetMonthlyUsageIfNeeded();

        // Assert
        expect(result.isSuccess, true);

        // リセット後の使用量を確認
        final afterReset = await mockTracker.getMonthlyUsage();
        expect(afterReset.value, equals(0)); // 月次リセットによって0になる
      });

      test('月次リセット失敗を設定できる', () async {
        // Arrange
        mockTracker.setResetMonthlyUsageIfNeededFailure(
          true,
          'Test resetMonthlyUsageIfNeeded error',
        );

        // Act
        final result = await mockTracker.resetMonthlyUsageIfNeeded();

        // Assert
        expect(result.isFailure, true);
        expect(
          result.error.message,
          contains('Test resetMonthlyUsageIfNeeded error'),
        );
      });
    });

    group('テスト用ヘルパーメソッド', () {
      test('月次使用量を設定できる', () async {
        // Act
        mockTracker.setMonthlyUsage(25);
        final result = await mockTracker.getMonthlyUsage();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, equals(25));
      });

      test('カスタムリセット日を設定できる', () async {
        // Arrange
        final customResetDate = DateTime(2023, 6, 15);

        // Act
        mockTracker.setLastResetDate(customResetDate);
        final result = await mockTracker.getNextResetDate();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value.year, equals(2023));
        expect(result.value.month, equals(7));
        expect(result.value.day, equals(1));
      });

      test('制限到達状態を作成できる', () async {
        // Arrange
        final status = _createBasicStatus();

        // Act
        mockTracker.createLimitReachedState();
        final result = await mockTracker.canUseAiGeneration(
          status,
          _isValidBasicSubscription,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, false);
      });

      test('月次リセット必要状態を作成できる', () async {
        // Arrange - 初期使用量を設定
        mockTracker.setMonthlyUsage(5);

        // Act
        mockTracker.createMonthlyResetNeededState();

        // 初回取得でリセットが発動し、使用量が0になることを確認
        final result = await mockTracker.getMonthlyUsage();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, equals(0)); // リセット後
      });

      test('Premium状態を作成できる', () async {
        // Act
        mockTracker.createPremiumState();
        mockTracker.setMonthlyUsage(10);
        final status = _createPremiumMonthlyStatus();
        final result = await mockTracker.canUseAiGeneration(
          status,
          _isValidPremiumSubscription,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, true); // Premiumプランなので使用可能
      });

      test('状態をリセットできる', () async {
        // Arrange
        mockTracker.setMonthlyUsage(15);
        mockTracker.setGetMonthlyUsageFailure(true);

        // Act
        mockTracker.resetToDefaults();

        // Assert
        expect(mockTracker.isInitialized, true);
        final result = await mockTracker.getMonthlyUsage();
        expect(result.isSuccess, true);
        expect(result.value, equals(0));
      });
    });

    group('境界値テスト', () {
      test('Basicプラン制限ちょうど(10回)での使用可否', () async {
        // Arrange
        mockTracker.setMonthlyUsage(10);
        final status = _createBasicStatus();

        // Act
        final result = await mockTracker.canUseAiGeneration(
          status,
          _isValidBasicSubscription,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, false);
      });

      test('Premiumプラン制限ちょうど(100回)での使用可否', () async {
        // Arrange
        mockTracker.createPremiumState();
        mockTracker.setMonthlyUsage(100);
        final status = _createPremiumMonthlyStatus();

        // Act
        final result = await mockTracker.canUseAiGeneration(
          status,
          _isValidPremiumSubscription,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, false);
      });

      test('制限の1回前では使用可能', () async {
        // Arrange
        mockTracker.setMonthlyUsage(9); // Basic制限10の1回前
        final status = _createBasicStatus();

        // Act
        final result = await mockTracker.canUseAiGeneration(
          status,
          _isValidBasicSubscription,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, true);
      });

      test('使用量0の状態で残り回数を取得', () async {
        // Act
        final result = await mockTracker.getRemainingGenerations(
          _isValidBasicSubscription,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, equals(10)); // BasicPlan制限 - 使用0 = 10
      });
    });

    group('エラーハンドリング', () {
      test('初期化されていない場合、全メソッドがエラーを返す', () async {
        // Arrange
        mockTracker.setInitialized(false);
        final status = _createBasicStatus();

        // Act & Assert
        final getMonthlyUsage = await mockTracker.getMonthlyUsage();
        expect(getMonthlyUsage.isFailure, true);

        final getRemainingGenerations = await mockTracker
            .getRemainingGenerations(_isValidBasicSubscription);
        expect(getRemainingGenerations.isFailure, true);

        final canUseAiGeneration = await mockTracker.canUseAiGeneration(
          status,
          _isValidBasicSubscription,
        );
        expect(canUseAiGeneration.isFailure, true);

        final incrementAiUsage = await mockTracker.incrementAiUsage(
          status,
          _isValidBasicSubscription,
        );
        expect(incrementAiUsage.isFailure, true);

        final resetUsage = await mockTracker.resetUsage();
        expect(resetUsage.isFailure, true);

        final getNextResetDate = await mockTracker.getNextResetDate();
        expect(getNextResetDate.isFailure, true);

        final resetMonthlyUsageIfNeeded = await mockTracker
            .resetMonthlyUsageIfNeeded();
        expect(resetMonthlyUsageIfNeeded.isFailure, true);
      });
    });

    group('破棄処理', () {
      test('破棄処理が正常に実行される', () {
        // Act
        mockTracker.dispose();

        // Assert
        expect(mockTracker.isInitialized, false);
      });
    });
  });
}

// =================================================================
// テスト用ヘルパー関数
// =================================================================

/// Basicプランのサブスクリプション状態を作成
SubscriptionStatus _createBasicStatus() {
  return SubscriptionStatus(
    planId: SubscriptionConstants.basicPlanId,
    isActive: true,
    startDate: DateTime.now(),
    expiryDate: null,
    autoRenewal: false,
    monthlyUsageCount: 0,
    lastResetDate: DateTime.now(),
    transactionId: '',
    lastPurchaseDate: null,
  );
}

/// PremiumMonthlyプランのサブスクリプション状態を作成
SubscriptionStatus _createPremiumMonthlyStatus() {
  return SubscriptionStatus(
    planId: SubscriptionConstants.premiumMonthlyPlanId,
    isActive: true,
    startDate: DateTime.now(),
    expiryDate: DateTime.now().add(const Duration(days: 30)),
    autoRenewal: true,
    monthlyUsageCount: 0,
    lastResetDate: DateTime.now(),
    transactionId: 'test_transaction',
    lastPurchaseDate: DateTime.now(),
  );
}

/// Basicプラン有効性チェック関数
bool _isValidBasicSubscription(SubscriptionStatus status) {
  return status.isActive && status.planId == SubscriptionConstants.basicPlanId;
}

/// Premiumプラン有効性チェック関数
bool _isValidPremiumSubscription(SubscriptionStatus status) {
  final isPremium =
      status.planId == SubscriptionConstants.premiumMonthlyPlanId ||
      status.planId == SubscriptionConstants.premiumYearlyPlanId;
  final isActive = status.isActive;
  final isNotExpired = status.expiryDate?.isAfter(DateTime.now()) ?? false;

  return isPremium && isActive && isNotExpired;
}

/// 無効なサブスクリプション（常にfalseを返す）
bool _isInvalidSubscription(SubscriptionStatus status) {
  return false;
}
