import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart' hide PurchaseStatus;
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/services/interfaces/in_app_purchase_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_state_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_sync_result.dart';
import 'package:smart_photo_diary/services/subscription_sync_delegate.dart';

import '../../integration/mocks/mock_services.dart';

class _MockSubscriptionStateService extends Mock
    implements ISubscriptionStateService {}

class _MockInAppPurchase extends Mock implements InAppPurchase {}

void main() {
  late _MockSubscriptionStateService mockStateService;
  late _MockInAppPurchase mockIAP;
  late MockILoggingService mockLogger;
  late StreamController<PurchaseResult> purchaseStreamController;

  // テスト用に短いタイムアウトを使用（実際の3秒を待たない）
  const testTimeout = Duration(milliseconds: 50);

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

  SubscriptionSyncDelegate buildDelegate({
    bool iapAvailable = true,
    void Function(bool)? onSyncStateChanged,
  }) {
    return SubscriptionSyncDelegate(
      getStateService: () => mockStateService,
      getInAppPurchase: () => iapAvailable ? mockIAP : null,
      purchaseStream: purchaseStreamController.stream,
      loggingService: mockLogger,
      timeout: testTimeout,
      onSyncStateChanged: onSyncStateChanged,
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
    mockLogger = TestServiceSetup.getLoggingService();
    purchaseStreamController = StreamController<PurchaseResult>.broadcast(
      sync: true,
    );

    when(() => mockStateService.isInitialized).thenReturn(true);
    when(() => mockIAP.restorePurchases()).thenAnswer((_) async {});
    when(
      () => mockStateService.updateStatus(any()),
    ).thenAnswer((_) async => const Success(null));
  });

  tearDown(() async {
    await purchaseStreamController.close();
    TestServiceSetup.clearAllMocks();
  });

  group('syncSubscriptionWithStore', () {
    test('IAP未初期化 → skipped を返し状態変更しない', () async {
      final delegate = buildDelegate(iapAvailable: false);

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.isSuccess, isTrue);
      expect(result.value.outcome, SubscriptionSyncOutcome.skipped);
      verifyNever(() => mockStateService.updateStatus(any()));
    });

    test('stateService未初期化 → skipped を返し状態変更しない', () async {
      when(() => mockStateService.isInitialized).thenReturn(false);
      final delegate = buildDelegate();

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.isSuccess, isTrue);
      expect(result.value.outcome, SubscriptionSyncOutcome.skipped);
      verifyNever(() => mockStateService.updateStatus(any()));
    });

    test('ローカルがBasic → noChange を返し状態変更しない', () async {
      when(
        () => mockStateService.getRawStatus(),
      ).thenAnswer((_) async => Success(buildStatus()));
      final delegate = buildDelegate();

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.isSuccess, isTrue);
      expect(result.value.outcome, SubscriptionSyncOutcome.noChange);
      verifyNever(() => mockIAP.restorePurchases());
      verifyNever(() => mockStateService.updateStatus(any()));
    });

    test('ローカルがPremium、restoredゼロ、エラーなし → Basic に降格', () async {
      when(() => mockStateService.getRawStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(
            planId: SubscriptionConstants.premiumMonthlyPlanId,
            expiryDate: DateTime.now().add(const Duration(days: 15)),
          ),
        ),
      );
      final delegate = buildDelegate();

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.isSuccess, isTrue);
      expect(result.value.outcome, SubscriptionSyncOutcome.downgradedToBasic);
      verify(() => mockStateService.updateStatus(any())).called(1);
    });

    test(
      'ローカルがPremium、restored 1件、expiryDate未来 → synced(1)、updateStatus呼ばれない',
      () async {
        when(() => mockStateService.getRawStatus()).thenAnswer(
          (_) async => Success(
            buildStatus(
              planId: SubscriptionConstants.premiumMonthlyPlanId,
              expiryDate: DateTime.now().add(const Duration(days: 15)),
            ),
          ),
        );
        when(() => mockIAP.restorePurchases()).thenAnswer((_) async {
          purchaseStreamController.add(
            const PurchaseResult(
              status: PurchaseStatus.restored,
              productId: SubscriptionConstants.premiumMonthlyProductId,
            ),
          );
        });
        final delegate = buildDelegate();

        final result = await delegate.syncSubscriptionWithStore();

        expect(result.isSuccess, isTrue);
        expect(result.value.outcome, SubscriptionSyncOutcome.synced);
        expect(result.value.restoredCount, 1);
        verifyNever(() => mockStateService.updateStatus(any()));
      },
    );

    test(
      'ローカルが月額Premium、restored が年額productId、expiryDate未来 → planId更新・365日期限でリフレッシュ',
      () async {
        when(() => mockStateService.getRawStatus()).thenAnswer(
          (_) async => Success(
            buildStatus(
              planId: SubscriptionConstants.premiumMonthlyPlanId,
              expiryDate: DateTime.now().add(const Duration(days: 15)),
            ),
          ),
        );
        when(() => mockIAP.restorePurchases()).thenAnswer((_) async {
          purchaseStreamController.add(
            const PurchaseResult(
              status: PurchaseStatus.restored,
              productId: SubscriptionConstants.premiumYearlyProductId,
            ),
          );
        });
        final delegate = buildDelegate();
        final before = DateTime.now();

        final result = await delegate.syncSubscriptionWithStore();

        expect(result.isSuccess, isTrue);
        expect(result.value.outcome, SubscriptionSyncOutcome.synced);
        final captured = verify(
          () => mockStateService.updateStatus(captureAny()),
        ).captured;
        final saved = captured.first as SubscriptionStatus;
        expect(saved.planId, SubscriptionConstants.premiumYearlyPlanId);
        final expectedExpiry = before.add(
          const Duration(days: SubscriptionConstants.subscriptionYearDays),
        );
        expect(
          saved.expiryDate!.isAfter(
            expectedExpiry.subtract(const Duration(seconds: 1)),
          ),
          isTrue,
        );
      },
    );

    test(
      'ローカルが年額Premium、restored が月額productId、expiryDate未来 → planId更新・30日期限でリフレッシュ',
      () async {
        when(() => mockStateService.getRawStatus()).thenAnswer(
          (_) async => Success(
            buildStatus(
              planId: SubscriptionConstants.premiumYearlyPlanId,
              expiryDate: DateTime.now().add(const Duration(days: 300)),
            ),
          ),
        );
        when(() => mockIAP.restorePurchases()).thenAnswer((_) async {
          purchaseStreamController.add(
            const PurchaseResult(
              status: PurchaseStatus.restored,
              productId: SubscriptionConstants.premiumMonthlyProductId,
            ),
          );
        });
        final delegate = buildDelegate();
        final before = DateTime.now();

        final result = await delegate.syncSubscriptionWithStore();

        expect(result.isSuccess, isTrue);
        expect(result.value.outcome, SubscriptionSyncOutcome.synced);
        final captured = verify(
          () => mockStateService.updateStatus(captureAny()),
        ).captured;
        final saved = captured.first as SubscriptionStatus;
        expect(saved.planId, SubscriptionConstants.premiumMonthlyPlanId);
        final expectedExpiry = before.add(
          const Duration(days: SubscriptionConstants.subscriptionMonthDays),
        );
        expect(
          saved.expiryDate!.isAfter(
            expectedExpiry.subtract(const Duration(seconds: 1)),
          ),
          isTrue,
        );
      },
    );

    test(
      'ローカルがPremium、restored 1件、expiryDate過去 → expiryDate更新してsynced',
      () async {
        when(() => mockStateService.getRawStatus()).thenAnswer(
          (_) async => Success(
            buildStatus(
              planId: SubscriptionConstants.premiumMonthlyPlanId,
              expiryDate: DateTime.now().subtract(const Duration(days: 1)),
            ),
          ),
        );
        when(() => mockIAP.restorePurchases()).thenAnswer((_) async {
          purchaseStreamController.add(
            const PurchaseResult(
              status: PurchaseStatus.restored,
              productId: SubscriptionConstants.premiumMonthlyProductId,
            ),
          );
        });
        final delegate = buildDelegate();

        final result = await delegate.syncSubscriptionWithStore();

        expect(result.isSuccess, isTrue);
        expect(result.value.outcome, SubscriptionSyncOutcome.synced);
        final captured = verify(
          () => mockStateService.updateStatus(captureAny()),
        ).captured;
        final saved = captured.first as SubscriptionStatus;
        expect(saved.planId, SubscriptionConstants.premiumMonthlyPlanId);
        expect(saved.expiryDate, isNotNull);
        expect(saved.expiryDate!.isAfter(DateTime.now()), isTrue);
      },
    );

    test(
      'ローカルがPremium月額、restored 1件、expiryDate null → 30日の期限でリフレッシュ',
      () async {
        when(() => mockStateService.getRawStatus()).thenAnswer(
          (_) async => Success(
            buildStatus(planId: SubscriptionConstants.premiumMonthlyPlanId),
          ),
        );
        when(() => mockIAP.restorePurchases()).thenAnswer((_) async {
          purchaseStreamController.add(
            const PurchaseResult(
              status: PurchaseStatus.restored,
              productId: SubscriptionConstants.premiumMonthlyProductId,
            ),
          );
        });
        final delegate = buildDelegate();
        final before = DateTime.now();

        final result = await delegate.syncSubscriptionWithStore();

        expect(result.isSuccess, isTrue);
        expect(result.value.outcome, SubscriptionSyncOutcome.synced);
        final captured = verify(
          () => mockStateService.updateStatus(captureAny()),
        ).captured;
        final saved = captured.first as SubscriptionStatus;
        final expectedExpiry = before.add(
          const Duration(days: SubscriptionConstants.subscriptionMonthDays),
        );
        expect(
          saved.expiryDate!.isAfter(
            expectedExpiry.subtract(const Duration(seconds: 1)),
          ),
          isTrue,
        );
      },
    );

    test('ローカルがPremium年額、restored 1件、expiryDate過去 → 365日の期限でリフレッシュ', () async {
      when(() => mockStateService.getRawStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(
            planId: SubscriptionConstants.premiumYearlyPlanId,
            expiryDate: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ),
      );
      when(() => mockIAP.restorePurchases()).thenAnswer((_) async {
        purchaseStreamController.add(
          const PurchaseResult(
            status: PurchaseStatus.restored,
            productId: SubscriptionConstants.premiumYearlyProductId,
          ),
        );
      });
      final delegate = buildDelegate();
      final before = DateTime.now();

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.isSuccess, isTrue);
      final captured = verify(
        () => mockStateService.updateStatus(captureAny()),
      ).captured;
      final saved = captured.first as SubscriptionStatus;
      final expectedExpiry = before.add(
        const Duration(days: SubscriptionConstants.subscriptionYearDays),
      );
      expect(
        saved.expiryDate!.isAfter(
          expectedExpiry.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });

    test('restored 1件、expiryDate過去、updateStatus失敗 → error を返す', () async {
      when(() => mockStateService.getRawStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(
            planId: SubscriptionConstants.premiumMonthlyPlanId,
            expiryDate: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ),
      );
      when(() => mockIAP.restorePurchases()).thenAnswer((_) async {
        purchaseStreamController.add(
          const PurchaseResult(
            status: PurchaseStatus.restored,
            productId: SubscriptionConstants.premiumMonthlyProductId,
          ),
        );
      });
      when(
        () => mockStateService.updateStatus(any()),
      ).thenAnswer((_) async => const Failure(ServiceException('write error')));
      final delegate = buildDelegate();

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.isSuccess, isTrue);
      expect(result.value.outcome, SubscriptionSyncOutcome.error);
    });

    test(
      'ローカルが年額Premium、restored が月額productId、expiryDate過去 → 月額30日・planIdも月額に更新',
      () async {
        when(() => mockStateService.getRawStatus()).thenAnswer(
          (_) async => Success(
            buildStatus(
              planId: SubscriptionConstants.premiumYearlyPlanId,
              expiryDate: DateTime.now().subtract(const Duration(days: 1)),
            ),
          ),
        );
        when(() => mockIAP.restorePurchases()).thenAnswer((_) async {
          purchaseStreamController.add(
            const PurchaseResult(
              status: PurchaseStatus.restored,
              productId: SubscriptionConstants.premiumMonthlyProductId,
            ),
          );
        });
        final delegate = buildDelegate();
        final before = DateTime.now();

        final result = await delegate.syncSubscriptionWithStore();

        expect(result.isSuccess, isTrue);
        expect(result.value.outcome, SubscriptionSyncOutcome.synced);
        final captured = verify(
          () => mockStateService.updateStatus(captureAny()),
        ).captured;
        final saved = captured.first as SubscriptionStatus;
        expect(saved.planId, SubscriptionConstants.premiumMonthlyPlanId);
        final expectedExpiry = before.add(
          const Duration(days: SubscriptionConstants.subscriptionMonthDays),
        );
        expect(
          saved.expiryDate!.isAfter(
            expectedExpiry.subtract(const Duration(seconds: 1)),
          ),
          isTrue,
        );
        expect(
          saved.expiryDate!.isBefore(
            before.add(
              const Duration(days: SubscriptionConstants.subscriptionYearDays),
            ),
          ),
          isTrue,
        );
      },
    );

    test('ローカルがPremium、error イベントあり → error を返し降格しない', () async {
      when(() => mockStateService.getRawStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(
            planId: SubscriptionConstants.premiumMonthlyPlanId,
            expiryDate: DateTime.now().add(const Duration(days: 15)),
          ),
        ),
      );
      when(() => mockIAP.restorePurchases()).thenAnswer((_) async {
        purchaseStreamController.add(
          const PurchaseResult(
            status: PurchaseStatus.error,
            errorMessage: 'network error',
          ),
        );
      });
      final delegate = buildDelegate();

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.isSuccess, isTrue);
      expect(result.value.outcome, SubscriptionSyncOutcome.error);
      verifyNever(() => mockStateService.updateStatus(any()));
    });

    test('restorePurchases() が例外スロー → error を返し降格しない', () async {
      when(() => mockStateService.getRawStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(
            planId: SubscriptionConstants.premiumMonthlyPlanId,
            expiryDate: DateTime.now().add(const Duration(days: 15)),
          ),
        ),
      );
      when(
        () => mockIAP.restorePurchases(),
      ).thenThrow(const ServiceException('Store unavailable'));
      final delegate = buildDelegate();

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.isSuccess, isTrue);
      expect(result.value.outcome, SubscriptionSyncOutcome.error);
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
      verifyNever(() => mockIAP.restorePurchases());
    });

    test('ローカルがPremium、storeNotAvailable イベント → error を返し降格しない', () async {
      when(() => mockStateService.getRawStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(
            planId: SubscriptionConstants.premiumMonthlyPlanId,
            expiryDate: DateTime.now().add(const Duration(days: 15)),
          ),
        ),
      );
      when(() => mockIAP.restorePurchases()).thenAnswer((_) async {
        purchaseStreamController.add(
          const PurchaseResult(status: PurchaseStatus.storeNotAvailable),
        );
      });
      final delegate = buildDelegate();

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.isSuccess, isTrue);
      expect(result.value.outcome, SubscriptionSyncOutcome.error);
      verifyNever(() => mockStateService.updateStatus(any()));
    });

    test('ローカルがPremium、降格時に既存monthlyUsageCountが保持される', () async {
      when(() => mockStateService.getRawStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(
            planId: SubscriptionConstants.premiumMonthlyPlanId,
            expiryDate: DateTime.now().add(const Duration(days: 15)),
          ).copyWith(monthlyUsageCount: 7),
        ),
      );
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
      expect(saved.monthlyUsageCount, 7);
    });

    test('ローカルがPremium、降格時updateStatus失敗 → error を返し降格しない', () async {
      when(() => mockStateService.getRawStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(
            planId: SubscriptionConstants.premiumMonthlyPlanId,
            expiryDate: DateTime.now().add(const Duration(days: 15)),
          ),
        ),
      );
      when(() => mockStateService.updateStatus(any())).thenAnswer(
        (_) async => const Failure(ServiceException('Hive write error')),
      );
      final delegate = buildDelegate();

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.isSuccess, isTrue);
      expect(result.value.outcome, SubscriptionSyncOutcome.error);
    });

    test('onSyncStateChanged: sync開始時にtrue、終了時にfalseが呼ばれる', () async {
      when(() => mockStateService.getRawStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(
            planId: SubscriptionConstants.premiumMonthlyPlanId,
            expiryDate: DateTime.now().add(const Duration(days: 15)),
          ),
        ),
      );
      final calls = <bool>[];
      final delegate = buildDelegate(onSyncStateChanged: calls.add);

      await delegate.syncSubscriptionWithStore();

      expect(calls, [true, false]);
    });

    test('ローカルがPremium、タイムアウト後に restored が来ても集計されず降格', () async {
      // タイムアウトを極短に設定し、delayed で遅延して emit しても間に合わないことを確認
      when(() => mockStateService.getRawStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(
            planId: SubscriptionConstants.premiumMonthlyPlanId,
            expiryDate: DateTime.now().add(const Duration(days: 15)),
          ),
        ),
      );
      when(() => mockIAP.restorePurchases()).thenAnswer((_) async {
        // testTimeout (50ms) より長い遅延で emit → 集計されない
        Future<void>.delayed(const Duration(milliseconds: 200)).then((_) {
          if (!purchaseStreamController.isClosed) {
            purchaseStreamController.add(
              const PurchaseResult(
                status: PurchaseStatus.restored,
                productId: SubscriptionConstants.premiumMonthlyProductId,
              ),
            );
          }
        });
      });
      final delegate = buildDelegate();

      final result = await delegate.syncSubscriptionWithStore();

      expect(result.isSuccess, isTrue);
      expect(result.value.outcome, SubscriptionSyncOutcome.downgradedToBasic);
    });
  });
}
