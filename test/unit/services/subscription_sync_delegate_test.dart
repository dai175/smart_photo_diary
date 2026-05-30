import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart' hide PurchaseStatus;
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/models/store_entitlement.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/services/interfaces/store_entitlement_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_state_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_sync_result.dart';
import 'package:smart_photo_diary/services/subscription_sync_delegate.dart';

import '../../integration/mocks/mock_services.dart';

class _MockSubscriptionStateService extends Mock
    implements ISubscriptionStateService {}

class _MockInAppPurchase extends Mock implements InAppPurchase {}

class _MockStoreEntitlementService extends Mock
    implements IStoreEntitlementService {}

void main() {
  late _MockSubscriptionStateService mockStateService;
  late _MockInAppPurchase mockIAP;
  late _MockStoreEntitlementService mockEntitlementService;
  late MockILoggingService mockLogger;

  SubscriptionStatus buildStatus({
    String planId = SubscriptionConstants.basicPlanId,
    DateTime? expiryDate,
  }) {
    return SubscriptionStatus(
      planId: planId,
      isActive: planId != SubscriptionConstants.basicPlanId,
      startDate: DateTime.now(),
      expiryDate: expiryDate,
      monthlyUsageCount: 0,
      lastResetDate: DateTime.now(),
      autoRenewal: expiryDate != null,
    );
  }

  SubscriptionSyncDelegate buildDelegate({bool iapAvailable = true}) {
    return SubscriptionSyncDelegate(
      getStateService: () => mockStateService,
      getInAppPurchase: () => iapAvailable ? mockIAP : null,
      getEntitlementService: () => mockEntitlementService,
      loggingService: mockLogger,
    );
  }

  setUpAll(() {
    registerMockFallbacks();
    registerFallbackValue(
      SubscriptionStatus(
        planId: 'basic',
        isActive: false,
        startDate: DateTime.now(),
        monthlyUsageCount: 0,
        autoRenewal: false,
      ),
    );
  });

  setUp(() {
    mockStateService = _MockSubscriptionStateService();
    mockIAP = _MockInAppPurchase();
    mockEntitlementService = _MockStoreEntitlementService();
    mockLogger = TestServiceSetup.getLoggingService();

    when(() => mockStateService.isInitialized).thenReturn(true);
    when(
      () => mockStateService.updateStatus(any()),
    ).thenAnswer((_) async => const Success(null));
  });

  tearDown(() {
    TestServiceSetup.clearAllMocks();
  });

  group('syncSubscriptionWithStore', () {
    test('IAP未初期化 → skipped を返し状態変更しない', () async {
      final delegate = buildDelegate(iapAvailable: false);

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.isSuccess, isTrue);
      expect(result.value.outcome, SubscriptionSyncOutcome.skipped);
      verifyNever(() => mockStateService.updateStatus(any()));
      verifyNever(() => mockEntitlementService.getActiveSubscription());
    });

    test('stateService未初期化 → skipped を返し状態変更しない', () async {
      when(() => mockStateService.isInitialized).thenReturn(false);
      final delegate = buildDelegate();

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.isSuccess, isTrue);
      expect(result.value.outcome, SubscriptionSyncOutcome.skipped);
      verifyNever(() => mockStateService.updateStatus(any()));
    });

    test('ローカルがBasic → noChange、エンタイトルメント取得もしない', () async {
      when(
        () => mockStateService.getRawStatus(),
      ).thenAnswer((_) async => Success(buildStatus()));
      final delegate = buildDelegate();

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.isSuccess, isTrue);
      expect(result.value.outcome, SubscriptionSyncOutcome.noChange);
      verifyNever(() => mockEntitlementService.getActiveSubscription());
      verifyNever(() => mockStateService.updateStatus(any()));
    });

    test('getRawStatus 失敗 → skipped を返し状態変更しない', () async {
      when(() => mockStateService.getRawStatus()).thenAnswer(
        (_) async => const Failure(ServiceException('Hive read error')),
      );
      final delegate = buildDelegate();

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.isSuccess, isTrue);
      expect(result.value.outcome, SubscriptionSyncOutcome.skipped);
      verifyNever(() => mockEntitlementService.getActiveSubscription());
    });

    test('ローカルがPremium、有効なエンタイトルメント無し(null) → Basic に降格', () async {
      when(() => mockStateService.getRawStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(
            planId: SubscriptionConstants.premiumMonthlyPlanId,
            expiryDate: DateTime.now().add(const Duration(days: 15)),
          ),
        ),
      );
      when(
        () => mockEntitlementService.getActiveSubscription(),
      ).thenAnswer((_) async => const Success(null));
      final delegate = buildDelegate();

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.isSuccess, isTrue);
      expect(result.value.outcome, SubscriptionSyncOutcome.downgradedToBasic);
      final captured = verify(
        () => mockStateService.updateStatus(captureAny()),
      ).captured;
      final saved = captured.first as SubscriptionStatus;
      expect(saved.planId, SubscriptionConstants.basicPlanId);
      expect(saved.isActive, isTrue);
      expect(saved.expiryDate, isNull);
      expect(saved.autoRenewal, isFalse);
    });

    test('降格時に既存の monthlyUsageCount が保持される', () async {
      when(() => mockStateService.getRawStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(
            planId: SubscriptionConstants.premiumMonthlyPlanId,
            expiryDate: DateTime.now().add(const Duration(days: 15)),
          ).copyWith(monthlyUsageCount: 7),
        ),
      );
      when(
        () => mockEntitlementService.getActiveSubscription(),
      ).thenAnswer((_) async => const Success(null));
      final delegate = buildDelegate();

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.value.outcome, SubscriptionSyncOutcome.downgradedToBasic);
      final captured = verify(
        () => mockStateService.updateStatus(captureAny()),
      ).captured;
      final saved = captured.first as SubscriptionStatus;
      expect(saved.monthlyUsageCount, 7);
    });

    test('ローカルがPremium、有効なエンタイトルメントあり → 実有効期限でリフレッシュしsynced', () async {
      final realExpiry = DateTime.now().add(const Duration(days: 23));
      when(() => mockStateService.getRawStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(
            planId: SubscriptionConstants.premiumMonthlyPlanId,
            expiryDate: DateTime.now().add(const Duration(days: 15)),
          ),
        ),
      );
      when(() => mockEntitlementService.getActiveSubscription()).thenAnswer(
        (_) async => Success(
          StoreEntitlement(
            productId: SubscriptionConstants.premiumMonthlyProductId,
            expiryDate: realExpiry,
            willAutoRenew: true,
          ),
        ),
      );
      final delegate = buildDelegate();

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.isSuccess, isTrue);
      expect(result.value.outcome, SubscriptionSyncOutcome.synced);
      final captured = verify(
        () => mockStateService.updateStatus(captureAny()),
      ).captured;
      final saved = captured.first as SubscriptionStatus;
      expect(saved.planId, SubscriptionConstants.premiumMonthlyPlanId);
      expect(saved.expiryDate, realExpiry);
      expect(saved.autoRenewal, isTrue);
    });

    test('解約済み(willAutoRenew=false)の購読 → autoRenewal=false で保存', () async {
      when(() => mockStateService.getRawStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(
            planId: SubscriptionConstants.premiumMonthlyPlanId,
            expiryDate: DateTime.now().add(const Duration(days: 15)),
          ),
        ),
      );
      when(() => mockEntitlementService.getActiveSubscription()).thenAnswer(
        (_) async => Success(
          StoreEntitlement(
            productId: SubscriptionConstants.premiumMonthlyProductId,
            expiryDate: DateTime.now().add(const Duration(days: 23)),
            willAutoRenew: false,
          ),
        ),
      );
      final delegate = buildDelegate();

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.value.outcome, SubscriptionSyncOutcome.synced);
      final captured = verify(
        () => mockStateService.updateStatus(captureAny()),
      ).captured;
      final saved = captured.first as SubscriptionStatus;
      expect(saved.autoRenewal, isFalse);
    });

    test('willAutoRenew が null（取得不能）→ 既存の autoRenewal を保持し上書きしない', () async {
      when(() => mockStateService.getRawStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(
            planId: SubscriptionConstants.premiumMonthlyPlanId,
            expiryDate: DateTime.now().add(const Duration(days: 15)),
          ).copyWith(autoRenewal: false),
        ),
      );
      when(() => mockEntitlementService.getActiveSubscription()).thenAnswer(
        (_) async => Success(
          StoreEntitlement(
            productId: SubscriptionConstants.premiumMonthlyProductId,
            expiryDate: DateTime.now().add(const Duration(days: 23)),
            willAutoRenew: null,
          ),
        ),
      );
      final delegate = buildDelegate();

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.value.outcome, SubscriptionSyncOutcome.synced);
      final captured = verify(
        () => mockStateService.updateStatus(captureAny()),
      ).captured;
      final saved = captured.first as SubscriptionStatus;
      expect(saved.autoRenewal, isFalse);
    });

    test(
      'ローカルが月額、エンタイトルメントが年額productId → planId・期限を年額エンタイトルメントに合わせる',
      () async {
        final realExpiry = DateTime.now().add(const Duration(days: 360));
        when(() => mockStateService.getRawStatus()).thenAnswer(
          (_) async => Success(
            buildStatus(
              planId: SubscriptionConstants.premiumMonthlyPlanId,
              expiryDate: DateTime.now().add(const Duration(days: 15)),
            ),
          ),
        );
        when(() => mockEntitlementService.getActiveSubscription()).thenAnswer(
          (_) async => Success(
            StoreEntitlement(
              productId: SubscriptionConstants.premiumYearlyProductId,
              expiryDate: realExpiry,
            ),
          ),
        );
        final delegate = buildDelegate();

        final result = await delegate.syncSubscriptionWithStore();

        expect(result.value.outcome, SubscriptionSyncOutcome.synced);
        final captured = verify(
          () => mockStateService.updateStatus(captureAny()),
        ).captured;
        final saved = captured.first as SubscriptionStatus;
        expect(saved.planId, SubscriptionConstants.premiumYearlyPlanId);
        expect(saved.expiryDate, realExpiry);
      },
    );

    test('エンタイトルメント取得が Failure → error を返し降格しない', () async {
      when(() => mockStateService.getRawStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(
            planId: SubscriptionConstants.premiumMonthlyPlanId,
            expiryDate: DateTime.now().add(const Duration(days: 15)),
          ),
        ),
      );
      when(() => mockEntitlementService.getActiveSubscription()).thenAnswer(
        (_) async => const Failure(ServiceException('channel unavailable')),
      );
      final delegate = buildDelegate();

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.isSuccess, isTrue);
      expect(result.value.outcome, SubscriptionSyncOutcome.error);
      verifyNever(() => mockStateService.updateStatus(any()));
    });

    test('エンタイトルメントが未知のproductId → error を返し降格しない', () async {
      when(() => mockStateService.getRawStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(
            planId: SubscriptionConstants.premiumMonthlyPlanId,
            expiryDate: DateTime.now().add(const Duration(days: 15)),
          ),
        ),
      );
      when(() => mockEntitlementService.getActiveSubscription()).thenAnswer(
        (_) async => Success(
          StoreEntitlement(
            productId: 'unknown_product_id',
            expiryDate: DateTime.now().add(const Duration(days: 30)),
          ),
        ),
      );
      final delegate = buildDelegate();

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.value.outcome, SubscriptionSyncOutcome.error);
      verifyNever(() => mockStateService.updateStatus(any()));
    });

    test('降格時 updateStatus 失敗 → error を返す', () async {
      when(() => mockStateService.getRawStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(
            planId: SubscriptionConstants.premiumMonthlyPlanId,
            expiryDate: DateTime.now().add(const Duration(days: 15)),
          ),
        ),
      );
      when(
        () => mockEntitlementService.getActiveSubscription(),
      ).thenAnswer((_) async => const Success(null));
      when(() => mockStateService.updateStatus(any())).thenAnswer(
        (_) async => const Failure(ServiceException('Hive write error')),
      );
      final delegate = buildDelegate();

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.value.outcome, SubscriptionSyncOutcome.error);
    });

    test('リフレッシュ時 updateStatus 失敗 → error を返す', () async {
      when(() => mockStateService.getRawStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(
            planId: SubscriptionConstants.premiumMonthlyPlanId,
            expiryDate: DateTime.now().add(const Duration(days: 15)),
          ),
        ),
      );
      when(() => mockEntitlementService.getActiveSubscription()).thenAnswer(
        (_) async => Success(
          StoreEntitlement(
            productId: SubscriptionConstants.premiumMonthlyProductId,
            expiryDate: DateTime.now().add(const Duration(days: 23)),
          ),
        ),
      );
      when(() => mockStateService.updateStatus(any())).thenAnswer(
        (_) async => const Failure(ServiceException('Hive write error')),
      );
      final delegate = buildDelegate();

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.value.outcome, SubscriptionSyncOutcome.error);
    });
  });
}
