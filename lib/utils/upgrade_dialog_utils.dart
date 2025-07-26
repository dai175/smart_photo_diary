import 'dart:async';
import 'package:flutter/material.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../core/service_locator.dart';
import '../models/subscription_plan.dart';
import '../models/plans/plan.dart';
import '../models/plans/plan_factory.dart';
import '../models/plans/premium_yearly_plan.dart';
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
  ///
  /// フェーズ5: Planクラスを使用したバージョンも追加
  static Future<void> showUpgradeDialog(BuildContext context) async {
    // 移行期間中は新しい方法を使用
    return showUpgradeDialogV2(context);
  }

  /// プレミアムプラン選択ダイアログを表示（V2: Planクラス使用）
  static Future<void> showUpgradeDialogV2(BuildContext context) async {
    try {
      // 有料プランを取得
      final premiumPlans = PlanFactory.getPremiumPlans();

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
      debugPrint('showUpgradeDialogV2: プラン選択ダイアログ表示開始');
      await _showPremiumPlanDialogV2(context, premiumPlans);
      debugPrint('showUpgradeDialogV2: プラン選択ダイアログ完了');
    } catch (e) {
      if (!context.mounted) return;
      DialogUtils.showSimpleDialog(context, 'エラーが発生しました: ${e.toString()}');
    }
  }

  /// プレミアムプラン選択ダイアログを表示（旧バージョン）
  static Future<void> showUpgradeDialogLegacy(BuildContext context) async {
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

  /// プレミアムプラン選択ダイアログ（V2: Planクラス使用）
  static Future<void> _showPremiumPlanDialogV2(
    BuildContext parentContext,
    List<Plan> plans,
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
                '月間100回のAI生成＋刈20種類のライティングプロンプトが利用できます。',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: AppSpacing.md),
              ...plans.map(
                (plan) =>
                    _buildPlanOptionV2(dialogContext, parentContext, plan),
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

  /// プラン選択オプション（V2: Planクラス使用）
  static Widget _buildPlanOptionV2(
    BuildContext dialogContext,
    BuildContext parentContext,
    Plan plan,
  ) {
    // 割引情報の取得や表示価格の計算
    String description = '';
    if (plan is PremiumYearlyPlan) {
      final discount = plan.discountPercentage;
      if (discount > 0) {
        description = '$discount%割引でお得';
      }
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

            // 購入処理を開始（Planクラス版）
            await _startPurchaseV2WithoutContext(plan);
          },
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.displayName,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
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
                    ],
                  ),
                ),
                Text(
                  plan.formattedPrice + (plan.isMonthly ? '/月' : '/年'),
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
        description = '';
        break;
      case SubscriptionPlan.premiumYearly:
        title = 'プレミアム（年額）';
        price = '¥2,800/年';
        description = '22%割引でお得';
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      if (description.isNotEmpty) ...[
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

  /// コンテキスト不要のシンプルな購入処理（V2: Planクラス使用）
  static Future<void> _startPurchaseV2WithoutContext(Plan plan) async {
    debugPrint('_startPurchaseV2WithoutContext: 開始 - プラン: ${plan.id}');

    // 二重実行防止チェック
    if (_isPurchasing) {
      debugPrint('_startPurchaseV2WithoutContext: 既に購入処理中のため中断');
      return;
    }

    _isPurchasing = true;

    try {
      final subscriptionService = await ServiceLocator()
          .getAsync<ISubscriptionService>();

      debugPrint('_startPurchaseV2WithoutContext: 購入処理開始');

      // Planクラスを使用した購入処理
      final result = await subscriptionService.purchasePlanClass(plan);

      debugPrint(
        '_startPurchaseV2WithoutContext: 購入処理完了 - result: ${result.runtimeType}',
      );

      // 結果に応じた処理
      if (result.isSuccess) {
        debugPrint('_startPurchaseV2WithoutContext: 購入成功');
      } else {
        final error = result.error;
        debugPrint('_startPurchaseV2WithoutContext: 購入失敗 - エラー: $error');

        // シミュレーター環境での特別処理
        if (error.toString().contains('In-App Purchase not available') ||
            error.toString().contains('Product not found')) {
          debugPrint('_startPurchaseV2WithoutContext: シミュレーター環境のため購入処理をスキップ');
        } else {
          debugPrint('_startPurchaseV2WithoutContext: 実際のエラーが発生: $error');
        }
      }
    } catch (e) {
      debugPrint('_startPurchaseV2WithoutContext: エラー発生: $e');

      // 基本的なエラー情報のみログ出力
      // SubscriptionService が適切にエラーハンドリングを行う
    } finally {
      _isPurchasing = false;
      debugPrint('_startPurchaseV2WithoutContext: 購入処理フラグをリセット');
    }
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
