import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../controllers/photo_selection_controller.dart';
import '../models/diary_entry.dart';
import '../screens/diary_screen.dart';
import '../screens/diary_detail_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/test_screen.dart';
import '../services/diary_service.dart';
import '../services/photo_service.dart';
import '../utils/dialog_utils.dart';
import '../widgets/home_content_widget.dart';

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
    DialogUtils.showSimpleDialog(context, message);
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
      HomeContentWidget(
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