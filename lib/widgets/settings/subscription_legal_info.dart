import 'package:flutter/material.dart';
import '../../constants/subscription_constants.dart';
import '../../localization/localization_extensions.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../utils/dynamic_pricing_utils.dart';
import '../../utils/url_launcher_utils.dart';

/// サブスクリプションの法的情報セクション（プラン詳細・自動更新・リンク）
class SubscriptionLegalInfo extends StatelessWidget {
  const SubscriptionLegalInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.settingsSubscriptionInfoTitle,
            style: AppTypography.titleSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PlanDetailRow(
            title: context.l10n.settingsPremiumMonthlyTitle,
            planId: SubscriptionConstants.premiumMonthlyPlanId,
            formatter: (price) => context.l10n.pricingPerMonthShort(price),
            features: context.l10n.settingsPremiumPlanFeatures,
          ),
          const SizedBox(height: AppSpacing.xs),
          _PlanDetailRow(
            title: context.l10n.settingsPremiumYearlyTitle,
            planId: SubscriptionConstants.premiumYearlyPlanId,
            formatter: (price) => context.l10n.pricingPerYearShort(price),
            features: context.l10n.settingsPremiumPlanFeatures,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildAutoRenewNotice(context),
          const SizedBox(height: AppSpacing.md),
          _buildLegalLinks(context),
        ],
      ),
    );
  }

  Widget _buildAutoRenewNotice(BuildContext context) {
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

  Widget _buildLegalLinks(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LegalLinkButton(
            text: context.l10n.commonPrivacyPolicy,
            icon: Icons.privacy_tip_outlined,
            onPressed: () =>
                UrlLauncherUtils.launchPrivacyPolicy(context: context),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _LegalLinkButton(
            text: context.l10n.commonTermsOfUse,
            icon: Icons.article_outlined,
            onPressed: () =>
                UrlLauncherUtils.launchTermsOfUse(context: context),
          ),
        ),
      ],
    );
  }
}

/// プラン詳細の1行表示
class _PlanDetailRow extends StatelessWidget {
  final String title;
  final String planId;
  final String Function(String) formatter;
  final String features;

  const _PlanDetailRow({
    required this.title,
    required this.planId,
    required this.formatter,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  DynamicPriceText(
                    planId: planId,
                    locale: context.l10n.localeName,
                    formatter: formatter,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    loadingWidget: Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                features,
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 法的リンクボタン
class _LegalLinkButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const _LegalLinkButton({
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: AppSpacing.iconXs, color: AppColors.primary),
      label: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.xs),
        ),
      ),
    );
  }
}
