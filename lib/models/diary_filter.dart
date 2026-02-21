import 'package:flutter/material.dart';
import 'diary_entry.dart';

/// 時間帯の区分
enum TimeOfDayPeriod {
  morning, // 5:00-11:59
  noon, // 12:00-17:59
  evening, // 18:00-21:59
  night; // 22:00-4:59

  /// 時刻から対応する時間帯を判定
  static TimeOfDayPeriod fromHour(int hour) {
    if (hour >= 5 && hour < 12) return morning;
    if (hour >= 12 && hour < 18) return noon;
    if (hour >= 18 && hour < 22) return evening;
    return night;
  }
}

class DiaryFilter {
  final DateTimeRange? dateRange;
  final Set<String> selectedTags;
  final Set<TimeOfDayPeriod> timeOfDay;
  final String? searchText;

  const DiaryFilter({
    this.dateRange,
    this.selectedTags = const {},
    this.timeOfDay = const {},
    this.searchText,
  });

  bool get isActive {
    return dateRange != null ||
        selectedTags.isNotEmpty ||
        timeOfDay.isNotEmpty ||
        (searchText != null && searchText!.isNotEmpty);
  }

  bool matches(DiaryEntry entry) {
    // 日付範囲フィルタ
    if (dateRange != null) {
      final entryDate = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      final startDate = DateTime(
        dateRange!.start.year,
        dateRange!.start.month,
        dateRange!.start.day,
      );
      final endDate = DateTime(
        dateRange!.end.year,
        dateRange!.end.month,
        dateRange!.end.day,
      );

      if (entryDate.isBefore(startDate) || entryDate.isAfter(endDate)) {
        return false;
      }
    }

    // タグフィルタ
    if (selectedTags.isNotEmpty) {
      final entryTags = entry.effectiveTags;
      if (!selectedTags.any((tag) => entryTags.contains(tag))) {
        return false;
      }
    }

    // 時間帯フィルタ
    if (timeOfDay.isNotEmpty) {
      final entryPeriod = TimeOfDayPeriod.fromHour(entry.date.hour);
      if (!timeOfDay.contains(entryPeriod)) {
        return false;
      }
    }

    // テキスト検索フィルタ
    if (searchText != null && searchText!.isNotEmpty) {
      final searchLower = searchText!.toLowerCase();
      final titleMatch = entry.title.toLowerCase().contains(searchLower);
      final contentMatch = entry.content.toLowerCase().contains(searchLower);

      if (!titleMatch && !contentMatch) {
        return false;
      }
    }

    return true;
  }

  DiaryFilter copyWith({
    DateTimeRange? dateRange,
    Set<String>? selectedTags,
    Set<TimeOfDayPeriod>? timeOfDay,
    String? searchText,
    bool clearDateRange = false,
    bool clearSearchText = false,
  }) {
    return DiaryFilter(
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      selectedTags: selectedTags ?? this.selectedTags,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      searchText: clearSearchText ? null : (searchText ?? this.searchText),
    );
  }

  static const DiaryFilter empty = DiaryFilter();

  int get activeFilterCount {
    int count = 0;
    if (dateRange != null) count++;
    count += selectedTags.length;
    count += timeOfDay.length;
    if (searchText != null && searchText!.isNotEmpty) count++;
    return count;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiaryFilter &&
          dateRange == other.dateRange &&
          _setEquals(selectedTags, other.selectedTags) &&
          _setEquals(timeOfDay, other.timeOfDay) &&
          searchText == other.searchText;

  @override
  int get hashCode => Object.hash(
    dateRange,
    Object.hashAll(selectedTags.toList()..sort()),
    Object.hashAll(
      timeOfDay.toList()..sort((a, b) => a.index.compareTo(b.index)),
    ),
    searchText,
  );

  static bool _setEquals<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);
}
