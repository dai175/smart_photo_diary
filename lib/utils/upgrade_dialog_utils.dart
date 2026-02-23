import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../services/interfaces/logging_service_interface.dart';
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
import '../localization/localization_extensions.dart';
import '../constants/subscription_constants.dart';
import 'dynamic_pricing_utils.dart';

/// アップグレードダイアログのユーティリティクラス
///
/// ホーム画面と設定画面で共通のアップグレード機能を提供
class UpgradeDialogUtils {
  UpgradeDialogUtils._(); // プライベートコンストラクタ

  // 購入処理中フラグ（二重実行防止）
  static bool _isPurchasing = false;

  // LoggingServiceのゲッター
  static ILoggingService get _logger => serviceLocator.get<ILoggingService>();

  /// プランの多言語化対応名称を取得
  static String _getLocalizedPlanName(BuildContext context, Plan plan) {
    if (plan.isMonthly) {
      return context.l10n.settingsPremiumMonthlyTitle;
    } else if (plan.isYearly) {
      return context.l10n.settingsPremiumYearlyTitle;
    } else {
      // BasicPlanなど、予期しないケース
      return plan.displayName;
    }
  }

  /// プレミアムプラン選択ダイアログを表示
  static Future<void> showUpgradeDialog(BuildContext context) async {
    try {
      // 有料プランを取得
      final premiumPlans = PlanFactory.getPremiumPlans();

      if (premiumPlans.isEmpty) {
        if (!context.mounted) return;
        DialogUtils.showSimpleDialog(
          context,
          context.l10n.upgradeDialogUnavailableMessage,
        );
        return;
      }

      // ローディング表示用のコントローラー
      OverlayEntry? loadingOverlay;

      try {
        // 価格取得中のローディング表示
        if (context.mounted) {
          loadingOverlay = _showLoadingOverlay(context);
        }

        // 共通ユーティリティを使用して複数プランの価格を取得
        final planIds = premiumPlans.map((plan) => plan.id).toList();
        final priceStrings = await DynamicPricingUtils.getMultiplePlanPrices(
          planIds,
          locale: context.l10n.localeName,
        );

        _logger.debug(
          'Fetched multiple plan prices via DynamicPricingUtils',
          context: 'UpgradeDialogUtils.showUpgradeDialog',
          data: 'prices=${priceStrings.toString()}',
        );

        // ローディング非表示
        loadingOverlay?.remove();
        loadingOverlay = null;

        // プレミアムプラン選択ダイアログを表示
        if (!context.mounted) return;
        _logger.debug(
          'Opening plan selection dialog with dynamic pricing',
          context: 'UpgradeDialogUtils.showUpgradeDialog',
        );
        await _showPremiumPlanDialog(context, premiumPlans, priceStrings);
        _logger.debug(
          'Plan selection dialog completed',
          context: 'UpgradeDialogUtils.showUpgradeDialog',
        );
      } finally {
        // 確実にローディングを非表示
        loadingOverlay?.remove();
      }
    } catch (e) {
      if (!context.mounted) return;
      DialogUtils.showSimpleDialog(
        context,
        context.l10n.commonUnexpectedErrorWithDetails(e.toString()),
      );
    }
  }

