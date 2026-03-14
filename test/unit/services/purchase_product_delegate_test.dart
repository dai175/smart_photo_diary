import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:smart_photo_diary/services/purchase_product_delegate.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_state_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/in_app_purchase_service_interface.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';

import '../../integration/mocks/mock_services.dart';

class MockSubscriptionStateService extends Mock
    implements ISubscriptionStateService {}

class MockInAppPurchase extends Mock implements InAppPurchase {}

class FakeProductDetails extends Fake implements ProductDetails {
  @override
  String get id => 'smart_photo_diary_premium_monthly_plan';

  @override
  String get title => 'Premium Monthly';

  @override
  String get description => 'Monthly subscription';

  @override
  String get price => '\u00a5300';

  @override
  double get rawPrice => 300.0;

  @override
  String get currencyCode => 'JPY';

  @override
  String get currencySymbol => '\u00a5';
}

void main() {
  late PurchaseProductDelegate delegate;
  late MockSubscriptionStateService mockStateService;
  late MockILoggingService mockLogger;
  late MockInAppPurchase mockInAppPurchase;

  setUpAll(() {
    registerMockFallbacks();

    // Register LoggingService in ServiceLocator for ErrorHandler
    if (!serviceLocator.isRegistered<ILoggingService>()) {
      serviceLocator.registerSingleton<ILoggingService>(MockILoggingService());
    }
  });

  setUp(() {
    mockStateService = MockSubscriptionStateService();
    mockLogger = TestServiceSetup.getLoggingService();
    mockInAppPurchase = MockInAppPurchase();

    delegate = PurchaseProductDelegate(
      getStateService: () => mockStateService,
      getInAppPurchase: () => mockInAppPurchase,
      loggingService: mockLogger,
    );
  });

  tearDown(() {
    TestServiceSetup.clearAllMocks();
  });

  group('getProductPrice', () {
    test('stateService未初期化 → Failure', () async {
      when(() => mockStateService.isInitialized).thenReturn(false);

      final result = await delegate.getProductPrice('premium_monthly');

      expect(result.isFailure, isTrue);
      expect(result.error, isA<ServiceException>());
    });

    test('InAppPurchaseがnull → Failure', () async {
      when(() => mockStateService.isInitialized).thenReturn(true);

      final nullIapDelegate = PurchaseProductDelegate(
        getStateService: () => mockStateService,
        getInAppPurchase: () => null,
        loggingService: mockLogger,
      );

      final result = await nullIapDelegate.getProductPrice('premium_monthly');

      expect(result.isFailure, isTrue);
      expect(
        result.error.toString(),
        contains('In-App Purchase not available'),
      );
    });

    test('BasicPlan(空productId) → Success(null)', () async {
      when(() => mockStateService.isInitialized).thenReturn(true);

      final result = await delegate.getProductPrice(BasicPlan().id);

      expect(result.isSuccess, isTrue);
      expect(result.value, isNull);
    });

    test('正常系 → Success(PurchaseProduct)', () async {
      when(() => mockStateService.isInitialized).thenReturn(true);
      final fakeProduct = FakeProductDetails();

      when(() => mockInAppPurchase.queryProductDetails(any())).thenAnswer(
        (_) async => ProductDetailsResponse(
          productDetails: [fakeProduct],
          notFoundIDs: [],
        ),
      );

      final result = await delegate.getProductPrice('premium_monthly');

      expect(result.isSuccess, isTrue);
      final product = result.value;
      expect(product, isNotNull);
      expect(product, isA<PurchaseProduct>());
      expect(product!.id, 'smart_photo_diary_premium_monthly_plan');
      expect(product.price, '\u00a5300');
      expect(product.currencyCode, 'JPY');
    });

    test('クエリエラー → Failure', () async {
      when(() => mockStateService.isInitialized).thenReturn(true);

      when(() => mockInAppPurchase.queryProductDetails(any())).thenAnswer(
        (_) async => ProductDetailsResponse(
          productDetails: [],
          notFoundIDs: [],
          error: IAPError(
            source: 'test',
            code: 'error',
            message: 'Query failed',
          ),
        ),
      );

      final result = await delegate.getProductPrice('premium_monthly');

      expect(result.isFailure, isTrue);
      expect(
        result.error.toString(),
        contains('Failed to fetch product price'),
      );
    });

    test('商品が見つからない → Success(null)', () async {
      when(() => mockStateService.isInitialized).thenReturn(true);

      when(() => mockInAppPurchase.queryProductDetails(any())).thenAnswer(
        (_) async => ProductDetailsResponse(
          productDetails: [],
          notFoundIDs: ['smart_photo_diary_premium_monthly_plan'],
        ),
      );

      final result = await delegate.getProductPrice('premium_monthly');

      expect(result.isSuccess, isTrue);
      expect(result.value, isNull);
    });
  });

  group('getProducts', () {
    test('stateService未初期化 → Failure', () async {
      when(() => mockStateService.isInitialized).thenReturn(false);

      final result = await delegate.getProducts();

      expect(result.isFailure, isTrue);
      expect(result.error, isA<ServiceException>());
    });

    test('正常系 → Success(商品リスト)', () async {
      when(() => mockStateService.isInitialized).thenReturn(true);
      final fakeProduct = FakeProductDetails();

      when(() => mockInAppPurchase.queryProductDetails(any())).thenAnswer(
        (_) async => ProductDetailsResponse(
          productDetails: [fakeProduct],
          notFoundIDs: [],
        ),
      );

      final result = await delegate.getProducts();

      expect(result.isSuccess, isTrue);
      expect(result.value, isNotEmpty);
      expect(result.value.first.id, 'smart_photo_diary_premium_monthly_plan');
    });

    test('クエリエラー → Failure', () async {
      when(() => mockStateService.isInitialized).thenReturn(true);

      when(() => mockInAppPurchase.queryProductDetails(any())).thenAnswer(
        (_) async => ProductDetailsResponse(
          productDetails: [],
          notFoundIDs: [],
          error: IAPError(
            source: 'test',
            code: 'error',
            message: 'Query failed',
          ),
        ),
      );

      final result = await delegate.getProducts();

      expect(result.isFailure, isTrue);
      expect(
        result.error.toString(),
        contains('Failed to fetch product details'),
      );
    });
  });

  group('queryProductDetails', () {
    test('クエリエラー → ServiceException', () async {
      when(() => mockStateService.isInitialized).thenReturn(true);

      when(() => mockInAppPurchase.queryProductDetails(any())).thenAnswer(
        (_) async => ProductDetailsResponse(
          productDetails: [],
          notFoundIDs: [],
          error: IAPError(
            source: 'test',
            code: 'error',
            message: 'Query failed',
          ),
        ),
      );

      expect(
        () => delegate.queryProductDetails(
          'smart_photo_diary_premium_monthly_plan',
        ),
        throwsA(isA<ServiceException>()),
      );
    });

    test('商品が見つからない → ServiceException', () async {
      when(() => mockStateService.isInitialized).thenReturn(true);

      when(() => mockInAppPurchase.queryProductDetails(any())).thenAnswer(
        (_) async => ProductDetailsResponse(
          productDetails: [],
          notFoundIDs: ['smart_photo_diary_premium_monthly_plan'],
        ),
      );

      expect(
        () => delegate.queryProductDetails(
          'smart_photo_diary_premium_monthly_plan',
        ),
        throwsA(isA<ServiceException>()),
      );
    });
  });
}
