import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/diary_service.dart';
import '../models/diary_entry.dart';
import 'diary_detail_screen.dart';

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
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: count > 1 ? const Color(0xFFFF6B6B) : const Color(0xFF4ECDC4),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          count > 9 ? '9+' : count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showDiarySelectionDialog(BuildContext context, List<DiaryEntry> diaries, DateTime selectedDay) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '${selectedDay.month}月${selectedDay.day}日の日記',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: diaries.length,
              itemBuilder: (context, index) {
                final diary = diaries[index];
                final title = diary.title.isNotEmpty ? diary.title : '無題';
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          diary.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '作成時刻: ${diary.date.hour.toString().padLeft(2, '0')}:${diary.date.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).pop(); // ダイアログを閉じる
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DiaryDetailScreen(diaryId: diary.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
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
        title: const Text(
          '統計',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 統計カード群
                  _buildStatisticsCards(),
                  const SizedBox(height: 24),
                  
                  // カレンダーセクション
                  _buildCalendarSection(),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildStatisticsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '記録の統計',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '総記録数',
                '$_totalEntries',
                '日記',
                Icons.book,
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '現在の連続記録',
                '$_currentStreak',
                '日',
                Icons.local_fire_department,
                const Color(0xFFFF6B6B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '最長連続記録',
                '$_longestStreak',
                '日',
                Icons.emoji_events,
                const Color(0xFFFFB800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '今月の記録',
                '${_getMonthlyCount()}',
                '日記',
                Icons.calendar_month,
                const Color(0xFF4ECDC4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '記録カレンダー',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          TableCalendar(
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
                      MaterialPageRoute(
                        builder: (context) => DiaryDetailScreen(diaryId: diaries.first.id),
                      ),
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
              weekendTextStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
              holidayTextStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: const BoxDecoration(
                color: Color(0xFFFF6B6B),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Color(0xFF4ECDC4),
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
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
              formatButtonDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.all(Radius.circular(12.0)),
              ),
              formatButtonTextStyle: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
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