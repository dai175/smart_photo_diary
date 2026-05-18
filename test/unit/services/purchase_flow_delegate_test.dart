import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:in_app_purchase/in_app_purchase.dart' hide PurchaseStatus;
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/services/purchase_flow_delegate.dart';
import 'package:smart_photo_diary/services/purchase_product_delegate.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_state_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/in_app_purchase_service_interface.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';

import '../../integration/mocks/mock_services.dart';

class MockSubscriptionStateService extends Mock
    implements ISubscriptionStateService {}

class MockInAppPurchase extends Mock implements InAppPurchase {}

class MockPurchaseProductDelegate extends Mock
    implements PurchaseProductDelegate {}

class FakeProductDetails extends Fake implements ProductDetails {}

void main() {
  late PurchaseFlowDelegate delegate;
  late MockSubscriptionStateService mockStateService;
  late MockILoggingService mockLogger;
  late MockInAppPurchase mockInAppPurchase;
  late MockPurchaseProductDelegate mockProductDelegate;
  late bool isPurchasing;

  setUpAll(() {
    registerMockFallbacks();
    registerFallbackValue(PurchaseParam(productDetails: FakeProductDetails()));

    // Register LoggingService in ServiceLocator for ErrorHandler
    if (!serviceLocator.isRegistered<ILoggingService>()) {
      serviceLocator.registerSingleton<ILoggingService>(MockILoggingService());
    }
  });

  setUp(() {
    mockStateService = MockSubscriptionStateService();
    mockLogger = TestServiceSetup.getLoggingService();
    mockInAppPurchase = MockInAppPurchase();
    mockProductDelegate = MockPurchaseProductDelegate();
    isPurchasing = false;

    delegate = PurchaseFlowDelegate(
      getStateService: () => mockStateService,
      getInAppPurchase: () => mockInAppPurchase,
      getIsPurchasing: () => isPurchasing,
      setIsPurchasing: (value) => isPurchasing = value,
      productDelegate: mockProductDelegate,
      loggingService: mockLogger,
    );
  });

  tearDown(() {
    TestServiceSetup.clearAllMocks();
  });

  group('purchasePlan', () {
    test('stateService未初期化 → Failure', () async {
      when(() => mockStateService.isInitialized).thenReturn(false);

      final result = await delegate.purchasePlan(PremiumMonthlyPlan());

      expect(result.isFailure, isTrue);
      expect(result.error, isA<ServiceException>());
      expect(result.error.toString(), contains('not initialized'));
    });

    test('InAppPurchaseがnull → Failure', () async {
      when(() => mockStateService.isInitialized).thenReturn(true);

      final nullIapDelegate = PurchaseFlowDelegate(
        getStateService: () => mockStateService,
        getInAppPurchase: () => null,
        getIsPurchasing: () => isPurchasing,
        setIsPurchasing: (value) => isPurchasing = value,
        productDelegate: mockProductDelegate,
        loggingService: mockLogger,
      );

      final result = await nullIapDelegate.purchasePlan(PremiumMonthlyPlan());

      expect(result.isFailure, isTrue);
      expect(
        result.error.toString(),
        contains('In-App Purchase not available'),
      );
    });

    test('別の購入が進行中 → Failure', () async {
      when(() => mockStateService.isInitialized).thenReturn(true);
      isPurchasing = true;

      final result = await delegate.purchasePlan(PremiumMonthlyPlan());

      expect(result.isFailure, isTrue);
      expect(
        result.error.toString(),
        contains('Another purchase is already in progress'),
      );
    });

    test('BasicPlan → Failure("Basic plan cannot be purchased")', () async {
      when(() => mockStateService.isInitialized).thenReturn(true);

      final result = await delegate.purchasePlan(BasicPlan());

      expect(result.isFailure, isTrue);
      expect(
        result.error.toString(),
        contains('Basic plan cannot be purchased'),
      );
    });

    test('queryProductDetailsがFailure → Failureを返して購入フラグを戻す', () async {
      when(() => mockStateService.isInitialized).thenReturn(true);

      when(() => mockProductDelegate.queryProductDetails(any())).thenAnswer(
        (_) async => const Failure(ServiceException('lookup failed')),
      );

      final result = await delegate.purchasePlan(PremiumMonthlyPlan());

      expect(result.isFailure, isTrue);
      expect(result.error.toString(), contains('lookup failed'));
      expect(isPurchasing, isFalse);
      verifyNever(
        () => mockInAppPurchase.buyNonConsumable(
          purchaseParam: any(named: 'purchaseParam'),
        ),
      );
    });

    test('正常系 → Success(pending)', () async {
      when(() => mockStateService.isInitialized).thenReturn(true);
      final fakeProduct = FakeProductDetails();

      when(
        () => mockProductDelegate.queryProductDetails(any()),
      ).thenAnswer((_) async => Success(fakeProduct));

      when(
        () => mockInAppPurchase.buyNonConsumable(
          purchaseParam: any(named: 'purchaseParam'),
        ),
      ).thenAnswer((_) async => true);

      final result = await delegate.purchasePlan(PremiumMonthlyPlan());

      expect(result.isSuccess, isTrue);
      expect(result.value.status, PurchaseStatus.pending);
      expect(result.value.plan, isA<PremiumMonthlyPlan>());
    });

    test('buyNonConsumableがfalse → Failure', () async {
      when(() => mockStateService.isInitialized).thenReturn(true);
      final fakeProduct = FakeProductDetails();

      when(
        () => mockProductDelegate.queryProductDetails(any()),
      ).thenAnswer((_) async => Success(fakeProduct));

      when(
        () => mockInAppPurchase.buyNonConsumable(
          purchaseParam: any(named: 'purchaseParam'),
        ),
      ).thenAnswer((_) async => false);

      final result = await delegate.purchasePlan(PremiumMonthlyPlan());

      expect(result.isFailure, isTrue);
      expect(result.error.toString(), contains('Failed to initiate purchase'));
    });
  });

  group('restorePurchases', () {
    test('stateService未初期化 → Failure', () async {
      when(() => mockStateService.isInitialized).thenReturn(false);

      final result = await delegate.restorePurchases();

      expect(result.isFailure, isTrue);
      expect(result.error, isA<ServiceException>());
    });

    test('正常系 → Success(pending)', () async {
      when(() => mockStateService.isInitialized).thenReturn(true);

      when(() => mockInAppPurchase.restorePurchases()).thenAnswer((_) async {});

      final result = await delegate.restorePurchases();

      expect(result.isSuccess, isTrue);
      expect(result.value.length, 1);
      expect(result.value.first.status, PurchaseStatus.pending);
    });
  });
}
