import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'constants/app_constants.dart';
import 'controllers/photo_selection_controller.dart';
import 'widgets/photo_grid_widget.dart';
import 'widgets/recent_diaries_widget.dart';
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
      title: AppConstants.appTitle,
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
  
  // コントローラー
  late final PhotoSelectionController _photoController;
  
  // 最近の日記リスト
  List<DiaryEntry> _recentDiaries = [];
  bool _loadingDiaries = true;

  @override
  void initState() {
    super.initState();
    _photoController = PhotoSelectionController();
    _loadTodayPhotos();
    _loadRecentDiaries();
  }
  
  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  // モーダル表示メソッド
  void _showSelectionLimitModal() {
    _showSimpleDialog(AppConstants.selectionLimitMessage);
  }

  void _showUsedPhotoModal() {
    _showSimpleDialog(AppConstants.usedPhotoMessage);
  }
  
  void _showSimpleDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppConstants.okButton),
            ),
          ],
        );
      },
    );
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

      // 使用済み写真IDを収集
      _collectUsedPhotoIds(allEntriesResolved);

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

  // 使用済み写真IDを収集
  void _collectUsedPhotoIds(List<DiaryEntry> allEntries) {
    final usedIds = <String>{};
    for (final entry in allEntries) {
      usedIds.addAll(entry.photoIds);
    }
    _photoController.setUsedPhotoIds(usedIds);
    debugPrint('使用済み写真ID数: ${usedIds.length}');
  }

  // 権限リクエストと写真の読み込み
  Future<void> _loadTodayPhotos() async {
    _photoController.setLoading(true);

    try {
      // 権限リクエスト
      final hasPermission = await PhotoService.requestPermission();
      debugPrint('権限ステータス: $hasPermission');

      _photoController.setPermission(hasPermission);

      if (!hasPermission) {
        _photoController.setLoading(false);
        return;
      }

      // 今日撮影された写真だけを取得
      final photos = await PhotoService.getTodayPhotos();
      debugPrint('取得した写真数: ${photos.length}');

      _photoController.setPhotoAssets(photos);
      _photoController.setLoading(false);
    } catch (e) {
      debugPrint('写真読み込みエラー: $e');
      _photoController.setLoading(false);
    }
  }

  // 画面一覧を取得するメソッド
  List<Widget> _getScreens() {
    final screens = [
      // ホーム画面（現在の画面）
      _HomeContent(
        photoController: _photoController,
        recentDiaries: _recentDiaries,
        isLoadingDiaries: _loadingDiaries,
        onRequestPermission: _loadTodayPhotos,
        onLoadRecentDiaries: _loadRecentDiaries,
        onSelectionLimitReached: _showSelectionLimitModal,
        onUsedPhotoSelected: _showUsedPhotoModal,
        onDiaryTap: (diaryId) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiaryDetailScreen(diaryId: diaryId),
            ),
          ).then((result) {
            _loadRecentDiaries();
            if (result == true) {
              _photoController.clearSelection();
            }
          });
        },
      ),
      const DiaryScreen(),
      const StatisticsScreen(),
    ];

    // デバッグモードの場合のみテスト画面を追加
    if (kDebugMode) {
      screens.add(const TestScreen());
    }

    // 設定画面を追加
    screens.add(SettingsScreen(
      onThemeChanged: widget.onThemeChanged,
      onAccentColorChanged: widget.onAccentColorChanged,
    ));

    return screens;
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
          
          // ホームタブに戻った時に最近の日記を再読み込み（使用済み写真状態を更新）
          if (index == 0) {
            _loadRecentDiaries();
          }
        },
        items: _buildNavigationItems(),
      ),
    );
  }
  
  // ナビゲーションアイテムを構築
  List<BottomNavigationBarItem> _buildNavigationItems() {
    final items = <BottomNavigationBarItem>[];
    
    // 基本アイテム
    for (int i = 0; i < 3; i++) {
      items.add(BottomNavigationBarItem(
        icon: Icon(AppConstants.navigationIcons[i]),
        label: AppConstants.navigationLabels[i],
      ));
    }
    
    // デバッグモードのみテストアイテムを追加
    if (kDebugMode) {
      items.add(BottomNavigationBarItem(
        icon: Icon(AppConstants.navigationIcons[3]),
        label: AppConstants.navigationLabels[3],
      ));
    }
    
    // 設定アイテムを追加
    items.add(BottomNavigationBarItem(
      icon: Icon(AppConstants.navigationIcons[4]),
      label: AppConstants.navigationLabels[4],
    ));
    
    return items;
  }
}

// ホーム画面のコンテンツクラス（リファクタリング済み）
class _HomeContent extends StatelessWidget {
  final PhotoSelectionController photoController;
  final List<DiaryEntry> recentDiaries;
  final bool isLoadingDiaries;
  final VoidCallback onRequestPermission;
  final VoidCallback onLoadRecentDiaries;
  final VoidCallback onSelectionLimitReached;
  final VoidCallback onUsedPhotoSelected;
  final Function(String) onDiaryTap;

  const _HomeContent({
    required this.photoController,
    required this.recentDiaries,
    required this.isLoadingDiaries,
    required this.onRequestPermission,
    required this.onLoadRecentDiaries,
    required this.onSelectionLimitReached,
    required this.onUsedPhotoSelected,
    required this.onDiaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildMainContent(context),
      ],
    );
  }
  
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: AppConstants.headerTopPadding,
        bottom: AppConstants.headerBottomPadding,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppConstants.headerGradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Text(
            AppConstants.appTitle,
            style: TextStyle(
              fontSize: AppConstants.titleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            '${DateTime.now().year}年${DateTime.now().month}月${DateTime.now().day}日',
            style: const TextStyle(
              fontSize: AppConstants.subtitleFontSize,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildMainContent(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: ThemeConstants.defaultScreenPadding,
        children: [
          PhotoGridWidget(
            controller: photoController,
            onSelectionLimitReached: onSelectionLimitReached,
            onUsedPhotoSelected: onUsedPhotoSelected,
            onRequestPermission: onRequestPermission,
          ),
          const SizedBox(height: AppConstants.smallPadding),
          _buildCreateDiaryButton(context),
          const SizedBox(height: AppConstants.largePadding),
          RecentDiariesWidget(
            recentDiaries: recentDiaries,
            isLoading: isLoadingDiaries,
            onDiaryTap: onDiaryTap,
          ),
          const SizedBox(height: AppConstants.bottomNavPadding),
        ],
      ),
    );
  }

  Widget _buildCreateDiaryButton(BuildContext context) {
    return ListenableBuilder(
      listenable: photoController,
      builder: (context, child) {
        return ElevatedButton(
          onPressed: photoController.selectedCount > 0
              ? () => _navigateToDiaryPreview(context)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            minimumSize: const Size.fromHeight(AppConstants.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ThemeConstants.borderRadius),
            ),
          ),
          child: Text('✨ ${photoController.selectedCount}枚の写真で日記を作成'),
        );
      },
    );
  }

  void _navigateToDiaryPreview(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryPreviewScreen(
          selectedAssets: photoController.selectedPhotos,
        ),
      ),
    ).then((_) {
      onLoadRecentDiaries();
      photoController.clearSelection();
    });
  }
}
