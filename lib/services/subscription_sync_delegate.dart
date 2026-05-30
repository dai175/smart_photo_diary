import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart' hide PurchaseStatus;

import '../constants/subscription_constants.dart';
import '../core/result/result.dart';
import '../models/plans/plan_factory.dart';
import '../models/store_entitlement.dart';
import '../models/subscription_status.dart';
import 'interfaces/logging_service_interface.dart';
import 'interfaces/store_entitlement_service_interface.dart';
import 'interfaces/subscription_state_service_interface.dart';
import 'interfaces/subscription_sync_result.dart';
import 'purchase_error_handler_mixin.dart';

/// 起動時のApp Store購読状態同期を担当するデリゲート。
///
/// StoreKit2 の Transaction.currentEntitlements から取得した「Apple 管理の実有効期限」を
/// 真実として、ローカルのサブスクリプション状態を補正する。
/// - 有効な購読が無い → Basic へ降格
/// - 有効な購読がある → 実有効期限・プランをローカルへ反映
/// - 取得に失敗 → 誤降格を防ぐため現状維持
class SubscriptionSyncDelegate with PurchaseErrorHandlerMixin {
  final ISubscriptionStateService Function() _getStateService;
  final InAppPurchase? Function() _getInAppPurchase;
  final IStoreEntitlementService Function() _getEntitlementService;
  final ILoggingService? _loggingService;

  SubscriptionSyncDelegate({
    required ISubscriptionStateService Function() getStateService,
    required InAppPurchase? Function() getInAppPurchase,
    required IStoreEntitlementService Function() getEntitlementService,
    ILoggingService? loggingService,
  }) : _getStateService = getStateService,
       _getInAppPurchase = getInAppPurchase,
       _getEntitlementService = getEntitlementService,
       _loggingService = loggingService;

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

    final current = statusResult.value;
    if (current.planId == SubscriptionConstants.basicPlanId) {
      _loggingService?.debug(
        'Store sync: already basic plan, no sync needed',
        context: logTag,
      );
      return Success(SubscriptionSyncResult.noChange());
    }

    final entitlementResult = await _getEntitlementService()
        .getActiveSubscription();
    if (entitlementResult.isFailure) {
      // 取得失敗（非iOS・チャネル未登録・通信不可等）は誤降格を防ぐため現状維持。
      _loggingService?.warning(
        'Store sync: failed to fetch entitlement, keeping current status',
        context: logTag,
        data: entitlementResult.error.message,
      );
      return Success(SubscriptionSyncResult.error());
    }

    return _applySync(current, entitlementResult.value);
  }

  /// StoreKit2 のエンタイトルメント結果をローカル状態へ反映する。
  ///
  /// 引数:
  /// - [current]: forcePlan などの上書きを含まない、DB上の生のサブスクリプション状態
  /// - [entitlement]: StoreKit2 が返した現在有効な購読。`null` なら有効な購読は存在しない
  ///   （失効・解約・返金・未購入）
  ///
  /// 「期限切れの restored イベントを active と誤認して期限を延長する」旧バグを防ぐため、
  /// entitlement の有無のみを根拠に降格/更新を決める。
  Future<Result<SubscriptionSyncResult>> _applySync(
    SubscriptionStatus current,
    StoreEntitlement? entitlement,
  ) async {
    if (entitlement == null) {
      _loggingService?.info(
        'Store sync: no active entitlement, downgrading to Basic',
        context: logTag,
      );
      // expiryDate を null に戻すため copyWith ではなく新規生成する。
      final downgraded = SubscriptionStatus(
        planId: SubscriptionConstants.basicPlanId,
        isActive: true,
        startDate: DateTime.now(),
        monthlyUsageCount: current.monthlyUsageCount,
        usageMonth: current.usageMonth,
        lastResetDate: current.lastResetDate,
        autoRenewal: false,
      );
      final saveResult = await getStateService().updateStatus(downgraded);
      if (saveResult.isFailure) {
        _loggingService?.error(
          'Store sync: failed to save downgraded status',
          context: logTag,
        );
        return Success(SubscriptionSyncResult.error());
      }
      return Success(SubscriptionSyncResult.downgradedToBasic());
    }

    final plan = PlanFactory.getPlanByProductId(entitlement.productId);
    if (plan == null) {
      // 自社の Premium 商品ID以外が返るケースは想定外。誤った降格・更新を避け現状維持。
      _loggingService?.warning(
        'Store sync: unknown product ID in entitlement, keeping current status',
        context: logTag,
        data: {'productId': entitlement.productId},
      );
      return Success(SubscriptionSyncResult.error());
    }

    // willAutoRenew が null（取得不能）のときは既存値を保持し、
    // 解約済み（autoRenewal=false）を誤って true で上書きしない。
    final refreshed = current.copyWith(
      planId: plan.id,
      expiryDate: entitlement.expiryDate,
      autoRenewal: entitlement.willAutoRenew ?? current.autoRenewal,
    );
    final saveResult = await getStateService().updateStatus(refreshed);
    if (saveResult.isFailure) {
      _loggingService?.warning(
        'Store sync: failed to refresh subscription state',
        context: logTag,
      );
      return Success(SubscriptionSyncResult.error());
    }

    _loggingService?.info(
      'Store sync: refreshed subscription state from entitlement',
      context: logTag,
      data: {
        'planId': plan.id,
        'expiryDate': entitlement.expiryDate.toString(),
      },
    );
    return Success(SubscriptionSyncResult.synced(1));
  }
}
