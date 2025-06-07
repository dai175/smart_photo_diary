import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import '../models/diary_entry.dart';
import '../models/diary_filter.dart';
import '../services/diary_service.dart';
import '../shared/filter_bottom_sheet.dart';
import '../shared/active_filters_display.dart';
import 'package:photo_manager/photo_manager.dart';
import 'diary_detail_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  // 実際の日記データ
  List<DiaryEntry> _diaryEntries = [];
  bool _isLoading = true;
  DiaryFilter _currentFilter = DiaryFilter.empty;


  @override
  void initState() {
    super.initState();
    _loadDiaryEntries();
  }

  // 日記エントリーをタップしたときに詳細画面に遷移
  void _navigateToDiaryDetail(DiaryEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryDetailScreen(diaryId: entry.id),
      ),
    ).then((result) {
      // 詳細画面から戻ってきたときに日記一覧を再読み込み
      _loadDiaryEntries();
      
      // 削除された場合の追加処理（必要に応じて）
      if (result == true) {
        debugPrint('日記が削除されました');
      }
    });
  }

  // 日記エントリーを読み込む
  Future<void> _loadDiaryEntries() async {
    try {
      final diaryService = await DiaryService.getInstance();
      final entries = await diaryService.getFilteredDiaryEntries(_currentFilter);

      setState(() {
        _diaryEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('日記エントリーの読み込みエラー: $e');
    }
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
        initialFilter: _currentFilter,
        onApply: _applyFilter,
      ),
    );
  }

  // フィルタを適用
  void _applyFilter(DiaryFilter filter) {
    setState(() {
      _currentFilter = filter;
      _isLoading = true;
    });
    _loadDiaryEntries();
  }

  // フィルタをクリア
  void _clearAllFilters() {
    _applyFilter(DiaryFilter.empty);
  }

  // 個別フィルタを削除
  void _removeTagFilter(String tag) {
    final newTags = Set<String>.from(_currentFilter.selectedTags)..remove(tag);
    _applyFilter(_currentFilter.copyWith(selectedTags: newTags));
  }


  void _removeTimeOfDayFilter(String time) {
    final newTimeOfDay = Set<String>.from(_currentFilter.timeOfDay)..remove(time);
    _applyFilter(_currentFilter.copyWith(timeOfDay: newTimeOfDay));
  }

  void _removeDateRangeFilter() {
    _applyFilter(_currentFilter.copyWith(clearDateRange: true));
  }


  void _removeSearchFilter() {
    _applyFilter(_currentFilter.copyWith(clearSearchText: true));
  }


  // タグを取得（永続化キャッシュ優先）
  Future<List<String>> _generateTags(DiaryEntry entry) async {
    try {
      final diaryService = await DiaryService.getInstance();
      return await diaryService.getTagsForEntry(entry);
    } catch (e) {
      debugPrint('タグ取得エラー: $e');
      // エラー時はフォールバックタグを返す（時間帯のみ）
      final fallbackTags = <String>[];
      
      final hour = entry.date.hour;
      if (hour >= 5 && hour < 12) {
        fallbackTags.add('朝');
      } else if (hour >= 12 && hour < 18) {
        fallbackTags.add('昼');
      } else if (hour >= 18 && hour < 22) {
        fallbackTags.add('夕方');
      } else {
        fallbackTags.add('夜');
      }
      
      return fallbackTags;
    }
  }

  // 実際の日記エントリーのカードを作成
  Widget _buildDiaryCard(DiaryEntry entry) {
    // タイトルを取得
    final title = entry.title.isNotEmpty ? entry.title : '無題';


    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日付
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              DateFormat('yyyy年MM月dd日').format(entry.date),
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // タイトル
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // 本文（一部）
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              entry.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ),

          // 写真があれば表示
          FutureBuilder<List<AssetEntity>>(
            future: entry.getPhotoAssets(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox();
              }

              final assets = snapshot.data!;
              return SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: assets.length,
                  itemBuilder: (context, imgIndex) {
                    return Padding(
                      padding: EdgeInsets.only(
                        left: imgIndex == 0 ? 16 : 8,
                        right: imgIndex == assets.length - 1 ? 16 : 0,
                        bottom: 8,
                      ),
                      child: FutureBuilder<Uint8List?>(
                        future: assets[imgIndex].thumbnailData,
                        builder: (context, thumbnailSnapshot) {
                          if (!thumbnailSnapshot.hasData) {
                            return const SizedBox(
                              width: 120,
                              height: 120,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              thumbnailSnapshot.data!,
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // タグ（動的生成）
          FutureBuilder<List<String>>(
            future: _generateTags(entry),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('タグを生成中...', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }
              
              final tags = snapshot.data ?? [];
              if (tags.isEmpty) return const SizedBox();
              
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final tag in tags)
                      Chip(
                        label: Text(
                          '#$tag',
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                        padding: const EdgeInsets.all(0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('日記一覧'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadDiaryEntries();
            },
          ),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _currentFilter.isActive 
                ? Theme.of(context).colorScheme.secondary 
                : null,
            ),
            onPressed: _showFilterBottomSheet,
          ),
        ],
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // アクティブフィルタ表示
          ActiveFiltersDisplay(
            filter: _currentFilter,
            onClear: _clearAllFilters,
            onRemoveTag: _removeTagFilter,
            onRemoveTimeOfDay: _removeTimeOfDayFilter,
            onRemoveDateRange: _removeDateRangeFilter,
            onRemoveSearch: _removeSearchFilter,
          ),
          
          // 日記一覧
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _diaryEntries.isNotEmpty
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _diaryEntries.length,
                    itemBuilder: (context, index) {
                      final entry = _diaryEntries[index];
                      return GestureDetector(
                        onTap: () => _navigateToDiaryDetail(entry),
                        child: _buildDiaryCard(entry),
                      );
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _currentFilter.isActive ? Icons.filter_list_off : Icons.book_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentFilter.isActive 
                            ? 'フィルタ条件に一致する日記がありません'
                            : '日記がありません',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentFilter.isActive 
                            ? 'フィルタを変更するか、クリアしてみてください'
                            : '写真を選んで最初の日記を作成しましょう',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (_currentFilter.isActive) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _clearAllFilters,
                            child: const Text('フィルタをクリア'),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
