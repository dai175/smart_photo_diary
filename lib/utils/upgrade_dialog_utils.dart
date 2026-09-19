import 'package:flutter/material.dart';
import '../core/service_registration.dart';
import '../core/result/result.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../services/interfaces/subscription_sync_result.dart';
import '../controllers/upgrade_dialog_controller.dart';
import '../widgets/upgrade/upgrade_dialog.dart';
import '../localization/localization_extensions.dart';
import 'dialog_utils.dart';

/// アップグレードダイアログのユーティリティクラス
///
/// ホーム画面と設定画面で共通のアップグレード機能を提供するファサード。
/// 実際のロジックは [UpgradeDialogController]、UIは [UpgradeDialog] に委譲する。
class UpgradeDialogUtils {
  UpgradeDialogUtils._();

  /// プレミアムプラン選択ダイアログを表示
  static Future<void> showUpgradeDialog(
    BuildContext context, {
    ILoggingService? logger,
    ISubscriptionService? subscriptionService,
  }) async {
    final locale = context.l10n.localeName;

    try {
      final resolvedLogger =
          logger ?? ServiceRegistration.get<ILoggingService>();
      final resolvedSubscriptionService =
          subscriptionService ??
          await ServiceRegistration.getAsync<ISubscriptionService>();

      final controller = UpgradeDialogController(
        logger: resolvedLogger,
        subscriptionService: resolvedSubscriptionService,
      );

      try {
        final loaded = await controller.loadPlansAndPrices(locale: locale);

        if (!loaded) {
          if (!context.mounted) return;
          DialogUtils.showSimpleDialog(
            context,
            context.l10n.upgradeDialogUnavailableMessage,
          );
          return;
        }

        if (!context.mounted) return;

        resolvedLogger.debug(
          'Opening plan selection dialog with dynamic pricing',
          context: 'UpgradeDialogUtils.showUpgradeDialog',
        );

        await showDialog(
          context: context,
          builder: (dialogContext) => UpgradeDialog(
            plans: controller.plans,
            priceStrings: controller.priceStrings,
            onPlanSelected: (plan) => controller.purchasePlan(plan),
            purchaseFailureMessage: () {
              final result = controller.lastPurchaseResult;
              if (result == null) return null;
              if (result.isCancelled) {
                return dialogContext.l10n.purchaseCanceledMessage;
              }
              return dialogContext.l10n.purchaseFailedMessage;
            },
            onRestorePressed: () =>
                _handleRestore(dialogContext, controller.restorePurchases),
          ),
        );

        if (controller.lastPurchaseResult?.isSuccess == true &&
            context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.purchaseSuccessMessage)),
          );
        }

        resolvedLogger.debug(
          'Plan selection dialog completed',
          context: 'UpgradeDialogUtils.showUpgradeDialog',
        );
      } finally {
        controller.dispose();
      }
    } catch (e) {
      if (!context.mounted) return;
      DialogUtils.showSimpleDialog(
        context,
        context.l10n.commonUnexpectedErrorWithDetails(e.toString()),
      );
    }
  }

  static Future<void> showRestoreResult(
    BuildContext context,
    Result<SubscriptionSyncResult> result,
  ) async {
    if (!context.mounted) return;

    if (result.isFailure) {
      await DialogUtils.showErrorDialog(
        context,
        context.l10n.restorePurchasesFailed,
      );
      return;
    }

    final message = switch (result.value.outcome) {
      SubscriptionSyncOutcome.synced => context.l10n.restorePurchasesSuccess,
      SubscriptionSyncOutcome.noChange => context.l10n.restorePurchasesNone,
      SubscriptionSyncOutcome.downgradedToBasic =>
        context.l10n.restorePurchasesNone,
      SubscriptionSyncOutcome.skipped ||
      SubscriptionSyncOutcome.error => context.l10n.restorePurchasesFailed,
    };

    if (result.value.outcome == SubscriptionSyncOutcome.synced) {
      await DialogUtils.showSuccessDialog(
        context,
        context.l10n.restorePurchasesButton,
        message,
      );
    } else if (result.value.outcome == SubscriptionSyncOutcome.noChange ||
        result.value.outcome == SubscriptionSyncOutcome.downgradedToBasic) {
      await DialogUtils.showSimpleDialog(context, message);
    } else {
      await DialogUtils.showErrorDialog(context, message);
    }
  }

  static Future<void> _handleRestore(
    BuildContext context,
    Future<Result<SubscriptionSyncResult>> Function() restore,
  ) async {
    final result = await restore();
    if (!context.mounted) return;
    await showRestoreResult(context, result);
  }
}
