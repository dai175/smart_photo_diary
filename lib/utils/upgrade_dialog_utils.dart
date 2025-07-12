import 'package:flutter/material.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../core/service_locator.dart';
import '../models/subscription_plan.dart';
import '../core/result/result.dart';
import '../utils/dialog_utils.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/custom_card.dart';
import '../ui/components/custom_dialog.dart';
import '../ui/animations/micro_interactions.dart';

/// アップグレードダイアログのユーティリティクラス
///
/// ホーム画面と設定画面で共通のアップグレード機能を提供
class UpgradeDialogUtils {
  UpgradeDialogUtils._(); // プライベートコンストラクタ

  /// プレミアムプラン選択ダイアログを表示
  static Future<void> showUpgradeDialog(BuildContext context) async {
    try {
      final subscriptionService = await ServiceLocator()
          .getAsync<ISubscriptionService>();

      // 利用可能なプランを取得
      final plansResult = subscriptionService.getAvailablePlans();
      if (plansResult is Failure) {
        if (!context.mounted) return;
        DialogUtils.showSimpleDialog(
          context,
          'プラン情報の取得に失敗しました。しばらく時間をおいて再度お試しください。',
        );
        return;
      }

      final plans = (plansResult as Success<List<SubscriptionPlan>>).value;
      final premiumPlans = plans
          .where((plan) => plan != SubscriptionPlan.basic)
          .toList();

      if (premiumPlans.isEmpty) {
        if (!context.mounted) return;
        DialogUtils.showSimpleDialog(
          context,
          'Premiumプランが利用できません。しばらく時間をおいて再度お試しください。',
        );
        return;
      }

      // プレミアムプラン選択ダイアログを表示
      if (!context.mounted) return;
      await _showPremiumPlanDialog(context, premiumPlans);
    } catch (e) {
      if (!context.mounted) return;
      DialogUtils.showSimpleDialog(context, 'エラーが発生しました: ${e.toString()}');
    }
  }

  /// プレミアムプラン選択ダイアログ（内部実装）
  static Future<void> _showPremiumPlanDialog(
    BuildContext context,
    List<SubscriptionPlan> plans,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'Premiumプラン',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '月間100回までAI日記生成が可能になり、全20種類のライティングプロンプトをご利用いただけます。',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: AppSpacing.md),
            ...plans.map((plan) => _buildPlanOption(context, plan)),
          ],
        ),
        actions: [
          CustomDialogAction(
            text: 'キャンセル',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// プラン選択オプション（内部実装）
  static Widget _buildPlanOption(BuildContext context, SubscriptionPlan plan) {
    String title, price, description;

    switch (plan) {
      case SubscriptionPlan.premiumMonthly:
        title = 'プレミアム（月額）';
        price = '¥300/月';
        description = '月間100回のAI生成';
        break;
      case SubscriptionPlan.premiumYearly:
        title = 'プレミアム（年額）';
        price = '¥2,800/年';
        description = '月間100回のAI生成（22%割引）';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: CustomCard(
        child: InkWell(
          onTap: () {
            MicroInteractions.hapticTap();
            Navigator.of(context).pop();
            _purchasePlan(context, plan);
          },
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        description,
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  price,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: AppSpacing.iconXs,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// プラン購入処理（内部実装）
  static Future<void> _purchasePlan(
    BuildContext context,
    SubscriptionPlan plan,
  ) async {
    try {
      _showLoadingDialog(context, '購入処理中...');

      final subscriptionService = await ServiceLocator()
          .getAsync<ISubscriptionService>();
      final result = await subscriptionService.purchasePlan(plan);

      if (!context.mounted) return;
      Navigator.of(context).pop(); // ローディング画面を閉じる

      if (result is Success) {
        if (!context.mounted) return;
        DialogUtils.showSimpleDialog(context, '購入が完了しました！Premiumプランをお楽しみください。');
      } else {
        final error = (result as Failure).error;
        if (!context.mounted) return;
        DialogUtils.showSimpleDialog(context, '購入に失敗しました: ${error.toString()}');
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // ローディング画面を閉じる
      if (!context.mounted) return;
      DialogUtils.showSimpleDialog(
        context,
        '購入処理中にエラーが発生しました: ${e.toString()}',
      );
    }
  }

  /// ローディングダイアログを表示（内部実装）
  static void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomDialog(
          barrierDismissible: false,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
