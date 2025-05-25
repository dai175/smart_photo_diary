import 'package:flutter/material.dart';
import 'screens/diary_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Photo Diary',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  // ダミー画像（ネット画像URL）
  final List<String> _dummyImages = [
    'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
    'https://images.unsplash.com/photo-1465101046530-73398c7f28ca',
    'https://images.unsplash.com/photo-1519125323398-675f0ddb6308',
    'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429',
  ];
  final List<bool> _selected = [true, true, false, false];

  final List<Map<String, String>> _recentDiaries = [
    {
      'date': '2025年5月23日',
      'text': '今日は友達と新しくオープンしたカフェに行った。パスタがとても美味しくて、ゆったりとした時間を過ごすことができた...',
    },
    {
      'date': '2025年5月22日',
      'text': '朝早く起きて散歩に出かけた。空がとてもきれいで、写真を撮らずにはいられなかった。平和な一日の始まり...',
    },
  ];

  void _toggleSelect(int index) {
    setState(() {
      _selected[index] = !_selected[index];
    });
  }
  
  // 画面一覧を取得するメソッド
  List<Widget> _getScreens() {
    return [
      // ホーム画面（現在の画面）
      _HomeContent(
        dummyImages: _dummyImages,
        selected: _selected,
        recentDiaries: _recentDiaries,
        onToggleSelect: _toggleSelect,
      ),
      // 日記一覧画面
      const DiaryScreen(),
      // 統計画面（未実装）
      const Center(child: Text('統計画面（開発中）')),
      // 設定画面（未実装）
      const Center(child: Text('設定画面（開発中）')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screens = _getScreens();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6FF),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6C4AB6),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: '日記'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '統計'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }
}

// ホーム画面のコンテンツを別クラスに分離
class _HomeContent extends StatelessWidget {
  final List<String> dummyImages;
  final List<bool> selected;
  final List<Map<String, String>> recentDiaries;
  final Function(int) onToggleSelect;

  const _HomeContent({
    required this.dummyImages,
    required this.selected,
    required this.recentDiaries,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // グラデーションヘッダー
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 50, bottom: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: const Column(
            children: [
              Text(
                '📸 Smart Photo Diary',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black26)],
                ),
              ),
              SizedBox(height: 8),
              Text(
                '今日の思い出を写真で記録しよう',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '新しい写真',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${dummyImages.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: dummyImages.isNotEmpty
                    ? ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: dummyImages.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => onToggleSelect(index),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    dummyImages[index],
                                    height: 90,
                                    width: 90,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      selected[index]
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: selected[index]
                                          ? Colors.green
                                          : Colors.grey,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Text('写真を追加してください'),
                      ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: selected.where((s) => s).isNotEmpty
                    ? () {}
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C4AB6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  '✨ ${selected.where((s) => s).length}枚の写真で日記を作成',
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '最近の日記',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...recentDiaries.map(
                (diary) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      const BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diary['date']!,
                        style: const TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        diary['text']!,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80), // ボトムナビ分の余白
            ],
          ),
        ),
      ],
    );
  }
}
