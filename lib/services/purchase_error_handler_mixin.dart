import 'package:in_app_purchase/in_app_purchase.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../core/errors/error_handler.dart';
import 'interfaces/subscription_state_service_interface.dart';
import 'interfaces/logging_service_interface.dart';

/// 購入デリゲート共通のエラーハンドリングと前提条件検証を提供する mixin
mixin PurchaseErrorHandlerMixin {
  /// ログタグ（サブクラスが実装）
  String get logTag;

  /// ロギングサービス（サブクラスが実装）
  ILoggingService? get loggingService;

  /// サブスクリプション状態サービスの取得（サブクラスが実装）
  ISubscriptionStateService getStateService();

  /// InAppPurchase インスタンスの取得（サブクラスが実装）
  InAppPurchase? getInAppPurchase();

  /// 基本前提条件の検証（初期化済み＋IAP利用可能）
  ServiceException? validateBasePreconditions() {
    if (!getStateService().isInitialized) {
      return const ServiceException(
        'SubscriptionStateService is not initialized',
      );
    }
    if (getInAppPurchase() == null) {
      return const ServiceException('In-App Purchase not available');
    }
    return null;
  }

  /// 共通エラーハンドリング
  Result<T> handlePurchaseError<T>(
    dynamic error,
    String operation, {
    String? details,
  }) {
    final errorContext = '$logTag.$operation';
    final message =
        'Operation failed: $operation${details != null ? ' - $details' : ''}';

    loggingService?.error(message, context: errorContext, error: error);

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
