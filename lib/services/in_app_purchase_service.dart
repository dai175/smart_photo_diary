import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../core/errors/error_handler.dart';
import '../models/plans/plan.dart';
import '../models/plans/plan_factory.dart';
import '../models/plans/basic_plan.dart';
import '../config/in_app_purchase_config.dart';
import 'interfaces/in_app_purchase_service_interface.dart';
import 'interfaces/subscription_state_service_interface.dart';
import 'interfaces/logging_service_interface.dart';
import 'mixins/service_logging.dart';
import 'mixins/purchase_event_handler.dart';
import '../core/service_locator.dart';

// 型エイリアスで名前衝突を解決
import 'interfaces/in_app_purchase_service_interface.dart' as iapsi;

/// InAppPurchaseService
///
/// IAP商品情報取得、購入フロー、復元、検証を担当する。
class InAppPurchaseService
    with ServiceLogging, PurchaseEventHandler
    implements IInAppPurchaseService {
  final ISubscriptionStateService _stateService;
  ILoggingService? _loggingService;

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

  InAppPurchaseService({required ISubscriptionStateService stateService})
    : _stateService = stateService {
    try {
      _loggingService = ServiceLocator().get<ILoggingService>();
    } catch (_) {
      // テスト環境など、LoggingServiceが未登録の場合はnullのまま
    }
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
  Future<Result<PurchaseProduct?>> getProductPrice(String planId) async {
    try {
      if (!_stateService.isInitialized) {
        return const Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }

      if (_inAppPurchase == null) {
        return const Failure(ServiceException('In-App Purchase not available'));
      }

      final plan = PlanFactory.createPlan(planId);
      final productId = InAppPurchaseConfig.getProductIdFromPlan(plan);

      log(
        'Fetching price for plan: $planId (productId: $productId)',
        level: LogLevel.info,
      );

      final ProductDetailsResponse response = await _inAppPurchase!
          .queryProductDetails({productId});

      if (response.error != null) {
        return Failure(
          ServiceException(
            'Failed to fetch product price',
            details: response.error.toString(),
          ),
        );
      }

      if (response.productDetails.isEmpty) {
        return const Success(null);
      }

      final productDetail = response.productDetails.first;
      final product = PurchaseProduct(
        id: productDetail.id,
        title: productDetail.title,
        description: productDetail.description,
        price: productDetail.price,
        priceAmount: double.tryParse(productDetail.rawPrice.toString()) ?? 0.0,
        currencyCode: productDetail.currencyCode,
        plan: plan,
      );

      log(
        'Successfully fetched price from App Store API',
        level: LogLevel.info,
        data: {
          'productId': productDetail.id,
          'formattedPrice': product.price,
          'currencyCode': product.currencyCode,
          'rawAmount': product.priceAmount,
        },
      );

      return Success(product);
    } catch (e) {
      return _handleError(e, 'getProductPrice', details: planId);
    }
  }

  @override
  Future<Result<List<PurchaseProduct>>> getProducts() async {
    try {
      if (!_stateService.isInitialized) {
        return const Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }

      if (_inAppPurchase == null) {
        return const Failure(ServiceException('In-App Purchase not available'));
      }

      log('Fetching product information...', level: LogLevel.info);

      final productIds = InAppPurchaseConfig.allProductIds.toSet();

      final ProductDetailsResponse response = await _inAppPurchase!
          .queryProductDetails(productIds);

      if (response.error != null) {
        return Failure(
          ServiceException(
            'Failed to fetch product details',
            details: response.error.toString(),
          ),
        );
      }

      if (response.notFoundIDs.isNotEmpty) {
        log(
          'Products not found: ${response.notFoundIDs}',
          level: LogLevel.warning,
        );
      }

      final products = response.productDetails.map((productDetail) {
        final plan = InAppPurchaseConfig.getPlanFromProductId(productDetail.id);

        return PurchaseProduct(
          id: productDetail.id,
          title: productDetail.title,
          description: productDetail.description,
          price: productDetail.price,
          priceAmount:
              double.tryParse(productDetail.rawPrice.toString()) ?? 0.0,
          currencyCode: productDetail.currencyCode,
          plan: plan,
        );
      }).toList();

      log(
        'Successfully fetched ${products.length} products',
        level: LogLevel.info,
      );

      return Success(products);
    } catch (e) {
      return _handleError(e, 'getProducts');
    }
  }

  @override
  Stream<PurchaseResult> get purchaseStream => _purchaseStreamController.stream;

  @override
  Future<Result<List<PurchaseResult>>> restorePurchases() async {
    try {
      if (!_stateService.isInitialized) {
        return const Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }

      if (_inAppPurchase == null) {
        return const Failure(ServiceException('In-App Purchase not available'));
      }

      log('Starting purchase restoration...', level: LogLevel.info);

      await _inAppPurchase!.restorePurchases();

      log('Purchase restoration initiated', level: LogLevel.info);

      return const Success([
        PurchaseResult(status: iapsi.PurchaseStatus.pending),
      ]);
    } catch (e) {
      return _handleError(e, 'restorePurchases');
    }
  }

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
  Future<Result<PurchaseResult>> purchasePlan(Plan plan) async {
    try {
      final validationError = _validatePurchasePreconditions(plan);
      if (validationError != null) return Failure(validationError);

      final productId = InAppPurchaseConfig.getProductIdFromPlan(plan);
      log(
        'Purchase process started',
        level: LogLevel.info,
        context: 'purchasePlan',
        data: {'planId': plan.id, 'productId': productId},
      );
      _isPurchasing = true;

      try {
        final productDetails = await _queryProductDetails(productId);

        final purchaseParam = PurchaseParam(productDetails: productDetails);

        log(
          'Calling buyNonConsumable...',
          level: LogLevel.info,
          context: 'purchasePlan',
        );
        final success = await _inAppPurchase!.buyNonConsumable(
          purchaseParam: purchaseParam,
        );

        if (!success) {
          _isPurchasing = false;
          return const Failure(ServiceException('Failed to initiate purchase'));
        }

        log(
          'Purchase process started successfully',
          level: LogLevel.info,
          context: 'purchasePlan',
        );

        return Success(
          PurchaseResult(
            status: iapsi.PurchaseStatus.pending,
            productId: productId,
            plan: plan,
          ),
        );
      } catch (storeError) {
        _isPurchasing = false;
        final simulatorResult = await _handleSimulatorStoreError(
          storeError,
          plan: plan,
          productId: productId,
        );
        if (simulatorResult != null) return simulatorResult;
        rethrow;
      }
    } catch (e) {
      _isPurchasing = false;
      return _handleError(
        e,
        'purchasePlan',
        details: 'planId: ${plan.id}, productId: ${plan.productId}',
      );
    }
  }

  /// 購入前提条件を検証。エラーがある場合は例外を返す。
  ServiceException? _validatePurchasePreconditions(Plan plan) {
    if (!_stateService.isInitialized) {
      return const ServiceException(
        'SubscriptionStateService is not initialized',
      );
    }
    if (_inAppPurchase == null) {
      return const ServiceException('In-App Purchase not available');
    }
    if (_isPurchasing) {
      return const ServiceException('Another purchase is already in progress');
    }
    if (plan.id == BasicPlan().id) {
      return const ServiceException('Basic plan cannot be purchased');
    }
    return null;
  }

  /// App Store から商品詳細を取得する
  Future<ProductDetails> _queryProductDetails(String productId) async {
    log(
      'Querying product details',
      level: LogLevel.debug,
      context: 'purchasePlan',
      data: {'productId': productId},
    );
    final response = await _inAppPurchase!.queryProductDetails({productId});

    if (response.error != null) {
      throw ServiceException(
        'Failed to get product details for purchase',
        details: response.error.toString(),
      );
    }

    if (response.productDetails.isEmpty) {
      throw ServiceException('Product not found: $productId');
    }

    final details = response.productDetails.first;
    log(
      'Product details retrieved',
      level: LogLevel.info,
      context: 'purchasePlan',
      data: {'id': details.id, 'title': details.title, 'price': details.price},
    );
    return details;
  }

  /// iOS シミュレータ環境でのストアエラーをハンドリング（デバッグ時のみ）
  Future<Result<PurchaseResult>?> _handleSimulatorStoreError(
    dynamic storeError, {
    required Plan plan,
    required String productId,
  }) async {
    log(
      'Store error occurred',
      level: LogLevel.error,
      context: 'purchasePlan',
      error: storeError,
    );

    if (kDebugMode && defaultTargetPlatform == TargetPlatform.iOS) {
      final errorString = storeError.toString();
      if (errorString.contains('not connected to app store') ||
          errorString.contains('sandbox') ||
          errorString.contains('StoreKit')) {
        log(
          'Simulator environment store connection error - mocking success',
          level: LogLevel.warning,
          context: 'purchasePlan',
        );

        await Future.delayed(const Duration(milliseconds: 1000));
        final result = await _stateService.createStatusForPlan(plan);
        if (result.isSuccess) {
          return Success(
            PurchaseResult(
              status: iapsi.PurchaseStatus.purchased,
              productId: productId,
              plan: plan,
              purchaseDate: DateTime.now(),
            ),
          );
        }
      }
    }
    return null;
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
