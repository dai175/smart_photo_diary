import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../localization/localization_extensions.dart';
import '../../models/plans/plan.dart';
import '../../ui/component_constants.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../ui/animations/micro_interactions.dart';
import 'premium_bullet_list.dart';
import 'plan_option_card.dart';
import 'auto_renew_notice.dart';

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
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: MicroInteractions.scaleTransition(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(ModalConstants.radius),
            boxShadow: ModalConstants.shadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ModalConstants.radius),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPremiumHeader(context),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      0,
                    ),
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
                              await Future.delayed(
                                AppConstants.quickAnimationDuration,
                              );
                              onPlanSelected(plan);
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const AutoRenewNotice(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.premiumBgDark : AppColors.premiumBg;
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          color: bgColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: ModalConstants.iconSize,
                height: ModalConstants.iconSize,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(
                    ModalConstants.iconRadius,
                  ),
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  size: AppSpacing.iconMd,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l10n.upgradeDialogTitle,
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: AppSpacing.sm,
          right: AppSpacing.sm,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: MaterialLocalizations.of(context).closeButtonLabel,
            icon: Icon(
              Icons.close,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}
