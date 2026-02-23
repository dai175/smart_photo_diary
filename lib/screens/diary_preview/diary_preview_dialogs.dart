import 'package:flutter/material.dart';

import '../../core/service_locator.dart';
import '../../core/service_registration.dart';
import '../../localization/localization_extensions.dart';
import '../../models/plans/basic_plan.dart';
import '../../services/interfaces/logging_service_interface.dart';
import '../../services/interfaces/subscription_service_interface.dart';
import '../../ui/components/custom_dialog.dart' show PresetDialogs;
import '../../utils/upgrade_dialog_utils.dart';

/// 日記プレビュー画面のダイアログヘルパー
///
/// 使用量制限ダイアログ、破棄確認ダイアログ、アップグレード誘導を担当する。
class DiaryPreviewDialogHelper {
  DiaryPreviewDialogHelper._();

  /// 日記破棄の確認ダイアログを表示
  static Future<bool> showDiscardConfirmationDialog(
    BuildContext context,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PresetDialogs.confirmation(
        context: context,
        title: context.l10n.diaryPreviewDiscardDialogTitle,
        message: context.l10n.diaryPreviewDiscardDialogMessage,
        confirmText: context.l10n.diaryPreviewDiscardDialogConfirm,
        cancelText: context.l10n.commonCancel,
        isDestructive: true,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
    return result ?? false;
  }

  /// Phase 1.7.2.1: 使用量制限エラー専用ダイアログ表示
  static Future<void> showUsageLimitDialog(BuildContext context) async {
    try {
      final subscriptionService =
          await ServiceRegistration.getAsync<ISubscriptionService>();

      final planResult = await subscriptionService.getCurrentPlanClass();
      final resetDateResult = await subscriptionService.getNextResetDate();

      final plan = planResult.isSuccess ? planResult.value : BasicPlan();
      final limit = plan.monthlyAiGenerationLimit;
      final nextResetDate = resetDateResult.isSuccess
          ? resetDateResult.value
          : DateTime.now().add(const Duration(days: 30));

      if (context.mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (context) => PresetDialogs.usageLimitReached(
            context: context,
            limit: limit,
            nextResetDate: nextResetDate,
            onUpgrade: () {
              Navigator.of(context).pop();
              navigateToUpgrade(context);
            },
            onDismiss: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // 前の画面に戻る
            },
          ),
        );
      }
    } catch (e) {
      final loggingService = serviceLocator.get<ILoggingService>();
      loggingService.warning(
        '使用量制限ダイアログ表示エラー',
        context: 'DiaryPreviewScreen._showUsageLimitDialog',
        data: e.toString(),
      );
      // フォールバック: 基本的なエラーダイアログ
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => PresetDialogs.error(
            context: context,
            title: context.l10n.diaryPreviewUsageLimitTitle,
            message: context.l10n.diaryPreviewUsageLimitMessage,
            onConfirm: () => Navigator.of(context).pop(),
          ),
        );
        if (context.mounted) {
          Navigator.of(context).pop(); // 前の画面に戻る
        }
      }
    }
  }

  /// アップグレード画面への遷移
  static Future<void> navigateToUpgrade(BuildContext context) async {
    await UpgradeDialogUtils.showUpgradeDialog(context);

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
