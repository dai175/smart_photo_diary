import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../constants/app_constants.dart';
import '../../constants/app_icons.dart';
import '../../localization/localization_extensions.dart';
import '../../models/diary_entry.dart';
import '../../ui/components/custom_card.dart';
import '../../ui/components/custom_dialog.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../ui/component_constants.dart';
import '../../ui/animations/list_animations.dart';
import '../diary_detail_screen.dart';
import 'statistics_calculator.dart';

/// 統計画面のカレンダーセクション
class StatisticsCalendar extends StatelessWidget {
  const StatisticsCalendar({
    super.key,
    required this.diaryMap,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.onHeaderTapped,
  });

  final Map<DateTime, List<DiaryEntry>> diaryMap;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final void Function(DateTime focusedDay) onPageChanged;
  final void Function(DateTime focusedDay) onHeaderTapped;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: focusedDay,
            calendarFormat: CalendarFormat.month,
            eventLoader: (day) =>
                StatisticsCalculator.getEventsForDay(diaryMap, day),
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            onDaySelected: onDaySelected,
            onPageChanged: onPageChanged,
            onHeaderTapped: onHeaderTapped,
            calendarStyle: CalendarStyle(
              defaultTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              weekendTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
              holidayTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
              outsideTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              cellMargin: const EdgeInsets.all(AppSpacing.xs),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
                  final eventCount = events.length;
                  return Positioned(
                    right: 4,
                    bottom: 4,
                    child: _buildMarker(context, eventCount),
                  );
                }
                return null;
              },
            ),
            headerStyle: HeaderStyle(
              titleCentered: true,
              titleTextStyle: AppTypography.titleLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              formatButtonVisible: false,
              leftChevronIcon: Icon(
                AppIcons.calendarPrev,
                color: Theme.of(context).colorScheme.primary,
              ),
              rightChevronIcon: Icon(
                AppIcons.calendarNext,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildMarker(BuildContext context, int count) {
    return Container(
      width: CalendarMarkerConstants.size,
      height: CalendarMarkerConstants.size,
      decoration: BoxDecoration(
        color: count > 1
            ? Theme.of(context).colorScheme.secondary.withValues(
                alpha: AppConstants.opacityHigh,
              )
            : Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: AppConstants.opacityHigh),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          count > 9 ? '9+' : count.toString(),
          style: AppTypography.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 日記選択ダイアログを表示
  static void showDiarySelectionDialog(
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
                final diary = diaries[index];
                final title = diary.title.isNotEmpty
                    ? diary.title
                    : l10n.diaryCardUntitled;

                return SlideInWidget(
                  delay: Duration(milliseconds: 100 * index),
                  child: Container(
                    margin: EdgeInsets.only(
                      bottom: index < diaries.length - 1 ? AppSpacing.sm : 0,
                    ),
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondary,
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xxs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: AppConstants.opacityXXLow,
                                    ),
                                    borderRadius: AppSpacing.chipRadius,
                                  ),
                                  child: Text(
                                    '${diary.date.hour.toString().padLeft(2, '0')}:${diary.date.minute.toString().padLeft(2, '0')}',
                                    style: AppTypography.labelSmall.copyWith(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.primaryLight
                                          : AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            size: AppSpacing.iconSm,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            CustomDialogAction(
              text: l10n.commonClose,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
