import 'package:flutter/material.dart';

import '../../../constants/subscription_constants.dart';
import '../../../localization/localization_extensions.dart';
import '../../../ui/design_system/app_colors.dart';
import '../../../ui/design_system/app_spacing.dart';
import '../../../ui/design_system/app_typography.dart';
import '../components/onboarding_plan_card.dart';
import '../components/onboarding_dynamic_plan_card.dart';

/// オンボーディング: プラン紹介ページ
class OnboardingPlansPage extends StatelessWidget {
  const OnboardingPlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: isPortrait
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: _buildContent(context),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context) {
    final l10n = context.l10n;

    return [
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.workspace_premium_rounded,
          size: 50,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: AppSpacing.xl),

      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          l10n.onboardingPlansTitle,
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: AppSpacing.xl),

      // Basicプラン
      OnboardingPlanCard(
        title: 'Basic',
        subtitle: l10n.onboardingPlanBasicSubtitle,
        icon: Icons.photo_rounded,
        color: AppColors.secondary,
        features: [
          l10n.onboardingPlanFeatureMonthlyLimit(
            SubscriptionConstants.basicMonthlyAiLimit,
          ),
          l10n.onboardingPlanFeatureRecentPhotos,
          l10n.onboardingPlanFeatureBasicPrompts,
        ],
      ),
      const SizedBox(height: AppSpacing.md),

      // Premiumプラン（動的価格対応）
      OnboardingDynamicPlanCard(
        title: 'Premium',
        planId: SubscriptionConstants.premiumMonthlyPlanId,
        formatter: (price) => context.l10n.pricingPerMonthShort(price),
        icon: Icons.star_rounded,
        color: AppColors.primary,
        features: [
          l10n.onboardingPlanFeatureMonthlyLimit(
            SubscriptionConstants.premiumMonthlyAiLimit,
          ),
          l10n.onboardingPlanFeaturePastDays(
            SubscriptionConstants.subscriptionYearDays,
          ),
          l10n.onboardingPlanFeatureRichPrompts,
        ],
      ),
      const SizedBox(height: AppSpacing.md),

      Text(
        l10n.onboardingPlanStartFree,
        style: AppTypography.titleMedium.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    ];
  }
}
