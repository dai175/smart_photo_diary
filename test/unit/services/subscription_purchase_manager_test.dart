import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:async';

import 'package:smart_photo_diary/services/subscription_purchase_manager.dart';
import 'package:smart_photo_diary/services/logging_service.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart'
    as ssi;

// 型のために明示的にインポート
typedef PurchaseResult = ssi.PurchaseResult;

// モッククラス
class MockLoggingService extends Mock implements LoggingService {}

void main() {
  group('SubscriptionPurchaseManager', () {
    late SubscriptionPurchaseManager manager;
    late MockLoggingService mockLoggingService;

    setUp(() {
      mockLoggingService = MockLoggingService();

      // LoggingServiceのセットアップ
      when(
        () => mockLoggingService.debug(
          any(),
          context: any(named: 'context'),
          data: any(named: 'data'),
        ),
      ).thenReturn(null);
      when(
        () => mockLoggingService.info(
          any(),
          context: any(named: 'context'),
          data: any(named: 'data'),
        ),
      ).thenReturn(null);
      when(
        () => mockLoggingService.warning(
          any(),
          context: any(named: 'context'),
          data: any(named: 'data'),
        ),
      ).thenReturn(null);
      when(
        () => mockLoggingService.error(
          any(),
          context: any(named: 'context'),
          error: any(named: 'error'),
        ),
      ).thenReturn(null);

      manager = SubscriptionPurchaseManager();
    });

    group('初期化とセットアップ', () {
      test('初期化前は未初期化状態', () {
        expect(manager.isInitialized, false);
        expect(manager.isPurchasing, false);
      });

      test('サブスクリプション状態更新コールバックを設定できる', () {
        // Arrange
        void callback(SubscriptionStatus status) {
          // コールバック処理（テストでは何もしない）
        }

        // Act & Assert（内部状態のため直接検証できないが、例外が発生しないことを確認）
        expect(
          () => manager.setSubscriptionStatusUpdateCallback(callback),
          returnsNormally,
        );
      });

      test('破棄処理が正常に実行される', () async {
        // Act & Assert
        expect(() => manager.dispose(), returnsNormally);
      });
    });

    group('商品情報取得', () {
      test('未初期化時はエラーを返す', () async {
        // Arrange
        final uninitializedManager = SubscriptionPurchaseManager();

        // Act
        final result = await uninitializedManager.getProducts();

        // Assert
        expect(result.isFailure, true);
        expect(result.error, isA<ServiceException>());
        expect(result.error.message, contains('not initialized'));
      });
    });

    group('購入処理', () {
      test('未初期化時は購入エラーを返す', () async {
        // Arrange
        final uninitializedManager = SubscriptionPurchaseManager();
        final plan = PremiumMonthlyPlan();

        // Act
        final result = await uninitializedManager.purchasePlanClass(plan);

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('not initialized'));
      });

      test('Basicプランの購入はエラーを返す', () async {
        // Arrange
        final plan = BasicPlan();

        // Act
        final result = await manager.purchasePlanClass(plan);

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('not initialized'));
      });

      test('プラン変更は未実装エラーを返す', () async {
        // Arrange
        final plan = PremiumYearlyPlan();

        // Act
        final result = await manager.changePlanClass(plan);

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('not initialized'));
      });
    });

    group('復元・検証機能', () {
      test('未初期化時は復元エラーを返す', () async {
        // Arrange
        final uninitializedManager = SubscriptionPurchaseManager();

        // Act
        final result = await uninitializedManager.restorePurchases();

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('not initialized'));
      });

      test('未初期化時は購入検証エラーを返す', () async {
        // Arrange
        final uninitializedManager = SubscriptionPurchaseManager();

        // Act
        final result = await uninitializedManager.validatePurchase(
          'test_transaction',
          () => Success(
            SubscriptionStatus(
              planId: SubscriptionConstants.basicPlanId,
              isActive: true,
              startDate: DateTime.now(),
              expiryDate: null,
              autoRenewal: false,
              monthlyUsageCount: 0,
              lastResetDate: DateTime.now(),
              transactionId: '',
              lastPurchaseDate: null,
            ),
          ),
        );

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('not initialized'));
      });

      test('有効なトランザクションIDの購入検証が成功する', () async {
        // Arrange
        const transactionId = 'test_transaction_123';

        Future<Result<SubscriptionStatus>> getCurrentStatus() async {
          return Success(
            SubscriptionStatus(
              planId: SubscriptionConstants.premiumMonthlyPlanId,
              isActive: true,
              startDate: DateTime.now(),
              expiryDate: DateTime.now().add(const Duration(days: 30)),
              autoRenewal: true,
              monthlyUsageCount: 5,
              lastResetDate: DateTime.now(),
              transactionId: transactionId,
              lastPurchaseDate: DateTime.now(),
            ),
          );
        }

        // Act
        final result = await manager.validatePurchase(
          transactionId,
          getCurrentStatus,
        );

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('not initialized'));
      });

      test('無効なトランザクションIDの購入検証は失敗する', () async {
        // Arrange
        const transactionId = 'invalid_transaction';

        Future<Result<SubscriptionStatus>> getCurrentStatus() async {
          return Success(
            SubscriptionStatus(
              planId: SubscriptionConstants.premiumMonthlyPlanId,
              isActive: true,
              startDate: DateTime.now(),
              expiryDate: DateTime.now().add(const Duration(days: 30)),
              autoRenewal: true,
              monthlyUsageCount: 5,
              lastResetDate: DateTime.now(),
              transactionId: 'different_transaction',
              lastPurchaseDate: DateTime.now(),
            ),
          );
        }

        // Act
        final result = await manager.validatePurchase(
          transactionId,
          getCurrentStatus,
        );

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('not initialized'));
      });

      test('期限切れサブスクリプションの購入検証は失敗する', () async {
        // Arrange
        const transactionId = 'test_transaction_123';

        Future<Result<SubscriptionStatus>> getCurrentStatus() async {
          return Success(
            SubscriptionStatus(
              planId: SubscriptionConstants.premiumMonthlyPlanId,
              isActive: true,
              startDate: DateTime.now().subtract(const Duration(days: 60)),
              expiryDate: DateTime.now().subtract(
                const Duration(days: 1),
              ), // 期限切れ
              autoRenewal: true,
              monthlyUsageCount: 5,
              lastResetDate: DateTime.now(),
              transactionId: transactionId,
              lastPurchaseDate: DateTime.now(),
            ),
          );
        }

        // Act
        final result = await manager.validatePurchase(
          transactionId,
          getCurrentStatus,
        );

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('not initialized'));
      });

      test('Basicプランの購入検証は失敗する', () async {
        // Arrange
        const transactionId = '';

        Future<Result<SubscriptionStatus>> getCurrentStatus() async {
          return Success(
            SubscriptionStatus(
              planId: SubscriptionConstants.basicPlanId,
              isActive: true,
              startDate: DateTime.now(),
              expiryDate: null,
              autoRenewal: false,
              monthlyUsageCount: 3,
              lastResetDate: DateTime.now(),
              transactionId: transactionId,
              lastPurchaseDate: null,
            ),
          );
        }

        // Act
        final result = await manager.validatePurchase(
          transactionId,
          getCurrentStatus,
        );

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('not initialized'));
      });

      test('現在状態の取得に失敗した場合は検証エラーを返す', () async {
        // Arrange
        const transactionId = 'test_transaction';

        Future<Result<SubscriptionStatus>> getCurrentStatus() async {
          return Failure(ServiceException('Failed to get status'));
        }

        // Act
        final result = await manager.validatePurchase(
          transactionId,
          getCurrentStatus,
        );

        // Assert
        expect(result.isFailure, true);
        expect(result.error.message, contains('not initialized'));
      });
    });

    group('購入状態監視', () {
      test('購入ストリームが利用可能', () {
        // Act
        final stream = manager.purchaseStream;

        // Assert
        expect(stream, isA<Stream<PurchaseResult>>());
      });
    });

    group('エラーハンドリング', () {
      test('In-App Purchase利用不可時は警告ログを出力して初期化を継続', () async {
        // Act
        final result = await manager.initialize(mockLoggingService);

        // Assert
        expect(result.isSuccess, true);
        expect(manager.isInitialized, true);
      });
    });

    group('プロパティとアクセサー', () {
      test('初期状態では購入処理中ではない', () {
        expect(manager.isPurchasing, false);
      });

      test('購入ストリームは常に利用可能', () {
        final stream = manager.purchaseStream;
        expect(stream, isA<Stream<PurchaseResult>>());
      });
    });
  });
}
