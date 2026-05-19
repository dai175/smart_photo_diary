import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart' as iap;
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/services/interfaces/in_app_purchase_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_state_service_interface.dart';
import 'package:smart_photo_diary/services/mixins/purchase_event_handler.dart';
import 'package:smart_photo_diary/services/mixins/service_logging.dart';

import '../../integration/mocks/mock_services.dart';

class _MockSubscriptionStateService extends Mock
    implements ISubscriptionStateService {}

// PurchaseDetails の具象テスト実装（verificationData は未使用）
class _TestPurchaseDetails implements iap.PurchaseDetails {
  @override
  final String productID;
  @override
  final String? purchaseID;
  @override
  iap.PurchaseStatus status;
  @override
  final String? transactionDate;
  @override
  iap.IAPError? error;
  @override
  bool pendingCompletePurchase;

  @override
  iap.PurchaseVerificationData get verificationData =>
      iap.PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: '',
        source: 'test',
      );

  _TestPurchaseDetails({
    required this.productID,
    this.purchaseID = 'test-txn-id',
    required this.status,
    this.transactionDate,
    this.error,
    this.pendingCompletePurchase = false,
  });
}

// ServiceLogging を先に宣言（PurchaseEventHandler が on ServiceLogging のため）
class _TestEventHandler with ServiceLogging, PurchaseEventHandler {
  @override
  final ISubscriptionStateService purchaseStateService;
  @override
  final StreamController<PurchaseResult> purchaseStreamController;
  @override
  final ILoggingService? loggingService;

  @override
  bool isPurchasing = false;

  @override
  iap.InAppPurchase? get inAppPurchaseInstance => null;

  @override
  String get logTag => 'TestPurchaseEventHandler';

  _TestEventHandler({
    required this.purchaseStateService,
    required this.purchaseStreamController,
    required this.loggingService,
  });
}

