import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:async';

import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';
import 'package:smart_photo_diary/services/logging_service.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import '../../mocks/mock_subscription_purchase_manager.dart';

// モッククラス
class MockLoggingService extends Mock implements LoggingService {}

void main() {
  group('MockSubscriptionPurchaseManager', () {
    late MockSubscriptionPurchaseManager mockManager;
    late MockLoggingService mockLoggingService;

    setUp(() {
      mockManager = MockSubscriptionPurchaseManager();
      mockLoggingService = MockLoggingService();
      
      // LoggingServiceの基本セットアップ
      when(() => mockLoggingService.debug(any(), context: any(named: 'context'), data: any(named: 'data'))).thenReturn(null);
      when(() => mockLoggingService.info(any(), context: any(named: 'context'), data: any(named: 'data'))).thenReturn(null);
      when(() => mockLoggingService.warning(any(), context: any(named: 'context'), data: any(named: 'data'))).thenReturn(null);
      when(() => mockLoggingService.error(any(), context: any(named: 'context'), error: any(named: 'error'))).thenReturn(null);
    });

    tearDown(() async {
      if (mockManager.isInitialized) {
        await mockManager.dispose();
      }
    });

    group('初期化とセットアップ', () {
      test('初期状態では未初期化', () {
        expect(mockManager.isInitialized, false);
        expect(mockManager.isPurchasing, false);
      });

      test('初期化が成功する', () async {
        // Act
        final result = await mockManager.initialize(mockLoggingService);

        // Assert
        expect(result.isSuccess, true);
        expect(mockManager.isInitialized, true);
      });

      test('初期化失敗を設定できる', () async {
        // Arrange
        mockManager.setInitializationFailure(true, 'Test initialization error');

        // Act
        final result = await mockManager.initialize(mockLoggingService);

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test initialization error'));
        expect(mockManager.isInitialized, false);
      });

      test('コールバックを設定できる', () {
        // Arrange
        void callback(SubscriptionStatus status) {
          // コールバック処理
        }

        // Act & Assert
        expect(() => mockManager.setSubscriptionStatusUpdateCallback(callback), returnsNormally);
      });
    });

    group('商品情報取得', () {
      test('初期化前は取得エラーを返す', () async {
        // Act
        final result = await mockManager.getProducts();

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('not initialized'));
      });

      test('初期化後は商品リストを返す', () async {
        // Arrange
        await mockManager.initialize(mockLoggingService);

        // Act
        final result = await mockManager.getProducts();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, isA<List<PurchaseProduct>>());
        expect(result.value.length, equals(2)); // Monthly + Yearly
        expect(result.value.first.id, equals('smart_photo_diary_premium_monthly'));
      });

      test('商品取得失敗を設定できる', () async {
        // Arrange
        await mockManager.initialize(mockLoggingService);
        mockManager.setGetProductsFailure(true, 'Test products error');

        // Act
        final result = await mockManager.getProducts();

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test products error'));
      });

      test('カスタム商品リストを設定できる', () async {
        // Arrange
        await mockManager.initialize(mockLoggingService);
        final customProducts = [
          PurchaseProduct(
            id: 'custom_product',
            title: 'Custom Product',
            description: 'Test product',
            price: '¥100',
            priceAmount: 100.0,
            currencyCode: 'JPY',
            plan: PremiumMonthlyPlan(),
          ),
        ];
        mockManager.setAvailableProducts(customProducts);

        // Act
        final result = await mockManager.getProducts();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value.length, equals(1));
        expect(result.value.first.id, equals('custom_product'));
      });
    });

    group('購入処理', () {
      test('初期化前は購入エラーを返す', () async {
        // Arrange
        final plan = PremiumMonthlyPlan();

        // Act
        final result = await mockManager.purchasePlanClass(plan);

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('not initialized'));
      });

      test('Basicプランの購入はエラーを返す', () async {
        // Arrange
        await mockManager.initialize(mockLoggingService);
        final plan = BasicPlan();

        // Act
        final result = await mockManager.purchasePlanClass(plan);

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Basic plan cannot be purchased'));
      });

      test('購入処理中は二重購入を拒否する', () async {
        // Arrange
        await mockManager.initialize(mockLoggingService);
        mockManager.setPurchasing(true);
        final plan = PremiumMonthlyPlan();

        // Act
        final result = await mockManager.purchasePlanClass(plan);

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Another purchase is already in progress'));
      });

      test('正常な購入処理が成功する', () async {
        // Arrange
        await mockManager.initialize(mockLoggingService);
        final plan = PremiumMonthlyPlan();
        final List<PurchaseResult> streamResults = [];
        
        // ストリームを監視
        final subscription = mockManager.purchaseStream.listen(streamResults.add);

        // Act
        final result = await mockManager.purchasePlanClass(plan);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value.status, equals(PurchaseStatus.purchased));
        expect(result.value.productId, equals(plan.productId));
        expect(result.value.transactionId, isNotNull);
        expect(result.value.purchaseDate, isNotNull);
        
        // ストリーム通知も確認
        await Future.delayed(const Duration(milliseconds: 100));
        expect(streamResults.length, equals(1));
        expect(streamResults.first.status, equals(PurchaseStatus.purchased));

        await subscription.cancel();
      });

      test('購入失敗を設定できる', () async {
        // Arrange
        await mockManager.initialize(mockLoggingService);
        mockManager.setPurchaseFailure(true, 'Test purchase error');
        final plan = PremiumYearlyPlan();
        final List<PurchaseResult> streamResults = [];
        
        final subscription = mockManager.purchaseStream.listen(streamResults.add);

        // Act
        final result = await mockManager.purchasePlanClass(plan);

        // Assert
        expect(result.isSuccess, true); // 購入失敗もPurchaseResultで返される
        expect(result.value.status, equals(PurchaseStatus.error));
        expect(result.value.errorMessage, contains('Test purchase error'));
        
        // ストリーム通知も確認
        await Future.delayed(const Duration(milliseconds: 100));
        expect(streamResults.length, equals(1));
        expect(streamResults.first.status, equals(PurchaseStatus.error));

        await subscription.cancel();
      });

      test('プラン変更は未実装エラーを返す', () async {
        // Arrange
        await mockManager.initialize(mockLoggingService);
        final plan = PremiumYearlyPlan();

        // Act
        final result = await mockManager.changePlanClass(plan);

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('not yet implemented'));
      });
    });

    group('復元・検証機能', () {
      test('初期化前は復元エラーを返す', () async {
        // Act
        final result = await mockManager.restorePurchases();

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('not initialized'));
      });

      test('空の履歴で復元が成功する', () async {
        // Arrange
        await mockManager.initialize(mockLoggingService);

        // Act
        final result = await mockManager.restorePurchases();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, isEmpty);
      });

      test('購入履歴がある場合の復元処理', () async {
        // Arrange
        await mockManager.initialize(mockLoggingService);
        final mockHistory = [
          PurchaseResult(
            status: PurchaseStatus.purchased,
            productId: 'test_product',
            transactionId: 'test_transaction',
            purchaseDate: DateTime.now(),
          ),
        ];
        mockManager.setPurchaseHistory(mockHistory);
        final List<PurchaseResult> streamResults = [];
        
        final subscription = mockManager.purchaseStream.listen(streamResults.add);

        // Act
        final result = await mockManager.restorePurchases();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value.length, equals(1));
        
        // ストリーム通知で復元が通知される
        await Future.delayed(const Duration(milliseconds: 300));
        expect(streamResults.length, equals(1));
        expect(streamResults.first.status, equals(PurchaseStatus.restored));

        await subscription.cancel();
      });

      test('復元失敗を設定できる', () async {
        // Arrange
        await mockManager.initialize(mockLoggingService);
        mockManager.setRestoreFailure(true, 'Test restore error');

        // Act
        final result = await mockManager.restorePurchases();

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test restore error'));
      });

      test('初期化前は検証エラーを返す', () async {
        // Act
        final result = await mockManager.validatePurchase(
          'test_transaction',
          () => Success(SubscriptionStatus(
            planId: 'basic',
            isActive: true,
            startDate: DateTime.now(),
            expiryDate: null,
            autoRenewal: false,
            monthlyUsageCount: 0,
            lastResetDate: DateTime.now(),
            transactionId: '',
            lastPurchaseDate: null,
          )),
        );

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('not initialized'));
      });

      test('有効なトランザクションIDの検証が成功する', () async {
        // Arrange
        await mockManager.initialize(mockLoggingService);
        const transactionId = 'test_transaction_123';
        
        Future<Result<SubscriptionStatus>> getCurrentStatus() async {
          return Success(SubscriptionStatus(
            planId: 'premium_monthly',
            isActive: true,
            startDate: DateTime.now(),
            expiryDate: DateTime.now().add(const Duration(days: 30)),
            autoRenewal: true,
            monthlyUsageCount: 5,
            lastResetDate: DateTime.now(),
            transactionId: transactionId,
            lastPurchaseDate: DateTime.now(),
          ));
        }

        // Act
        final result = await mockManager.validatePurchase(transactionId, getCurrentStatus);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, true);
      });

      test('無効なトランザクションIDの検証は失敗する', () async {
        // Arrange
        await mockManager.initialize(mockLoggingService);
        const transactionId = 'invalid_transaction';
        
        Future<Result<SubscriptionStatus>> getCurrentStatus() async {
          return Success(SubscriptionStatus(
            planId: 'premium_monthly',
            isActive: true,
            startDate: DateTime.now(),
            expiryDate: DateTime.now().add(const Duration(days: 30)),
            autoRenewal: true,
            monthlyUsageCount: 5,
            lastResetDate: DateTime.now(),
            transactionId: 'different_transaction',
            lastPurchaseDate: DateTime.now(),
          ));
        }

        // Act
        final result = await mockManager.validatePurchase(transactionId, getCurrentStatus);

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, false);
      });

      test('検証失敗を設定できる', () async {
        // Arrange
        await mockManager.initialize(mockLoggingService);
        mockManager.setValidationFailure(true, 'Test validation error');
        
        Future<Result<SubscriptionStatus>> getCurrentStatus() async {
          return Success(SubscriptionStatus(
            planId: 'basic',
            isActive: true,
            startDate: DateTime.now(),
            expiryDate: null,
            autoRenewal: false,
            monthlyUsageCount: 0,
            lastResetDate: DateTime.now(),
            transactionId: '',
            lastPurchaseDate: null,
          ));
        }

        // Act
        final result = await mockManager.validatePurchase('test', getCurrentStatus);

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('Test validation error'));
      });
    });

    group('キャンセル処理', () {
      test('初期化前はキャンセルエラーを返す', () async {
        // Act
        final result = await mockManager.cancelSubscription(
          () => Success(SubscriptionStatus(
            planId: 'basic',
            isActive: true,
            startDate: DateTime.now(),
            expiryDate: null,
            autoRenewal: false,
            monthlyUsageCount: 0,
            lastResetDate: DateTime.now(),
            transactionId: '',
            lastPurchaseDate: null,
          )),
          (status) {},
        );

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('not initialized'));
      });

      test('キャンセル処理が成功する', () async {
        // Arrange
        await mockManager.initialize(mockLoggingService);
        SubscriptionStatus? updatedStatus;
        
        Future<Result<SubscriptionStatus>> getCurrentStatus() async {
          return Success(SubscriptionStatus(
            planId: 'premium_monthly',
            isActive: true,
            startDate: DateTime.now(),
            expiryDate: DateTime.now().add(const Duration(days: 30)),
            autoRenewal: true,
            monthlyUsageCount: 5,
            lastResetDate: DateTime.now(),
            transactionId: 'test_transaction',
            lastPurchaseDate: DateTime.now(),
          ));
        }
        
        void updateStatus(SubscriptionStatus status) {
          updatedStatus = status;
        }

        // Act
        final result = await mockManager.cancelSubscription(getCurrentStatus, updateStatus);

        // Assert
        expect(result.isSuccess, true);
        expect(updatedStatus, isNotNull);
        expect(updatedStatus!.autoRenewal, false);
        expect(updatedStatus!.planId, equals('premium_monthly'));
      });
    });

    group('テスト用ヘルパーメソッド', () {
      test('購入完了をシミュレートできる', () async {
        // Arrange
        await mockManager.initialize(mockLoggingService);
        const productId = 'test_product';
        final plan = PremiumMonthlyPlan();
        final List<PurchaseResult> streamResults = [];
        
        final subscription = mockManager.purchaseStream.listen(streamResults.add);

        // Act
        mockManager.simulatePurchaseComplete(productId, plan);

        // Assert
        await Future.delayed(const Duration(milliseconds: 100));
        expect(streamResults.length, equals(1));
        expect(streamResults.first.status, equals(PurchaseStatus.purchased));
        expect(streamResults.first.productId, equals(productId));

        await subscription.cancel();
      });

      test('購入キャンセルをシミュレートできる', () async {
        // Arrange
        await mockManager.initialize(mockLoggingService);
        mockManager.setPurchasing(true);
        const productId = 'test_product';
        final List<PurchaseResult> streamResults = [];
        
        final subscription = mockManager.purchaseStream.listen(streamResults.add);

        // Act
        mockManager.simulatePurchaseCancel(productId);

        // Assert
        expect(mockManager.isPurchasing, false);
        await Future.delayed(const Duration(milliseconds: 100));
        expect(streamResults.length, equals(1));
        expect(streamResults.first.status, equals(PurchaseStatus.cancelled));

        await subscription.cancel();
      });

      test('購入エラーをシミュレートできる', () async {
        // Arrange
        await mockManager.initialize(mockLoggingService);
        mockManager.setPurchasing(true);
        const productId = 'test_product';
        const errorMessage = 'Test error';
        final List<PurchaseResult> streamResults = [];
        
        final subscription = mockManager.purchaseStream.listen(streamResults.add);

        // Act
        mockManager.simulatePurchaseError(productId, errorMessage);

        // Assert
        expect(mockManager.isPurchasing, false);
        await Future.delayed(const Duration(milliseconds: 100));
        expect(streamResults.length, equals(1));
        expect(streamResults.first.status, equals(PurchaseStatus.error));
        expect(streamResults.first.errorMessage, equals(errorMessage));

        await subscription.cancel();
      });

      test('購入履歴をクリアできる', () async {
        // Arrange
        await mockManager.initialize(mockLoggingService);
        final mockHistory = [
          PurchaseResult(
            status: PurchaseStatus.purchased,
            productId: 'test_product',
            transactionId: 'test_transaction',
            purchaseDate: DateTime.now(),
          ),
        ];
        mockManager.setPurchaseHistory(mockHistory);

        // Act
        mockManager.clearPurchaseHistory();
        final result = await mockManager.restorePurchases();

        // Assert
        expect(result.isSuccess, true);
        expect(result.value, isEmpty);
      });

      test('状態をリセットできる', () async {
        // Arrange
        await mockManager.initialize(mockLoggingService);
        mockManager.setPurchasing(true);
        mockManager.setInitializationFailure(true);

        // Act
        mockManager.resetToDefaults();

        // Assert
        expect(mockManager.isInitialized, false);
        expect(mockManager.isPurchasing, false);
        
        // リセット後は正常に初期化できる
        final result = await mockManager.initialize(mockLoggingService);
        expect(result.isSuccess, true);
      });
    });

    group('購入ストリーム', () {
      test('購入ストリームが利用可能', () {
        // Act
        final stream = mockManager.purchaseStream;

        // Assert
        expect(stream, isA<Stream<PurchaseResult>>());
      });

      test('ストリームに手動で結果を追加できる', () async {
        // Arrange
        await mockManager.initialize(mockLoggingService);
        final testResult = PurchaseResult(
          status: PurchaseStatus.pending,
          productId: 'test_product',
        );
        final List<PurchaseResult> streamResults = [];
        
        final subscription = mockManager.purchaseStream.listen(streamResults.add);

        // Act
        mockManager.addToPurchaseStream(testResult);

        // Assert
        await Future.delayed(const Duration(milliseconds: 100));
        expect(streamResults.length, equals(1));
        expect(streamResults.first.status, equals(PurchaseStatus.pending));
        expect(streamResults.first.productId, equals('test_product'));

        await subscription.cancel();
      });
    });

    group('破棄処理', () {
      test('破棄処理が正常に実行される', () async {
        // Arrange
        await mockManager.initialize(mockLoggingService);

        // Act
        await mockManager.dispose();

        // Assert
        expect(mockManager.isInitialized, false);
        expect(mockManager.isPurchasing, false);
      });
    });
  });
}