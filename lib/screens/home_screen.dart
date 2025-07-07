import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_constants.dart';
import '../controllers/photo_selection_controller.dart';
import '../models/diary_entry.dart';
import '../screens/diary_screen.dart';
import '../screens/diary_detail_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/statistics_screen.dart';
import '../services/interfaces/diary_service_interface.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../core/service_registration.dart';
import '../utils/dialog_utils.dart';
import '../widgets/home_content_widget.dart';
import '../ui/components/custom_dialog.dart';
import '../ui/design_system/app_colors.dart';

class HomeScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;

  const HomeScreen({super.key, this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  // コントローラー
  late final PhotoSelectionController _photoController;

  // 最近の日記リスト
  List<DiaryEntry> _recentDiaries = [];
  bool _loadingDiaries = true;

  // 権限リクエスト中フラグ
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _photoController = PhotoSelectionController();
    _loadTodayPhotos();
    _loadRecentDiaries();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _photoController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // アプリがフォアグラウンドに戻った時に権限状態をチェック
      _refreshHome();
    }
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

  // 権限拒否時のダイアログを表示
  Future<void> _showPermissionDeniedDialog() async {
    if (!mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomDialog(
          icon: Icons.photo_library_outlined,
          iconColor: AppColors.warning,
          title: '写真へのアクセスを許可',
          message: '日記作成のために写真ライブラリへのアクセスが必要です。設定アプリで写真へのアクセスを許可してください。',
          actions: [
            CustomDialogAction(
              text: 'キャンセル',
              onPressed: () => Navigator.of(context).pop(),
            ),
            CustomDialogAction(
              text: '設定を開く',
              isPrimary: true,
              icon: Icons.settings_rounded,
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  // Limited Access時のダイアログを表示
  Future<void> _showLimitedAccessDialog() async {
    if (!mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomDialog(
          icon: Icons.photo_library_outlined,
          iconColor: AppColors.info,
          title: '写真を追加選択',
          message: '現在、選択された写真のみアクセス可能です。日記作成に使用したい写真を追加で選択しますか？',
          actions: [
            CustomDialogAction(
              text: '後で',
              onPressed: () => Navigator.of(context).pop(),
            ),
            CustomDialogAction(
              text: '写真を選択',
              isPrimary: true,
              icon: Icons.add_photo_alternate_rounded,
              onPressed: () async {
                Navigator.of(context).pop();
                final photoService =
                    ServiceRegistration.get<PhotoServiceInterface>();
                await photoService.presentLimitedLibraryPicker();
                // 選択後に写真を再読み込み
                _loadTodayPhotos();
              },
            ),
          ],
        );
      },
    );
  }

  // ホーム画面全体のリロード
  Future<void> _refreshHome() async {
    await Future.wait([_loadTodayPhotos(), _loadRecentDiaries()]);
  }

  // 最近の日記を読み込む
  Future<void> _loadRecentDiaries() async {
    try {
      if (!mounted) return;

      setState(() {
        _loadingDiaries = true;
      });

      final diaryService =
          await ServiceRegistration.getAsync<DiaryServiceInterface>();
      final allEntries = await diaryService.getSortedDiaryEntries();

      if (!mounted) return;

      // 最新の3つの日記を取得
      final recentEntries = allEntries.take(3).toList();

      // 使用済み写真IDを収集
      _collectUsedPhotoIds(allEntries);

      if (!mounted) return;

      setState(() {
        _recentDiaries = recentEntries;
        _loadingDiaries = false;
      });
    } catch (e) {
      debugPrint('日記の読み込みエラー: $e');
      if (mounted) {
        setState(() {
          _recentDiaries = [];
          _loadingDiaries = false;
        });
      }
    }
  }

  // 使用済み写真IDを収集
  void _collectUsedPhotoIds(List<DiaryEntry> allEntries) {
    final usedIds = <String>{};
    for (final entry in allEntries) {
      usedIds.addAll(entry.photoIds);
    }
    _photoController.setUsedPhotoIds(usedIds);
  }

  // 権限リクエストと写真の読み込み
  Future<void> _loadTodayPhotos() async {
    if (!mounted) return;

    // 既に権限リクエスト中の場合は処理をスキップ
    if (_isRequestingPermission) {
      return;
    }

    _isRequestingPermission = true;
    _photoController.setLoading(true);

    try {
      // 権限リクエスト
      final photoService = ServiceRegistration.get<PhotoServiceInterface>();
      final hasPermission = await photoService.requestPermission();

      if (!mounted) return;

      _photoController.setPermission(hasPermission);

      if (!hasPermission) {
        _photoController.setLoading(false);
        // 権限が拒否された場合は説明ダイアログを表示
        await _showPermissionDeniedDialog();
        return;
      }

      // 今日撮影された写真だけを取得
      final photos = await photoService.getTodayPhotos();

      if (!mounted) return;

      // Limited Access で写真が少ない場合は追加選択を提案
      if (photos.isEmpty) {
        final isLimited = await photoService.isLimitedAccess();
        if (isLimited) {
          await _showLimitedAccessDialog();
        }
      }

      _photoController.setPhotoAssets(photos);
      _photoController.setLoading(false);
    } catch (e) {
      if (mounted) {
        _photoController.setPhotoAssets([]);
        _photoController.setLoading(false);
      }
    } finally {
      _isRequestingPermission = false;
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
        onRefresh: _refreshHome,
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

    // 設定画面を追加
    screens.add(SettingsScreen(onThemeChanged: widget.onThemeChanged));

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

    // 全アイテムを追加
    for (int i = 0; i < AppConstants.navigationIcons.length; i++) {
      items.add(
        BottomNavigationBarItem(
          icon: Icon(AppConstants.navigationIcons[i]),
          label: AppConstants.navigationLabels[i],
        ),
      );
    }

    return items;
  }
}
