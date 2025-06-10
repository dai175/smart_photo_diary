import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/diary_service.dart';
import '../models/diary_entry.dart';
import 'diary_detail_screen.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/custom_card.dart';
import '../ui/animations/list_animations.dart';

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
  CalendarFormat _calendarFormat = CalendarFormat.month;

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
    final sortedDates = _diaryMap.keys.toList()
      ..sort((a, b) => b.compareTo(a));

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
      if (previousDate == null || 
          date.difference(previousDate).inDays == 1) {
        currentCount++;
        _longestStreak = _longestStreak > currentCount ? _longestStreak : currentCount;
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
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: count > 1 ? AppColors.error : AppColors.success,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (count > 1 ? AppColors.error : AppColors.success).withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          count > 9 ? '9+' : count.toString(),
          style: AppTypography.withColor(
            AppTypography.labelSmall,
            Colors.white,
          ),
        ),
      ),
    );
  }

  void _showDiarySelectionDialog(BuildContext context, List<DiaryEntry> diaries, DateTime selectedDay) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.cardRadiusLarge,
          ),
          child: Container(
            padding: AppSpacing.dialogPadding,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppSpacing.cardRadiusLarge,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ヘッダー
                Container(
                  padding: AppSpacing.cardPadding,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: AppSpacing.cardRadius,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.white,
                          size: AppSpacing.iconSm,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${selectedDay.month}月${selectedDay.day}日の日記',
                            style: AppTypography.withColor(
                              AppTypography.titleLarge,
                              AppColors.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            '${diaries.length}件の日記があります',
                            style: AppTypography.withColor(
                              AppTypography.bodyMedium,
                              AppColors.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // 日記リスト
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 300,
                    maxWidth: 400,
                  ),
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
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: AppTypography.withColor(
                                        AppTypography.labelLarge,
                                        Colors.white,
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
                                        style: AppTypography.titleMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        diary.content,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.withColor(
                                          AppTypography.bodySmall,
                                          AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: AppSpacing.xxs,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryContainer,
                                          borderRadius: AppSpacing.chipRadius,
                                        ),
                                        child: Text(
                                          '${diary.date.hour.toString().padLeft(2, '0')}:${diary.date.minute.toString().padLeft(2, '0')}',
                                          style: AppTypography.withColor(
                                            AppTypography.labelSmall,
                                            AppColors.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.onSurfaceVariant,
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
                
                const SizedBox(height: AppSpacing.lg),
                
                // アクションボタン
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.onSurfaceVariant,
                      ),
                      child: Text(
                        'キャンセル',
                        style: AppTypography.labelLarge,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            child: IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
              ),
              onPressed: _loadStatistics,
              tooltip: '統計を更新',
            ),
          ),
        ],
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
                          color: AppColors.primaryContainer.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const CircularProgressIndicator(strokeWidth: 3),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        '統計データを読み込み中...',
                        style: AppTypography.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'あなたの日記の記録を分析しています',
                        style: AppTypography.withColor(
                          AppTypography.bodyMedium,
                          AppColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 統計カード群
                  FadeInWidget(
                    child: _buildStatisticsCards(),
                  ),
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
    );
  }

  Widget _buildStatisticsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: AppSpacing.cardRadius,
            boxShadow: AppSpacing.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: AppSpacing.iconMd,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '記録の統計',
                    style: AppTypography.withColor(
                      AppTypography.headlineMedium,
                      AppColors.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'あなたの日記習慣を見てみよう',
                    style: AppTypography.withColor(
                      AppTypography.bodyMedium,
                      AppColors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: SlideInWidget(
                delay: const Duration(milliseconds: 100),
                child: _buildStatCard(
                  '総記録数',
                  '$_totalEntries',
                  '日記',
                  Icons.book_rounded,
                  AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SlideInWidget(
                delay: const Duration(milliseconds: 150),
                child: _buildStatCard(
                  '現在の連続記録',
                  '$_currentStreak',
                  '日',
                  Icons.local_fire_department_rounded,
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
                  Icons.emoji_events_rounded,
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
                  Icons.calendar_month_rounded,
                  AppColors.success,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String unit, IconData icon, Color color) {
    return CustomCard(
      elevation: AppSpacing.elevationSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: AppSpacing.iconMd,
                ),
              ),
              const Spacer(),
              // 小さなアクセント点
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTypography.withColor(
              AppTypography.labelMedium,
              AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: AppTypography.withColor(
                  AppTypography.displaySmall,
                  color,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  unit,
                  style: AppTypography.withColor(
                    AppTypography.labelSmall,
                    AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
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
          Row(
            children: [
              Icon(
                Icons.calendar_view_month_rounded,
                color: AppColors.primary,
                size: AppSpacing.iconMd,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '記録カレンダー',
                style: AppTypography.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: AppSpacing.cardRadius,
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
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
                  final diaries = _diaryMap[DateTime(selectedDay.year, selectedDay.month, selectedDay.day)];
                  if (diaries != null && diaries.isNotEmpty) {
                    if (diaries.length == 1) {
                      // 1つの日記の場合は直接遷移
                      Navigator.push(
                        context,
                        DiaryDetailScreen(diaryId: diaries.first.id).customRoute(),
                      );
                    } else {
                      // 複数の日記がある場合は選択ダイアログを表示
                      _showDiarySelectionDialog(context, diaries, selectedDay);
                    }
                  }
                }
              },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
              calendarStyle: CalendarStyle(
                weekendTextStyle: TextStyle(color: AppColors.primary),
                holidayTextStyle: TextStyle(color: AppColors.primary),
                selectedDecoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                markerDecoration: const BoxDecoration(
                  color: AppColors.success,
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
                titleTextStyle: AppTypography.headlineSmall,
                formatButtonDecoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppSpacing.buttonRadius,
                  boxShadow: AppSpacing.buttonShadow,
                ),
                formatButtonTextStyle: AppTypography.withColor(
                  AppTypography.labelMedium,
                  Colors.white,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.primary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                ),
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
        final date = DateTime(diary.date.year, diary.date.month, diary.date.day);
        monthlyDates.add(date);
      }
    }
    
    return monthlyDates.length;
  }
}