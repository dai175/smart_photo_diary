import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../localization/localization_extensions.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../ui/animations/list_animations.dart';

const _tonesBgLight = [Color(0xFFEEEAE3), Color(0xFFF2EAE2), Color(0xFFF4E1D2)];
const _tonesBgDark = [Color(0xFF2A2723), Color(0xFF2C2421), Color(0xFF2E211C)];

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
                delay: AppConstants.microStaggerUnit,
                child: _buildStatCard(
                  context,
                  l10n.statisticsTotalEntriesTitle,
                  '$totalEntries',
                  l10n.statisticsUnitDiary,
                  0,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SlideInWidget(
                delay: AppConstants.fastAnimationDuration,
                child: _buildStatCard(
                  context,
                  l10n.statisticsCurrentStreakTitle,
                  '$currentStreak',
                  l10n.statisticsUnitDay,
                  1,
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
                delay: AppConstants.quickAnimationDuration,
                child: _buildStatCard(
                  context,
                  l10n.statisticsLongestStreakTitle,
                  '$longestStreak',
                  l10n.statisticsUnitDay,
                  2,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SlideInWidget(
                delay: AppConstants.staggerDelayMedium,
                child: _buildStatCard(
                  context,
                  l10n.statisticsMonthlyCountTitle,
                  '$monthlyCount',
                  l10n.statisticsUnitDiary,
                  3,
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
    int index,
  ) {
    final theme = Theme.of(context);
    final tones = theme.brightness == Brightness.dark
        ? _tonesBgDark
        : _tonesBgLight;
    final muted = theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: tones[index % 3],
        borderRadius: AppSpacing.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTypography.sectionLabel.copyWith(color: muted),
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
                  style: AppTypography.statsDisplay.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                unit,
                style: AppTypography.sectionLabel.copyWith(color: muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
