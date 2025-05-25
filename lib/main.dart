import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/diary_screen.dart';
import 'services/photo_service.dart';

Future<void> main() async {
  // Flutterの初期化を確実に行う
  WidgetsFlutterBinding.ensureInitialized();

  // .envファイルの読み込み
  await dotenv.load();

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

  // 写真アセットのリスト
  List<dynamic> _photoAssets = [];
  List<bool> _selected = [];
  bool _hasPermission = false;
  bool _isLoading = true;

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

  @override
  void initState() {
    super.initState();
    _loadTodayPhotos();
  }

  // 権限リクエストと写真の読み込み
  Future<void> _loadTodayPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 権限リクエスト
      final hasPermission = await PhotoService.requestPermission();
      debugPrint('権限ステータス: $hasPermission');

      setState(() {
        _hasPermission = hasPermission;
      });

      if (!hasPermission) {
        // 権限がない場合は継続しない
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 今日撮影された写真だけを取得
      final photos = await PhotoService.getTodayPhotos();

      debugPrint('取得した写真数: ${photos.length}');

      setState(() {
        _photoAssets = photos;
        _selected = List.generate(photos.length, (index) => true);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('写真読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 画面一覧を取得するメソッド
  List<Widget> _getScreens() {
    return [
      // ホーム画面（現在の画面）
      _HomeContent(
        photoAssets: _photoAssets,
        selected: _selected,
        recentDiaries: _recentDiaries,
        onToggleSelect: _toggleSelect,
        isLoading: _isLoading,
        hasPermission: _hasPermission,
        onRequestPermission: _loadTodayPhotos,
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
  final List<dynamic> photoAssets;
  final List<bool> selected;
  final List<Map<String, String>> recentDiaries;
  final Function(int) onToggleSelect;
  final bool isLoading;
  final bool hasPermission;
  final VoidCallback onRequestPermission;

  const _HomeContent({
    required this.photoAssets,
    required this.selected,
    required this.recentDiaries,
    required this.onToggleSelect,
    required this.isLoading,
    required this.hasPermission,
    required this.onRequestPermission,
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
          ),
          child: Column(
            children: [
              const Text(
                'Smart Photo Diary',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${DateTime.now().year}年${DateTime.now().month}月${DateTime.now().day}日',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        ),
        // メインコンテンツ
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '新しい写真',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      '${photoAssets.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 300,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : !hasPermission
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.no_photography,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text('写真へのアクセス権限が必要です'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: onRequestPermission,
                              child: const Text('権限をリクエスト'),
                            ),
                          ],
                        ),
                      )
                    : photoAssets.isNotEmpty
                    ? GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: photoAssets.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => onToggleSelect(index),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: FutureBuilder<dynamic>(
                                    future: PhotoService.getThumbnail(
                                      photoAssets[index],
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                              ConnectionState.done &&
                                          snapshot.hasData) {
                                        return Image.memory(
                                          snapshot.data!,
                                          height: 90,
                                          width: 90,
                                          fit: BoxFit.cover,
                                        );
                                      } else {
                                        return Container(
                                          height: 90,
                                          width: 90,
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                    },
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
                    : const Center(child: Text('写真が見つかりませんでした')),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: selected.where((s) => s).isNotEmpty ? () {} : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C4AB6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('✨ ${selected.where((s) => s).length}枚の写真で日記を作成'),
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