  /// プレミアムプラン選択ダイアログ
  static Future<void> _showPremiumPlanDialog(
    BuildContext parentContext,
    List<Plan> plans,
    Map<String, String> priceStrings,
  ) async {
    return showDialog(
      context: parentContext,
      builder: (dialogContext) => CustomDialog(
        title: dialogContext.l10n.upgradeDialogTitle,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPremiumBulletList(dialogContext),
              const SizedBox(height: AppSpacing.md),
              ...plans.map(
                (plan) => _buildPlanOption(
                  dialogContext,
                  parentContext,
                  plan,
                  priceStrings[plan.id],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildAutoRenewNotice(dialogContext),
            ],
          ),
        ),
        actions: [
          CustomDialogAction(
            text: dialogContext.l10n.commonCancel,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }

  /// Premium特典の箇条書きリスト
  static Widget _buildPremiumBulletList(BuildContext context) {
    final bullets = [
      context.l10n.premiumBulletPhotos,
      context.l10n.premiumBulletStories,
      context.l10n.premiumBulletStyles,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: bullets
          .map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      text,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  /// プラン選択オプション
  static Widget _buildPlanOption(
    BuildContext dialogContext,
    BuildContext parentContext,
    Plan plan,
    String? priceString,
  ) {
    // 割引情報の取得や表示価格の計算
    String description = '';
    if (plan is PremiumYearlyPlan) {
      final discount = plan.discountPercentage;
      if (discount > 0) {
        description = dialogContext.l10n.upgradeDialogDiscountValue(discount);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: CustomCard(
        child: InkWell(
          onTap: () async {
            _logger.debug(
              'Plan option tapped: ${plan.id}',
              context: 'UpgradeDialogUtils._buildPlanOption',
              data:
                  'displayName=${plan.displayName}, productId=${plan.productId}',
            );

            // シンプルなアプローチ：ダイアログを閉じてから購入処理
            Navigator.of(dialogContext).pop();

            // 少し待機してUI安定化
            await Future.delayed(AppConstants.quickAnimationDuration);

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
                        _getLocalizedPlanName(dialogContext, plan),
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
                _buildPriceDisplay(dialogContext, plan, priceString),
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

  /// 自動更新に関する注意事項（Apple ガイドライン 3.1.2 準拠）
  static Widget _buildAutoRenewNotice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: AppSpacing.iconXs,
                color: AppColors.info,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                context.l10n.settingsSubscriptionAutoRenewTitle,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.settingsSubscriptionAutoRenewDescription,
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// ローディングオーバーレイを表示
  static OverlayEntry _showLoadingOverlay(BuildContext context) {
    final loadingText = context.l10n.loadingPrices;
    final overlay = OverlayEntry(
      builder: (overlayContext) => Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(overlayContext).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.md),
                Text(loadingText, style: AppTypography.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlay);
    return overlay;
  }

  /// 価格表示ウィジェット（共通ユーティリティ対応）
  static Widget _buildPriceDisplay(
    BuildContext context,
    Plan plan,
    String? priceString,
  ) {
    // 動的価格またはフォールバック価格を解決
    final price =
        priceString ??
        SubscriptionConstants.formatPriceForPlan(
          plan.id,
          context.l10n.localeName,
        );
    final priceText = plan.isMonthly
        ? context.l10n.pricingPerMonthShort(price)
        : context.l10n.pricingPerYearShort(price);

    _logger.debug(
      priceString != null
          ? 'Using dynamic price from DynamicPricingUtils for ${plan.id}'
          : 'Using fallback price for ${plan.id}',
      context: 'UpgradeDialogUtils._buildPriceDisplay',
      data: 'price_text=$priceText',
    );

    return Text(
      priceText,
      style: AppTypography.titleMedium.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }

  /// コンテキスト不要のシンプルな購入処理
  static Future<void> _startPurchaseWithoutContext(Plan plan) async {
    _logger.info(
      'Purchase flow started: ${plan.id}',
      context: 'UpgradeDialogUtils._startPurchaseWithoutContext',
      data: 'productId=${plan.productId}, price=${plan.price}',
    );

    // 二重実行防止チェック
    if (_isPurchasing) {
      _logger.warning(
        'Purchase already in progress; skipping',
        context: 'UpgradeDialogUtils._startPurchaseWithoutContext',
      );
      return;
    }

    _isPurchasing = true;

    try {
      _logger.debug(
        'Resolving subscription service via ServiceLocator',
        context: 'UpgradeDialogUtils._startPurchaseWithoutContext',
      );
      final subscriptionService = await serviceLocator
          .getAsync<ISubscriptionService>();

      _logger.debug(
        'Calling purchasePlanClass method',
        context: 'UpgradeDialogUtils._startPurchaseWithoutContext',
      );

      // Planクラスを使用した購入処理
      final result = await subscriptionService.purchasePlanClass(plan);

      _logger.debug(
        'Received purchase response',
        context: 'UpgradeDialogUtils._startPurchaseWithoutContext',
        data: 'isSuccess: ${result.isSuccess}',
      );

      // 結果に応じた処理
      if (result.isSuccess) {
        final purchaseResult = result.value;
        _logger.info(
          'Purchase succeeded',
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
            'Possibly simulator or TestFlight environment',
            context: 'UpgradeDialogUtils._startPurchaseWithoutContext',
            data: error.toString(),
          );
        } else {
          _logger.error(
            'Purchase failed',
            context: 'UpgradeDialogUtils._startPurchaseWithoutContext',
            error: error,
          );
        }
      }
    } catch (e) {
      _logger.error(
        'Unexpected error occurred',
        context: 'UpgradeDialogUtils._startPurchaseWithoutContext',
        error: e,
      );

      // 基本的なエラー情報のみログ出力
      // SubscriptionService が適切にエラーハンドリングを行う
    } finally {
      _isPurchasing = false;
      _logger.debug(
        'Purchase flow finished, resetting flag',
        context: 'UpgradeDialogUtils._startPurchaseWithoutContext',
      );
    }
  }
}
