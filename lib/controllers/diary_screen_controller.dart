import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import '../models/diary_filter.dart';
import '../services/diary_service.dart';

class DiaryScreenController extends ChangeNotifier {
  // 日記データ
  List<DiaryEntry> _diaryEntries = [];
  bool _isLoading = true;
  DiaryFilter _currentFilter = DiaryFilter.empty;
  
  // 検索機能
  bool _isSearching = false;
  String _searchQuery = '';
  late final TextEditingController _searchController;

  // Getters
  List<DiaryEntry> get diaryEntries => _diaryEntries;
  bool get isLoading => _isLoading;
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
    try {
      _setLoading(true);
      final diaryService = await DiaryService.getInstance();
      final entries = await diaryService.getFilteredDiaryEntries(_currentFilter);

      _diaryEntries = entries;
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      debugPrint('日記エントリーの読み込みエラー: $e');
    }
  }

  // フィルタを適用
  void applyFilter(DiaryFilter filter) {
    _currentFilter = filter;
    _setLoading(true);
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
    _setLoading(true);
    _searchDiaryEntries(query);
  }

  // 検索クリア
  void clearSearch() {
    _searchController.clear();
    performSearch('');
  }

  // 検索で日記を絞り込み
  Future<void> _searchDiaryEntries(String query) async {
    try {
      final diaryService = await DiaryService.getInstance();
      List<DiaryEntry> entries;

      if (query.isEmpty) {
        // 検索クエリが空の場合は通常のフィルタを適用
        entries = await diaryService.getFilteredDiaryEntries(_currentFilter);
      } else {
        // 検索クエリがある場合は検索フィルタを作成
        final searchFilter = _currentFilter.copyWith(searchText: query);
        entries = await diaryService.getFilteredDiaryEntries(searchFilter);
      }

      _diaryEntries = entries;
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      debugPrint('検索エラー: $e');
    }
  }

  // リフレッシュ
  void refresh() {
    _setLoading(true);
    loadDiaryEntries();
  }

  // ローディング状態の設定
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
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