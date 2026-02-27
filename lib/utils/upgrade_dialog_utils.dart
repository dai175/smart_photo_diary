import 'package:flutter/material.dart';
import '../core/service_locator.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../services/interfaces/logging_service_interface.dart';
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
  static Future<void> showUpgradeDialog(BuildContext context) async {
    final logger = serviceLocator.get<ILoggingService>();
    final locale = context.l10n.localeName;

    try {
      final subscriptionService = await serviceLocator
          .getAsync<ISubscriptionService>();

      final controller = UpgradeDialogController(
        logger: logger,
        subscriptionService: subscriptionService,
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

        logger.debug(
          'Opening plan selection dialog with dynamic pricing',
          context: 'UpgradeDialogUtils.showUpgradeDialog',
        );

        await showDialog(
          context: context,
          builder: (dialogContext) => UpgradeDialog(
            plans: controller.plans,
            priceStrings: controller.priceStrings,
            onPlanSelected: (plan) => controller.purchasePlan(plan),
          ),
        );

        logger.debug(
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
}
