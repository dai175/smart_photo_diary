import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'screens/diary_screen.dart';
import 'screens/test_screen.dart';
import 'screens/diary_preview_screen.dart';
import 'screens/diary_detail_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/settings_screen.dart';
import 'services/photo_service.dart';
import 'services/diary_service.dart';
import 'services/settings_service.dart';
import 'models/diary_entry.dart';

Future<void> main() async {
  // Flutterの初期化を確実に行う
  WidgetsFlutterBinding.ensureInitialized();

  // Hiveの初期化
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  // アダプターの登録
  Hive.registerAdapter(DiaryEntryAdapter());

  // .envファイルの読み込み
  await dotenv.load();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late SettingsService _settingsService;
  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = const Color(0xFF6C4AB6);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      _settingsService = await SettingsService.getInstance();
      setState(() {
        _themeMode = _settingsService.themeMode;
        _accentColor = _settingsService.accentColor;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onThemeChanged(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  void _onAccentColorChanged(Color color) {
    setState(() {
      _accentColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Smart Photo Diary',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accentColor,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accentColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(
        onThemeChanged: _onThemeChanged,
        onAccentColorChanged: _onAccentColorChanged,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;
  final Function(Color)? onAccentColorChanged;
  
  const HomeScreen({
    super.key,
    this.onThemeChanged,
    this.onAccentColorChanged,
  });

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

  // 最近の日記リスト
  List<DiaryEntry> _recentDiaries = [];
  bool _loadingDiaries = true;

  void _toggleSelect(int index) {
    setState(() {
      _selected[index] = !_selected[index];
    });
  }

  @override
  void initState() {
    super.initState();
    _loadTodayPhotos();
    _loadRecentDiaries();
  }

  // 最近の日記を読み込む
  Future<void> _loadRecentDiaries() async {
    try {
      setState(() {
        _loadingDiaries = true;
      });

      final diaryService = await DiaryService.getInstance();
      final allEntries = diaryService.getSortedDiaryEntries();

      // 最新の3つの日記を取得
      final allEntriesResolved = await allEntries;
      final recentEntries = allEntriesResolved.take(3).toList();

      setState(() {
        _recentDiaries = recentEntries;
        _loadingDiaries = false;
      });
    } catch (e) {
      debugPrint('日記の読み込みエラー: $e');
      setState(() {
        _loadingDiaries = false;
      });
    }
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
        isLoadingDiaries: _loadingDiaries,
        hasPermission: _hasPermission,
        onRequestPermission: _loadTodayPhotos,
        onLoadRecentDiaries: _loadRecentDiaries,
        onDiaryTap: (diaryId) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiaryDetailScreen(diaryId: diaryId),
            ),
          ).then((_) {
            // 日記詳細画面から戻ってきたときに最近の日記を再読み込み
            _loadRecentDiaries();
          });
        },
      ),
      // 日記一覧画面
      const DiaryScreen(),
      // 統計画面
      const StatisticsScreen(),
      // テスト画面（画像分析と日記生成のテスト用）
      const TestScreen(),
      // 設定画面
      SettingsScreen(
        onThemeChanged: widget.onThemeChanged,
        onAccentColorChanged: widget.onAccentColorChanged,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screens = _getScreens();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
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
          BottomNavigationBarItem(icon: Icon(Icons.science), label: 'テスト'),
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
  final List<DiaryEntry> recentDiaries;
  final Function(int) onToggleSelect;
  final bool isLoading;
  final bool isLoadingDiaries;
  final bool hasPermission;
  final VoidCallback onRequestPermission;
  final Function(String) onDiaryTap;
  final VoidCallback onLoadRecentDiaries;

  const _HomeContent({
    required this.photoAssets,
    required this.selected,
    required this.recentDiaries,
    required this.onToggleSelect,
    required this.isLoading,
    required this.isLoadingDiaries,
    required this.hasPermission,
    required this.onRequestPermission,
    required this.onDiaryTap,
    required this.onLoadRecentDiaries,
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
                onPressed: selected.where((s) => s).isNotEmpty
                    ? () {
                        // 選択された写真を取得
                        final List<AssetEntity> selectedPhotos = [];
                        for (int i = 0; i < photoAssets.length; i++) {
                          if (selected[i]) {
                            selectedPhotos.add(photoAssets[i]);
                          }
                        }

                        // 日記プレビュー画面へ遷移
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DiaryPreviewScreen(
                              selectedAssets: selectedPhotos,
                            ),
                          ),
                        ).then((_) {
                          // 日記プレビュー画面から戻ってきたときに最近の日記を再読み込み
                          onLoadRecentDiaries();
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
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
              isLoadingDiaries
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : recentDiaries.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('保存された日記がありません')),
                    )
                  : Column(
                      children: recentDiaries.map((diary) {
                        // タイトルを取得
                        final title = diary.title.isNotEmpty
                            ? diary.title
                            : '無題';

                        return GestureDetector(
                          onTap: () => onDiaryTap(diary.id),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerLow,
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
                                  DateFormat('yyyy年MM月dd日').format(diary.date),
                                  style: const TextStyle(
                                    color: Colors.purple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  diary.content,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 15,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 80), // ボトムナビ分の余白
            ],
          ),
        ),
      ],
    );
  }
}
