import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../constants/app_icons.dart';
import '../../localization/localization_extensions.dart';
import '../../models/diary_entry.dart';
import '../../ui/animations/list_animations.dart';
import '../../ui/component_constants.dart';
import '../../ui/components/custom_card.dart';
import '../../ui/components/custom_dialog.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../diary_detail_screen.dart';

/// 選択日の日記一覧ダイアログを表示する
void showDiarySelectionDialog(
  BuildContext context,
  List<DiaryEntry> diaries,
  DateTime selectedDay,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      final l10n = context.l10n;
      return CustomDialog(
        icon: AppIcons.calendarToday,
        iconColor: Theme.of(context).colorScheme.primary,
        title: l10n.formatFullDate(selectedDay),
        message: l10n.statisticsDiaryCountMessage(diaries.length),
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: DialogConstants.listMaxHeight,
            maxWidth: DialogConstants.listMaxWidth,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: diaries.length,
            itemBuilder: (context, index) {
              return _DiaryListItem(
                diary: diaries[index],
                index: index,
                isLast: index == diaries.length - 1,
              );
            },
          ),
        ),
        onClose: () => Navigator.of(context).pop(),
      );
    },
  );
}

class _DiaryListItem extends StatelessWidget {
  const _DiaryListItem({
    required this.diary,
    required this.index,
    required this.isLast,
  });

  final DiaryEntry diary;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = diary.title.isNotEmpty ? diary.title : l10n.diaryCardUntitled;

    return SlideInWidget(
      delay: Duration(milliseconds: 100 * index),
      child: Container(
        margin: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
        child: CustomCard(
          onTap: () {
            Navigator.of(context).pop();
            Navigator.push(
              context,
              DiaryDetailScreen(diaryId: diary.id).customRoute(),
            );
          },
          child: Row(
            children: [
              Container(
                width: TileConstants.sizeMd,
                height: TileConstants.sizeMd,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: AppTypography.labelLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      diary.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(
                          alpha: AppConstants.opacityXXLow,
                        ),
                        borderRadius: AppSpacing.chipRadius,
                      ),
                      child: Text(
                        l10n.formatTime(diary.date),
                        style: AppTypography.labelSmall.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.accentLight
                              : AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: AppSpacing.iconSm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
