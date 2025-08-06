import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/diary_service.dart';
import '../models/diary_entry.dart';
import 'diary_detail_screen.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/custom_card.dart';
import '../ui/components/custom_dialog.dart';
import '../ui/animations/list_animations.dart';
import '../ui/animations/micro_interactions.dart';
import '../constants/app_icons.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late DiaryService _diaryService;
  List<DiaryEntry> _allDiaries = [];
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 統計データ
  int _totalEntries = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  Map<DateTime, List<DiaryEntry>> _diaryMap = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _diaryService = await DiaryService.getInstance();
      _allDiaries = await _diaryService.getSortedDiaryEntries();

      _calculateStatistics();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('統計データの読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateStatistics() {
    _totalEntries = _allDiaries.length;

    // 日記データをマップに変換（日付をキーとして、複数日記対応）
    _diaryMap = {};
    for (final diary in _allDiaries) {
      final date = DateTime(diary.date.year, diary.date.month, diary.date.day);
      if (_diaryMap[date] == null) {
        _diaryMap[date] = [];
      }
      _diaryMap[date]!.add(diary);
    }

    // 連続記録日数を計算
    _calculateStreaks();
  }

  void _calculateStreaks() {
    if (_allDiaries.isEmpty) {
      _currentStreak = 0;
      _longestStreak = 0;
      return;
    }

    // 日付順にソート（降順）
    final sortedDates = _diaryMap.keys.toList()..sort((a, b) => b.compareTo(a));

    // 現在の連続記録日数を計算
    _currentStreak = 0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    DateTime checkDate = todayDate;
    while (_diaryMap.containsKey(checkDate)) {
      _currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // 最長連続記録日数を計算
    _longestStreak = 0;
    int currentCount = 0;
    DateTime? previousDate;

    for (final date in sortedDates.reversed) {
      if (previousDate == null || date.difference(previousDate).inDays == 1) {
        currentCount++;
        _longestStreak = _longestStreak > currentCount
            ? _longestStreak
            : currentCount;
      } else {
        currentCount = 1;
      }
      previousDate = date;
    }
  }

  List<DiaryEntry> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _diaryMap[normalizedDay] ?? [];
  }

  Widget _buildMarker(int count) {
    return Builder(
      builder: (context) => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: count > 1
              ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
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
      ),
    );
  }

  void _showDiarySelectionDialog(
    BuildContext context,
    List<DiaryEntry> diaries,
    DateTime selectedDay,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          icon: AppIcons.calendarToday,
          iconColor: Theme.of(context).colorScheme.primary,
          title: DateFormat('yyyy年MM月dd日').format(selectedDay),
          message: '${diaries.length}件の日記があります',
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300, maxWidth: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: diaries.length,
              itemBuilder: (context, index) {
                final diary = diaries[index];
                final title = diary.title.isNotEmpty ? diary.title : '無題';

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
                            width: 40,
                            height: 40,
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    borderRadius: AppSpacing.chipRadius,
                                  ),
                                  child: Text(
                                    '${diary.date.hour.toString().padLeft(2, '0')}:${diary.date.minute.toString().padLeft(2, '0')}',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
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
              text: '閉じる',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('統計'),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
      ),
      body: _isLoading
          ? Center(
              child: FadeInWidget(
                child: CustomCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: AppSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const CircularProgressIndicator(strokeWidth: 3),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        '統計データを読み込み中...',
                        style: AppTypography.titleLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'あなたの日記の記録を分析しています',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : MicroInteractions.pullToRefresh(
              onRefresh: _loadStatistics,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 統計カード群
                    FadeInWidget(child: _buildStatisticsCards()),
                    const SizedBox(height: AppSpacing.xl),

                    // カレンダーセクション
                    SlideInWidget(
                      delay: const Duration(milliseconds: 200),
                      child: _buildCalendarSection(),
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatisticsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SlideInWidget(
                delay: const Duration(milliseconds: 100),
                child: _buildStatCard(
                  '総記録数',
                  '$_totalEntries',
                  '日記',
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
                  '連続記録数',
                  '$_currentStreak',
                  '日',
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
                  '最長連続記録',
                  '$_longestStreak',
                  '日',
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
                  '今月の記録',
                  '${_getMonthlyCount()}',
                  '日記',
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
            child: Icon(icon, color: color, size: 20),
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

  Widget _buildCalendarSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            eventLoader: _getEventsForDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });

                // 選択した日に日記がある場合は選択ダイアログまたは直接遷移
                final diaries =
                    _diaryMap[DateTime(
                      selectedDay.year,
                      selectedDay.month,
                      selectedDay.day,
                    )];
                if (diaries != null && diaries.isNotEmpty) {
                  if (diaries.length == 1) {
                    // 1つの日記の場合は直接遷移
                    Navigator.push(
                      context,
                      DiaryDetailScreen(
                        diaryId: diaries.first.id,
                      ).customRoute(),
                    );
                  } else {
                    // 複数の日記がある場合は選択ダイアログを表示
                    _showDiarySelectionDialog(context, diaries, selectedDay);
                  }
                }
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            onHeaderTapped: (focusedDay) {
              // ヘッダータップで当月に遷移
              final now = DateTime.now();
              final currentMonth = DateTime(now.year, now.month, now.day);

              // 現在表示中の月と異なる場合のみ遷移
              if (focusedDay.year != currentMonth.year ||
                  focusedDay.month != currentMonth.month) {
                setState(() {
                  _focusedDay = currentMonth;
                  _selectedDay = null; // 選択をクリア
                });
              }
            },
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
              cellMargin: const EdgeInsets.all(4),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isNotEmpty) {
                  final eventCount = events.length;
                  return Positioned(
                    right: 4,
                    bottom: 4,
                    child: _buildMarker(eventCount),
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

  int _getMonthlyCount() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);

    // 今月記録した日数を計算（同じ日に複数の日記があっても1日としてカウント）
    final monthlyDates = <DateTime>{};
    for (final diary in _allDiaries) {
      if (diary.date.isAfter(currentMonth.subtract(const Duration(days: 1))) &&
          diary.date.isBefore(nextMonth)) {
        final date = DateTime(
          diary.date.year,
          diary.date.month,
          diary.date.day,
        );
        monthlyDates.add(date);
      }
    }

    return monthlyDates.length;
  }
}
