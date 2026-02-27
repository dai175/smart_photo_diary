import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../localization/localization_extensions.dart';
import '../../models/plans/plan.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/components/custom_dialog.dart';
import 'premium_bullet_list.dart';
import 'plan_option_card.dart';
import 'auto_renew_notice.dart';

/// プレミアムプラン選択ダイアログ Widget
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
    return CustomDialog(
      title: context.l10n.upgradeDialogTitle,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
      actions: [
        CustomDialogAction(
          text: context.l10n.commonCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
