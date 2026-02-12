import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../localization/localization_extensions.dart';
import '../../ui/components/custom_card.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../ui/animations/list_animations.dart';

/// 統計カード群ウィジェット
class StatisticsCards extends StatelessWidget {
  const StatisticsCards({
    super.key,
    required this.totalEntries,
    required this.currentStreak,
    required this.longestStreak,
    required this.monthlyCount,
  });

  final int totalEntries;
  final int currentStreak;
  final int longestStreak;
  final int monthlyCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SlideInWidget(
                delay: const Duration(milliseconds: 100),
                child: _buildStatCard(
                  context,
                  l10n.statisticsTotalEntriesTitle,
                  '$totalEntries',
                  l10n.statisticsUnitDiary,
                  AppIcons.statisticsTotal,
                  AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SlideInWidget(
                delay: const Duration(milliseconds: 150),
                child: _buildStatCard(
                  context,
                  l10n.statisticsCurrentStreakTitle,
                  '$currentStreak',
                  l10n.statisticsUnitDay,
                  AppIcons.statisticsStreak,
                  AppColors.error,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: SlideInWidget(
                delay: const Duration(milliseconds: 200),
                child: _buildStatCard(
                  context,
                  l10n.statisticsLongestStreakTitle,
                  '$longestStreak',
                  l10n.statisticsUnitDay,
                  AppIcons.statisticsRecord,
                  AppColors.warning,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SlideInWidget(
                delay: const Duration(milliseconds: 250),
                child: _buildStatCard(
                  context,
                  l10n.statisticsMonthlyCountTitle,
                  '$monthlyCount',
                  l10n.statisticsUnitDiary,
                  AppIcons.statisticsMonth,
                  AppColors.success,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return CustomCard(
      elevation: AppSpacing.elevationSm,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Icon(icon, color: color, size: AppSpacing.iconSm),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.labelSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: AppTypography.headlineSmall.copyWith(
                          color: color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      unit,
                      style: AppTypography.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
