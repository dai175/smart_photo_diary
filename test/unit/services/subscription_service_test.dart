import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:smart_photo_diary/services/subscription_service.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/models/subscription_plan.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import '../helpers/hive_test_helpers.dart';

void main() {
  group('SubscriptionService', () {
    late SubscriptionService subscriptionService;
    
    setUpAll(() async {
      // Hiveテスト環境のセットアップ
      await HiveTestHelpers.setupHiveForTesting();
    });
    
    setUp(() async {
      // 各テスト前にHiveボックスをクリア
      await HiveTestHelpers.clearSubscriptionBox();
      
      // SubscriptionServiceインスタンスをリセット
      SubscriptionService.resetForTesting();
    });
    
    tearDownAll(() async {
      // テスト終了時にHiveを閉じる
      await HiveTestHelpers.closeHive();
    });
    
    group('シングルトンパターン', () {
      test('getInstance()は同じインスタンスを返す', () async {
        // Act
        final instance1 = await SubscriptionService.getInstance();
        final instance2 = await SubscriptionService.getInstance();
        
        // Assert
        expect(instance1, same(instance2));
        expect(instance1.isInitialized, isTrue);
      });
      
      test('初期化は一度だけ実行される', () async {
        // Act
        final instance1 = await SubscriptionService.getInstance();
        final instance2 = await SubscriptionService.getInstance();
        
        // Assert
        expect(instance1.isInitialized, isTrue);
        expect(instance2.isInitialized, isTrue);
        
        // 両方とも同じインスタンスなので、初期化も一度だけ
        expect(instance1, same(instance2));
      });
    });
    
    group('初期化処理', () {
      test('初回初期化時にBasicプランの初期状態が作成される', () async {
        // Act
        subscriptionService = await SubscriptionService.getInstance();
        
        // Assert
        expect(subscriptionService.isInitialized, isTrue);
        
        // Hiveボックスが初期化されている
        final box = subscriptionService.subscriptionBox;
        expect(box, isNotNull);
        expect(box!.isOpen, isTrue);
        
        // 初期状態が作成されている
        final status = box.get(SubscriptionConstants.statusKey);
        expect(status, isNotNull);
        expect(status!.planId, equals(SubscriptionPlan.basic.id));
        expect(status.isActive, isTrue);
        expect(status.monthlyUsageCount, equals(0));
        expect(status.expiryDate, isNull); // Basicプランは期限なし
      });
      
      test('既に状態が存在する場合は初期状態を作成しない', () async {
        // Arrange - 事前に状態を作成
        final box = await Hive.openBox<SubscriptionStatus>(
          SubscriptionConstants.hiveBoxName
        );
        
        final existingStatus = SubscriptionStatus(
          planId: SubscriptionPlan.premiumMonthly.id,
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          autoRenewal: true,
          monthlyUsageCount: 5,
          lastResetDate: DateTime.now(),
          transactionId: 'test_transaction',
          lastPurchaseDate: DateTime.now(),
        );
        
        await box.put(SubscriptionConstants.statusKey, existingStatus);
        await box.close();
        
        // Act
        subscriptionService = await SubscriptionService.getInstance();
        
        // Assert
        final status = subscriptionService.subscriptionBox
            ?.get(SubscriptionConstants.statusKey);
        expect(status, isNotNull);
        expect(status!.planId, equals(SubscriptionPlan.premiumMonthly.id));
        expect(status.monthlyUsageCount, equals(5));
        expect(status.transactionId, equals('test_transaction'));
      });
      
      test('正常に初期化が完了する', () async {
        // Act
        subscriptionService = await SubscriptionService.getInstance();
        
        // Assert
        expect(subscriptionService.isInitialized, isTrue);
        expect(subscriptionService.subscriptionBox?.isOpen, isTrue);
      });
    });
    
    group('Hive操作実装確認 (Phase 1.3.2)', () {
      setUp(() async {
        subscriptionService = await SubscriptionService.getInstance();
      });
      
      test('getCurrentStatus()は初期化後にBasicプランを返す', () async {
        // Act
        final result = await subscriptionService.getCurrentStatus();
        
        // Assert
        expect(result.isSuccess, isTrue);
        final status = result.value;
        expect(status.planId, equals(SubscriptionPlan.basic.id));
        expect(status.isActive, isTrue);
        expect(status.monthlyUsageCount, equals(0));
      });
      
      test('updateStatus()でサブスクリプション状態を更新できる', () async {
        // Arrange
        final newStatus = SubscriptionStatus(
          planId: SubscriptionPlan.premiumMonthly.id,
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          autoRenewal: true,
          monthlyUsageCount: 5,
          lastResetDate: DateTime.now(),
          transactionId: 'test_transaction_update',
          lastPurchaseDate: DateTime.now(),
        );
        
        // Act
        final updateResult = await subscriptionService.updateStatus(newStatus);
        final getResult = await subscriptionService.getCurrentStatus();
        
        // Assert
        expect(updateResult.isSuccess, isTrue);
        expect(getResult.isSuccess, isTrue);
        final status = getResult.value;
        expect(status.planId, equals(SubscriptionPlan.premiumMonthly.id));
        expect(status.monthlyUsageCount, equals(5));
        expect(status.transactionId, equals('test_transaction_update'));
      });
      
      test('refreshStatus()でHiveボックスを再読み込みできる', () async {
        // Arrange
        final newStatus = SubscriptionStatus(
          planId: SubscriptionPlan.premiumYearly.id,
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 365)),
          autoRenewal: true,
          monthlyUsageCount: 15,
          lastResetDate: DateTime.now(),
          transactionId: 'test_refresh',
          lastPurchaseDate: DateTime.now(),
        );
        
        await subscriptionService.updateStatus(newStatus);
        
        // Act
        final result = await subscriptionService.refreshStatus();
        
        // Assert
        expect(result.isSuccess, isTrue);
        final status = result.value;
        expect(status.planId, equals(SubscriptionPlan.premiumYearly.id));
        expect(status.monthlyUsageCount, equals(15));
        expect(status.transactionId, equals('test_refresh'));
      });
      
      test('createStatus()でBasicプランの状態を作成できる', () async {
        // Arrange
        await subscriptionService.clearStatus();
        
        // Act
        final result = await subscriptionService.createStatus(SubscriptionPlan.basic);
        
        // Assert
        expect(result.isSuccess, isTrue);
        final status = result.value;
        expect(status.planId, equals(SubscriptionPlan.basic.id));
        expect(status.isActive, isTrue);
        expect(status.expiryDate, isNull); // Basicプランは期限なし
        expect(status.autoRenewal, isFalse);
        expect(status.monthlyUsageCount, equals(0));
      });
      
      test('createStatus()でPremium月額プランの状態を作成できる', () async {
        // Arrange
        await subscriptionService.clearStatus();
        
        // Act
        final result = await subscriptionService.createStatus(SubscriptionPlan.premiumMonthly);
        
        // Assert
        expect(result.isSuccess, isTrue);
        final status = result.value;
        expect(status.planId, equals(SubscriptionPlan.premiumMonthly.id));
        expect(status.isActive, isTrue);
        expect(status.expiryDate, isNotNull);
        expect(status.autoRenewal, isTrue);
        expect(status.monthlyUsageCount, equals(0));
        
        // 有効期限が月額プラン期間（30日）に設定されている
        final expectedExpiry = status.startDate!.add(Duration(days: SubscriptionConstants.subscriptionMonthDays));
        expect(status.expiryDate!.difference(expectedExpiry).inMinutes.abs(), lessThan(1));
      });
      
      test('createStatus()でPremium年額プランの状態を作成できる', () async {
        // Arrange
        await subscriptionService.clearStatus();
        
        // Act
        final result = await subscriptionService.createStatus(SubscriptionPlan.premiumYearly);
        
        // Assert
        expect(result.isSuccess, isTrue);
        final status = result.value;
        expect(status.planId, equals(SubscriptionPlan.premiumYearly.id));
        expect(status.isActive, isTrue);
        expect(status.expiryDate, isNotNull);
        expect(status.autoRenewal, isTrue);
        expect(status.monthlyUsageCount, equals(0));
        
        // 有効期限が年額プラン期間（365日）に設定されている
        final expectedExpiry = status.startDate!.add(Duration(days: SubscriptionConstants.subscriptionYearDays));
        expect(status.expiryDate!.difference(expectedExpiry).inMinutes.abs(), lessThan(1));
      });
      
      test('clearStatus()でサブスクリプション状態を削除できる', () async {
        // Act
        final clearResult = await subscriptionService.clearStatus();
        final getResult = await subscriptionService.getCurrentStatus();
        
        // Assert
        expect(clearResult.isSuccess, isTrue);
        expect(getResult.isSuccess, isTrue);
        // getCurrentStatus()は状態がない場合に初期状態を作成するため、Basicプランが返される
        final status = getResult.value;
        expect(status.planId, equals(SubscriptionPlan.basic.id));
      });
    });
    
    group('未実装メソッド確認', () {
      setUp(() async {
        subscriptionService = await SubscriptionService.getInstance();
      });
      
      test('getCurrentStatus()は正常にBasicプランを返す', () async {
        // Act
        final result = await subscriptionService.getCurrentStatus();
        
        // Assert
        expect(result.isSuccess, isTrue);
        final status = result.value;
        expect(status.planId, equals(SubscriptionPlan.basic.id));
        expect(status.isActive, isTrue);
      });
      
      test('canUseAiGeneration()は未実装エラーを返す', () async {
        // Act
        final result = await subscriptionService.canUseAiGeneration();
        
        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error.toString(), contains('Phase 1.3.3で実装予定'));
      });
      
      test('canAccessPremiumFeatures()は未実装エラーを返す', () async {
        // Act
        final result = await subscriptionService.canAccessPremiumFeatures();
        
        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error.toString(), contains('Phase 1.3.4で実装予定'));
      });
    });
    
    group('内部状態確認', () {
      test('isInitialized プロパティが正しく動作する', () async {
        // Arrange
        SubscriptionService.resetForTesting();
        
        // Act
        subscriptionService = await SubscriptionService.getInstance();
        
        // Assert
        expect(subscriptionService.isInitialized, isTrue);
      });
      
      test('subscriptionBox プロパティがHiveボックスを返す', () async {
        // Act
        subscriptionService = await SubscriptionService.getInstance();
        
        // Assert
        final box = subscriptionService.subscriptionBox;
        expect(box, isNotNull);
        expect(box!.isOpen, isTrue);
        expect(box.name, equals(SubscriptionConstants.hiveBoxName));
      });
      
      test('resetForTesting()でインスタンスがリセットされる', () async {
        // Arrange
        final instance1 = await SubscriptionService.getInstance();
        
        // Act
        SubscriptionService.resetForTesting();
        final instance2 = await SubscriptionService.getInstance();
        
        // Assert
        expect(instance1, isNot(same(instance2)));
      });
    });
  });
}