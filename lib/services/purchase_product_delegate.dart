import 'package:in_app_purchase/in_app_purchase.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../core/errors/error_handler.dart';
import '../models/plans/plan_factory.dart';
import '../config/in_app_purchase_config.dart';
import 'interfaces/in_app_purchase_service_interface.dart';
import 'interfaces/subscription_state_service_interface.dart';
import 'interfaces/logging_service_interface.dart';

/// 商品クエリを担当する内部委譲クラス
class PurchaseProductDelegate {
  final ISubscriptionStateService Function() _getStateService;
  final InAppPurchase? Function() _getInAppPurchase;
  final ILoggingService? _loggingService;

  PurchaseProductDelegate({
    required ISubscriptionStateService Function() getStateService,
    required InAppPurchase? Function() getInAppPurchase,
    ILoggingService? loggingService,
  }) : _getStateService = getStateService,
       _getInAppPurchase = getInAppPurchase,
       _loggingService = loggingService;

  /// 指定プランの実際の価格情報を取得
  Future<Result<PurchaseProduct?>> getProductPrice(String planId) async {
    try {
      final validationError = _validatePreconditions();
      if (validationError != null) return Failure(validationError);

      final plan = PlanFactory.createPlan(planId);
      final productId = InAppPurchaseConfig.getProductIdFromPlan(plan);

      _log('Fetching price for plan: $planId (productId: $productId)');

      final response = await _getInAppPurchase()!.queryProductDetails({
        productId,
      });

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

      _log(
        'Successfully fetched price from App Store API',
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

  /// In-App Purchase商品情報を取得
  Future<Result<List<PurchaseProduct>>> getProducts() async {
    try {
      final validationError = _validatePreconditions();
      if (validationError != null) return Failure(validationError);

      _log('Fetching product information...');

      final productIds = InAppPurchaseConfig.allProductIds.toSet();
      final response = await _getInAppPurchase()!.queryProductDetails(
        productIds,
      );

      if (response.error != null) {
        return Failure(
          ServiceException(
            'Failed to fetch product details',
            details: response.error.toString(),
          ),
        );
      }

      if (response.notFoundIDs.isNotEmpty) {
        _loggingService?.warning(
          'Products not found: ${response.notFoundIDs}',
          context: _logTag,
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

      _log('Successfully fetched ${products.length} products');

      return Success(products);
    } catch (e) {
      return _handleError(e, 'getProducts');
    }
  }

  /// App Store から商品詳細を取得する
  Future<ProductDetails> queryProductDetails(String productId) async {
    _loggingService?.debug(
      'Querying product details',
      context: _logTag,
      data: {'productId': productId},
    );
    final response = await _getInAppPurchase()!.queryProductDetails({
      productId,
    });

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
    _log(
      'Product details retrieved',
      data: {'id': details.id, 'title': details.title, 'price': details.price},
    );
    return details;
  }

  // =================================================================
  // 内部ヘルパー
  // =================================================================

  static const _logTag = 'PurchaseProductDelegate';

  ServiceException? _validatePreconditions() {
    if (!_getStateService().isInitialized) {
      return const ServiceException(
        'SubscriptionStateService is not initialized',
      );
    }
    if (_getInAppPurchase() == null) {
      return const ServiceException('In-App Purchase not available');
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
