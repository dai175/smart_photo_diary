import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../localization/localization_extensions.dart';
import '../../models/plans/plan.dart';
import '../../ui/components/custom_dialog.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import 'auto_renew_notice.dart';
import 'plan_option_card.dart';
import 'premium_bullet_list.dart';

class UpgradeDialog extends StatelessWidget {
  final List<Plan> plans;
  final Map<String, String> priceStrings;
  final void Function(Plan plan) onPlanSelected;

  const UpgradeDialog({
    super.key,
    required this.plans,
    required this.priceStrings,
    required this.onPlanSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomDialog(
      icon: Icons.stars_rounded,
      iconColor: AppColors.accent,
      title: context.l10n.upgradeDialogTitle,
      headerColor: isDark ? AppColors.premiumBgDark : AppColors.premiumBg,
      onClose: () => Navigator.of(context).pop(),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PremiumBulletList(),
            const SizedBox(height: AppSpacing.md),
            ...plans.map(
              (plan) => PlanOptionCard(
                plan: plan,
                priceString: priceStrings[plan.id],
                onTap: () async {
                  Navigator.of(context).pop();
                  await Future.delayed(AppConstants.quickAnimationDuration);
                  onPlanSelected(plan);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const AutoRenewNotice(),
          ],
        ),
      ),
    );
  }
}
