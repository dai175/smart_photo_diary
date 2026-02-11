import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../core/errors/error_handler.dart';
import '../models/subscription_status.dart';
import '../models/plans/plan.dart';
import '../models/plans/plan_factory.dart';
import '../models/plans/basic_plan.dart';
import '../constants/subscription_constants.dart';
import '../config/in_app_purchase_config.dart';
import 'interfaces/in_app_purchase_service_interface.dart';
import 'interfaces/subscription_state_service_interface.dart';
import 'interfaces/logging_service_interface.dart';
import 'subscription_state_service.dart';
import '../core/service_locator.dart';

// 型エイリアスで名前衝突を解決
import 'package:in_app_purchase/in_app_purchase.dart' as iap;
import 'interfaces/in_app_purchase_service_interface.dart' as iapsi;

/// InAppPurchaseService
///
/// IAP商品情報取得、購入フロー、復元、検証を担当する。
class InAppPurchaseService implements IInAppPurchaseService {
  final ISubscriptionStateService _stateService;
  ILoggingService? _loggingService;

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
      _log(
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
      _log('Initializing In-App Purchase...', level: LogLevel.info);

      try {
        if (kDebugMode && (defaultTargetPlatform == TargetPlatform.iOS)) {
          _log(
            'Running in iOS debug mode - checking simulator environment',
            level: LogLevel.debug,
          );
        }

        final bool isAvailable = await InAppPurchase.instance.isAvailable();
        if (!isAvailable) {
          _log(
            'In-App Purchase not available on this device',
            level: LogLevel.warning,
          );
          return;
        }

        _inAppPurchase = InAppPurchase.instance;

        _purchaseSubscription = _inAppPurchase!.purchaseStream.listen(
          _onPurchaseUpdated,
          onError: _onPurchaseError,
          onDone: () =>
              _log('Purchase stream completed', level: LogLevel.debug),
        );

        _log('In-App Purchase initialization completed', level: LogLevel.info);
      } catch (bindingError) {
        final errorString = bindingError.toString();
        if (errorString.contains('Binding has not yet been initialized') ||
            errorString.contains('ServicesBinding')) {
          _log(
            'In-App Purchase not available (test/simulator environment)',
            level: LogLevel.warning,
          );
          return;
        }
        rethrow;
      }
    } catch (e) {
      _log(
        'Failed to initialize In-App Purchase',
        level: LogLevel.error,
        error: e,
      );
      _log('Error details: $e', level: LogLevel.error);
    }
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      await _processPurchaseUpdate(purchaseDetails);
    }
  }

  void _onPurchaseError(dynamic error) {
    _log('Purchase stream error', level: LogLevel.error, error: error);

    final errorResult = PurchaseResult(
      status: iapsi.PurchaseStatus.error,
      errorMessage: error.toString(),
    );
    _purchaseStreamController.add(errorResult);
  }

  Future<void> _processPurchaseUpdate(PurchaseDetails purchaseDetails) async {
    try {
      _log(
        'Processing purchase update',
        level: LogLevel.info,
        data: {'status': purchaseDetails.status},
      );

      switch (purchaseDetails.status) {
        case iap.PurchaseStatus.purchased:
          await _handlePurchaseCompleted(purchaseDetails);
          break;

        case iap.PurchaseStatus.restored:
          await _handlePurchaseRestored(purchaseDetails);
          break;

        case iap.PurchaseStatus.error:
          await _handlePurchaseError(purchaseDetails);
          break;

        case iap.PurchaseStatus.canceled:
          await _handlePurchaseCanceled(purchaseDetails);
          break;

        case iap.PurchaseStatus.pending:
          await _handlePurchasePending(purchaseDetails);
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase!.completePurchase(purchaseDetails);
        _log(
          'Purchase completion confirmed to platform',
          level: LogLevel.debug,
        );
      }
    } catch (e) {
      _log('Error processing purchase update', level: LogLevel.error, error: e);
    }
  }

  Future<void> _handlePurchaseCompleted(PurchaseDetails purchaseDetails) async {
    try {
      _log(
        'Purchase completed',
        level: LogLevel.info,
        data: {'productId': purchaseDetails.productID},
      );

      await _applyPurchaseSideEffects(purchaseDetails);

      final plan = InAppPurchaseConfig.getPlanFromProductId(
        purchaseDetails.productID,
      );
      final result = PurchaseResult(
        status: iapsi.PurchaseStatus.purchased,
        productId: purchaseDetails.productID,
        transactionId: purchaseDetails.purchaseID,
        purchaseDate: DateTime.now(),
        plan: plan,
      );
      _purchaseStreamController.add(result);

      _isPurchasing = false;
      _log(
        '購入フラグをリセットしました',
        level: LogLevel.debug,
        context: '_handlePurchaseCompleted',
      );
    } catch (e) {
      _log(
        'Error handling purchase completion',
        level: LogLevel.error,
        error: e,
      );
      await _handlePurchaseError(purchaseDetails);
    }
  }

  /// 購入完了時のサイドエフェクト（サブスクリプション状態更新）のみを実行する。
  /// ストリームイベントはemitしない。
  Future<void> _applyPurchaseSideEffects(
    PurchaseDetails purchaseDetails,
  ) async {
    final plan = InAppPurchaseConfig.getPlanFromProductId(
      purchaseDetails.productID,
    );
    await _updateSubscriptionFromPurchase(purchaseDetails, plan);
  }

  Future<void> _handlePurchaseRestored(PurchaseDetails purchaseDetails) async {
    try {
      _log(
        'Purchase restored',
        level: LogLevel.info,
        data: {'productId': purchaseDetails.productID},
      );

      // サイドエフェクトのみ実行（ストリームイベントはemitしない）
      await _applyPurchaseSideEffects(purchaseDetails);

      final result = PurchaseResult(
        status: iapsi.PurchaseStatus.restored,
        productId: purchaseDetails.productID,
        transactionId: purchaseDetails.purchaseID,
        purchaseDate: DateTime.now(),
        plan: InAppPurchaseConfig.getPlanFromProductId(
          purchaseDetails.productID,
        ),
      );
      _purchaseStreamController.add(result);
    } catch (e) {
      _log(
        'Error handling purchase restoration',
        level: LogLevel.error,
        error: e,
      );
    }
  }

  Future<void> _handlePurchaseError(PurchaseDetails purchaseDetails) async {
    _log(
      'Purchase error',
      level: LogLevel.error,
      error: purchaseDetails.error?.message,
    );

    final result = PurchaseResult(
      status: iapsi.PurchaseStatus.error,
      productId: purchaseDetails.productID,
      errorMessage: purchaseDetails.error?.message ?? 'Unknown purchase error',
    );
    _purchaseStreamController.add(result);

    _isPurchasing = false;
    _log(
      '購入フラグをリセットしました',
      level: LogLevel.debug,
      context: '_handlePurchaseError',
    );
  }

  Future<void> _handlePurchaseCanceled(PurchaseDetails purchaseDetails) async {
    _log(
      'Purchase canceled',
      level: LogLevel.info,
      data: {'productId': purchaseDetails.productID},
    );

    final result = PurchaseResult(
      status: iapsi.PurchaseStatus.cancelled,
      productId: purchaseDetails.productID,
    );
    _purchaseStreamController.add(result);

    _isPurchasing = false;
    _log(
      '購入フラグをリセットしました',
      level: LogLevel.debug,
      context: '_handlePurchaseCanceled',
    );
  }

  Future<void> _handlePurchasePending(PurchaseDetails purchaseDetails) async {
    _log(
      'Purchase pending',
      level: LogLevel.info,
      data: {'productId': purchaseDetails.productID},
    );

    final result = PurchaseResult(
      status: iapsi.PurchaseStatus.pending,
      productId: purchaseDetails.productID,
    );
    _purchaseStreamController.add(result);
  }

  Future<void> _updateSubscriptionFromPurchase(
    PurchaseDetails purchaseDetails,
    Plan plan,
  ) async {
    try {
      final now = DateTime.now();

      DateTime expiryDate;
      if (plan.id == SubscriptionConstants.premiumMonthlyPlanId) {
        expiryDate = now.add(
          const Duration(days: SubscriptionConstants.subscriptionMonthDays),
        );
      } else if (plan.id == SubscriptionConstants.premiumYearlyPlanId) {
        expiryDate = now.add(
          const Duration(days: SubscriptionConstants.subscriptionYearDays),
        );
      } else {
        throw ArgumentError('Basic plan cannot be purchased');
      }

      final newStatus = SubscriptionStatus(
        planId: plan.id,
        isActive: true,
        startDate: now,
        expiryDate: expiryDate,
        autoRenewal: true,
        monthlyUsageCount: 0,
        lastResetDate: now,
        transactionId: purchaseDetails.purchaseID ?? '',
        lastPurchaseDate: now,
      );

      await _stateService.updateStatus(newStatus);

      _log('Subscription status updated from purchase', level: LogLevel.info);
    } catch (e) {
      _log(
        'Error updating subscription from purchase',
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
        return Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }

      if (_inAppPurchase == null) {
        return Failure(ServiceException('In-App Purchase not available'));
      }

      final plan = PlanFactory.createPlan(planId);
      final productId = InAppPurchaseConfig.getProductIdFromPlan(plan);

      _log(
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
        return Success(null);
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

      _log(
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
        return Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }

      if (_inAppPurchase == null) {
        return Failure(ServiceException('In-App Purchase not available'));
      }

      _log('Fetching product information...', level: LogLevel.info);

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
        _log(
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

      _log(
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
        return Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }

      if (_inAppPurchase == null) {
        return Failure(ServiceException('In-App Purchase not available'));
      }

      _log('Starting purchase restoration...', level: LogLevel.info);

      await _inAppPurchase!.restorePurchases();

      _log('Purchase restoration initiated', level: LogLevel.info);

      return Success([PurchaseResult(status: iapsi.PurchaseStatus.pending)]);
    } catch (e) {
      return _handleError(e, 'restorePurchases');
    }
  }

  @override
  Future<Result<bool>> validatePurchase(String transactionId) async {
    try {
      if (!_stateService.isInitialized) {
        return Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }

      _log('Validating purchase: $transactionId', level: LogLevel.info);

      final statusResult = await _stateService.getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final status = statusResult.value;
      final isValid =
          status.transactionId == transactionId && _isSubscriptionValid(status);

      _log('Purchase validation result: $isValid', level: LogLevel.info);

      return Success(isValid);
    } catch (e) {
      return _handleError(e, 'validatePurchase', details: transactionId);
    }
  }

  @override
  Future<Result<PurchaseResult>> purchasePlan(Plan plan) async {
    try {
      if (!_stateService.isInitialized) {
        return Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }

      if (_inAppPurchase == null) {
        return Failure(ServiceException('In-App Purchase not available'));
      }

      if (_isPurchasing) {
        return Failure(
          ServiceException('Another purchase is already in progress'),
        );
      }

      if (plan.id == BasicPlan().id) {
        return Failure(ServiceException('Basic plan cannot be purchased'));
      }

      _log(
        '購入処理開始',
        level: LogLevel.info,
        context: 'purchasePlan',
        data: {'planId': plan.id, 'productId': plan.productId},
      );
      _isPurchasing = true;

      final productId = InAppPurchaseConfig.getProductIdFromPlan(plan);
      _log(
        '商品ID取得完了',
        level: LogLevel.debug,
        context: 'purchasePlan',
        data: {'productId': productId},
      );

      try {
        _log(
          '商品詳細をクエリ中',
          level: LogLevel.debug,
          context: 'purchasePlan',
          data: {'productId': productId},
        );
        final productResponse = await _inAppPurchase!.queryProductDetails({
          productId,
        });
        _log(
          '商品クエリ完了',
          level: LogLevel.debug,
          context: 'purchasePlan',
          data: {
            'error': productResponse.error,
            'productCount': productResponse.productDetails.length,
          },
        );

        if (productResponse.error != null) {
          _isPurchasing = false;
          return Failure(
            ServiceException(
              'Failed to get product details for purchase',
              details: productResponse.error.toString(),
            ),
          );
        }

        if (productResponse.productDetails.isEmpty) {
          _isPurchasing = false;
          return Failure(ServiceException('Product not found: $productId'));
        }

        final productDetails = productResponse.productDetails.first;
        _log(
          '商品詳細取得',
          level: LogLevel.info,
          context: 'purchasePlan',
          data: {
            'id': productDetails.id,
            'title': productDetails.title,
            'price': productDetails.price,
          },
        );

        final PurchaseParam purchaseParam = PurchaseParam(
          productDetails: productDetails,
        );

        _log(
          'buyNonConsumable呼び出し中...',
          level: LogLevel.info,
          context: 'purchasePlan',
        );
        final bool success = await _inAppPurchase!.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
        _log(
          'buyNonConsumable結果',
          level: LogLevel.info,
          context: 'purchasePlan',
          data: {'success': success},
        );

        if (!success) {
          _isPurchasing = false;
          return Failure(ServiceException('Failed to initiate purchase'));
        }

        _log('購入処理が正常に開始されました', level: LogLevel.info, context: 'purchasePlan');

        return Success(
          PurchaseResult(
            status: iapsi.PurchaseStatus.pending,
            productId: productId,
            plan: plan,
          ),
        );
      } catch (storeError) {
        _isPurchasing = false;
        _log(
          'ストアエラー発生',
          level: LogLevel.error,
          context: 'purchasePlan',
          error: storeError,
        );

        if (kDebugMode && defaultTargetPlatform == TargetPlatform.iOS) {
          final errorString = storeError.toString();
          if (errorString.contains('not connected to app store') ||
              errorString.contains('sandbox') ||
              errorString.contains('StoreKit')) {
            _log(
              'シミュレーター環境のストア接続エラー - 成功をモック',
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

        rethrow;
      }
    } catch (e) {
      _isPurchasing = false;
      _log(
        '予期しないエラー',
        level: LogLevel.error,
        context: 'purchasePlan',
        error: e,
      );
      return _handleError(
        e,
        'purchasePlan',
        details: 'planId: ${plan.id}, productId: ${plan.productId}',
      );
    }
  }

  @override
  Future<Result<void>> changePlan(Plan newPlan) async {
    try {
      if (!_stateService.isInitialized) {
        return Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }

      return Failure(
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
        return Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }

      _log('Canceling subscription...', level: LogLevel.info);

      final statusResult = await _stateService.getCurrentStatus();
      if (statusResult.isFailure) {
        return Failure(statusResult.error);
      }

      final currentStatus = statusResult.value;

      final updatedStatus = currentStatus.copyWith(autoRenewal: false);

      await _stateService.updateStatus(updatedStatus);

      _log('Subscription auto-renewal disabled', level: LogLevel.info);

      return const Success(null);
    } catch (e) {
      return _handleError(e, 'cancelSubscription');
    }
  }

  @override
  Future<void> dispose() async {
    _log('Disposing InAppPurchaseService...', level: LogLevel.info);

    await _purchaseSubscription?.cancel();
    _purchaseSubscription = null;

    await _purchaseStreamController.close();

    _inAppPurchase = null;

    _log('InAppPurchaseService disposed', level: LogLevel.info);
  }

  // =================================================================
  // 内部ヘルパーメソッド
  // =================================================================

  bool _isSubscriptionValid(SubscriptionStatus status) {
    final stateService = _stateService;
    if (stateService is SubscriptionStateService) {
      return stateService.isSubscriptionValid(status);
    }
    if (!status.isActive) return false;
    final currentPlan = PlanFactory.createPlan(status.planId);
    if (currentPlan.id == 'basic') return true;
    if (status.expiryDate == null) return false;
    return DateTime.now().isBefore(status.expiryDate!);
  }

  void _log(
    String message, {
    LogLevel level = LogLevel.info,
    dynamic error,
    String? context,
    Map<String, dynamic>? data,
  }) {
    final logContext = context ?? 'InAppPurchaseService';

    if (_loggingService != null) {
      switch (level) {
        case LogLevel.debug:
          _loggingService!.debug(message, context: logContext, data: data);
          break;
        case LogLevel.info:
          _loggingService!.info(message, context: logContext, data: data);
          break;
        case LogLevel.warning:
          _loggingService!.warning(message, context: logContext, data: data);
          break;
        case LogLevel.error:
          _loggingService!.error(message, context: logContext, error: error);
          break;
      }

      if (error != null && level != LogLevel.error) {
        _loggingService!.error('Error details: $error', context: logContext);
      }
    } else {
      final prefix = level == LogLevel.error
          ? 'ERROR'
          : level == LogLevel.warning
          ? 'WARNING'
          : level == LogLevel.debug
          ? 'DEBUG'
          : 'INFO';

      debugPrint('[$prefix] $logContext: $message');
      if (error != null) {
        debugPrint('[$prefix] $logContext: Error - $error');
      }
    }
  }

  Result<T> _handleError<T>(
    dynamic error,
    String operation, {
    String? details,
  }) {
    final errorContext = 'InAppPurchaseService.$operation';
    final message =
        'Operation failed: $operation${details != null ? ' - $details' : ''}';

    _log(message, level: LogLevel.error, error: error, context: errorContext);

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
