import '../../models/diary_entry.dart';

/// 統計データの計算結果
class StatisticsData {
  final int totalEntries;
  final int currentStreak;
  final int longestStreak;
  final int monthlyCount;
  final Map<DateTime, List<DiaryEntry>> diaryMap;
  final int? previousMonthlyCount;
  final int? previousCompletedStreak;

  const StatisticsData({
    required this.totalEntries,
    required this.currentStreak,
    required this.longestStreak,
    required this.monthlyCount,
    required this.diaryMap,
    this.previousMonthlyCount,
    this.previousCompletedStreak,
  });
}

/// 統計計算ロジック（純粋関数）
class StatisticsCalculator {
  const StatisticsCalculator._();

  /// 全日記エントリーから統計データを算出
  static StatisticsData calculate(List<DiaryEntry> allDiaries) {
    final diaryMap = _buildDiaryMap(allDiaries);
    final streaks = _calculateStreaks(diaryMap);
    final (monthlyCount, previousMonthlyCount) = _getMonthlyAndPreviousCount(
      allDiaries,
    );

    return StatisticsData(
      totalEntries: allDiaries.length,
      currentStreak: streaks.$1,
      longestStreak: streaks.$2,
      monthlyCount: monthlyCount,
      diaryMap: diaryMap,
      previousMonthlyCount: previousMonthlyCount,
      previousCompletedStreak: _getPreviousCompletedStreak(
        diaryMap,
        streaks.$1,
      ),
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

  /// 今月・先月の記録日数を1パスで計算。戻り値は (currentMonth, previousMonth)
  static (int, int) _getMonthlyAndPreviousCount(List<DiaryEntry> allDiaries) {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month);
    final nextMonthStart = DateTime(now.year, now.month + 1);
    final prevMonthStart = DateTime(now.year, now.month - 1);

    final currentDates = <DateTime>{};
    final previousDates = <DateTime>{};
    for (final diary in allDiaries) {
      final d = DateTime(diary.date.year, diary.date.month, diary.date.day);
      if (!d.isBefore(currentMonthStart) && d.isBefore(nextMonthStart)) {
        currentDates.add(d);
      } else if (!d.isBefore(prevMonthStart) && d.isBefore(currentMonthStart)) {
        previousDates.add(d);
      }
    }
    return (currentDates.length, previousDates.length);
  }

  /// 現在ストリークの直前にあった完了ストリークの日数を返す（存在しない場合は null）
  static int? _getPreviousCompletedStreak(
    Map<DateTime, List<DiaryEntry>> diaryMap,
    int currentStreak,
  ) {
    if (diaryMap.isEmpty) return null;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final earliest = diaryMap.keys.reduce((a, b) => a.isBefore(b) ? a : b);

    // Skip past the current streak, then skip any gap days
    DateTime check = todayDate.subtract(Duration(days: currentStreak + 1));
    while (!diaryMap.containsKey(check) && !check.isBefore(earliest)) {
      check = check.subtract(const Duration(days: 1));
    }
    if (!diaryMap.containsKey(check)) return null;

    int prev = 0;
    while (diaryMap.containsKey(check)) {
      prev++;
      check = check.subtract(const Duration(days: 1));
    }
    return prev;
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
