import 'package:flutter/material.dart';
import '../controllers/diary_screen_controller.dart';
import '../widgets/diary_card_widget.dart';
import '../shared/filter_bottom_sheet.dart';
import '../shared/active_filters_display.dart';
import 'diary_detail_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late final DiaryScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DiaryScreenController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 日記エントリーをタップしたときに詳細画面に遷移
  void _navigateToDiaryDetail(String diaryId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryDetailScreen(diaryId: diaryId),
      ),
    ).then((result) {
      // 詳細画面から戻ってきたときに日記一覧を再読み込み
      _controller.loadDiaryEntries();
      
      // 削除された場合の追加処理（必要に応じて）
      if (result == true) {
        debugPrint('日記が削除されました');
      }
    });
  }

  // フィルタボトムシートを表示
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterBottomSheet(
        initialFilter: _controller.currentFilter,
        onApply: _controller.applyFilter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: _buildAppBar(),
          body: Column(
            children: [
              // アクティブフィルタ表示
              ActiveFiltersDisplay(
                filter: _controller.currentFilter,
                onClear: _controller.clearAllFilters,
                onRemoveTag: _controller.removeTagFilter,
                onRemoveTimeOfDay: _controller.removeTimeOfDayFilter,
                onRemoveDateRange: _controller.removeDateRangeFilter,
                onRemoveSearch: _controller.removeSearchFilter,
              ),
              
              // 日記一覧
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: _controller.isSearching 
        ? TextField(
            controller: _controller.searchController,
            autofocus: true,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            decoration: InputDecoration(
              hintText: 'タイトルや本文を検索...',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
              ),
              border: InputBorder.none,
            ),
            onChanged: _controller.performSearch,
          )
        : const Text('日記一覧'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      leading: _controller.isSearching 
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _controller.stopSearch,
          )
        : null,
      actions: _controller.isSearching 
        ? [
            if (_controller.searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _controller.clearSearch,
              ),
          ]
        : [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _controller.refresh,
            ),
            IconButton(
              icon: const Icon(Icons.search), 
              onPressed: _controller.startSearch,
            ),
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: _controller.currentFilter.isActive 
                  ? Theme.of(context).colorScheme.secondary 
                  : null,
              ),
              onPressed: _showFilterBottomSheet,
            ),
          ],
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      elevation: 0,
    );
  }

  Widget _buildContent() {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.diaryEntries.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _controller.diaryEntries.length,
        itemBuilder: (context, index) {
          final entry = _controller.diaryEntries[index];
          return DiaryCardWidget(
            entry: entry,
            onTap: () => _navigateToDiaryDetail(entry.id),
          );
        },
      );
    }

    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _controller.getEmptyStateIcon(),
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            _controller.getEmptyStateMessage(),
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _controller.getEmptyStateSubMessage(),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (_controller.currentFilter.isActive && !_controller.isSearching) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _controller.clearAllFilters,
              child: const Text('フィルタをクリア'),
            ),
          ],
        ],
      ),
    );
  }
}