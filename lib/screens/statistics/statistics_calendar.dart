import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../constants/app_icons.dart';
import '../../models/diary_entry.dart';
import '../../ui/component_constants.dart';
import '../../ui/components/custom_card.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import 'calendar_day_cell.dart';
import 'calendar_legend.dart';
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
                final locale = Localizations.localeOf(context).toLanguageTag();
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
                return CalendarDayCell(day: day);
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
          const CalendarLegend(),
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
}
