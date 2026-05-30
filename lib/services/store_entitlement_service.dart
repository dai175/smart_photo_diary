import 'package:flutter/services.dart';

import '../constants/subscription_constants.dart';
import '../core/errors/app_exceptions.dart';
import '../core/result/result.dart';
import '../models/store_entitlement.dart';
import 'interfaces/logging_service_interface.dart';
import 'interfaces/store_entitlement_service_interface.dart';

/// StoreKit2 のエンタイトルメントを MethodChannel 経由で取得する実装。
///
/// ネイティブ側ハンドラ: `ios/Runner/StoreKit2EntitlementHandler.swift`
class StoreEntitlementService implements IStoreEntitlementService {
  static const MethodChannel _defaultChannel = MethodChannel(
    'smart_photo_diary/storekit2',
  );

  static const String _logContext = 'StoreEntitlementService';

  final ILoggingService _logger;
  final MethodChannel _channel;

  StoreEntitlementService({
    required ILoggingService logger,
    MethodChannel? channel,
  }) : _logger = logger,
       _channel = channel ?? _defaultChannel;

  @override
  Future<Result<StoreEntitlement?>> getActiveSubscription() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getActiveSubscription',
        {
          'productIds': [
            SubscriptionConstants.premiumMonthlyProductId,
            SubscriptionConstants.premiumYearlyProductId,
          ],
        },
      );

      if (result == null) {
        _logger.info(
          'StoreKit2: no active subscription entitlement',
          context: _logContext,
        );
        return const Success(null);
      }

      final entitlement = StoreEntitlement.fromMap(result);
      _logger.info(
        'StoreKit2: active entitlement found',
        context: _logContext,
        data: entitlement.toString(),
      );
      return Success(entitlement);
    } on MissingPluginException catch (e) {
      // 非iOS、またはチャネル未登録。状態変更の根拠にはしない（Failure）。
      _logger.warning(
        'StoreKit2: channel unavailable (non-iOS or not registered)',
        context: _logContext,
        data: e.toString(),
      );
      return Failure(
        ServiceException('StoreKit2 channel unavailable', originalError: e),
      );
    } on PlatformException catch (e) {
      _logger.warning(
        'StoreKit2: platform error while fetching entitlement',
        context: _logContext,
        data: e.toString(),
      );
      return Failure(
        ServiceException(
          'Failed to fetch StoreKit2 entitlement',
          details: e.message,
          originalError: e,
        ),
      );
    }
  }
}
