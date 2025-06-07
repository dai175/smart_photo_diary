import 'package:flutter/material.dart';
import 'diary_entry.dart';

class DiaryFilter {
  final DateTimeRange? dateRange;
  final Set<String> selectedTags;
  final Set<String> timeOfDay;
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
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      final startDate = DateTime(dateRange!.start.year, dateRange!.start.month, dateRange!.start.day);
      final endDate = DateTime(dateRange!.end.year, dateRange!.end.month, dateRange!.end.day);
      
      if (entryDate.isBefore(startDate) || entryDate.isAfter(endDate)) {
        return false;
      }
    }

    // タグフィルタ
    if (selectedTags.isNotEmpty) {
      final entryTags = entry.cachedTags ?? [];
      if (!selectedTags.any((tag) => entryTags.contains(tag))) {
        return false;
      }
    }



    // 時間帯フィルタ
    if (timeOfDay.isNotEmpty) {
      final hour = entry.date.hour;
      String entryTimeOfDay;
      
      if (hour >= 5 && hour < 12) {
        entryTimeOfDay = '朝';
      } else if (hour >= 12 && hour < 18) {
        entryTimeOfDay = '昼';
      } else if (hour >= 18 && hour < 22) {
        entryTimeOfDay = '夕方';
      } else {
        entryTimeOfDay = '夜';
      }
      
      if (!timeOfDay.contains(entryTimeOfDay)) {
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
    Set<String>? timeOfDay,
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
    if (selectedTags.isNotEmpty) count++;
    if (timeOfDay.isNotEmpty) count++;
    if (searchText != null && searchText!.isNotEmpty) count++;
    return count;
  }

  List<String> get activeFilterLabels {
    final labels = <String>[];
    
    if (dateRange != null) {
      labels.add('期間指定');
    }
    
    if (selectedTags.isNotEmpty) {
      if (selectedTags.length == 1) {
        labels.add('#${selectedTags.first}');
      } else {
        labels.add('タグ(${selectedTags.length})');
      }
    }
    
    
    
    if (timeOfDay.isNotEmpty) {
      if (timeOfDay.length == 1) {
        labels.add(timeOfDay.first);
      } else {
        labels.add('時間帯(${timeOfDay.length})');
      }
    }
    
    if (searchText != null && searchText!.isNotEmpty) {
      labels.add('検索: ${searchText!}');
    }
    
    return labels;
  }
}