void main() {
  late _TestEventHandler handler;
  late _MockSubscriptionStateService mockStateService;
  late MockILoggingService mockLogger;
  late StreamController<PurchaseResult> streamController;

  SubscriptionStatus buildStatus({
    String planId = SubscriptionConstants.basicPlanId,
    int usageCount = 0,
    DateTime? expiryDate,
    DateTime? lastResetDate,
  }) {
    return SubscriptionStatus(
      planId: planId,
      isActive: true,
      startDate: DateTime.now(),
      expiryDate: expiryDate,
      monthlyUsageCount: usageCount,
      lastResetDate: lastResetDate ?? DateTime.now(),
      autoRenewal: expiryDate != null,
    );
  }

  _TestPurchaseDetails makePurchase({
    required String productId,
    required iap.PurchaseStatus status,
  }) {
    return _TestPurchaseDetails(
      productID: productId,
      purchaseID: 'txn-test-${DateTime.now().millisecondsSinceEpoch}',
      transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
      status: status,
    );
  }

  setUpAll(registerMockFallbacks);

  setUp(() {
    mockStateService = _MockSubscriptionStateService();
    mockLogger = TestServiceSetup.getLoggingService();
    // sync: true で同期配信にする（テスト内でイベント順序を確実にするため）
    streamController = StreamController<PurchaseResult>.broadcast(sync: true);
    handler = _TestEventHandler(
      purchaseStateService: mockStateService,
      purchaseStreamController: streamController,
      loggingService: mockLogger,
    );
  });

  tearDown(() async {
    if (!streamController.isClosed) {
      await streamController.close();
    }
    TestServiceSetup.clearAllMocks();
  });

  group('processPurchaseUpdate - ステータス別ルーティング', () {
    setUp(() {
      when(() => mockStateService.getCurrentStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(planId: SubscriptionConstants.premiumMonthlyPlanId),
        ),
      );
      when(
        () => mockStateService.updateStatus(any()),
      ).thenAnswer((_) async => const Success(null));
    });

    test('purchased → purchasedステータスがストリームに流れ、isPurchasingがfalseになる', () async {
      handler.isPurchasing = true;
      final purchase = makePurchase(
        productId: SubscriptionConstants.premiumMonthlyProductId,
        status: iap.PurchaseStatus.purchased,
      );
      final emitted = <PurchaseResult>[];
      final sub = streamController.stream.listen(emitted.add);

      await handler.processPurchaseUpdate(purchase);

      expect(emitted.length, 1);
      expect(emitted.first.status, PurchaseStatus.purchased);
      expect(emitted.first.plan, isA<PremiumMonthlyPlan>());
      expect(handler.isPurchasing, isFalse);
      await sub.cancel();
    });

    test('restored → restoredステータスがストリームに流れ、isPurchasingがfalseになる', () async {
      handler.isPurchasing = true;
      final purchase = makePurchase(
        productId: SubscriptionConstants.premiumMonthlyProductId,
        status: iap.PurchaseStatus.restored,
      );
      final emitted = <PurchaseResult>[];
      final sub = streamController.stream.listen(emitted.add);

      await handler.processPurchaseUpdate(purchase);

      expect(emitted.length, 1);
      expect(emitted.first.status, PurchaseStatus.restored);
      expect(handler.isPurchasing, isFalse);
      await sub.cancel();
    });

    test('canceled → cancelledステータスがストリームに流れ、isPurchasingがfalseになる', () async {
      handler.isPurchasing = true;
      final purchase = makePurchase(
        productId: SubscriptionConstants.premiumMonthlyProductId,
        status: iap.PurchaseStatus.canceled,
      );
      final emitted = <PurchaseResult>[];
      final sub = streamController.stream.listen(emitted.add);

      await handler.processPurchaseUpdate(purchase);

      expect(emitted.length, 1);
      expect(emitted.first.status, PurchaseStatus.cancelled);
      expect(handler.isPurchasing, isFalse);
      await sub.cancel();
    });

    test('error → errorステータスがストリームに流れ、isPurchasingがfalseになる', () async {
      handler.isPurchasing = true;
      final purchase = makePurchase(
        productId: SubscriptionConstants.premiumMonthlyProductId,
        status: iap.PurchaseStatus.error,
      );
      final emitted = <PurchaseResult>[];
      final sub = streamController.stream.listen(emitted.add);

      await handler.processPurchaseUpdate(purchase);

      expect(emitted.length, 1);
      expect(emitted.first.status, PurchaseStatus.error);
      expect(handler.isPurchasing, isFalse);
      await sub.cancel();
    });

    test('pending → pendingステータスがストリームに流れる（isPurchasingは変わらない）', () async {
      handler.isPurchasing = true;
      final purchase = makePurchase(
        productId: SubscriptionConstants.premiumMonthlyProductId,
        status: iap.PurchaseStatus.pending,
      );
      final emitted = <PurchaseResult>[];
      final sub = streamController.stream.listen(emitted.add);

      await handler.processPurchaseUpdate(purchase);

      expect(emitted.length, 1);
      expect(emitted.first.status, PurchaseStatus.pending);
      // pending は isPurchasing をリセットしない
      expect(handler.isPurchasing, isTrue);
      await sub.cancel();
    });
  });

  group('applyPurchaseSideEffects - サブスクリプション状態更新（収益直撃ロジック）', () {
    test('Monthly購入完了 → now+30日のexpiryDateでupdateStatusが呼ばれる', () async {
      when(
        () => mockStateService.getCurrentStatus(),
      ).thenAnswer((_) async => Success(buildStatus(usageCount: 5)));
      when(
        () => mockStateService.updateStatus(any()),
      ).thenAnswer((_) async => const Success(null));

      final purchase = makePurchase(
        productId: SubscriptionConstants.premiumMonthlyProductId,
        status: iap.PurchaseStatus.purchased,
      );

      final before = DateTime.now();
      final plan = await handler.applyPurchaseSideEffects(purchase);
      final after = DateTime.now();

      expect(plan, isA<PremiumMonthlyPlan>());

      final captured = verify(
        () => mockStateService.updateStatus(captureAny()),
      ).captured;
      final updatedStatus = captured.first as SubscriptionStatus;

      expect(updatedStatus.planId, SubscriptionConstants.premiumMonthlyPlanId);
      expect(updatedStatus.isActive, isTrue);
      expect(updatedStatus.monthlyUsageCount, 5); // 使用量を引き継ぐ
      expect(updatedStatus.expiryDate, isNotNull);
      // now+30日であることを確認（前後1秒の誤差を許容）
      final minExpiry = before.add(const Duration(days: 30));
      final maxExpiry = after.add(const Duration(days: 30));
      expect(
        updatedStatus.expiryDate!.isAfter(minExpiry) ||
            updatedStatus.expiryDate!.isAtSameMomentAs(minExpiry),
        isTrue,
      );
      expect(updatedStatus.expiryDate!.isBefore(maxExpiry), isTrue);
    });

    test('Yearly購入完了 → now+365日のexpiryDateでupdateStatusが呼ばれる', () async {
      when(
        () => mockStateService.getCurrentStatus(),
      ).thenAnswer((_) async => Success(buildStatus(usageCount: 2)));
      when(
        () => mockStateService.updateStatus(any()),
      ).thenAnswer((_) async => const Success(null));

      final purchase = makePurchase(
        productId: SubscriptionConstants.premiumYearlyProductId,
        status: iap.PurchaseStatus.purchased,
      );

      final before = DateTime.now();
      final plan = await handler.applyPurchaseSideEffects(purchase);
      final after = DateTime.now();

      expect(plan, isA<PremiumYearlyPlan>());

      final captured = verify(
        () => mockStateService.updateStatus(captureAny()),
      ).captured;
      final updatedStatus = captured.first as SubscriptionStatus;

      expect(updatedStatus.planId, SubscriptionConstants.premiumYearlyPlanId);
      final minExpiry = before.add(const Duration(days: 365));
      final maxExpiry = after.add(const Duration(days: 365));
      expect(
        updatedStatus.expiryDate!.isAfter(minExpiry) ||
            updatedStatus.expiryDate!.isAtSameMomentAs(minExpiry),
        isTrue,
      );
      expect(updatedStatus.expiryDate!.isBefore(maxExpiry), isTrue);
    });

    test('復元時に既存有効期限が未来 → 既存expiryDateが維持される', () async {
      final futureExpiry = DateTime.now().add(const Duration(days: 15));
      when(() => mockStateService.getCurrentStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(
            planId: SubscriptionConstants.premiumMonthlyPlanId,
            expiryDate: futureExpiry,
          ),
        ),
      );
      when(
        () => mockStateService.updateStatus(any()),
      ).thenAnswer((_) async => const Success(null));

      final purchase = _TestPurchaseDetails(
        productID: SubscriptionConstants.premiumMonthlyProductId,
        purchaseID: 'restore-txn',
        transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
        status: iap.PurchaseStatus.restored,
        pendingCompletePurchase: false,
      );

      await handler.applyPurchaseSideEffects(purchase);

      final captured = verify(
        () => mockStateService.updateStatus(captureAny()),
      ).captured;
      final updatedStatus = captured.first as SubscriptionStatus;

      // 有効期限は維持される（±1秒の誤差を許容）
      expect(
        updatedStatus.expiryDate!.millisecondsSinceEpoch,
        closeTo(futureExpiry.millisecondsSinceEpoch, 1000),
      );
    });

    test('復元時に既存有効期限が過去 → now+30日の新しいexpiryDateが設定される', () async {
      final pastExpiry = DateTime.now().subtract(const Duration(days: 5));
      when(() => mockStateService.getCurrentStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(
            planId: SubscriptionConstants.premiumMonthlyPlanId,
            expiryDate: pastExpiry,
          ),
        ),
      );
      when(
        () => mockStateService.updateStatus(any()),
      ).thenAnswer((_) async => const Success(null));

      final purchase = _TestPurchaseDetails(
        productID: SubscriptionConstants.premiumMonthlyProductId,
        purchaseID: 'restore-txn',
        transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
        status: iap.PurchaseStatus.restored,
        pendingCompletePurchase: false,
      );

      final before = DateTime.now();
      await handler.applyPurchaseSideEffects(purchase);

      final captured = verify(
        () => mockStateService.updateStatus(captureAny()),
      ).captured;
      final updatedStatus = captured.first as SubscriptionStatus;

      // 過去の有効期限は維持されず、新しい有効期限が設定される
      final minExpiry = before.add(const Duration(days: 30));
      expect(
        updatedStatus.expiryDate!.isAfter(minExpiry) ||
            updatedStatus.expiryDate!.isAtSameMomentAs(minExpiry),
        isTrue,
      );
    });

    test('不明なproductId → ServiceException がスローされ、updateStatusは呼ばれない', () async {
      final purchase = _TestPurchaseDetails(
        productID: 'unknown_invalid_product_id',
        status: iap.PurchaseStatus.purchased,
        pendingCompletePurchase: false,
      );

      await expectLater(
        () => handler.applyPurchaseSideEffects(purchase),
        throwsA(isA<ServiceException>()),
      );

      verifyNever(() => mockStateService.updateStatus(any()));
    });

    test('購入時の使用量カウントは現在の値を引き継ぐ', () async {
      when(
        () => mockStateService.getCurrentStatus(),
      ).thenAnswer((_) async => Success(buildStatus(usageCount: 7)));
      when(
        () => mockStateService.updateStatus(any()),
      ).thenAnswer((_) async => const Success(null));

      final purchase = makePurchase(
        productId: SubscriptionConstants.premiumMonthlyProductId,
        status: iap.PurchaseStatus.purchased,
      );

      await handler.applyPurchaseSideEffects(purchase);

      final captured = verify(
        () => mockStateService.updateStatus(captureAny()),
      ).captured;
      final updatedStatus = captured.first as SubscriptionStatus;

      // 月途中アップグレードで使用量がリセットされないことを確認
      expect(updatedStatus.monthlyUsageCount, 7);
    });

    test('getCurrentStatus失敗時 → usageCount=0、lastResetDate=nowで続行する', () async {
      when(() => mockStateService.getCurrentStatus()).thenAnswer(
        (_) async => const Failure(ServiceException('state unavailable')),
      );
      when(
        () => mockStateService.updateStatus(any()),
      ).thenAnswer((_) async => const Success(null));

      final purchase = makePurchase(
        productId: SubscriptionConstants.premiumMonthlyProductId,
        status: iap.PurchaseStatus.purchased,
      );

      // エラーにならず、usageCount=0でフォールバック
      await handler.applyPurchaseSideEffects(purchase);

      final captured = verify(
        () => mockStateService.updateStatus(captureAny()),
      ).captured;
      final updatedStatus = captured.first as SubscriptionStatus;

      expect(updatedStatus.monthlyUsageCount, 0);
    });
  });

  group('isPurchasing フラグ管理', () {
    setUp(() {
      when(() => mockStateService.getCurrentStatus()).thenAnswer(
        (_) async => Success(
          buildStatus(planId: SubscriptionConstants.premiumMonthlyPlanId),
        ),
      );
      when(
        () => mockStateService.updateStatus(any()),
      ).thenAnswer((_) async => const Success(null));
    });

    test('handlePurchaseCompleted → isPurchasingがfalseにリセットされる', () async {
      handler.isPurchasing = true;
      final purchase = makePurchase(
        productId: SubscriptionConstants.premiumMonthlyProductId,
        status: iap.PurchaseStatus.purchased,
      );

      await handler.handlePurchaseCompleted(purchase);

      expect(handler.isPurchasing, isFalse);
    });

    test('handlePurchaseCanceled → isPurchasingがfalseにリセットされる', () async {
      handler.isPurchasing = true;
      final purchase = makePurchase(
        productId: SubscriptionConstants.premiumMonthlyProductId,
        status: iap.PurchaseStatus.canceled,
      );

      await handler.handlePurchaseCanceled(purchase);

      expect(handler.isPurchasing, isFalse);
    });

    test('handlePurchaseErrorEvent → isPurchasingがfalseにリセットされる', () async {
      handler.isPurchasing = true;
      final purchase = makePurchase(
        productId: SubscriptionConstants.premiumMonthlyProductId,
        status: iap.PurchaseStatus.error,
      );

      await handler.handlePurchaseErrorEvent(purchase);

      expect(handler.isPurchasing, isFalse);
    });

    test('handlePurchaseRestored → isPurchasingがfalseにリセットされる', () async {
      handler.isPurchasing = true;
      final purchase = makePurchase(
        productId: SubscriptionConstants.premiumMonthlyProductId,
        status: iap.PurchaseStatus.restored,
      );

      await handler.handlePurchaseRestored(purchase);

      expect(handler.isPurchasing, isFalse);
    });
  });
}
