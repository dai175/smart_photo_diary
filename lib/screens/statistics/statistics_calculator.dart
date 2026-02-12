import '../../models/diary_entry.dart';

/// 統計データの計算結果
class StatisticsData {
  final int totalEntries;
  final int currentStreak;
  final int longestStreak;
  final int monthlyCount;
  final Map<DateTime, List<DiaryEntry>> diaryMap;

  const StatisticsData({
    required this.totalEntries,
    required this.currentStreak,
    required this.longestStreak,
    required this.monthlyCount,
    required this.diaryMap,
  });
}

/// 統計計算ロジック（純粋関数）
class StatisticsCalculator {
  const StatisticsCalculator._();

  /// 全日記エントリーから統計データを算出
  static StatisticsData calculate(List<DiaryEntry> allDiaries) {
    final diaryMap = _buildDiaryMap(allDiaries);
    final streaks = _calculateStreaks(diaryMap);
    final monthlyCount = _getMonthlyCount(allDiaries);

    return StatisticsData(
      totalEntries: allDiaries.length,
      currentStreak: streaks.$1,
      longestStreak: streaks.$2,
      monthlyCount: monthlyCount,
      diaryMap: diaryMap,
    );
  }

  static Map<DateTime, List<DiaryEntry>> _buildDiaryMap(
    List<DiaryEntry> allDiaries,
  ) {
    final diaryMap = <DateTime, List<DiaryEntry>>{};
    for (final diary in allDiaries) {
      final date = DateTime(diary.date.year, diary.date.month, diary.date.day);
      if (diaryMap[date] == null) {
        diaryMap[date] = [];
      }
      diaryMap[date]!.add(diary);
    }
    return diaryMap;
  }

  /// 連続記録を計算。戻り値は (currentStreak, longestStreak)
  static (int, int) _calculateStreaks(
    Map<DateTime, List<DiaryEntry>> diaryMap,
  ) {
    if (diaryMap.isEmpty) return (0, 0);

    final sortedDates = diaryMap.keys.toList()..sort((a, b) => b.compareTo(a));

    // 現在の連続記録日数
    int currentStreak = 0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    DateTime checkDate = todayDate;
    while (diaryMap.containsKey(checkDate)) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // 最長連続記録日数
    int longestStreak = 0;
    int currentCount = 0;
    DateTime? previousDate;
    for (final date in sortedDates.reversed) {
      if (previousDate == null || date.difference(previousDate).inDays == 1) {
        currentCount++;
        longestStreak = longestStreak > currentCount
            ? longestStreak
            : currentCount;
      } else {
        currentCount = 1;
      }
      previousDate = date;
    }

    return (currentStreak, longestStreak);
  }

  /// 今月の記録日数を計算
  static int _getMonthlyCount(List<DiaryEntry> allDiaries) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);

    final monthlyDates = <DateTime>{};
    for (final diary in allDiaries) {
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

  /// 特定日のイベントを取得
  static List<DiaryEntry> getEventsForDay(
    Map<DateTime, List<DiaryEntry>> diaryMap,
    DateTime day,
  ) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return diaryMap[normalizedDay] ?? [];
  }
}
