import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import '../models/diary_filter.dart';
import '../services/interfaces/diary_query_service_interface.dart';
import '../core/service_locator.dart';
import '../core/errors/app_exceptions.dart';
import 'base_error_controller.dart';
import '../constants/app_constants.dart';

class DiaryScreenController extends BaseErrorController {
  // 日記データ
  List<DiaryEntry> _diaryEntries = [];
  DiaryFilter _currentFilter = DiaryFilter.empty;

  // 検索機能
  bool _isSearching = false;
  String _searchQuery = '';
  late final TextEditingController _searchController;

  // ページング
  static const int _pageSize = AppConstants.diaryPageSize;
  int _offset = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Getters
  List<DiaryEntry> get diaryEntries => _diaryEntries;
  DiaryFilter get currentFilter => _currentFilter;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  TextEditingController get searchController => _searchController;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  DiaryScreenController() {
    _searchController = TextEditingController();
    loadDiaryEntries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 日記エントリーを読み込む（初期ページ）
  Future<void> loadDiaryEntries() async {
    try {
      // 初回および再読込時はローディング表示
      setLoading(true);
      _resetPaging();
      final diaryService = await ServiceLocator()
          .getAsync<IDiaryQueryService>();
      final result = await diaryService.getFilteredDiaryEntriesPage(
        _currentFilter,
        offset: _offset,
        limit: _pageSize,
      );

      result.fold(
        (entries) {
          _diaryEntries = entries;
          _offset = entries.length;
          _hasMore = entries.length == _pageSize;
          clearError();
          setLoading(false);
          notifyListeners();
        },
        (error) {
          setError(error);
          setLoading(false);
          notifyListeners();
        },
      );
    } catch (e) {
      setError(ServiceException('Failed to load diaries: $e'));
      setLoading(false);
      notifyListeners();
    }
  }

  // 次ページを読み込む
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final diaryService = await ServiceLocator()
          .getAsync<IDiaryQueryService>();
      final result = await diaryService.getFilteredDiaryEntriesPage(
        _currentFilter,
        offset: _offset,
        limit: _pageSize,
      );

      result.fold(
        (entries) {
          _diaryEntries = [..._diaryEntries, ...entries];
          _offset += entries.length;
          _hasMore = entries.length == _pageSize;
          _isLoadingMore = false;
          notifyListeners();
        },
        (error) {
          setError(error);
          _isLoadingMore = false;
          notifyListeners();
        },
      );
    } catch (e) {
      setError(ServiceException('Failed to load more: $e'));
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void _resetPaging() {
    _offset = 0;
    _hasMore = true;
    _isLoadingMore = false;
  }

  // フィルタを適用（シマー表示あり、FilterBottomSheet用）
  void applyFilter(DiaryFilter filter) {
    _currentFilter = filter;
    setLoading(true);
    notifyListeners();
    loadDiaryEntries();
  }

  // フィルタを適用（シマー表示なし、フィルタチップ操作用）
  void _applyFilterSilently(DiaryFilter filter) {
    _currentFilter = filter;
    notifyListeners();
    _loadEntriesWithoutShimmer();
  }

  // シマーなしでエントリーを読み込む
  Future<void> _loadEntriesWithoutShimmer() async {
    try {
      _resetPaging();
      final diaryService = await ServiceLocator()
          .getAsync<IDiaryQueryService>();
      final result = await diaryService.getFilteredDiaryEntriesPage(
        _currentFilter,
        offset: _offset,
        limit: _pageSize,
      );

      result.fold(
        (entries) {
          _diaryEntries = entries;
          _offset = entries.length;
          _hasMore = entries.length == _pageSize;
          clearError();
          notifyListeners();
        },
        (error) {
          setError(error);
          notifyListeners();
        },
      );
    } catch (e) {
      setError(ServiceException('Failed to load diaries: $e'));
      notifyListeners();
    }
  }

  // フィルタをクリア
  void clearAllFilters() {
    _applyFilterSilently(DiaryFilter.empty);
  }

  // 個別フィルタを削除
  void removeTagFilter(String tag) {
    final newTags = Set<String>.from(_currentFilter.selectedTags)..remove(tag);
    _applyFilterSilently(_currentFilter.copyWith(selectedTags: newTags));
  }

  void removeTimeOfDayFilter(TimeOfDayPeriod period) {
    final newTimeOfDay = Set<TimeOfDayPeriod>.from(_currentFilter.timeOfDay)
      ..remove(period);
    _applyFilterSilently(_currentFilter.copyWith(timeOfDay: newTimeOfDay));
  }

  void removeDateRangeFilter() {
    _applyFilterSilently(_currentFilter.copyWith(clearDateRange: true));
  }

  void removeSearchFilter() {
    _applyFilterSilently(_currentFilter.copyWith(clearSearchText: true));
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
    try {
      final diaryService = await ServiceLocator()
          .getAsync<IDiaryQueryService>();

      final filter = query.isEmpty
          ? _currentFilter
          : _currentFilter.copyWith(searchText: query);

      _resetPaging();
      final result = await diaryService.getFilteredDiaryEntriesPage(
        filter,
        offset: _offset,
        limit: _pageSize,
      );

      result.fold(
        (entries) {
          _diaryEntries = entries;
          _offset = entries.length;
          _hasMore = entries.length == _pageSize;
          clearError();
          setLoading(false);
          notifyListeners();
        },
        (error) {
          setError(error);
          setLoading(false);
          notifyListeners();
        },
      );
    } catch (e) {
      setError(ServiceException('Search failed: $e'));
      setLoading(false);
      notifyListeners();
    }
  }

  // シマーを表示せずにデータを再読み込み（スクロール位置維持）
  Future<void> silentRefresh() async {
    try {
      final diaryService = await ServiceLocator()
          .getAsync<IDiaryQueryService>();
      final fetchCount = _offset > 0 ? _offset : _pageSize;
      final result = await diaryService.getFilteredDiaryEntriesPage(
        _currentFilter,
        offset: 0,
        limit: fetchCount,
      );

      result.fold(
        (entries) {
          _diaryEntries = entries;
          _offset = entries.length;
          if (entries.length < fetchCount) {
            _hasMore = false;
          }
          clearError();
          notifyListeners();
        },
        (_) {
          // サイレントリフレッシュのエラーは無視（既存リストを表示し続ける）
        },
      );
    } catch (_) {
      // サイレントリフレッシュのエラーは無視
    }
  }

  // リフレッシュ
  Future<void> refresh() async {
    setLoading(true);
    await loadDiaryEntries();
  }

  // 空の状態メッセージを取得（多言語化対応）
  String getLocalizedEmptyStateMessage({
    required String Function() noDiariesMessage,
    required String Function(String query) noSearchResultsMessage,
    required String Function() noFilterResultsMessage,
  }) {
    if (_isSearching) {
      return noSearchResultsMessage(_searchQuery);
    } else if (_currentFilter.isActive) {
      return noFilterResultsMessage();
    } else {
      return noDiariesMessage();
    }
  }
}
