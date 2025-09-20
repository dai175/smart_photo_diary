import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/custom_card.dart';
import '../ui/components/loading_shimmer.dart';
import '../localization/localization_extensions.dart';

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
            padding: EdgeInsets.only(bottom: index < 2 ? AppSpacing.md : 0),
            child: const DiaryCardShimmer(),
          ),
        ),
      );
    }

    if (recentDiaries.isEmpty) {
      return Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: AppSpacing.cardRadius,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: AppSpacing.iconLg,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.diaryNoEntriesMessage,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          .map(
            (entry) => Padding(
              padding: EdgeInsets.only(
                bottom: entry.key < recentDiaries.length - 1
                    ? AppSpacing.md
                    : 0,
              ),
              child: _buildDiaryCard(context, entry.value),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDiaryCard(BuildContext context, DiaryEntry diary) {
    final title = diary.title.isNotEmpty
        ? diary.title
        : context.l10n.diaryCardUntitled;

    return CustomCard(
      onTap: () => onDiaryTap(diary.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildDateLabel(context, diary.date),
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
            _buildTags(context, diary.tags!),
          ],
        ],
      ),
    );
  }

  Widget _buildDateLabel(BuildContext context, DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: AppSpacing.chipRadius,
      ),
      child: Text(
        context.l10n.formatMonthDay(date),
        style: AppTypography.labelSmall.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
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

  Widget _buildTags(BuildContext context, List<String> tags) {
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
                color: Theme.of(
                  context,
                ).colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: AppSpacing.chipRadius,
              ),
              child: Text(
                tag,
                style: AppTypography.labelSmall.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
