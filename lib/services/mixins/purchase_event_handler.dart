import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart' as iap;
import '../../models/subscription_status.dart';
import '../../models/plans/plan.dart';
import '../../constants/subscription_constants.dart';
import '../../config/in_app_purchase_config.dart';
import '../interfaces/in_app_purchase_service_interface.dart' as iapsi;
import '../interfaces/in_app_purchase_service_interface.dart';
import '../interfaces/subscription_state_service_interface.dart';
import '../interfaces/logging_service_interface.dart';
import 'service_logging.dart';

/// 購入イベントハンドリング mixin
///
/// 購入ストリームからのイベントを処理し、
/// サブスクリプション状態を更新する責務を持つ。
mixin PurchaseEventHandler on ServiceLogging {
  /// サブスクリプション状態サービス
  ISubscriptionStateService get purchaseStateService;

  /// 購入結果ストリームコントローラ
  StreamController<PurchaseResult> get purchaseStreamController;

  /// InAppPurchaseインスタンス（未初期化時はnull）
  iap.InAppPurchase? get inAppPurchaseInstance;

  /// 購入処理中フラグ
  bool get isPurchasing;
  set isPurchasing(bool value);

  /// 購入ストリーム更新ハンドラ
  void onPurchaseUpdated(List<iap.PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      await processPurchaseUpdate(purchaseDetails);
    }
  }

  /// 購入ストリームエラーハンドラ
  void onPurchaseError(dynamic error) {
    log('Purchase stream error', level: LogLevel.error, error: error);

    final errorResult = PurchaseResult(
      status: iapsi.PurchaseStatus.error,
      errorMessage: error.toString(),
    );
    purchaseStreamController.add(errorResult);
  }

  /// 個別の購入更新を処理
  Future<void> processPurchaseUpdate(
    iap.PurchaseDetails purchaseDetails,
  ) async {
    try {
      log(
        'Processing purchase update',
        level: LogLevel.info,
        data: {'status': purchaseDetails.status},
      );

      switch (purchaseDetails.status) {
        case iap.PurchaseStatus.purchased:
          await handlePurchaseCompleted(purchaseDetails);
          break;

        case iap.PurchaseStatus.restored:
          await handlePurchaseRestored(purchaseDetails);
          break;

        case iap.PurchaseStatus.error:
          await handlePurchaseErrorEvent(purchaseDetails);
          break;

        case iap.PurchaseStatus.canceled:
          await handlePurchaseCanceled(purchaseDetails);
          break;

        case iap.PurchaseStatus.pending:
          await handlePurchasePending(purchaseDetails);
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await inAppPurchaseInstance!.completePurchase(purchaseDetails);
        log('Purchase completion confirmed to platform', level: LogLevel.debug);
      }
    } catch (e) {
      log('Error processing purchase update', level: LogLevel.error, error: e);
    }
  }

  /// 購入完了を処理
  Future<void> handlePurchaseCompleted(
    iap.PurchaseDetails purchaseDetails,
  ) async {
    try {
      log(
        'Purchase completed',
        level: LogLevel.info,
        data: {'productId': purchaseDetails.productID},
      );

      await applyPurchaseSideEffects(purchaseDetails);

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
      purchaseStreamController.add(result);

      isPurchasing = false;
      log(
        '購入フラグをリセットしました',
        level: LogLevel.debug,
        context: 'handlePurchaseCompleted',
      );
    } catch (e) {
      log(
        'Error handling purchase completion',
        level: LogLevel.error,
        error: e,
      );
      await handlePurchaseErrorEvent(purchaseDetails);
    }
  }

  /// 購入完了時のサイドエフェクト（サブスクリプション状態更新）のみを実行する。
  /// ストリームイベントはemitしない。
  Future<void> applyPurchaseSideEffects(
    iap.PurchaseDetails purchaseDetails,
  ) async {
    final plan = InAppPurchaseConfig.getPlanFromProductId(
      purchaseDetails.productID,
    );
    await updateSubscriptionFromPurchase(purchaseDetails, plan);
  }

  /// 購入復元を処理
  Future<void> handlePurchaseRestored(
    iap.PurchaseDetails purchaseDetails,
  ) async {
    try {
      log(
        'Purchase restored',
        level: LogLevel.info,
        data: {'productId': purchaseDetails.productID},
      );

      // サイドエフェクトのみ実行（ストリームイベントはemitしない）
      await applyPurchaseSideEffects(purchaseDetails);

      final result = PurchaseResult(
        status: iapsi.PurchaseStatus.restored,
        productId: purchaseDetails.productID,
        transactionId: purchaseDetails.purchaseID,
        purchaseDate: DateTime.now(),
        plan: InAppPurchaseConfig.getPlanFromProductId(
          purchaseDetails.productID,
        ),
      );
      purchaseStreamController.add(result);

      isPurchasing = false;
    } catch (e) {
      isPurchasing = false;
      log(
        'Error handling purchase restoration',
        level: LogLevel.error,
        error: e,
      );
    }
  }

  /// 購入エラーを処理
  Future<void> handlePurchaseErrorEvent(
    iap.PurchaseDetails purchaseDetails,
  ) async {
    log(
      'Purchase error',
      level: LogLevel.error,
      error: purchaseDetails.error?.message,
    );

    final result = PurchaseResult(
      status: iapsi.PurchaseStatus.error,
      productId: purchaseDetails.productID,
      errorMessage: purchaseDetails.error?.message ?? 'Unknown purchase error',
    );
    purchaseStreamController.add(result);

    isPurchasing = false;
    log(
      '購入フラグをリセットしました',
      level: LogLevel.debug,
      context: 'handlePurchaseErrorEvent',
    );
  }

  /// 購入キャンセルを処理
  Future<void> handlePurchaseCanceled(
    iap.PurchaseDetails purchaseDetails,
  ) async {
    log(
      'Purchase canceled',
      level: LogLevel.info,
      data: {'productId': purchaseDetails.productID},
    );

    final result = PurchaseResult(
      status: iapsi.PurchaseStatus.cancelled,
      productId: purchaseDetails.productID,
    );
    purchaseStreamController.add(result);

    isPurchasing = false;
    log(
      '購入フラグをリセットしました',
      level: LogLevel.debug,
      context: 'handlePurchaseCanceled',
    );
  }

  /// 購入ペンディングを処理
  Future<void> handlePurchasePending(
    iap.PurchaseDetails purchaseDetails,
  ) async {
    log(
      'Purchase pending',
      level: LogLevel.info,
      data: {'productId': purchaseDetails.productID},
    );

    final result = PurchaseResult(
      status: iapsi.PurchaseStatus.pending,
      productId: purchaseDetails.productID,
    );
    purchaseStreamController.add(result);
  }

  /// 購入からサブスクリプション状態を更新
  Future<void> updateSubscriptionFromPurchase(
    iap.PurchaseDetails purchaseDetails,
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

      // 現在の使用量を引き継ぐ（月途中のアップグレードで使用量がリセットされるのを防止）
      final currentStatusResult = await purchaseStateService.getCurrentStatus();
      final currentUsageCount = currentStatusResult.isSuccess
          ? currentStatusResult.value.monthlyUsageCount
          : 0;
      final currentLastResetDate = currentStatusResult.isSuccess
          ? currentStatusResult.value.lastResetDate
          : now;

      final newStatus = SubscriptionStatus(
        planId: plan.id,
        isActive: true,
        startDate: now,
        expiryDate: expiryDate,
        autoRenewal: true,
        monthlyUsageCount: currentUsageCount,
        lastResetDate: currentLastResetDate ?? now,
        transactionId: purchaseDetails.purchaseID ?? '',
        lastPurchaseDate: now,
      );

      await purchaseStateService.updateStatus(newStatus);

      log('Subscription status updated from purchase', level: LogLevel.info);
    } catch (e) {
      log(
        'Error updating subscription from purchase',
        level: LogLevel.error,
        error: e,
      );
      rethrow;
    }
  }
}
