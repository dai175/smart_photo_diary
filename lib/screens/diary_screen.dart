import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import '../models/diary_entry.dart';
import '../services/diary_service.dart';
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
    ).then((_) {
      // 詳細画面から戻ってきたときに日記一覧を再読み込み
      _loadDiaryEntries();
    });
  }

  // 日記エントリーを読み込む
  Future<void> _loadDiaryEntries() async {
    try {
      final diaryService = await DiaryService.getInstance();
      final entries = await diaryService.getSortedDiaryEntries();

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

  // 気分に応じたアイコンを返す
  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'relaxed':
        return Icons.sentiment_satisfied;
      case 'excited':
        return Icons.celebration;
      case 'productive':
        return Icons.task_alt;
      default:
        return Icons.sentiment_neutral;
    }
  }

  // 気分に応じた色を返す
  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'happy':
        return Colors.amber;
      case 'relaxed':
        return Colors.lightBlue;
      case 'excited':
        return Colors.pink;
      case 'productive':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // 実際の日記エントリーのカードを作成
  Widget _buildDiaryCard(DiaryEntry entry) {
    // タイトルを取得
    final title = entry.title.isNotEmpty ? entry.title : '無題';

    // タグを抽出（将来的に実装予定）
    final tags = <String>['AI生成', '写真日記'];

    // 気分をランダムに設定（将来的に実装予定）
    final moods = ['happy', 'relaxed', 'excited', 'productive'];
    final mood = moods[entry.date.day % moods.length];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日付とムードアイコン
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('yyyy年MM月dd日').format(entry.date),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(_getMoodIcon(mood), color: _getMoodColor(mood)),
              ],
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

          // タグ
          Padding(
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
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
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
                    Icons.book_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '日記がありません',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '写真を選んで最初の日記を作成しましょう',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 新規日記作成画面へ遷移（将来実装）
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
