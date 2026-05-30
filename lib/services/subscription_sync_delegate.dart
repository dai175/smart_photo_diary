import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart' hide PurchaseStatus;

import '../constants/subscription_constants.dart';
import '../core/result/result.dart';
import '../models/plans/plan_factory.dart';
import '../models/subscription_status.dart';
import 'interfaces/in_app_purchase_service_interface.dart';
import 'interfaces/logging_service_interface.dart';
import 'interfaces/subscription_state_service_interface.dart';
import 'interfaces/subscription_sync_result.dart';
import 'purchase_error_handler_mixin.dart';

/// 起動時のApp Store購読状態同期を担当するデリゲート
///
/// ローカルがPremiumなのにStoreに有効購読が無い場合にBasicへ降格させる。
/// ネットワークエラー時は誤Basic化を防ぐため現状維持する。
class SubscriptionSyncDelegate with PurchaseErrorHandlerMixin {
  final ISubscriptionStateService Function() _getStateService;
  final InAppPurchase? Function() _getInAppPurchase;
  final Stream<PurchaseResult> _purchaseStream;
  final ILoggingService? _loggingService;
  final Duration _timeout;

  /// sync中フラグの制御コールバック — PurchaseEventHandler 側の isSyncing を操作する
  final void Function(bool)? _onSyncStateChanged;

  SubscriptionSyncDelegate({
    required ISubscriptionStateService Function() getStateService,
    required InAppPurchase? Function() getInAppPurchase,
    required Stream<PurchaseResult> purchaseStream,
    ILoggingService? loggingService,
    Duration timeout = SubscriptionConstants.storeSyncTimeout,
    void Function(bool)? onSyncStateChanged,
  }) : _getStateService = getStateService,
       _getInAppPurchase = getInAppPurchase,
       _purchaseStream = purchaseStream,
       _loggingService = loggingService,
       _timeout = timeout,
       _onSyncStateChanged = onSyncStateChanged;

  @override
  String get logTag => 'SubscriptionSyncDelegate';

  @override
  ILoggingService? get loggingService => _loggingService;

  @override
  ISubscriptionStateService getStateService() => _getStateService();

  @override
  InAppPurchase? getInAppPurchase() => _getInAppPurchase();

  Future<Result<SubscriptionSyncResult>> syncSubscriptionWithStore() async {
    final validationError = validateBasePreconditions();
    if (validationError != null) {
      _loggingService?.warning(
        'Store sync skipped: preconditions not met',
        context: logTag,
        data: validationError.message,
      );
      return Success(SubscriptionSyncResult.skipped());
    }

    final statusResult = await getStateService().getRawStatus();
    if (statusResult.isFailure) {
      _loggingService?.warning(
        'Store sync skipped: failed to get current status',
        context: logTag,
      );
      return Success(SubscriptionSyncResult.skipped());
    }

    final currentPlanId = statusResult.value.planId;
    if (currentPlanId == SubscriptionConstants.basicPlanId) {
      _loggingService?.debug(
        'Store sync: already basic plan, no sync needed',
        context: logTag,
      );
      return Success(SubscriptionSyncResult.noChange());
    }

    var restoredCount = 0;
    String? restoredProductId;
    var hasError = false;

    final subscription = _purchaseStream.listen((result) {
      if (result.status == PurchaseStatus.restored) {
        restoredCount++;
        restoredProductId = result.productId;
      } else if (result.status == PurchaseStatus.error ||
          result.status == PurchaseStatus.networkError ||
          result.status == PurchaseStatus.storeNotAvailable) {
        hasError = true;
      }
    });

    _onSyncStateChanged?.call(true);
    try {
      await getInAppPurchase()!.restorePurchases();
      await Future<void>.delayed(_timeout);
    } catch (e) {
      _loggingService?.error(
        'Store sync: restorePurchases failed',
        context: logTag,
        error: e,
      );
      return Success(SubscriptionSyncResult.error());
    } finally {
      await subscription.cancel();
      _onSyncStateChanged?.call(false);
    }

    if (hasError) {
      _loggingService?.warning(
        'Store sync: error received, keeping current status',
        context: logTag,
      );
      return Success(SubscriptionSyncResult.error());
    }

    if (restoredCount == 0) {
      _loggingService?.info(
        'Store sync: no valid subscriptions found, downgrading to Basic',
        context: logTag,
      );
      final current = statusResult.value;
      final downgradedStatus = SubscriptionStatus(
        planId: SubscriptionConstants.basicPlanId,
        isActive: true,
        startDate: DateTime.now(),
        monthlyUsageCount: current.monthlyUsageCount,
        usageMonth: current.usageMonth,
        lastResetDate: current.lastResetDate,
        autoRenewal: false,
      );
      final saveResult = await getStateService().updateStatus(downgradedStatus);
      if (saveResult.isFailure) {
        _loggingService?.error(
          'Store sync: failed to save downgraded status',
          context: logTag,
        );
        return Success(SubscriptionSyncResult.error());
      }
      return Success(SubscriptionSyncResult.downgradedToBasic());
    }

    _loggingService?.info(
      'Store sync: subscriptions found',
      context: logTag,
      data: {'restoredCount': restoredCount},
    );

    // ローカルの expiryDate が切れている（または未設定）か、Store 側でプランが
    // 変更されている場合に更新する。
    // in_app_purchase は自動更新に対して purchased イベントを発火しないため、
    // 起動時同期がローカル期限を最新に保つ唯一の手段になる。
    // プラン変更（月額→年額など）は期限が有効中でも即座に反映する。
    final current = statusResult.value;
    final now = DateTime.now();
    final activePlan = PlanFactory.getPlanByProductId(restoredProductId ?? '');
    final activePlanId = activePlan?.id ?? current.planId;
    final isExpiryStale =
        current.expiryDate == null || current.expiryDate!.isBefore(now);
    final isPlanChanged = activePlanId != current.planId;

    if (isExpiryStale || isPlanChanged) {
      final duration = Duration(
        days: (activePlan?.isYearly ?? false)
            ? SubscriptionConstants.subscriptionYearDays
            : SubscriptionConstants.subscriptionMonthDays,
      );
      final refreshed = current.copyWith(
        planId: activePlanId,
        expiryDate: now.add(duration),
        autoRenewal: true,
      );
      final saveResult = await getStateService().updateStatus(refreshed);
      if (saveResult.isFailure) {
        _loggingService?.warning(
          'Store sync: failed to refresh subscription state',
          context: logTag,
        );
        return Success(SubscriptionSyncResult.error());
      } else {
        _loggingService?.info(
          'Store sync: refreshed subscription state',
          context: logTag,
          data: {
            'planId': activePlanId,
            'planChanged': isPlanChanged,
            'expiryRefreshed': isExpiryStale,
          },
        );
      }
    }

    return Success(SubscriptionSyncResult.synced(restoredCount));
  }
}
