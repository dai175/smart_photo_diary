import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import '../models/diary_filter.dart';
import '../services/diary_service.dart';
import 'base_error_controller.dart';

class DiaryScreenController extends BaseErrorController {
  // 日記データ
  List<DiaryEntry> _diaryEntries = [];
  DiaryFilter _currentFilter = DiaryFilter.empty;
  
  // 検索機能
  bool _isSearching = false;
  String _searchQuery = '';
  late final TextEditingController _searchController;

  // Getters
  List<DiaryEntry> get diaryEntries => _diaryEntries;
  DiaryFilter get currentFilter => _currentFilter;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  TextEditingController get searchController => _searchController;

  DiaryScreenController() {
    _searchController = TextEditingController();
    loadDiaryEntries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 日記エントリーを読み込む
  Future<void> loadDiaryEntries() async {
    final result = await safeExecute(() async {
      final diaryService = await DiaryService.getInstance();
      return await diaryService.getFilteredDiaryEntries(_currentFilter);
    }, context: 'DiaryScreenController.loadDiaryEntries');

    if (result != null) {
      _diaryEntries = result;
    }
  }

  // フィルタを適用
  void applyFilter(DiaryFilter filter) {
    _currentFilter = filter;
    setLoading(true);
    notifyListeners();
    loadDiaryEntries();
  }

  // フィルタをクリア
  void clearAllFilters() {
    applyFilter(DiaryFilter.empty);
  }

  // 個別フィルタを削除
  void removeTagFilter(String tag) {
    final newTags = Set<String>.from(_currentFilter.selectedTags)..remove(tag);
    applyFilter(_currentFilter.copyWith(selectedTags: newTags));
  }

  void removeTimeOfDayFilter(String time) {
    final newTimeOfDay = Set<String>.from(_currentFilter.timeOfDay)..remove(time);
    applyFilter(_currentFilter.copyWith(timeOfDay: newTimeOfDay));
  }

  void removeDateRangeFilter() {
    applyFilter(_currentFilter.copyWith(clearDateRange: true));
  }

  void removeSearchFilter() {
    applyFilter(_currentFilter.copyWith(clearSearchText: true));
  }

  // 検索開始
  void startSearch() {
    _isSearching = true;
    notifyListeners();
  }

  // 検索終了
  void stopSearch() {
    _isSearching = false;
    _searchQuery = '';
    _searchController.clear();
    notifyListeners();
    loadDiaryEntries(); // 全ての日記を再表示
  }

  // 検索実行
  void performSearch(String query) {
    _searchQuery = query;
    setLoading(true);
    _searchDiaryEntries(query);
  }

  // 検索クリア
  void clearSearch() {
    _searchController.clear();
    performSearch('');
  }

  // 検索で日記を絞り込み
  Future<void> _searchDiaryEntries(String query) async {
    final result = await safeExecute(() async {
      final diaryService = await DiaryService.getInstance();
      
      if (query.isEmpty) {
        // 検索クエリが空の場合は通常のフィルタを適用
        return await diaryService.getFilteredDiaryEntries(_currentFilter);
      } else {
        // 検索クエリがある場合は検索フィルタを作成
        final searchFilter = _currentFilter.copyWith(searchText: query);
        return await diaryService.getFilteredDiaryEntries(searchFilter);
      }
    }, context: 'DiaryScreenController.searchDiaryEntries');

    if (result != null) {
      _diaryEntries = result;
    }
  }

  // リフレッシュ
  Future<void> refresh() async {
    setLoading(true);
    await loadDiaryEntries();
  }

  // 空の状態メッセージを取得
  String getEmptyStateMessage() {
    if (_isSearching) {
      return '「$_searchQuery」に一致する日記がありません';
    } else if (_currentFilter.isActive) {
      return 'フィルタ条件に一致する日記がありません';
    } else {
      return '日記がありません';
    }
  }

  // 空の状態サブメッセージを取得
  String getEmptyStateSubMessage() {
    if (_isSearching) {
      return '別のキーワードで検索してみてください';
    } else if (_currentFilter.isActive) {
      return 'フィルタを変更するか、クリアしてみてください';
    } else {
      return '写真を選んで最初の日記を作成しましょう';
    }
  }

  // 空の状態アイコンを取得
  IconData getEmptyStateIcon() {
    if (_isSearching) {
      return Icons.search_off;
    } else if (_currentFilter.isActive) {
      return Icons.filter_list_off;
    } else {
      return Icons.book_outlined;
    }
  }
}