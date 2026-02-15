import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/services/feature_access_service.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_state_service_interface.dart';

class MockSubscriptionStateService extends Mock
    implements ISubscriptionStateService {}

class MockLoggingService extends Mock implements ILoggingService {}

void main() {
  late MockSubscriptionStateService mockStateService;
  late MockLoggingService mockLoggingService;
  late FeatureAccessService service;

  setUp(() {
    mockStateService = MockSubscriptionStateService();
    mockLoggingService = MockLoggingService();

    // ServiceLocatorにLoggingServiceを登録
    ServiceLocator().clear();
    ServiceLocator().registerSingleton<ILoggingService>(mockLoggingService);

    service = FeatureAccessService(stateService: mockStateService);
  });

  tearDown(() {
    ServiceLocator().clear();
  });

  /// Basicプラン用のSubscriptionStatusを作成
  SubscriptionStatus createBasicStatus() {
    return SubscriptionStatus(
      planId: SubscriptionConstants.basicPlanId,
      isActive: true,
    );
  }

  /// 有効なPremiumプラン用のSubscriptionStatusを作成
  SubscriptionStatus createValidPremiumStatus() {
    return SubscriptionStatus(
      planId: SubscriptionConstants.premiumMonthlyPlanId,
      isActive: true,
      startDate: DateTime.now(),
      expiryDate: DateTime.now().add(const Duration(days: 30)),
    );
  }

  /// 期限切れPremiumプラン用のSubscriptionStatusを作成
  SubscriptionStatus createExpiredPremiumStatus() {
    return SubscriptionStatus(
      planId: SubscriptionConstants.premiumMonthlyPlanId,
      isActive: true,
      startDate: DateTime.now().subtract(const Duration(days: 60)),
      expiryDate: DateTime.now().subtract(const Duration(days: 1)),
    );
  }

  /// StateServiceの共通モックセットアップ
  void setupStateService(SubscriptionStatus status, {bool isValid = true}) {
    when(() => mockStateService.isInitialized).thenReturn(true);
    when(
      () => mockStateService.getCurrentStatus(),
    ).thenAnswer((_) async => Success(status));
    when(
      () => mockStateService.isSubscriptionValid(status),
    ).thenReturn(isValid);
  }

  group('FeatureAccessService', () {
    group('canAccessPremiumFeatures', () {
      test('Basicプランではfalseを返す', () async {
        final status = createBasicStatus();
        setupStateService(status);

        final result = await service.canAccessPremiumFeatures();

        expect(result, isA<Success<bool>>());
        expect(result.value, isFalse);
      });

      test('有効なPremiumプランではtrueを返す', () async {
        final status = createValidPremiumStatus();
        setupStateService(status, isValid: true);

        final result = await service.canAccessPremiumFeatures();

        expect(result, isA<Success<bool>>());
        expect(result.value, isTrue);
      });

      test('期限切れPremiumプランではfalseを返す', () async {
        final status = createExpiredPremiumStatus();
        setupStateService(status, isValid: false);

        final result = await service.canAccessPremiumFeatures();

        expect(result, isA<Success<bool>>());
        expect(result.value, isFalse);
      });

      test('StateServiceが未初期化の場合Failureを返す', () async {
        when(() => mockStateService.isInitialized).thenReturn(false);

        final result = await service.canAccessPremiumFeatures();

        expect(result, isA<Failure<bool>>());
        expect(result.error, isA<ServiceException>());
      });

      test('StateServiceのgetCurrentStatusが失敗した場合Failureを返す', () async {
        when(() => mockStateService.isInitialized).thenReturn(true);
        when(
          () => mockStateService.getCurrentStatus(),
        ).thenAnswer((_) async => const Failure(ServiceException('DB error')));

        final result = await service.canAccessPremiumFeatures();

        expect(result, isA<Failure<bool>>());
      });
    });

    group('canAccessWritingPrompts', () {
      test('Basicプランでもtrueを返す', () async {
        final status = createBasicStatus();
        setupStateService(status);

        final result = await service.canAccessWritingPrompts();

        expect(result, isA<Success<bool>>());
        expect(result.value, isTrue);
      });

      test('有効なPremiumプランではtrueを返す', () async {
        final status = createValidPremiumStatus();
        setupStateService(status, isValid: true);

        final result = await service.canAccessWritingPrompts();

        expect(result, isA<Success<bool>>());
        expect(result.value, isTrue);
      });

      test('StateServiceが未初期化の場合Failureを返す', () async {
        when(() => mockStateService.isInitialized).thenReturn(false);

        final result = await service.canAccessWritingPrompts();

        expect(result, isA<Failure<bool>>());
      });
    });

    group('canAccessDataExport', () {
      test('Basicプランではtrueを返す（JSON限定）', () async {
        final status = createBasicStatus();
        setupStateService(status);

        final result = await service.canAccessDataExport();

        expect(result, isA<Success<bool>>());
        expect(result.value, isTrue);
      });

      test('有効なPremiumプランではtrueを返す', () async {
        final status = createValidPremiumStatus();
        setupStateService(status, isValid: true);

        final result = await service.canAccessDataExport();

        expect(result, isA<Success<bool>>());
        expect(result.value, isTrue);
      });

      test('期限切れPremiumプランではfalseを返す', () async {
        final status = createExpiredPremiumStatus();
        setupStateService(status, isValid: false);

        final result = await service.canAccessDataExport();

        expect(result, isA<Success<bool>>());
        expect(result.value, isFalse);
      });
    });

    group('canAccessAdvancedFilters', () {
      test('Basicプランではfalseを返す', () async {
        final status = createBasicStatus();
        setupStateService(status);

        final result = await service.canAccessAdvancedFilters();

        expect(result, isA<Success<bool>>());
        expect(result.value, isFalse);
      });

      test('有効なPremiumプランではtrueを返す', () async {
        final status = createValidPremiumStatus();
        setupStateService(status, isValid: true);

        final result = await service.canAccessAdvancedFilters();

        expect(result, isA<Success<bool>>());
        expect(result.value, isTrue);
      });
    });

    group('canAccessAdvancedAnalytics', () {
      test('Basicプランではfalseを返す', () async {
        final status = createBasicStatus();
        setupStateService(status);

        final result = await service.canAccessAdvancedAnalytics();

        expect(result, isA<Success<bool>>());
        expect(result.value, isFalse);
      });

      test('有効なPremiumプランではtrueを返す', () async {
        final status = createValidPremiumStatus();
        setupStateService(status, isValid: true);

        final result = await service.canAccessAdvancedAnalytics();

        expect(result, isA<Success<bool>>());
        expect(result.value, isTrue);
      });
    });

    group('canAccessStatsDashboard', () {
      test('Basicプランではfalseを返す', () async {
        final status = createBasicStatus();
        setupStateService(status);

        final result = await service.canAccessStatsDashboard();

        expect(result, isA<Success<bool>>());
        expect(result.value, isFalse);
      });

      test('有効なPremiumプランではtrueを返す', () async {
        final status = createValidPremiumStatus();
        setupStateService(status, isValid: true);

        final result = await service.canAccessStatsDashboard();

        expect(result, isA<Success<bool>>());
        expect(result.value, isTrue);
      });
    });

    group('canAccessPrioritySupport', () {
      test('Basicプランではfalseを返す', () async {
        final status = createBasicStatus();
        setupStateService(status);

        final result = await service.canAccessPrioritySupport();

        expect(result, isA<Success<bool>>());
        expect(result.value, isFalse);
      });

      test('有効なPremiumプランではtrueを返す', () async {
        final status = createValidPremiumStatus();
        setupStateService(status, isValid: true);

        final result = await service.canAccessPrioritySupport();

        expect(result, isA<Success<bool>>());
        expect(result.value, isTrue);
      });

      test('期限切れPremiumプランではfalseを返す', () async {
        final status = createExpiredPremiumStatus();
        setupStateService(status, isValid: false);

        final result = await service.canAccessPrioritySupport();

        expect(result, isA<Success<bool>>());
        expect(result.value, isFalse);
      });

      test('StateServiceが未初期化の場合Failureを返す', () async {
        when(() => mockStateService.isInitialized).thenReturn(false);

        final result = await service.canAccessPrioritySupport();

        expect(result, isA<Failure<bool>>());
        expect(result.error, isA<ServiceException>());
      });
    });

    group('例外処理パス', () {
      test('getCurrentStatusが例外をスロー → Failure(ServiceException)', () async {
        when(() => mockStateService.isInitialized).thenReturn(true);
        when(
          () => mockStateService.getCurrentStatus(),
        ).thenThrow(Exception('Unexpected error'));

        final result = await service.canAccessPremiumFeatures();

        expect(result, isA<Failure<bool>>());
      });

      test(
        'canAccessWritingPromptsでgetCurrentStatusが例外をスロー → Failure',
        () async {
          when(() => mockStateService.isInitialized).thenReturn(true);
          when(
            () => mockStateService.getCurrentStatus(),
          ).thenThrow(Exception('DB crash'));

          final result = await service.canAccessWritingPrompts();

          expect(result, isA<Failure<bool>>());
        },
      );

      test('canAccessDataExportでgetCurrentStatusが例外をスロー → Failure', () async {
        when(() => mockStateService.isInitialized).thenReturn(true);
        when(
          () => mockStateService.getCurrentStatus(),
        ).thenThrow(Exception('IO error'));

        final result = await service.canAccessDataExport();

        expect(result, isA<Failure<bool>>());
      });

      test('getFeatureAccessでStateServiceが例外をスロー → Failure', () async {
        when(() => mockStateService.isInitialized).thenReturn(true);
        when(
          () => mockStateService.getCurrentStatus(),
        ).thenThrow(Exception('Fatal error'));

        final result = await service.getFeatureAccess();

        expect(result, isA<Failure<Map<String, bool>>>());
      });
    });

    group('getFeatureAccess', () {
      test('Basicプランでは正しい機能アクセスマップを返す', () async {
        final status = createBasicStatus();
        setupStateService(status);

        final result = await service.getFeatureAccess();

        expect(result, isA<Success<Map<String, bool>>>());
        final access = result.value;
        expect(access['premiumFeatures'], isFalse);
        expect(access['writingPrompts'], isTrue);
        expect(access['advancedFilters'], isFalse);
        expect(access['advancedAnalytics'], isFalse);
        expect(access['prioritySupport'], isFalse);
        expect(access['dataExport'], isTrue);
        expect(access['statsDashboard'], isFalse);
      });

      test('有効なPremiumプランでは正しい機能アクセスマップを返す', () async {
        final status = createValidPremiumStatus();
        setupStateService(status, isValid: true);

        final result = await service.getFeatureAccess();

        expect(result, isA<Success<Map<String, bool>>>());
        final access = result.value;
        expect(access['premiumFeatures'], isTrue);
        expect(access['writingPrompts'], isTrue);
        expect(access['advancedFilters'], isTrue);
        expect(access['advancedAnalytics'], isTrue);
        expect(access['prioritySupport'], isTrue);
        expect(access['dataExport'], isTrue);
        expect(access['statsDashboard'], isTrue);
      });

      test('StateServiceが未初期化の場合Failureを返す', () async {
        when(() => mockStateService.isInitialized).thenReturn(false);

        final result = await service.getFeatureAccess();

        expect(result, isA<Failure<Map<String, bool>>>());
      });
    });
  });
}
