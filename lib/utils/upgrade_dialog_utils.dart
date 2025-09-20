import 'dart:async';
import 'package:flutter/material.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../services/logging_service.dart';
import '../core/service_locator.dart';
import '../models/plans/plan.dart';
import '../models/plans/plan_factory.dart';
import '../models/plans/premium_yearly_plan.dart';
import '../utils/dialog_utils.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/custom_card.dart';
import '../ui/components/custom_dialog.dart';
import '../ui/animations/micro_interactions.dart';
import '../localization/localization_extensions.dart';

/// アップグレードダイアログのユーティリティクラス
///
/// ホーム画面と設定画面で共通のアップグレード機能を提供
class UpgradeDialogUtils {
  UpgradeDialogUtils._(); // プライベートコンストラクタ

  // 購入処理中フラグ（二重実行防止）
  static bool _isPurchasing = false;

  // LoggingServiceのゲッター
  static LoggingService get _logger => serviceLocator.get<LoggingService>();

  /// プレミアムプラン選択ダイアログを表示
  static Future<void> showUpgradeDialog(BuildContext context) async {
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
      _logger.debug(
        'プラン選択ダイアログ表示開始',
        context: 'UpgradeDialogUtils.showUpgradeDialog',
      );
      await _showPremiumPlanDialog(context, premiumPlans);
      _logger.debug(
        'プラン選択ダイアログ完了',
        context: 'UpgradeDialogUtils.showUpgradeDialog',
      );
    } catch (e) {
      if (!context.mounted) return;
      DialogUtils.showSimpleDialog(context, 'エラーが発生しました: ${e.toString()}');
    }
  }

  /// プレミアムプラン選択ダイアログ
  static Future<void> _showPremiumPlanDialog(
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
                '月間100回のAI生成、過去1年の写真、全20種類のライティングプロンプトが利用できます。',
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

  /// プラン選択オプション
  static Widget _buildPlanOption(
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

            _logger.debug(
              'プランオプションタップ: ${plan.id}',
              context: 'UpgradeDialogUtils._buildPlanOption',
              data:
                  'displayName=${plan.displayName}, productId=${plan.productId}',
            );

            // シンプルなアプローチ：ダイアログを閉じてから購入処理
            Navigator.of(dialogContext).pop();

            // 少し待機してUI安定化
            await Future.delayed(const Duration(milliseconds: 200));

            // 購入処理を開始
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
                  plan.isMonthly
                      ? dialogContext.l10n.pricingPerMonthShort(
                          dialogContext.l10n.formatCurrency(plan.price),
                        )
                      : dialogContext.l10n.pricingPerYearShort(
                          dialogContext.l10n.formatCurrency(plan.price),
                        ),
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
  static Future<void> _startPurchaseWithoutContext(Plan plan) async {
    _logger.info(
      '購入処理開始: ${plan.id}',
      context: 'UpgradeDialogUtils._startPurchaseWithoutContext',
      data: 'productId=${plan.productId}, price=${plan.price}',
    );

    // 二重実行防止チェック
    if (_isPurchasing) {
      _logger.warning(
        '既に購入処理中のため中断',
        context: 'UpgradeDialogUtils._startPurchaseWithoutContext',
      );
      return;
    }

    _isPurchasing = true;

    try {
      _logger.debug(
        'ServiceLocatorからサブスクリプションサービス取得中',
        context: 'UpgradeDialogUtils._startPurchaseWithoutContext',
      );
      final subscriptionService = await ServiceLocator()
          .getAsync<ISubscriptionService>();

      _logger.debug(
        'purchasePlanClassメソッド呼び出し中',
        context: 'UpgradeDialogUtils._startPurchaseWithoutContext',
      );

      // Planクラスを使用した購入処理
      final result = await subscriptionService.purchasePlanClass(plan);

      _logger.debug(
        '購入処理レスポンス受信',
        context: 'UpgradeDialogUtils._startPurchaseWithoutContext',
        data: 'isSuccess: ${result.isSuccess}',
      );

      // 結果に応じた処理
      if (result.isSuccess) {
        final purchaseResult = result.value;
        _logger.info(
          '購入成功',
          context: 'UpgradeDialogUtils._startPurchaseWithoutContext',
          data:
              'status=${purchaseResult.status}, productId=${purchaseResult.productId}',
        );
      } else {
        final error = result.error;

        // シミュレーター環境での特別処理
        if (error.toString().contains('In-App Purchase not available') ||
            error.toString().contains('Product not found')) {
          _logger.warning(
            'シミュレーター環境またはTestFlight環境の可能性',
            context: 'UpgradeDialogUtils._startPurchaseWithoutContext',
            data: error.toString(),
          );
        } else {
          _logger.error(
            '購入失敗',
            context: 'UpgradeDialogUtils._startPurchaseWithoutContext',
            error: error,
          );
        }
      }
    } catch (e) {
      _logger.error(
        '予期しないエラー発生',
        context: 'UpgradeDialogUtils._startPurchaseWithoutContext',
        error: e,
      );

      // 基本的なエラー情報のみログ出力
      // SubscriptionService が適切にエラーハンドリングを行う
    } finally {
      _isPurchasing = false;
      _logger.debug(
        '購入処理完了、フラグをリセット',
        context: 'UpgradeDialogUtils._startPurchaseWithoutContext',
      );
    }
  }
}
