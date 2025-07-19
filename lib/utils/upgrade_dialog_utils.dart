import 'dart:async';
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

  // 購入処理中フラグ（二重実行防止）
  static bool _isPurchasing = false;

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
      debugPrint('showUpgradeDialog: プラン選択ダイアログ表示開始');
      await _showPremiumPlanDialog(context, premiumPlans);
      debugPrint('showUpgradeDialog: プラン選択ダイアログ完了');
    } catch (e) {
      if (!context.mounted) return;
      DialogUtils.showSimpleDialog(context, 'エラーが発生しました: ${e.toString()}');
    }
  }

  /// プレミアムプラン選択ダイアログ（内部実装）
  static Future<void> _showPremiumPlanDialog(
    BuildContext parentContext,
    List<SubscriptionPlan> plans,
  ) async {
    return showDialog(
      context: parentContext,
      builder: (dialogContext) => CustomDialog(
        title: 'Premiumプラン',
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '月間100回のAI生成＋全20種類のライティングプロンプトが利用できます。',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: AppSpacing.md),
              ...plans.map(
                (plan) => _buildPlanOption(dialogContext, parentContext, plan),
              ),
            ],
          ),
        ),
        actions: [
          CustomDialogAction(
            text: 'キャンセル',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }

  /// プラン選択オプション（内部実装）
  static Widget _buildPlanOption(
    BuildContext dialogContext,
    BuildContext parentContext,
    SubscriptionPlan plan,
  ) {
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
          onTap: () async {
            MicroInteractions.hapticTap();

            debugPrint('プランオプションタップ: ${plan.id}');

            // シンプルなアプローチ：ダイアログを閉じてから購入処理
            Navigator.of(dialogContext).pop();

            // 少し待機してUI安定化
            await Future.delayed(const Duration(milliseconds: 200));

            // 購入処理を開始（コンテキスト不要）
            await _startPurchaseWithoutContext(plan);
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
                          color: Theme.of(
                            dialogContext,
                          ).colorScheme.onSurfaceVariant,
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
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                  size: AppSpacing.iconXs,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// コンテキスト不要のシンプルな購入処理
  static Future<void> _startPurchaseWithoutContext(
    SubscriptionPlan plan,
  ) async {
    debugPrint('_startPurchaseWithoutContext: 開始 - プラン: ${plan.id}');

    // 二重実行防止チェック
    if (_isPurchasing) {
      debugPrint('_startPurchaseWithoutContext: 既に購入処理中のため中断');
      return;
    }

    _isPurchasing = true;

    try {
      final subscriptionService = await ServiceLocator()
          .getAsync<ISubscriptionService>();

      debugPrint('_startPurchaseWithoutContext: 購入処理開始');

      // SubscriptionService に購入処理を委譲
      final result = await subscriptionService.purchasePlan(plan);

      debugPrint(
        '_startPurchaseWithoutContext: 購入処理完了 - result: ${result.runtimeType}',
      );

      // 結果に応じた処理
      if (result is Success) {
        debugPrint('_startPurchaseWithoutContext: 購入成功');
      } else if (result is Failure) {
        final error = result.error;
        debugPrint('_startPurchaseWithoutContext: 購入失敗 - エラー: $error');

        // シミュレーター環境での特別処理
        if (error.toString().contains('In-App Purchase not available') ||
            error.toString().contains('Product not found')) {
          debugPrint('_startPurchaseWithoutContext: シミュレーター環境のため購入処理をスキップ');
        } else {
          debugPrint('_startPurchaseWithoutContext: 実際のエラーが発生: $error');
        }
      }
    } catch (e) {
      debugPrint('_startPurchaseWithoutContext: エラー発生: $e');

      // 基本的なエラー情報のみログ出力
      // SubscriptionService が適切にエラーハンドリングを行う
    } finally {
      _isPurchasing = false;
      debugPrint('_startPurchaseWithoutContext: 購入処理フラグをリセット');
    }
  }
}
