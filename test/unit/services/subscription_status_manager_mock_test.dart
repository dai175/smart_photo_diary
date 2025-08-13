import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive/hive.dart';
import 'package:smart_photo_diary/services/subscription_status_manager.dart';
import 'package:smart_photo_diary/services/logging_service.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';

// Hive Boxのモック
class MockSubscriptionBox extends Mock implements Box<SubscriptionStatus> {}

// LoggingServiceのモック
class MockLoggingService extends Mock implements LoggingService {}

// SubscriptionStatusのFake
class FakeSubscriptionStatus extends Fake implements SubscriptionStatus {}

void main() {
  setUpAll(() {
    // mocktail の fallback values を登録
    registerFallbackValue(FakeSubscriptionStatus());
  });
  group('SubscriptionStatusManager - Mock Test', () {
    late SubscriptionStatusManager statusManager;
    late MockSubscriptionBox mockSubscriptionBox;
    late MockLoggingService mockLoggingService;

    setUp(() {
      mockSubscriptionBox = MockSubscriptionBox();
      mockLoggingService = MockLoggingService();

      // LoggingServiceのモック設定
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

      statusManager = SubscriptionStatusManager(
        mockSubscriptionBox,
        mockLoggingService,
      );
    });

    tearDown(() {
      statusManager.dispose();
    });

    group('getCurrentStatus() - モック動作確認', () {
      test('Hiveから既存のステータスを正常に取得する', () async {
        // Arrange
        final mockStatus = SubscriptionStatus(
          planId: SubscriptionConstants.premiumMonthlyPlanId,
          isActive: true,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          expiryDate: DateTime.now().add(const Duration(days: 25)),
          autoRenewal: true,
          monthlyUsageCount: 3,
          lastResetDate: DateTime.now().subtract(const Duration(days: 5)),
          transactionId: 'mock_transaction',
          lastPurchaseDate: DateTime.now().subtract(const Duration(days: 5)),
        );

        when(
          () => mockSubscriptionBox.get(SubscriptionConstants.statusKey),
        ).thenReturn(mockStatus);

        // Act
        final result = await statusManager.getCurrentStatus();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(
          result.value.planId,
          equals(SubscriptionConstants.premiumMonthlyPlanId),
        );
        expect(result.value.monthlyUsageCount, equals(3));

        // Hiveのget()が呼ばれたことを確認
        verify(
          () => mockSubscriptionBox.get(SubscriptionConstants.statusKey),
        ).called(1);
      });

      test('Hiveにデータがない場合、初期Basic状態を作成する', () async {
        // Arrange
        when(
          () => mockSubscriptionBox.get(SubscriptionConstants.statusKey),
        ).thenReturn(null);
        when(
          () => mockSubscriptionBox.put(any(), any()),
        ).thenAnswer((_) => Future.value());

        // Act
        final result = await statusManager.getCurrentStatus();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value.planId, equals(SubscriptionConstants.basicPlanId));
        expect(result.value.isActive, isTrue);
        expect(result.value.expiryDate, isNull);

        // Hiveのgetとputが呼ばれたことを確認
        verify(
          () => mockSubscriptionBox.get(SubscriptionConstants.statusKey),
        ).called(1);
        verify(
          () => mockSubscriptionBox.put(SubscriptionConstants.statusKey, any()),
        ).called(1);
      });

      test('Hiveでエラーが発生した場合、適切にハンドリングされる', () async {
        // Arrange
        when(
          () => mockSubscriptionBox.get(any()),
        ).thenThrow(Exception('Hive error'));

        // Act
        final result = await statusManager.getCurrentStatus();

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());

        // エラーログが呼ばれたことを確認
        verify(
          () => mockLoggingService.error(
            any(),
            context: any(named: 'context'),
            error: any(named: 'error'),
          ),
        ).called(greaterThan(0));
      });
    });

    group('updateStatus() - モック動作確認', () {
      test('新しいステータスが正常にHiveに保存される', () async {
        // Arrange
        final newStatus = SubscriptionStatus(
          planId: SubscriptionConstants.premiumYearlyPlanId,
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 365)),
          autoRenewal: true,
          monthlyUsageCount: 0,
          lastResetDate: DateTime.now(),
          transactionId: 'new_mock_transaction',
          lastPurchaseDate: DateTime.now(),
        );

        when(
          () => mockSubscriptionBox.put(any(), any()),
        ).thenAnswer((_) => Future.value());

        // Act
        final result = await statusManager.updateStatus(newStatus);

        // Assert
        expect(result.isSuccess, isTrue);

        // Hiveのput()が正しい引数で呼ばれたことを確認
        verify(
          () => mockSubscriptionBox.put(
            SubscriptionConstants.statusKey,
            newStatus,
          ),
        ).called(1);

        // 情報ログが呼ばれたことを確認
        verify(
          () => mockLoggingService.info(
            any(),
            context: any(named: 'context'),
            data: any(named: 'data'),
          ),
        ).called(greaterThan(0));
      });

      test('Hive保存でエラーが発生した場合、適切にハンドリングされる', () async {
        // Arrange
        final testStatus = SubscriptionStatus(
          planId: SubscriptionConstants.basicPlanId,
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: null,
          autoRenewal: false,
          monthlyUsageCount: 1,
          lastResetDate: DateTime.now(),
          transactionId: '',
          lastPurchaseDate: null,
        );

        when(
          () => mockSubscriptionBox.put(any(), any()),
        ).thenThrow(Exception('Hive put error'));

        // Act
        final result = await statusManager.updateStatus(testStatus);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());

        // エラーログが呼ばれたことを確認
        verify(
          () => mockLoggingService.error(
            any(),
            context: any(named: 'context'),
            error: any(named: 'error'),
          ),
        ).called(greaterThan(0));
      });
    });

    group('createStatus() - モック動作確認', () {
      test('Basicプラン用ステータスが正常に作成・保存される', () async {
        // Arrange
        final basicPlan = BasicPlan();
        when(
          () => mockSubscriptionBox.put(any(), any()),
        ).thenAnswer((_) => Future.value());

        // Act
        final result = await statusManager.createStatus(basicPlan);

        // Assert
        expect(result.isSuccess, isTrue);

        final status = result.value;
        expect(status.planId, equals(SubscriptionConstants.basicPlanId));
        expect(status.isActive, isTrue);
        expect(status.expiryDate, isNull);
        expect(status.autoRenewal, isFalse);
        expect(status.transactionId, isEmpty);
        expect(status.lastPurchaseDate, isNull);

        // Hiveのput()が呼ばれたことを確認
        verify(
          () => mockSubscriptionBox.put(SubscriptionConstants.statusKey, any()),
        ).called(1);
      });

      test('PremiumMonthlyプラン用ステータスが正常に作成・保存される', () async {
        // Arrange
        final premiumPlan = PremiumMonthlyPlan();
        when(
          () => mockSubscriptionBox.put(any(), any()),
        ).thenAnswer((_) => Future.value());

        // Act
        final result = await statusManager.createStatus(premiumPlan);

        // Assert
        expect(result.isSuccess, isTrue);

        final status = result.value;
        expect(
          status.planId,
          equals(SubscriptionConstants.premiumMonthlyPlanId),
        );
        expect(status.isActive, isTrue);
        expect(status.expiryDate, isNotNull);
        expect(status.autoRenewal, isTrue);
        expect(status.transactionId, isNotEmpty);
        expect(status.lastPurchaseDate, isNotNull);

        // 有効期限が30日後に設定されていることを確認
        final expectedExpiry = DateTime.now().add(const Duration(days: 30));
        final actualExpiry = status.expiryDate!;
        expect(
          actualExpiry.difference(expectedExpiry).inMinutes.abs(),
          lessThan(1),
        );

        // Hiveのput()が呼ばれたことを確認
        verify(
          () => mockSubscriptionBox.put(SubscriptionConstants.statusKey, any()),
        ).called(1);
      });
    });

    group('clearStatus() - モック動作確認', () {
      test('ステータスが正常に削除される', () async {
        // Arrange
        when(
          () => mockSubscriptionBox.delete(any()),
        ).thenAnswer((_) => Future.value());

        // Act
        final result = await statusManager.clearStatus();

        // Assert
        expect(result.isSuccess, isTrue);

        // Hiveのdelete()が呼ばれたことを確認
        verify(
          () => mockSubscriptionBox.delete(SubscriptionConstants.statusKey),
        ).called(1);

        // 警告ログが呼ばれたことを確認（テスト専用機能のため）
        verify(
          () =>
              mockLoggingService.warning(any(), context: any(named: 'context')),
        ).called(greaterThan(0));
      });

      test('削除でエラーが発生した場合、適切にハンドリングされる', () async {
        // Arrange
        when(
          () => mockSubscriptionBox.delete(any()),
        ).thenThrow(Exception('Hive delete error'));

        // Act
        final result = await statusManager.clearStatus();

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());

        // エラーログが呼ばれたことを確認
        verify(
          () => mockLoggingService.error(
            any(),
            context: any(named: 'context'),
            error: any(named: 'error'),
          ),
        ).called(greaterThan(0));
      });
    });

    group('canAccessPremiumFeatures() - モック動作確認', () {
      test('有効なPremiumプランでtrueが返される', () async {
        // Arrange
        final premiumStatus = SubscriptionStatus(
          planId: SubscriptionConstants.premiumMonthlyPlanId,
          isActive: true,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          expiryDate: DateTime.now().add(const Duration(days: 25)),
          autoRenewal: true,
          monthlyUsageCount: 2,
          lastResetDate: DateTime.now(),
          transactionId: 'premium_transaction',
          lastPurchaseDate: DateTime.now(),
        );

        when(
          () => mockSubscriptionBox.get(SubscriptionConstants.statusKey),
        ).thenReturn(premiumStatus);

        // Act
        final result = await statusManager.canAccessPremiumFeatures();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);

        // デバッグログが呼ばれたことを確認
        verify(
          () => mockLoggingService.debug(
            any(),
            context: any(named: 'context'),
            data: any(named: 'data'),
          ),
        ).called(greaterThan(0));
      });

      test('Basicプランでfalseが返される', () async {
        // Arrange
        final basicStatus = SubscriptionStatus(
          planId: SubscriptionConstants.basicPlanId,
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: null,
          autoRenewal: false,
          monthlyUsageCount: 1,
          lastResetDate: DateTime.now(),
          transactionId: '',
          lastPurchaseDate: null,
        );

        when(
          () => mockSubscriptionBox.get(SubscriptionConstants.statusKey),
        ).thenReturn(basicStatus);

        // Act
        final result = await statusManager.canAccessPremiumFeatures();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });

      test('期限切れPremiumプランでfalseが返される', () async {
        // Arrange
        final expiredStatus = SubscriptionStatus(
          planId: SubscriptionConstants.premiumMonthlyPlanId,
          isActive: true,
          startDate: DateTime.now().subtract(const Duration(days: 40)),
          expiryDate: DateTime.now().subtract(const Duration(days: 10)), // 期限切れ
          autoRenewal: true,
          monthlyUsageCount: 5,
          lastResetDate: DateTime.now(),
          transactionId: 'expired_transaction',
          lastPurchaseDate: DateTime.now(),
        );

        when(
          () => mockSubscriptionBox.get(SubscriptionConstants.statusKey),
        ).thenReturn(expiredStatus);

        // Act
        final result = await statusManager.canAccessPremiumFeatures();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });
    });

    group('ログ出力の確認', () {
      test('初期化時にデバッグログが出力される', () {
        // SubscriptionStatusManager の初期化は setUp で行われているので、
        // デバッグログが呼ばれたことを確認
        verify(
          () => mockLoggingService.debug(
            'SubscriptionStatusManager initialized',
            context: any(named: 'context'),
          ),
        ).called(1);
      });

      test('dispose時に情報ログが出力される', () {
        // Act
        statusManager.dispose();

        // Assert
        verify(
          () => mockLoggingService.info(
            'Disposing SubscriptionStatusManager...',
            context: any(named: 'context'),
          ),
        ).called(1);

        verify(
          () => mockLoggingService.info(
            'SubscriptionStatusManager disposed',
            context: any(named: 'context'),
          ),
        ).called(1);
      });
    });

    group('モック検証テスト', () {
      test('モックが適切に設定されている', () {
        // LoggingServiceのモックが設定されていることを確認
        expect(mockLoggingService, isA<MockLoggingService>());
        expect(mockSubscriptionBox, isA<MockSubscriptionBox>());

        // StatusManagerが初期化されていることを確認
        expect(statusManager.isInitialized, isTrue);
      });

      test('呼び出し回数の検証が正しく動作する', () async {
        // Arrange
        when(() => mockSubscriptionBox.get(any())).thenReturn(null);
        when(
          () => mockSubscriptionBox.put(any(), any()),
        ).thenAnswer((_) => Future.value());

        // Act
        await statusManager.getCurrentStatus();
        await statusManager.getCurrentStatus();

        // Assert
        // getCurrentStatus()を2回呼んだので、get()も2回呼ばれる
        verify(
          () => mockSubscriptionBox.get(SubscriptionConstants.statusKey),
        ).called(2);
      });
    });
  });
}
