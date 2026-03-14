import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:smart_photo_diary/services/purchase_error_handler_mixin.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_state_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/service_locator.dart';

import '../../integration/mocks/mock_services.dart';

class MockSubscriptionStateService extends Mock
    implements ISubscriptionStateService {}

class MockInAppPurchase extends Mock implements InAppPurchase {}

/// Concrete test class that uses the mixin
class TestPurchaseErrorHandler with PurchaseErrorHandlerMixin {
  @override
  String get logTag => 'TestHandler';

  @override
  ILoggingService? get loggingService => _loggingService;

  @override
  ISubscriptionStateService getStateService() => _stateService;

  @override
  InAppPurchase? getInAppPurchase() => _inAppPurchase;

  final ILoggingService? _loggingService;
  final ISubscriptionStateService _stateService;
  final InAppPurchase? _inAppPurchase;

  TestPurchaseErrorHandler({
    ILoggingService? loggingService,
    required ISubscriptionStateService stateService,
    InAppPurchase? inAppPurchase,
  }) : _loggingService = loggingService,
       _stateService = stateService,
       _inAppPurchase = inAppPurchase;
}

void main() {
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
  });

  tearDown(() {
    TestServiceSetup.clearAllMocks();
  });

  group('validateBasePreconditions', () {
    test('stateService未初期化 → ServiceException', () {
      when(() => mockStateService.isInitialized).thenReturn(false);

      final handler = TestPurchaseErrorHandler(
        loggingService: mockLogger,
        stateService: mockStateService,
        inAppPurchase: mockInAppPurchase,
      );

      final error = handler.validateBasePreconditions();

      expect(error, isNotNull);
      expect(error, isA<ServiceException>());
      expect(error.toString(), contains('not initialized'));
    });

    test('InAppPurchaseがnull → ServiceException', () {
      when(() => mockStateService.isInitialized).thenReturn(true);

      final handler = TestPurchaseErrorHandler(
        loggingService: mockLogger,
        stateService: mockStateService,
        inAppPurchase: null,
      );

      final error = handler.validateBasePreconditions();

      expect(error, isNotNull);
      expect(error, isA<ServiceException>());
      expect(error.toString(), contains('In-App Purchase not available'));
    });

    test('全条件OK → null', () {
      when(() => mockStateService.isInitialized).thenReturn(true);

      final handler = TestPurchaseErrorHandler(
        loggingService: mockLogger,
        stateService: mockStateService,
        inAppPurchase: mockInAppPurchase,
      );

      final error = handler.validateBasePreconditions();

      expect(error, isNull);
    });
  });

  group('handlePurchaseError', () {
    test('AppExceptionをFailureに変換', () {
      when(() => mockStateService.isInitialized).thenReturn(true);

      final handler = TestPurchaseErrorHandler(
        loggingService: mockLogger,
        stateService: mockStateService,
        inAppPurchase: mockInAppPurchase,
      );

      const appException = ServiceException('Test error');
      final result = handler.handlePurchaseError<String>(
        appException,
        'testOperation',
      );

      expect(result.isFailure, isTrue);
      expect(result.error, isA<ServiceException>());
      expect(result.error.toString(), contains('Test error'));
    });

    test('一般エラーをServiceExceptionに変換してFailure', () {
      when(() => mockStateService.isInitialized).thenReturn(true);

      final handler = TestPurchaseErrorHandler(
        loggingService: mockLogger,
        stateService: mockStateService,
        inAppPurchase: mockInAppPurchase,
      );

      final result = handler.handlePurchaseError<String>(
        Exception('Generic error'),
        'testOperation',
      );

      expect(result.isFailure, isTrue);
      expect(result.error, isA<ServiceException>());
    });

    test('エラーをログに記録する', () {
      when(() => mockStateService.isInitialized).thenReturn(true);

      final handler = TestPurchaseErrorHandler(
        loggingService: mockLogger,
        stateService: mockStateService,
        inAppPurchase: mockInAppPurchase,
      );

      const appException = ServiceException('Logged error');
      handler.handlePurchaseError<String>(
        appException,
        'testOperation',
        details: 'some details',
      );

      verify(
        () => mockLogger.error(
          any(),
          context: any(named: 'context'),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      ).called(greaterThanOrEqualTo(1));
    });
  });
}
