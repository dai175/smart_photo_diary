import 'package:flutter_test/flutter_test.dart';

import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import '../../mocks/mock_subscription_status_manager.dart';

void main() {
  group('MockSubscriptionStatusManager', () {
    late MockSubscriptionStatusManager mockManager;

    setUp(() {
      mockManager = MockSubscriptionStatusManager();
    });

    tearDown(() {
      mockManager.dispose();
    });

    group('初期化とセットアップ', () {
      test('初期状態では初期化済み', () {
        expect(mockManager.isInitialized, true);
      });

      test('初期化状態を設定できる', () {
        // Act
        mockManager.setInitialized(false);

        // Assert
        expect(mockManager.isInitialized, false);
      });

      test('デフォルトでBasicプランの状態が設定される', () async {
        // Act
        final result = await mockManager.getCurrentStatus();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value.planId, equals(SubscriptionConstants.basicPlanId));
        expect(result.value.isActive, true);
        expect(result.value.expiryDate, isNull);
        expect(result.value.autoRenewal, false);
      });

      test('カスタム初期状態を設定できる', () async {
        // Arrange
        final customStatus = SubscriptionStatus(
          planId: 'premium_monthly',
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          autoRenewal: true,
          monthlyUsageCount: 5,
          lastResetDate: DateTime.now(),
          transactionId: 'test_transaction',
          lastPurchaseDate: DateTime.now(),
        );

        // Act
        final mockManagerWithCustomState = MockSubscriptionStatusManager(
          initialStatus: customStatus,
        );

        final result = await mockManagerWithCustomState.getCurrentStatus();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value.planId, equals('premium_monthly'));
        expect(result.value.monthlyUsageCount, equals(5));

        mockManagerWithCustomState.dispose();
      });
    });

    group('状態取得と管理', () {
      test('未初期化時はエラーを返す', () async {
        // Arrange
        mockManager.setInitialized(false);

        // Act
        final result = await mockManager.getCurrentStatus();

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('not initialized'));
      });

      test('現在の状態を正常に取得できる', () async {
        // Act
        final result = await mockManager.getCurrentStatus();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, isA<SubscriptionStatus>());
        expect(result.value.planId, isNotEmpty);
      });

      test('状態取得失敗を設定できる', () async {
        // Arrange
        mockManager.setGetCurrentStatusFailure(
          true,
          'Test getCurrentStatus error',
        );

        // Act
        final result = await mockManager.getCurrentStatus();

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test getCurrentStatus error'));
      });

      test('カスタム状態を設定できる', () async {
        // Arrange
        final now = DateTime.now();
        final customStatus = SubscriptionStatus(
          planId: 'premium_yearly',
          isActive: true,
          startDate: now,
          expiryDate: now.add(const Duration(days: 365)),
          autoRenewal: true,
          monthlyUsageCount: 10,
          lastResetDate: now,
          transactionId: 'yearly_transaction',
          lastPurchaseDate: now,
        );

        // Act
        mockManager.setCurrentStatus(customStatus);
        final result = await mockManager.getCurrentStatus();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value.planId, equals('premium_yearly'));
        expect(result.value.monthlyUsageCount, equals(10));
        expect(result.value.transactionId, equals('yearly_transaction'));
      });
    });

    group('状態更新機能', () {
      test('未初期化時は更新エラーを返す', () async {
        // Arrange
        mockManager.setInitialized(false);
        final status = SubscriptionStatus(
          planId: 'basic',
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: null,
          autoRenewal: false,
          monthlyUsageCount: 0,
          lastResetDate: DateTime.now(),
          transactionId: '',
          lastPurchaseDate: null,
        );

        // Act
        final result = await mockManager.updateStatus(status);

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('not initialized'));
      });

      test('状態更新が正常に動作する', () async {
        // Arrange
        final now = DateTime.now();
        final newStatus = SubscriptionStatus(
          planId: 'premium_monthly',
          isActive: true,
          startDate: now,
          expiryDate: now.add(const Duration(days: 30)),
          autoRenewal: true,
          monthlyUsageCount: 15,
          lastResetDate: now,
          transactionId: 'updated_transaction',
          lastPurchaseDate: now,
        );

        // Act
        final updateResult = await mockManager.updateStatus(newStatus);
        final getResult = await mockManager.getCurrentStatus();

        // Assert
        expect(updateResult.isSuccess, true);
        expect(getResult.isSuccess, true);
        expect(getResult.value.planId, equals('premium_monthly'));
        expect(getResult.value.monthlyUsageCount, equals(15));
        expect(getResult.value.transactionId, equals('updated_transaction'));
      });

      test('状態更新失敗を設定できる', () async {
        // Arrange
        mockManager.setUpdateStatusFailure(true, 'Test updateStatus error');
        final status = SubscriptionStatus(
          planId: 'basic',
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: null,
          autoRenewal: false,
          monthlyUsageCount: 0,
          lastResetDate: DateTime.now(),
          transactionId: '',
          lastPurchaseDate: null,
        );

        // Act
        final result = await mockManager.updateStatus(status);

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test updateStatus error'));
      });

      test('リフレッシュが正常に動作する', () async {
        // Act
        final result = await mockManager.refreshStatus();

        // Assert
        expect(result.isSuccess, true);
      });

      test('リフレッシュ失敗を設定できる', () async {
        // Arrange
        mockManager.setRefreshStatusFailure(true, 'Test refresh error');

        // Act
        final result = await mockManager.refreshStatus();

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test refresh error'));
      });
    });

    group('状態作成と削除', () {
      test('Basicプランで状態作成が成功する', () async {
        // Arrange
        final basicPlan = BasicPlan();

        // Act
        final result = await mockManager.createStatus(basicPlan);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value.planId, equals(basicPlan.id));
        expect(result.value.isActive, true);
        expect(result.value.expiryDate, isNull);
        expect(result.value.autoRenewal, false);
        expect(result.value.transactionId, isEmpty);
        expect(result.value.lastPurchaseDate, isNull);
      });

      test('Premiumプランで状態作成が成功する', () async {
        // Arrange
        final premiumPlan = PremiumMonthlyPlan();

        // Act
        final result = await mockManager.createStatus(premiumPlan);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value.planId, equals(premiumPlan.id));
        expect(result.value.isActive, true);
        expect(result.value.expiryDate, isNotNull);
        expect(result.value.expiryDate!.isAfter(DateTime.now()), true);
        expect(result.value.autoRenewal, true);
        expect(result.value.transactionId, isNotEmpty);
        expect(result.value.lastPurchaseDate, isNotNull);
      });

      test('年間プランで状態作成が成功する', () async {
        // Arrange
        final yearlyPlan = PremiumYearlyPlan();

        // Act
        final result = await mockManager.createStatus(yearlyPlan);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value.planId, equals(yearlyPlan.id));
        expect(result.value.expiryDate, isNotNull);

        // 有効期限が約1年後であることを確認（誤差を考慮して360-370日の範囲で確認）
        final daysDifference = result.value.expiryDate!
            .difference(DateTime.now())
            .inDays;
        expect(daysDifference, greaterThanOrEqualTo(360));
        expect(daysDifference, lessThanOrEqualTo(370));
      });

      test('状態作成失敗を設定できる', () async {
        // Arrange
        mockManager.setCreateStatusFailure(true, 'Test createStatus error');
        final plan = BasicPlan();

        // Act
        final result = await mockManager.createStatus(plan);

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test createStatus error'));
      });

      test('状態削除が正常に動作する', () async {
        // Act
        final clearResult = await mockManager.clearStatus();
        final getResult = await mockManager.getCurrentStatus();

        // Assert
        expect(clearResult.isSuccess, true);
        // 削除後にgetCurrentStatusを呼ぶとデフォルト状態が再作成される
        expect(getResult.isSuccess, true);
      });

      test('状態削除失敗を設定できる', () async {
        // Arrange
        mockManager.setClearStatusFailure(true, 'Test clearStatus error');

        // Act
        final result = await mockManager.clearStatus();

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test clearStatus error'));
      });
    });

    group('プラン管理機能', () {
      test('有効なプランIDでプラン取得が成功する', () {
        // Arrange
        final planId = SubscriptionConstants.premiumMonthlyPlanId;

        // Act
        final result = mockManager.getPlanClass(planId);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, isA<PremiumMonthlyPlan>());
        expect(result.value.id, equals(planId));
      });

      test('無効なプランIDでプラン取得が失敗する', () {
        // Act
        final result = mockManager.getPlanClass('invalid_plan_id');

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Invalid plan ID'));
      });

      test('プラン取得失敗を設定できる', () {
        // Arrange
        mockManager.setGetPlanClassFailure(true, 'Test getPlanClass error');

        // Act
        final result = mockManager.getPlanClass('basic');

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test getPlanClass error'));
      });

      test('現在のプラン取得が成功する', () async {
        // Arrange
        final premiumPlan = PremiumYearlyPlan();
        mockManager.setCurrentPlan(premiumPlan);

        // Act
        final result = await mockManager.getCurrentPlanClass();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, isA<PremiumYearlyPlan>());
        expect(result.value.id, equals(premiumPlan.id));
      });

      test('現在のプラン取得失敗を設定できる', () async {
        // Arrange
        mockManager.setGetCurrentPlanClassFailure(
          true,
          'Test getCurrentPlanClass error',
        );

        // Act
        final result = await mockManager.getCurrentPlanClass();

        // Assert
        expect(result.isFailure, true);
        expect(
          result.error.message,
          contains('Test getCurrentPlanClass error'),
        );
      });

      test('強制プランID取得が正常に動作する', () {
        // Assert
        expect(
          mockManager.getForcedPlanId('premium'),
          equals(SubscriptionConstants.premiumMonthlyPlanId),
        );
        expect(
          mockManager.getForcedPlanId('premium_monthly'),
          equals(SubscriptionConstants.premiumMonthlyPlanId),
        );
        expect(
          mockManager.getForcedPlanId('premium_yearly'),
          equals(SubscriptionConstants.premiumYearlyPlanId),
        );
        expect(
          mockManager.getForcedPlanId('basic'),
          equals(SubscriptionConstants.basicPlanId),
        );
        expect(
          mockManager.getForcedPlanId('unknown'),
          equals(SubscriptionConstants.basicPlanId),
        );
      });
    });

    group('サブスクリプション有効性判定', () {
      test('アクティブなBasicプランは有効と判定される', () async {
        // Arrange
        final basicPlan = BasicPlan();
        mockManager.setCurrentPlan(basicPlan);
        final statusResult = await mockManager.getCurrentStatus();

        // Act
        final isValid = mockManager.isSubscriptionValid(statusResult.value);

        // Assert
        expect(isValid, true);
      });

      test('アクティブで有効期限内のPremiumプランは有効と判定される', () {
        // Arrange
        final now = DateTime.now();
        final validStatus = SubscriptionStatus(
          planId: 'premium_monthly',
          isActive: true,
          startDate: now,
          expiryDate: now.add(const Duration(days: 30)),
          autoRenewal: true,
          monthlyUsageCount: 5,
          lastResetDate: now,
          transactionId: 'valid_transaction',
          lastPurchaseDate: now,
        );

        // Act
        final isValid = mockManager.isSubscriptionValid(validStatus);

        // Assert
        expect(isValid, true);
      });

      test('非アクティブなプランは無効と判定される', () {
        // Arrange
        final inactiveStatus = SubscriptionStatus(
          planId: 'premium_monthly',
          isActive: false,
          startDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          autoRenewal: true,
          monthlyUsageCount: 5,
          lastResetDate: DateTime.now(),
          transactionId: 'inactive_transaction',
          lastPurchaseDate: DateTime.now(),
        );

        // Act
        final isValid = mockManager.isSubscriptionValid(inactiveStatus);

        // Assert
        expect(isValid, false);
      });

      test('期限切れのPremiumプランは無効と判定される', () {
        // Arrange
        final now = DateTime.now();
        final expiredStatus = SubscriptionStatus(
          planId: 'premium_monthly',
          isActive: true,
          startDate: now.subtract(const Duration(days: 60)),
          expiryDate: now.subtract(const Duration(days: 1)), // 昨日期限切れ
          autoRenewal: true,
          monthlyUsageCount: 5,
          lastResetDate: now,
          transactionId: 'expired_transaction',
          lastPurchaseDate: now.subtract(const Duration(days: 60)),
        );

        // Act
        final isValid = mockManager.isSubscriptionValid(expiredStatus);

        // Assert
        expect(isValid, false);
      });

      test('有効期限がnullのPremiumプランは無効と判定される', () {
        // Arrange
        final invalidStatus = SubscriptionStatus(
          planId: 'premium_monthly',
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: null, // 有効期限がない
          autoRenewal: true,
          monthlyUsageCount: 5,
          lastResetDate: DateTime.now(),
          transactionId: 'invalid_transaction',
          lastPurchaseDate: DateTime.now(),
        );

        // Act
        final isValid = mockManager.isSubscriptionValid(invalidStatus);

        // Assert
        expect(isValid, false);
      });
    });

    group('プレミアム機能アクセス権限', () {
      test('Basicプランはプレミアム機能にアクセスできない', () async {
        // Arrange
        final basicPlan = BasicPlan();
        mockManager.setCurrentPlan(basicPlan);

        // Act
        final result = await mockManager.canAccessPremiumFeatures();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, false);
      });

      test('有効なPremiumプランはプレミアム機能にアクセスできる', () async {
        // Arrange
        final premiumPlan = PremiumMonthlyPlan();
        mockManager.setCurrentPlan(premiumPlan);

        // Act
        final result = await mockManager.canAccessPremiumFeatures();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, true);
      });

      test('期限切れのPremiumプランはプレミアム機能にアクセスできない', () async {
        // Arrange
        mockManager.createExpiredPremiumStatus();

        // Act
        final result = await mockManager.canAccessPremiumFeatures();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, false);
      });

      test('非アクティブなプランはプレミアム機能にアクセスできない', () async {
        // Arrange
        mockManager.createInactiveStatus();

        // Act
        final result = await mockManager.canAccessPremiumFeatures();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, false);
      });

      test('プレミアム機能アクセス権限チェック失敗を設定できる', () async {
        // Arrange
        mockManager.setCanAccessPremiumFeaturesFailure(
          true,
          'Test canAccessPremiumFeatures error',
        );

        // Act
        final result = await mockManager.canAccessPremiumFeatures();

        // Assert
        expect(result.isFailure, true);
        expect(
          result.error.message,
          contains('Test canAccessPremiumFeatures error'),
        );
      });
    });

    group('テスト用ヘルパーメソッド', () {
      test('使用量を設定できる', () async {
        // Act
        mockManager.setUsageCount(25);
        final result = await mockManager.getCurrentStatus();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value.monthlyUsageCount, equals(25));
      });

      test('有効期限を設定できる', () async {
        // Arrange
        final customExpiryDate = DateTime.now().add(const Duration(days: 15));

        // Act
        mockManager.setExpiryDate(customExpiryDate);
        final result = await mockManager.getCurrentStatus();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value.expiryDate, equals(customExpiryDate));
      });

      test('期限切れPremium状態を作成できる', () async {
        // Act
        mockManager.createExpiredPremiumStatus();
        final result = await mockManager.getCurrentStatus();

        // Assert
        expect(result.isSuccess, true);
        expect(
          result.value.planId,
          equals(SubscriptionConstants.premiumMonthlyPlanId),
        );
        expect(result.value.isActive, true);
        expect(result.value.expiryDate!.isBefore(DateTime.now()), true);
        expect(mockManager.isSubscriptionValid(result.value), false);
      });

      test('非アクティブ状態を作成できる', () async {
        // Act
        mockManager.createInactiveStatus();
        final result = await mockManager.getCurrentStatus();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value.isActive, false);
        expect(mockManager.isSubscriptionValid(result.value), false);
      });

      test('状態をリセットできる', () async {
        // Arrange
        mockManager.setCurrentPlan(PremiumMonthlyPlan());
        mockManager.setGetCurrentStatusFailure(true);

        // Act
        mockManager.resetToDefaults();

        // Assert
        expect(mockManager.isInitialized, true);
        final result = await mockManager.getCurrentStatus();
        expect(result.isSuccess, true);
        expect(result.value.planId, equals(SubscriptionConstants.basicPlanId));
      });
    });

    group('破棄処理', () {
      test('破棄処理が正常に実行される', () {
        // Act
        mockManager.dispose();

        // Assert
        expect(mockManager.isInitialized, false);
      });
    });
  });
}
