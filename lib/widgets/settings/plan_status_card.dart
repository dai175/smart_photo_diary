import 'package:flutter/material.dart';
import '../../localization/localization_extensions.dart';
import '../../models/subscription_info_v2.dart';
import '../../ui/component_constants.dart';
import '../../ui/components/animated_button.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../ui/components/modern_chip.dart';

class PlanStatusCard extends StatelessWidget {
  final SubscriptionInfoV2? info;
  final VoidCallback onUpgradePressed;

  const PlanStatusCard({
    super.key,
    required this.info,
    required this.onUpgradePressed,
  });

  static const _cardPadding = EdgeInsets.all(18);
  static const _usageWarningThreshold = 0.85;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardRadius = BorderRadius.circular(CardConstants.radiusHero);
    final info = this.info;

    if (info == null) {
      return Container(
        padding: _cardPadding,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: cardRadius,
        ),
        child: Text(
          context.l10n.settingsSubscriptionSectionTitle,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final isDark = theme.brightness == Brightness.dark;
    final stats = info.usageStats;
    final isPremium = info.isPremium;
    final planName = info.getLocalizedPlanDisplayName(context.l10n.localeName);
    final usageRate = stats.usageRate.clamp(0.0, 1.0);
    final resetDate = context.l10n.formatMonthDayLong(stats.nextResetDate);
    final expiryDate = info.periodInfo.expiryDate != null
        ? context.l10n.formatMonthDayLong(info.periodInfo.expiryDate!)
        : null;

    final cardBgColor = isDark
        ? AppColors.premiumBgDark
        : (isPremium ? AppColors.premiumBg : AppColors.cardBg);
    final barColor = usageRate > _usageWarningThreshold
        ? colorScheme.error
        : AppColors.calSelected;

    return Container(
      padding: _cardPadding,
      decoration: BoxDecoration(color: cardBgColor, borderRadius: cardRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModernChip(
            label: planName,
            size: ChipSize.medium,
            backgroundColor: isPremium
                ? (isDark ? AppColors.tagPrimaryBg : colorScheme.surface)
                : AppColors.tagPrimaryBg,
            foregroundColor: isPremium
                ? AppColors.tagAccentFg
                : AppColors.tagPrimaryFg,
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.planCardThisMonth.toUpperCase(),
            style: AppTypography.sectionLabel.copyWith(
              color: AppColors.accentMuted,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${stats.monthlyUsageCount}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  height: 1.0,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '/ ${stats.monthlyLimit} ${context.l10n.planCardDiaryUnit}',
                style: const TextStyle(fontSize: 16, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n.planCardRemainingAndReset(
              stats.remainingCount,
              resetDate,
            ),
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: usageRate,
            minHeight: 6,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusXs),
            backgroundColor: colorScheme.outlineVariant,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
          const SizedBox(height: 14),
          if (!isPremium)
            PrimaryButton(
              onPressed: onUpgradePressed,
              width: double.infinity,
              text: context.l10n.settingsUpgradeToPremium,
            )
          else if (expiryDate != null)
            Text(
              context.l10n.planCardAutoRenews(expiryDate),
              style: AppTypography.caption.copyWith(color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}
