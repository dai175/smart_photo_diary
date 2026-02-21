import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_icons.dart';
import '../../localization/localization_extensions.dart';
import '../../models/subscription_info_v2.dart';
import '../../ui/animations/micro_interactions.dart';
import '../../ui/components/animated_button.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../utils/upgrade_dialog_utils.dart';

/// Subscription-related settings section.
///
/// Displays current plan status, usage statistics, warnings,
/// and upgrade button.
class SubscriptionSettingsSection extends StatefulWidget {
  final SubscriptionInfoV2? subscriptionInfo;
  final VoidCallback onStateChanged;

  const SubscriptionSettingsSection({
    super.key,
    required this.subscriptionInfo,
    required this.onStateChanged,
  });

  @override
  State<SubscriptionSettingsSection> createState() =>
      _SubscriptionSettingsSectionState();
}

class _SubscriptionSettingsSectionState
    extends State<SubscriptionSettingsSection> {
  bool _subscriptionExpanded = false;

  SubscriptionDisplayDataV2 _getLocalizedDisplayData() {
    return widget.subscriptionInfo!.getLocalizedDisplayData(
      locale: context.l10n.localeName,
      usageFormatter: (used, limit) =>
          context.l10n.usageStatusUsageValue(used, limit),
      remainingFormatter: (remaining) =>
          context.l10n.usageStatusRemainingValue(remaining),
      limitReachedFormatter: () =>
          context.l10n.subscriptionUsageWarningLimitReached,
      warningRemainingFormatter: (remaining) =>
          context.l10n.subscriptionUsageWarningRemaining(remaining),
      upgradeRecommendationLimitFormatter: (limit) =>
          context.l10n.subscriptionUpgradeRecommendationLimit(limit),
      upgradeRecommendationGeneralFormatter: () =>
          context.l10n.subscriptionUpgradeRecommendationGeneral,
      expiredText: context.l10n.subscriptionExpired,
      todayText: context.l10n.subscriptionResetToday,
      tomorrowText: context.l10n.subscriptionResetTomorrow,
      inactiveStatusText: context.l10n.subscriptionStatusInactive,
      expiryNearStatusText: context.l10n.subscriptionStatusExpiryNear,
      autoRenewalNotApplicableText:
          context.l10n.subscriptionAutoRenewalNotApplicable,
      autoRenewalEnabledText: context.l10n.subscriptionAutoRenewalEnabled,
      autoRenewalDisabledText: context.l10n.subscriptionAutoRenewalDisabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subscriptionInfo == null) {
      return _buildLoadingState(context);
    }

    return Column(
      children: [
        _buildHeader(context),
        if (_subscriptionExpanded) ...[
          _buildExpandedContent(context),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      child: Row(
        children: [
          Icon(
            Icons.card_membership_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: AppSpacing.iconMd,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.settingsSubscriptionSectionTitle,
                  style: AppTypography.titleMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  context.l10n.commonLoading,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final info = widget.subscriptionInfo!;
    final displayData = _getLocalizedDisplayData();

    return MicroInteractions.bounceOnTap(
      enableHaptic: true,
      onTap: () {
        setState(() {
          _subscriptionExpanded = !_subscriptionExpanded;
        });
      },
      child: Container(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            Icon(
              info.isPremium
                  ? Icons.star_rounded
                  : Icons.card_membership_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: AppSpacing.iconMd,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.settingsSubscriptionSectionTitle,
                    style: AppTypography.titleMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    displayData.planStatus != null
                        ? context.l10n.settingsCurrentPlanWithStatus(
                            displayData.planName,
                            displayData.planStatus!,
                          )
                        : context.l10n.settingsCurrentPlan(
                            displayData.planName,
                          ),
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: _subscriptionExpanded ? 0.25 : 0.0,
              duration: AppConstants.quickAnimationDuration,
              child: Icon(
                AppIcons.actionForward,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: AppSpacing.iconSm,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    final info = widget.subscriptionInfo!;
    final displayData = _getLocalizedDisplayData();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: AppSpacing.cardRadius,
      ),
      child: Column(
        children: [
          _buildSubscriptionItem(
            context.l10n.settingsSubscriptionUsageLabel,
            displayData.usageText,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSubscriptionItem(
            context.l10n.settingsSubscriptionRemainingLabel,
            displayData.remainingText,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSubscriptionItem(
            context.l10n.settingsSubscriptionResetLabel,
            displayData.resetDateText,
          ),
          if (displayData.expiryText != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildSubscriptionItem(
              context.l10n.settingsSubscriptionExpiryLabel,
              displayData.expiryText!,
            ),
          ],
          if (displayData.warningMessage != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildWarningMessage(displayData.warningMessage!),
          ],
          if (displayData.recommendationMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildRecommendationMessage(displayData.recommendationMessage!),
          ],
          if (!info.isPremium) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildUpgradeButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildSubscriptionItem(String label, String value) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.labelLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildWarningMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: AppSpacing.iconSm,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.info,
            size: AppSpacing.iconSm,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.info,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton() {
    return PrimaryButton(
      onPressed: () {
        _showUpgradeDialog();
      },
      text: context.l10n.settingsUpgradeToPremium,
      width: double.infinity,
    );
  }

  Future<void> _showUpgradeDialog() async {
    await UpgradeDialogUtils.showUpgradeDialog(context);
    if (!mounted) return;
    widget.onStateChanged();
  }
}
