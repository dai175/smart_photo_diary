import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
              selectedDecoration: const BoxDecoration(
                color: AppColors.calSelected,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.calToday,
                  width: CalendarMarkerConstants.todayBorderWidth,
                ),
              ),
              todayTextStyle: const TextStyle(
                color: AppColors.calToday,
                fontWeight: FontWeight.w600,
              ),
              cellMargin: const EdgeInsets.all(AppSpacing.xs),
            ),
            calendarBuilders: CalendarBuilders(
              headerTitleBuilder: (context, day) {
                final theme = Theme.of(context);
                final locale = Localizations.localeOf(context).languageCode;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${day.year}',
                      style: AppTypography.sectionLabel.copyWith(
                        color: AppColors.accentMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      DateFormat.MMMM(locale).format(day),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                );
              },
              defaultBuilder: (context, day, focusedDay) {
                final normalizedDay = DateTime(day.year, day.month, day.day);
                if (!diaryMap.containsKey(normalizedDay)) return null;
                return Container(
                  margin: const EdgeInsets.all(AppSpacing.xxs),
                  decoration: const BoxDecoration(
                    color: AppColors.calEntryBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              },
              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    right: AppSpacing.xs,
                    bottom: AppSpacing.xs,
                    child: _buildMarker(events.length),
                  );
                }
                return null;
              },
            ),
            headerStyle: HeaderStyle(
              titleCentered: true,
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
          _buildLegend(context),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildMarker(int count) {
    if (count == 1) {
      return Container(
        width: CalendarMarkerConstants.dotSize,
        height: CalendarMarkerConstants.dotSize,
        decoration: const BoxDecoration(
          color: AppColors.calDot,
          shape: BoxShape.circle,
        ),
      );
    }
    return Container(
      width: CalendarMarkerConstants.size,
      height: CalendarMarkerConstants.size,
      decoration: const BoxDecoration(
        color: AppColors.calCountBg,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          count > 9 ? '9+' : count.toString(),
          style: const TextStyle(
            color: AppColors.calCountFg,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          _buildLegendItem(
            _buildLegendCircle(color: AppColors.calEntryBg),
            l10n.statisticsCalendarLegendEntry,
          ),
          _buildLegendItem(
            _buildLegendBadge(),
            l10n.statisticsCalendarLegendMultiple,
          ),
          _buildLegendItem(
            _buildLegendRing(),
            l10n.statisticsCalendarLegendToday,
          ),
          _buildLegendItem(
            _buildLegendCircle(color: AppColors.calSelected),
            l10n.statisticsCalendarLegendSelected,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Widget indicator, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        const SizedBox(width: AppSpacing.xs),
        Text(
          label.toUpperCase(),
          style: AppTypography.sectionLabel.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildLegendCircle({required Color color, Widget? child}) {
    return Container(
      width: CalendarMarkerConstants.legendIndicatorSize,
      height: CalendarMarkerConstants.legendIndicatorSize,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: child,
    );
  }

  Widget _buildLegendBadge() {
    return _buildLegendCircle(
      color: AppColors.calCountBg,
      child: const Center(
        child: Text(
          '2',
          style: TextStyle(
            color: AppColors.calCountFg,
            fontSize: 6,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendRing() {
    return Container(
      width: CalendarMarkerConstants.legendIndicatorSize,
      height: CalendarMarkerConstants.legendIndicatorSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.calToday,
          width: CalendarMarkerConstants.todayBorderWidth,
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
                                    color: AppColors.accent.withValues(
                                      alpha: AppConstants.opacityXXLow,
                                    ),
                                    borderRadius: AppSpacing.chipRadius,
                                  ),
                                  child: Text(
                                    l10n.formatTime(diary.date),
                                    style: AppTypography.labelSmall.copyWith(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
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
          onClose: () => Navigator.of(context).pop(),
        );
      },
    );
  }
}
