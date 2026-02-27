import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../core/errors/error_handler.dart';
import '../models/plans/plan.dart';
import 'interfaces/in_app_purchase_service_interface.dart';
import 'interfaces/subscription_state_service_interface.dart';
import 'interfaces/logging_service_interface.dart';
import 'mixins/service_logging.dart';
import 'mixins/purchase_event_handler.dart';
import 'purchase_product_delegate.dart';
import 'purchase_flow_delegate.dart';

/// InAppPurchaseService
///
/// IAP商品情報取得、購入フロー、復元、検証を担当するファサード。
/// 商品クエリは [PurchaseProductDelegate]、購入フローは [PurchaseFlowDelegate] に委譲する。
class InAppPurchaseService
    with ServiceLogging, PurchaseEventHandler
    implements IInAppPurchaseService {
  final ISubscriptionStateService _stateService;
  final ILoggingService? _loggingService;

  @override
  ILoggingService? get loggingService => _loggingService;

  @override
  String get logTag => 'InAppPurchaseService';

  // PurchaseEventHandler mixin 用のアクセサ
  @override
  ISubscriptionStateService get purchaseStateService => _stateService;

  @override
  StreamController<PurchaseResult> get purchaseStreamController =>
      _purchaseStreamController;

  @override
  InAppPurchase? get inAppPurchaseInstance => _inAppPurchase;

  @override
  bool get isPurchasing => _isPurchasing;

  @override
  set isPurchasing(bool value) => _isPurchasing = value;

  // In-App Purchase関連
  InAppPurchase? _inAppPurchase;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  // 購入状態ストリーム
  final StreamController<PurchaseResult> _purchaseStreamController =
      StreamController<PurchaseResult>.broadcast();

  // 購入処理中フラグ
  bool _isPurchasing = false;

  // デリゲート
  late final PurchaseProductDelegate _productDelegate;
  late final PurchaseFlowDelegate _flowDelegate;

  InAppPurchaseService({
    required ISubscriptionStateService stateService,
    ILoggingService? logger,
  }) : _stateService = stateService,
       _loggingService = logger {
    _productDelegate = PurchaseProductDelegate(
      getStateService: () => _stateService,
      getInAppPurchase: () => _inAppPurchase,
      loggingService: _loggingService,
    );
    _flowDelegate = PurchaseFlowDelegate(
      getStateService: () => _stateService,
      getInAppPurchase: () => _inAppPurchase,
      getIsPurchasing: () => _isPurchasing,
      setIsPurchasing: (value) => _isPurchasing = value,
      productDelegate: _productDelegate,
      loggingService: _loggingService,
    );
  }

  @override
  Future<Result<void>> initialize() async {
    try {
      await _initializeInAppPurchase();
      return const Success(null);
    } catch (e) {
      log(
        'Error initializing InAppPurchaseService',
        level: LogLevel.error,
        error: e,
      );
      return Failure(
        ServiceException(
          'Failed to initialize InAppPurchaseService',
          details: e.toString(),
        ),
      );
    }
  }

  Future<void> _initializeInAppPurchase() async {
    try {
      log('Initializing In-App Purchase...', level: LogLevel.info);

      try {
        if (kDebugMode && (defaultTargetPlatform == TargetPlatform.iOS)) {
          log(
            'Running in iOS debug mode - checking simulator environment',
            level: LogLevel.debug,
          );
        }

        final bool isAvailable = await InAppPurchase.instance.isAvailable();
        if (!isAvailable) {
          log(
            'In-App Purchase not available on this device',
            level: LogLevel.warning,
          );
          return;
        }

        _inAppPurchase = InAppPurchase.instance;

        _purchaseSubscription = _inAppPurchase!.purchaseStream.listen(
          onPurchaseUpdated,
          onError: onPurchaseError,
          onDone: () => log('Purchase stream completed', level: LogLevel.debug),
        );

        log('In-App Purchase initialization completed', level: LogLevel.info);
      } catch (bindingError) {
        final errorString = bindingError.toString();
        if (errorString.contains('Binding has not yet been initialized') ||
            errorString.contains('ServicesBinding')) {
          log(
            'In-App Purchase not available (test/simulator environment)',
            level: LogLevel.warning,
          );
          return;
        }
        rethrow;
      }
    } catch (e) {
      log(
        'Failed to initialize In-App Purchase',
        level: LogLevel.error,
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<Result<PurchaseProduct?>> getProductPrice(String planId) =>
      _productDelegate.getProductPrice(planId);

  @override
  Future<Result<List<PurchaseProduct>>> getProducts() =>
      _productDelegate.getProducts();

  @override
  Stream<PurchaseResult> get purchaseStream => _purchaseStreamController.stream;

  @override
  Future<Result<PurchaseResult>> purchasePlan(Plan plan) =>
      _flowDelegate.purchasePlan(plan);

  @override
  Future<Result<List<PurchaseResult>>> restorePurchases() =>
      _flowDelegate.restorePurchases();

  @override
  Future<Result<bool>> validatePurchase(String transactionId) async {
    try {
      if (!_stateService.isInitialized) {
        return const Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }

      log('Validating purchase: $transactionId', level: LogLevel.info);

      final statusResult = await _stateService.getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;
      final isValid =
          status.transactionId == transactionId &&
          _stateService.isSubscriptionValid(status);

      log('Purchase validation result: $isValid', level: LogLevel.info);

      return Success(isValid);
    } catch (e) {
      return _handleError(e, 'validatePurchase', details: transactionId);
    }
  }

  @override
  Future<Result<void>> changePlan(Plan newPlan) async {
    try {
      if (!_stateService.isInitialized) {
        return const Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }

      return const Failure(
        ServiceException(
          'Plan change is not yet implemented',
          details: 'This feature will be available in future versions',
        ),
      );
    } catch (e) {
      return _handleError(e, 'changePlan', details: newPlan.id);
    }
  }

  @override
  Future<Result<void>> cancelSubscription() async {
    try {
      if (!_stateService.isInitialized) {
        return const Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }

      log('Canceling subscription...', level: LogLevel.info);

      final statusResult = await _stateService.getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final currentStatus = statusResult.value;
      final updatedStatus = currentStatus.copyWith(autoRenewal: false);
      await _stateService.updateStatus(updatedStatus);

      log('Subscription auto-renewal disabled', level: LogLevel.info);

      return const Success(null);
    } catch (e) {
      return _handleError(e, 'cancelSubscription');
    }
  }

  @override
  Future<void> dispose() async {
    log('Disposing InAppPurchaseService...', level: LogLevel.info);

    await _purchaseSubscription?.cancel();
    _purchaseSubscription = null;

    await _purchaseStreamController.close();

    _inAppPurchase = null;

    log('InAppPurchaseService disposed', level: LogLevel.info);
  }

  // =================================================================
  // 内部ヘルパーメソッド
  // =================================================================

  Result<T> _handleError<T>(
    dynamic error,
    String operation, {
    String? details,
  }) {
    final errorContext = 'InAppPurchaseService.$operation';
    final message =
        'Operation failed: $operation${details != null ? ' - $details' : ''}';

    log(message, level: LogLevel.error, error: error, context: errorContext);

    final handledException = ErrorHandler.handleError(
      error,
      context: errorContext,
    );

    final serviceException = handledException is ServiceException
        ? handledException
        : ServiceException(
            'Failed to $operation',
            details: details ?? error.toString(),
            originalError: error,
          );

    return Failure(serviceException);
  }
}
