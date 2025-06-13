import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../models/diary_entry.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/custom_card.dart';
import '../ui/components/loading_shimmer.dart';

/// 最近の日記表示ウィジェット
class RecentDiariesWidget extends StatelessWidget {
  final List<DiaryEntry> recentDiaries;
  final bool isLoading;
  final Function(String) onDiaryTap;

  const RecentDiariesWidget({
    super.key,
    required this.recentDiaries,
    required this.isLoading,
    required this.onDiaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }


  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: EdgeInsets.only(
              bottom: index < 2 ? AppSpacing.md : 0,
            ),
            child: const DiaryCardShimmer(),
          ),
        ),
      );
    }

    if (recentDiaries.isEmpty) {
      return Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppSpacing.cardRadius,
          border: Border.all(
            color: AppColors.outline.withValues(alpha: 0.2),
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: AppSpacing.iconLg,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppConstants.noDiariesMessage,
              style: AppTypography.withColor(
                AppTypography.bodyMedium,
                AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: recentDiaries
          .asMap()
          .entries
          .map((entry) => Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key < recentDiaries.length - 1 ? AppSpacing.md : 0,
                ),
                child: _buildDiaryCard(context, entry.value),
              ))
          .toList(),
    );
  }

  Widget _buildDiaryCard(BuildContext context, DiaryEntry diary) {
    final title = diary.title.isNotEmpty ? diary.title : '無題';

    return CustomCard(
      onTap: () => onDiaryTap(diary.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildDateLabel(diary.date),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: AppSpacing.iconSm,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildTitle(context, title),
          const SizedBox(height: AppSpacing.xs),
          _buildDiaryContent(context, diary.content),
          if (diary.tags?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildTags(diary.tags!),
          ],
        ],
      ),
    );
  }

  Widget _buildDateLabel(DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: AppSpacing.chipRadius,
      ),
      child: Text(
        DateFormat('MM/dd').format(date),
        style: AppTypography.withColor(
          AppTypography.labelSmall,
          AppColors.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, String title) {
    return Text(
      title,
      style: AppTypography.titleMedium,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDiaryContent(BuildContext context, String content) {
    return Text(
      content,
      style: AppTypography.bodyMedium.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTags(List<String> tags) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: tags
          .take(3)
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: AppSpacing.chipRadius,
              ),
              child: Text(
                tag,
                style: AppTypography.withColor(
                  AppTypography.labelSmall,
                  AppColors.accent,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}