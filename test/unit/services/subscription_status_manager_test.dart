import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:smart_photo_diary/services/subscription_status_manager.dart';
import 'package:smart_photo_diary/services/logging_service.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import '../helpers/hive_test_helpers.dart';

void main() {
  group('SubscriptionStatusManager', () {
    late SubscriptionStatusManager statusManager;
    late Box<SubscriptionStatus> mockSubscriptionBox;
    late LoggingService mockLoggingService;

    setUpAll(() async {
      // Hiveテスト環境のセットアップ
      await HiveTestHelpers.setupHiveForTesting();
    });

    setUp(() async {
      // 各テスト前にHiveボックスをクリア
      await HiveTestHelpers.clearSubscriptionBox();

      // モックHiveボックス取得
      mockSubscriptionBox = await Hive.openBox<SubscriptionStatus>('subscription');
      
      // LoggingServiceインスタンスを作成
      mockLoggingService = await LoggingService.getInstance();
      
      // StatusManagerインスタンス作成
      statusManager = SubscriptionStatusManager(
        mockSubscriptionBox,
        mockLoggingService,
      );
    });

    tearDown(() async {
      statusManager.dispose();
      await mockSubscriptionBox.clear();
    });

    tearDownAll(() async {
      await HiveTestHelpers.closeHive();
    });

    group('初期化とプロパティ', () {
      test('初期化後にisInitializedがtrueになる', () {
        // Assert
        expect(statusManager.isInitialized, isTrue);
      });
    });

    group('getCurrentStatus()', () {
      test('初期状態で基本プランのStatusが作成される', () async {
        // Act
        final result = await statusManager.getCurrentStatus();

        // Assert
        expect(result.isSuccess, isTrue);
        
        final status = result.value;
        expect(status.planId, equals(SubscriptionConstants.basicPlanId));
        expect(status.isActive, isTrue);
        expect(status.expiryDate, isNull);
        expect(status.monthlyUsageCount, equals(0));
        expect(status.autoRenewal, isFalse);
      });

      test('保存済みStatusが存在する場合、それを返す', () async {
        // Arrange
        final savedStatus = SubscriptionStatus(
          planId: SubscriptionConstants.premiumMonthlyPlanId,
          isActive: true,
          startDate: DateTime.now().subtract(const Duration(days: 10)),
          expiryDate: DateTime.now().add(const Duration(days: 20)),
          autoRenewal: true,
          monthlyUsageCount: 5,
          lastResetDate: DateTime.now().subtract(const Duration(days: 10)),
          transactionId: 'test_transaction',
          lastPurchaseDate: DateTime.now().subtract(const Duration(days: 10)),
        );
        
        await mockSubscriptionBox.put(SubscriptionConstants.statusKey, savedStatus);

        // Act
        final result = await statusManager.getCurrentStatus();

        // Assert
        expect(result.isSuccess, isTrue);
        
        final status = result.value;
        expect(status.planId, equals(SubscriptionConstants.premiumMonthlyPlanId));
        expect(status.isActive, isTrue);
        expect(status.monthlyUsageCount, equals(5));
        expect(status.autoRenewal, isTrue);
      });

    });

    group('updateStatus()', () {
      test('新しいStatusが正常に保存される', () async {
        // Arrange
        final newStatus = SubscriptionStatus(
          planId: SubscriptionConstants.premiumMonthlyPlanId,
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          autoRenewal: true,
          monthlyUsageCount: 3,
          lastResetDate: DateTime.now(),
          transactionId: 'new_transaction',
          lastPurchaseDate: DateTime.now(),
        );

        // Act
        final result = await statusManager.updateStatus(newStatus);

        // Assert
        expect(result.isSuccess, isTrue);
        
        // 保存されたかを確認
        final savedStatus = mockSubscriptionBox.get(SubscriptionConstants.statusKey);
        expect(savedStatus, isNotNull);
        expect(savedStatus!.planId, equals(SubscriptionConstants.premiumMonthlyPlanId));
        expect(savedStatus.monthlyUsageCount, equals(3));
      });
    });

    group('refreshStatus()', () {
      test('Status情報が正常にリフレッシュされる', () async {
        // Arrange
        final existingStatus = SubscriptionStatus(
          planId: SubscriptionConstants.basicPlanId,
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: null,
          autoRenewal: false,
          monthlyUsageCount: 2,
          lastResetDate: DateTime.now(),
          transactionId: '',
          lastPurchaseDate: null,
        );
        
        await mockSubscriptionBox.put(SubscriptionConstants.statusKey, existingStatus);

        // Act
        final result = await statusManager.refreshStatus();

        // Assert
        expect(result.isSuccess, isTrue);
      });
    });

    group('createStatus()', () {
      test('Basicプラン用のStatusが正常に作成される', () async {
        // Arrange
        final basicPlan = BasicPlan();

        // Act
        final result = await statusManager.createStatus(basicPlan);

        // Assert
        expect(result.isSuccess, isTrue);
        
        final status = result.value;
        expect(status.planId, equals(SubscriptionConstants.basicPlanId));
        expect(status.isActive, isTrue);
        expect(status.expiryDate, isNull);
        expect(status.autoRenewal, isFalse);
        expect(status.monthlyUsageCount, equals(0));
        expect(status.transactionId, isEmpty);
        expect(status.lastPurchaseDate, isNull);
      });

      test('PremiumMonthlyプラン用のStatusが正常に作成される', () async {
        // Arrange
        final premiumPlan = PremiumMonthlyPlan();

        // Act
        final result = await statusManager.createStatus(premiumPlan);

        // Assert
        expect(result.isSuccess, isTrue);
        
        final status = result.value;
        expect(status.planId, equals(SubscriptionConstants.premiumMonthlyPlanId));
        expect(status.isActive, isTrue);
        expect(status.expiryDate, isNotNull);
        expect(status.expiryDate!.isAfter(DateTime.now().add(const Duration(days: 29))), isTrue);
        expect(status.autoRenewal, isTrue);
        expect(status.monthlyUsageCount, equals(0));
        expect(status.transactionId, isNotEmpty);
        expect(status.lastPurchaseDate, isNotNull);
      });

      test('PremiumYearlyプラン用のStatusが正常に作成される', () async {
        // Arrange
        final premiumPlan = PremiumYearlyPlan();

        // Act
        final result = await statusManager.createStatus(premiumPlan);

        // Assert
        expect(result.isSuccess, isTrue);
        
        final status = result.value;
        expect(status.planId, equals(SubscriptionConstants.premiumYearlyPlanId));
        expect(status.isActive, isTrue);
        expect(status.expiryDate, isNotNull);
        expect(status.expiryDate!.isAfter(DateTime.now().add(const Duration(days: 364))), isTrue);
        expect(status.autoRenewal, isTrue);
        expect(status.monthlyUsageCount, equals(0));
        expect(status.transactionId, isNotEmpty);
        expect(status.lastPurchaseDate, isNotNull);
      });
    });

    group('clearStatus()', () {
      test('Status情報が正常に削除される', () async {
        // Arrange
        final existingStatus = SubscriptionStatus(
          planId: SubscriptionConstants.basicPlanId,
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: null,
          autoRenewal: false,
          monthlyUsageCount: 2,
          lastResetDate: DateTime.now(),
          transactionId: '',
          lastPurchaseDate: null,
        );
        
        await mockSubscriptionBox.put(SubscriptionConstants.statusKey, existingStatus);

        // Act
        final result = await statusManager.clearStatus();

        // Assert
        expect(result.isSuccess, isTrue);
        
        // 削除されたかを確認
        final savedStatus = mockSubscriptionBox.get(SubscriptionConstants.statusKey);
        expect(savedStatus, isNull);
      });
    });

    group('getPlanClass()', () {
      test('BasicプランIDから正しいPlanクラスが取得できる', () {
        // Act
        final result = statusManager.getPlanClass(SubscriptionConstants.basicPlanId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value.id, equals(SubscriptionConstants.basicPlanId));
        expect(result.value.displayName, equals('Basic'));
      });

      test('PremiumMonthlyプランIDから正しいPlanクラスが取得できる', () {
        // Act
        final result = statusManager.getPlanClass(SubscriptionConstants.premiumMonthlyPlanId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value.id, equals(SubscriptionConstants.premiumMonthlyPlanId));
        expect(result.value.displayName, equals('Premium (月額)'));
      });

      test('PremiumYearlyプランIDから正しいPlanクラスが取得できる', () {
        // Act
        final result = statusManager.getPlanClass(SubscriptionConstants.premiumYearlyPlanId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value.id, equals(SubscriptionConstants.premiumYearlyPlanId));
        expect(result.value.displayName, equals('Premium (年額)'));
      });

      test('不正なプランIDの場合にエラーが返される', () {
        // Act
        final result = statusManager.getPlanClass('invalid_plan_id');

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
      });
    });

    group('getCurrentPlanClass()', () {
      test('現在のプランクラスが正常に取得できる', () async {
        // Arrange - PremiumMonthlyプランのStatusを作成
        final premiumStatus = SubscriptionStatus(
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
        
        await mockSubscriptionBox.put(SubscriptionConstants.statusKey, premiumStatus);

        // Act
        final result = await statusManager.getCurrentPlanClass();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value.id, equals(SubscriptionConstants.premiumMonthlyPlanId));
        expect(result.value.displayName, equals('Premium (月額)'));
      });
    });

    group('getForcedPlanId()', () {
      test('各種強制プラン名から正しいプランIDが取得できる', () {
        // Test cases
        final testCases = {
          'premium': SubscriptionConstants.premiumMonthlyPlanId,
          'premium_monthly': SubscriptionConstants.premiumMonthlyPlanId,
          'premium_yearly': SubscriptionConstants.premiumYearlyPlanId,
          'basic': SubscriptionConstants.basicPlanId,
          'unknown': SubscriptionConstants.basicPlanId, // デフォルト
        };

        testCases.forEach((input, expected) {
          // Act
          final result = statusManager.getForcedPlanId(input);

          // Assert
          expect(result, equals(expected), reason: 'Input: $input');
        });
      });
    });

    group('isSubscriptionValid()', () {
      test('アクティブなBasicプランは有効と判定される', () {
        // Arrange
        final basicStatus = SubscriptionStatus(
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

        // Act
        final result = statusManager.isSubscriptionValid(basicStatus);

        // Assert
        expect(result, isTrue);
      });

      test('非アクティブなプランは無効と判定される', () {
        // Arrange
        final inactiveStatus = SubscriptionStatus(
          planId: SubscriptionConstants.premiumMonthlyPlanId,
          isActive: false,
          startDate: DateTime.now().subtract(const Duration(days: 10)),
          expiryDate: DateTime.now().add(const Duration(days: 20)),
          autoRenewal: true,
          monthlyUsageCount: 0,
          lastResetDate: DateTime.now(),
          transactionId: 'test',
          lastPurchaseDate: DateTime.now(),
        );

        // Act
        final result = statusManager.isSubscriptionValid(inactiveStatus);

        // Assert
        expect(result, isFalse);
      });

      test('期限切れのPremiumプランは無効と判定される', () {
        // Arrange
        final expiredStatus = SubscriptionStatus(
          planId: SubscriptionConstants.premiumMonthlyPlanId,
          isActive: true,
          startDate: DateTime.now().subtract(const Duration(days: 40)),
          expiryDate: DateTime.now().subtract(const Duration(days: 10)),
          autoRenewal: true,
          monthlyUsageCount: 0,
          lastResetDate: DateTime.now(),
          transactionId: 'test',
          lastPurchaseDate: DateTime.now(),
        );

        // Act
        final result = statusManager.isSubscriptionValid(expiredStatus);

        // Assert
        expect(result, isFalse);
      });

      test('有効期限内のPremiumプランは有効と判定される', () {
        // Arrange
        final validPremiumStatus = SubscriptionStatus(
          planId: SubscriptionConstants.premiumMonthlyPlanId,
          isActive: true,
          startDate: DateTime.now().subtract(const Duration(days: 10)),
          expiryDate: DateTime.now().add(const Duration(days: 20)),
          autoRenewal: true,
          monthlyUsageCount: 0,
          lastResetDate: DateTime.now(),
          transactionId: 'test',
          lastPurchaseDate: DateTime.now(),
        );

        // Act
        final result = statusManager.isSubscriptionValid(validPremiumStatus);

        // Assert
        expect(result, isTrue);
      });
    });

    group('canAccessPremiumFeatures()', () {
      test('有効なPremiumプランでプレミアム機能にアクセス可能', () async {
        // Arrange
        final premiumStatus = SubscriptionStatus(
          planId: SubscriptionConstants.premiumMonthlyPlanId,
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          autoRenewal: true,
          monthlyUsageCount: 0,
          lastResetDate: DateTime.now(),
          transactionId: 'test',
          lastPurchaseDate: DateTime.now(),
        );
        
        await mockSubscriptionBox.put(SubscriptionConstants.statusKey, premiumStatus);

        // Act
        final result = await statusManager.canAccessPremiumFeatures();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('Basicプランではプレミアム機能にアクセス不可', () async {
        // Arrange - getCurrentStatus()で自動作成されるBasicプランを使用

        // Act
        final result = await statusManager.canAccessPremiumFeatures();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });

      test('期限切れのPremiumプランではプレミアム機能にアクセス不可', () async {
        // Arrange
        final expiredPremiumStatus = SubscriptionStatus(
          planId: SubscriptionConstants.premiumMonthlyPlanId,
          isActive: true,
          startDate: DateTime.now().subtract(const Duration(days: 40)),
          expiryDate: DateTime.now().subtract(const Duration(days: 10)),
          autoRenewal: true,
          monthlyUsageCount: 0,
          lastResetDate: DateTime.now(),
          transactionId: 'test',
          lastPurchaseDate: DateTime.now(),
        );
        
        await mockSubscriptionBox.put(SubscriptionConstants.statusKey, expiredPremiumStatus);

        // Act
        final result = await statusManager.canAccessPremiumFeatures();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });
    });

    group('dispose()', () {
      test('dispose()後にisInitializedがfalseになる', () {
        // Act
        statusManager.dispose();

        // Assert
        expect(statusManager.isInitialized, isFalse);
      });
    });

    group('エラーハンドリング', () {
      late SubscriptionStatusManager uninitializedManager;

      setUp(() {
        // 初期化されていないマネージャーを作成
        uninitializedManager = SubscriptionStatusManager(
          mockSubscriptionBox,
          mockLoggingService,
        );
        // disposeで初期化フラグを無効化
        uninitializedManager.dispose();
      });

      test('初期化されていない場合、getCurrentStatus()がエラーを返す', () async {
        // Act
        final result = await uninitializedManager.getCurrentStatus();

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
        expect(result.error.message, contains('StatusManager is not initialized'));
      });

      test('初期化されていない場合、updateStatus()がエラーを返す', () async {
        // Arrange
        final testStatus = SubscriptionStatus(
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

        // Act
        final result = await uninitializedManager.updateStatus(testStatus);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
        expect(result.error.message, contains('StatusManager is not initialized'));
      });

      test('初期化されていない場合、refreshStatus()がエラーを返す', () async {
        // Act
        final result = await uninitializedManager.refreshStatus();

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
        expect(result.error.message, contains('StatusManager is not initialized'));
      });

      test('初期化されていない場合、createStatus()がエラーを返す', () async {
        // Arrange
        final basicPlan = BasicPlan();

        // Act
        final result = await uninitializedManager.createStatus(basicPlan);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
        expect(result.error.message, contains('StatusManager is not initialized'));
      });

      test('初期化されていない場合、clearStatus()がエラーを返す', () async {
        // Act
        final result = await uninitializedManager.clearStatus();

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
        expect(result.error.message, contains('StatusManager is not initialized'));
      });

      test('初期化されていない場合、getCurrentPlanClass()がエラーを返す', () async {
        // Act
        final result = await uninitializedManager.getCurrentPlanClass();

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
      });

      test('初期化されていない場合、canAccessPremiumFeatures()がエラーを返す', () async {
        // Act
        final result = await uninitializedManager.canAccessPremiumFeatures();

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
      });

      test('Hive操作でエラーが発生した場合、適切にハンドリングされる', () async {
        // Arrange
        await mockSubscriptionBox.close(); // ボックスを閉じてエラーを発生させる

        // Act
        final result = await statusManager.getCurrentStatus();

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());

        // テスト後にボックスを再オープン
        mockSubscriptionBox = await Hive.openBox<SubscriptionStatus>('subscription');
        statusManager = SubscriptionStatusManager(
          mockSubscriptionBox,
          mockLoggingService,
        );
      });
    });

    group('境界値テスト', () {
      test('Premiumプランの有効期限ちょうどの場合、無効と判定される', () {
        // Arrange
        final now = DateTime.now();
        final expiredStatus = SubscriptionStatus(
          planId: SubscriptionConstants.premiumMonthlyPlanId,
          isActive: true,
          startDate: now.subtract(const Duration(days: 30)),
          expiryDate: now, // ちょうど今の時刻
          autoRenewal: true,
          monthlyUsageCount: 0,
          lastResetDate: now,
          transactionId: 'test',
          lastPurchaseDate: now,
        );

        // Act
        final result = statusManager.isSubscriptionValid(expiredStatus);

        // Assert
        expect(result, isFalse);
      });

      test('有効期限がnullのPremiumプランは無効と判定される', () {
        // Arrange
        final statusWithNullExpiry = SubscriptionStatus(
          planId: SubscriptionConstants.premiumMonthlyPlanId,
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: null, // 有効期限がnull
          autoRenewal: true,
          monthlyUsageCount: 0,
          lastResetDate: DateTime.now(),
          transactionId: 'test',
          lastPurchaseDate: DateTime.now(),
        );

        // Act
        final result = statusManager.isSubscriptionValid(statusWithNullExpiry);

        // Assert
        expect(result, isFalse);
      });
    });
  });
}