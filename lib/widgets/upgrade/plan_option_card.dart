import 'package:flutter/material.dart';

import '../../constants/subscription_constants.dart';
import '../../localization/localization_extensions.dart';
import '../../models/plans/plan.dart';
import '../../models/plans/premium_yearly_plan.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../ui/components/custom_card.dart';

/// プラン選択オプションカード Widget
class PlanOptionCard extends StatelessWidget {
  final Plan plan;
  final String? priceString;
  final VoidCallback onTap;

  const PlanOptionCard({
    super.key,
    required this.plan,
    this.priceString,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final description = switch (plan) {
      PremiumYearlyPlan(discountPercentage: final discount) when discount > 0 =>
        context.l10n.upgradeDialogDiscountValue(discount),
      _ => '',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: CustomCard(
        child: InkWell(
          onTap: onTap,
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
                        _getLocalizedPlanName(context),
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
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildPriceDisplay(context),
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

  String _getLocalizedPlanName(BuildContext context) {
    if (plan.isMonthly) {
      return context.l10n.settingsPremiumMonthlyTitle;
    } else if (plan.isYearly) {
      return context.l10n.settingsPremiumYearlyTitle;
    } else {
      return plan.displayName;
    }
  }

  Widget _buildPriceDisplay(BuildContext context) {
    final price =
        priceString ??
        SubscriptionConstants.formatPriceForPlan(
          plan.id,
          context.l10n.localeName,
        );
    final priceText = plan.isMonthly
        ? context.l10n.pricingPerMonthShort(price)
        : context.l10n.pricingPerYearShort(price);

    return Text(
      priceText,
      style: AppTypography.titleMedium.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }
}
