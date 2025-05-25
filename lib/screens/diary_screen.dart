import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import '../models/diary_entry.dart';
import '../services/diary_service.dart';
import 'package:photo_manager/photo_manager.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  // 実際の日記データ
  List<DiaryEntry> _diaryEntries = [];
  bool _isLoading = true;

  // ダミーの日記データ（実際のデータがない場合に表示）
  final List<Map<String, dynamic>> _dummyDiaries = [
    {
      'id': '1',
      'date': '2025年5月23日',
      'title': '新しいカフェでランチ',
      'text':
          '今日は友達と新しくオープンしたカフェに行った。パスタがとても美味しくて、ゆったりとした時間を過ごすことができた。店内の雰囲気も良く、また行きたいと思う。帰りに近くの公園も散歩して、リフレッシュできた一日だった。',
      'images': [
        'https://images.unsplash.com/photo-1554118811-1e0d58224f24',
        'https://images.unsplash.com/photo-1513442542250-854d436a73f2',
      ],
      'tags': ['カフェ', '友達', '散歩'],
      'mood': 'happy',
    },
    {
      'id': '2',
      'date': '2025年5月22日',
      'title': '朝の散歩と写真撮影',
      'text':
          '朝早く起きて散歩に出かけた。空がとてもきれいで、写真を撮らずにはいられなかった。平和な一日の始まり。近所の公園では桜が満開で、季節の移り変わりを感じられた。',
      'images': [
        'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429',
      ],
      'tags': ['朝活', '散歩', '写真'],
      'mood': 'relaxed',
    },
    {
      'id': '3',
      'date': '2025年5月20日',
      'title': '新しい本を読み始めた',
      'text':
          '今日から新しい小説を読み始めた。最近忙しくて読書する時間がなかったけど、久しぶりに読書の時間を作れて良かった。物語に引き込まれて、あっという間に100ページ読んでしまった。',
      'images': [],
      'tags': ['読書', '休日'],
      'mood': 'relaxed',
    },
    {
      'id': '4',
      'date': '2025年5月18日',
      'title': '友人の誕生日パーティー',
      'text': '夜は友人の誕生日パーティーに参加。久しぶりに会う友人もいて、楽しい時間を過ごせた。プレゼントも喜んでもらえて嬉しかった。',
      'images': [
        'https://images.unsplash.com/photo-1513151233558-d860c5398176',
        'https://images.unsplash.com/photo-1530103862676-de8c9debad1d',
      ],
      'tags': ['誕生日', '友達', 'パーティー'],
      'mood': 'excited',
    },
    {
      'id': '5',
      'date': '2025年5月15日',
      'title': '在宅勤務の一日',
      'text':
          '今日は在宅勤務。集中して作業ができて、予定よりも早くプロジェクトを進めることができた。昼休みには近所のカフェでテイクアウトしたサンドイッチを食べた。',
      'images': [],
      'tags': ['仕事', '在宅'],
      'mood': 'productive',
    },
  ];

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
    // タイトルを抽出（最初の行をタイトルとして使用）
    final contentLines = entry.content.split('\n');
    final title = contentLines.isNotEmpty ? contentLines.first : '無題';

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
                    backgroundColor: const Color(0xFF6C4AB6).withAlpha(204),
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
  void initState() {
    super.initState();
    _loadDiaryEntries();
  }

  Future<void> _loadDiaryEntries() async {
    try {
      final diaryService = await DiaryService.getInstance();
      final entries = diaryService.getSortedDiaryEntries();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6FF),
      appBar: AppBar(
        title: const Text('日記一覧'),
        backgroundColor: const Color(0xFF6C4AB6),
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
              itemCount: _diaryEntries.length,
              itemBuilder: (context, index) {
                final entry = _diaryEntries[index];
                return _buildDiaryCard(entry);
              },
            )
          : ListView.builder(
              itemCount: _dummyDiaries.length,
              itemBuilder: (context, index) {
                final diary = _dummyDiaries[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                              diary['date'],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              _getMoodIcon(diary['mood']),
                              color: _getMoodColor(diary['mood']),
                            ),
                          ],
                        ),
                      ),

                      // タイトル
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          diary['title'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // 本文（一部）
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text(
                          diary['text'],
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),

                      // 画像があれば表示
                      if (diary['images'].isNotEmpty)
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: diary['images'].length,
                            itemBuilder: (context, imgIndex) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: imgIndex == 0 ? 16 : 8,
                                  right: imgIndex == diary['images'].length - 1
                                      ? 16
                                      : 0,
                                  bottom: 8,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    diary['images'][imgIndex],
                                    height: 120,
                                    width: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      // タグ
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            for (final tag in diary['tags'])
                              Chip(
                                label: Text(
                                  '#$tag',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: const Color(
                                  0xFF6C4AB6,
                                ).withAlpha(204), // 0.8の透明度に相当
                                padding: const EdgeInsets.all(0),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 新規日記作成画面へ遷移（将来実装）
        },
        backgroundColor: const Color(0xFF6C4AB6),
        child: const Icon(Icons.add),
      ),
    );
  }
}
