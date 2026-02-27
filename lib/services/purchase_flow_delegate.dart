import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../core/errors/error_handler.dart';
import '../models/plans/plan.dart';
import '../models/plans/basic_plan.dart';
import '../config/in_app_purchase_config.dart';
import 'interfaces/in_app_purchase_service_interface.dart' as iapsi;
import 'interfaces/in_app_purchase_service_interface.dart';
import 'interfaces/subscription_state_service_interface.dart';
import 'interfaces/logging_service_interface.dart';
import 'purchase_product_delegate.dart';

/// 購入フロー・復元を担当する内部委譲クラス
class PurchaseFlowDelegate {
  final ISubscriptionStateService Function() _getStateService;
  final InAppPurchase? Function() _getInAppPurchase;
  final bool Function() _getIsPurchasing;
  final void Function(bool) _setIsPurchasing;
  final PurchaseProductDelegate _productDelegate;
  final ILoggingService? _loggingService;

  PurchaseFlowDelegate({
    required ISubscriptionStateService Function() getStateService,
    required InAppPurchase? Function() getInAppPurchase,
    required bool Function() getIsPurchasing,
    required void Function(bool) setIsPurchasing,
    required PurchaseProductDelegate productDelegate,
    ILoggingService? loggingService,
  }) : _getStateService = getStateService,
       _getInAppPurchase = getInAppPurchase,
       _getIsPurchasing = getIsPurchasing,
       _setIsPurchasing = setIsPurchasing,
       _productDelegate = productDelegate,
       _loggingService = loggingService;

  /// プランを購入
  Future<Result<PurchaseResult>> purchasePlan(Plan plan) async {
    try {
      final validationError = _validatePurchasePreconditions(plan);
      if (validationError != null) return Failure(validationError);

      final productId = InAppPurchaseConfig.getProductIdFromPlan(plan);
      _log(
        'Purchase process started',
        data: {'planId': plan.id, 'productId': productId},
      );
      _setIsPurchasing(true);

      final productDetails = await _productDelegate.queryProductDetails(
        productId,
      );
      final purchaseParam = PurchaseParam(productDetails: productDetails);

      try {
        _log('Calling buyNonConsumable...');
        final success = await _getInAppPurchase()!.buyNonConsumable(
          purchaseParam: purchaseParam,
        );

        if (!success) {
          _setIsPurchasing(false);
          return const Failure(ServiceException('Failed to initiate purchase'));
        }

        _log('Purchase process started successfully');

        return Success(
          PurchaseResult(
            status: iapsi.PurchaseStatus.pending,
            productId: productId,
            plan: plan,
          ),
        );
      } catch (storeError) {
        _setIsPurchasing(false);
        final simulatorResult = await _handleSimulatorStoreError(
          storeError,
          plan: plan,
          productId: productId,
        );
        if (simulatorResult != null) return simulatorResult;
        rethrow;
      }
    } catch (e) {
      _setIsPurchasing(false);
      return _handleError(
        e,
        'purchasePlan',
        details: 'planId: ${plan.id}, productId: ${plan.productId}',
      );
    }
  }

  /// 購入を復元
  Future<Result<List<PurchaseResult>>> restorePurchases() async {
    try {
      final stateService = _getStateService();
      if (!stateService.isInitialized) {
        return const Failure(
          ServiceException('SubscriptionStateService is not initialized'),
        );
      }

      final inAppPurchase = _getInAppPurchase();
      if (inAppPurchase == null) {
        return const Failure(ServiceException('In-App Purchase not available'));
      }

      _log('Starting purchase restoration...');

      await inAppPurchase.restorePurchases();

      _log('Purchase restoration initiated');

      return const Success([
        PurchaseResult(status: iapsi.PurchaseStatus.pending),
      ]);
    } catch (e) {
      return _handleError(e, 'restorePurchases');
    }
  }

  // =================================================================
  // 内部ヘルパー
  // =================================================================

  static const _logTag = 'PurchaseFlowDelegate';

  /// 購入前提条件を検証
  ServiceException? _validatePurchasePreconditions(Plan plan) {
    if (!_getStateService().isInitialized) {
      return const ServiceException(
        'SubscriptionStateService is not initialized',
      );
    }
    if (_getInAppPurchase() == null) {
      return const ServiceException('In-App Purchase not available');
    }
    if (_getIsPurchasing()) {
      return const ServiceException('Another purchase is already in progress');
    }
    if (plan.id == BasicPlan().id) {
      return const ServiceException('Basic plan cannot be purchased');
    }
    return null;
  }

  /// iOS シミュレータ環境でのストアエラーをハンドリング（デバッグ時のみ）
  Future<Result<PurchaseResult>?> _handleSimulatorStoreError(
    dynamic storeError, {
    required Plan plan,
    required String productId,
  }) async {
    _loggingService?.error(
      'Store error occurred',
      context: _logTag,
      error: storeError,
    );

    if (kDebugMode && defaultTargetPlatform == TargetPlatform.iOS) {
      final errorString = storeError.toString();
      if (errorString.contains('not connected to app store') ||
          errorString.contains('sandbox') ||
          errorString.contains('StoreKit')) {
        _loggingService?.warning(
          'Simulator environment store connection error - mocking success',
          context: _logTag,
        );

        await Future.delayed(const Duration(milliseconds: 1000));
        final result = await _getStateService().createStatusForPlan(plan);
        if (result.isSuccess) {
          return Success(
            PurchaseResult(
              status: iapsi.PurchaseStatus.purchased,
              productId: productId,
              plan: plan,
              purchaseDate: DateTime.now(),
            ),
          );
        } else {
          _loggingService?.warning(
            'Simulator mock: createStatusForPlan failed',
            context: _logTag,
          );
        }
      }
    }
    return null;
  }

  void _log(String message, {Map<String, dynamic>? data}) {
    _loggingService?.info(message, context: _logTag, data: data);
  }

  Result<T> _handleError<T>(
    dynamic error,
    String operation, {
    String? details,
  }) {
    final errorContext = '$_logTag.$operation';
    final message =
        'Operation failed: $operation${details != null ? ' - $details' : ''}';

    _loggingService?.error(message, context: errorContext, error: error);

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
