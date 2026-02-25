import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import '../constants/app_constants.dart';
import '../controllers/home_controller.dart';
import '../controllers/photo_selection_controller.dart';
import '../core/errors/app_exceptions.dart';
import '../core/result/result.dart';
import '../models/diary_entry.dart';
import '../models/photo_type_filter.dart';
import '../screens/diary_screen.dart';
import '../screens/diary_detail_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/statistics_screen.dart';
import '../services/interfaces/diary_service_interface.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../services/interfaces/settings_service_interface.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../services/photo_query_service.dart';
import '../core/service_registration.dart';
import '../core/service_locator.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../utils/dialog_utils.dart';
import '../utils/upgrade_dialog_utils.dart';
import '../widgets/home_content_widget.dart';
import '../ui/components/custom_dialog.dart';
import '../controllers/scroll_signal.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/component_constants.dart';
import '../models/diary_change.dart';
import '../localization/localization_extensions.dart';
import 'dart:async';

part 'home/home_dialogs.dart';
part 'home/home_data_loader.dart';

class HomeScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;

  const HomeScreen({super.key, this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, _HomeDialogsMixin, _HomeDataLoaderMixin {
  // サービス
  late final ILoggingService _logger;

  // タブナビゲーション・画面キー管理コントローラー
  late final HomeController _homeController;

  // 統合後の単一コントローラー
  late final PhotoSelectionController _photoController;

  // 権限リクエスト中フラグ
  bool _isRequestingPermission = false;

  // 追加読み込み関連
  int _currentPhotoOffset = 0;
  static const int _photosPerPage =
      AppConstants.timelinePageSize; // タイムライン用ページサイズ
  bool _isPreloading = false; // 先読み中フラグ（UIブロッキングなし）

  // ホームタブ再タップで先頭へスクロールさせるためのシグナル
  final ScrollSignal _homeScrollSignal = ScrollSignal();
  // 日記タブ・設定タブ再タップで先頭へスクロールさせるためのシグナル
  final ScrollSignal _diaryScrollSignal = ScrollSignal();
  final ScrollSignal _settingsScrollSignal = ScrollSignal();

  // 写真タイプフィルター（設定から読み込み）
  late final ISettingsService _settingsService;
  late PhotoTypeFilter _photoTypeFilter;
  Set<String> _screenshotAssetIds = {};

  // 日記変更イベント購読
  StreamSubscription<DiaryChange>? _diarySub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _logger = serviceLocator.get<ILoggingService>();
    _settingsService = serviceLocator.get<ISettingsService>();
    _photoTypeFilter = _settingsService.photoTypeFilter;
    _settingsService.photoTypeFilterNotifier.addListener(
      _onPhotoTypeFilterChanged,
    );
    _homeController = HomeController();
    _photoController = PhotoSelectionController();
    // 統合後は日付制限を常時有効化
    _photoController.setDateRestrictionEnabled(true);

    _currentPhotoOffset = 0; // オフセットをリセット
    _isPreloading = false; // 先読みフラグをリセット
    _photoController.setHasMorePhotos(true); // コントローラーにも設定
    _loadTodayPhotos();
    _loadUsedPhotoIds();
    _subscribeDiaryChanges();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settingsService.photoTypeFilterNotifier.removeListener(
      _onPhotoTypeFilterChanged,
    );
    _diarySub?.cancel();
    _homeController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _onResumed();
    }
  }

  void _onPhotoTypeFilterChanged() {
    if (!mounted) return;
    _photoTypeFilter = _settingsService.photoTypeFilterNotifier.value;
    unawaited(_refreshHome());
  }

  Future<void> _onResumed() async {
    // 使用済み写真IDのみ更新（日記が他画面で変更された可能性に対応）
    // スクロール位置・読み込み済み写真データ・オフセットはすべて保持
    await _loadUsedPhotoIds();
  }

  /// 日記詳細画面を開いた結果を共通で処理
  Future<void> _handleDiaryDetailResult(dynamic result) async {
    if (result == true) {
      _photoController.clearSelection();
      await _loadUsedPhotoIds();
      if (mounted) {
        _homeController.refreshDiaryAndStats();
      }
    }
  }

  /// 日記詳細画面に遷移
  Future<void> _openDiaryDetail(String diaryId) async {
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryDetailScreen(diaryId: diaryId),
      ),
    );

    await _handleDiaryDetailResult(result);
  }

  /// 写真IDから日記詳細画面に遷移
  Future<void> _navigateToDiaryDetailByPhotoId(String photoId) async {
    try {
      final diaryService = await ServiceRegistration.getAsync<IDiaryService>();
      final result = await diaryService.getDiaryEntryByPhotoId(photoId);

      switch (result) {
        case Success(data: final diaryEntry):
          if (diaryEntry != null) {
            _logger.info(
              'Navigating to diary detail for photoId: $photoId, diaryId: ${diaryEntry.id}',
            );
            await _openDiaryDetail(diaryEntry.id);
          } else {
            _logger.warning('No diary found for photoId: $photoId');
            if (mounted) {
              _showSimpleDialog(context.l10n.homeLinkedDiaryNotFound);
            }
          }
        case Failure(exception: final e):
          _logger.error('Error retrieving diary by photo ID', error: e);
          if (mounted) {
            _showSimpleDialog(
              '${context.l10n.homeDiaryLoadError}\n${e.message}',
            );
          }
      }
    } catch (e) {
      _logger.error('Error retrieving diary by photo ID', error: e);
      if (mounted) {
        _showSimpleDialog('${context.l10n.homeDiaryLoadError}\n$e');
      }
    }
  }

  // ホーム画面全体のリロード
  Future<void> _refreshHome() async {
    _currentPhotoOffset = 0; // オフセットをリセット
    _isPreloading = false; // 先読みフラグをリセット
    _photoController.setHasMorePhotos(true); // コントローラーにも設定
    await _loadTodayPhotos();
    await _loadUsedPhotoIds();
  }

  // カメラ撮影処理
  Future<void> _capturePhoto() async {
    try {
      final photoService = ServiceRegistration.get<IPhotoService>();

      _logger.info(
        'Starting camera capture (from FAB)',
        context: 'HomeScreen._capturePhoto',
      );

      // カメラで撮影（権限チェックはcapturePhoto内で実行）
      final captureResult = await photoService.capturePhoto();

      if (captureResult.isFailure) {
        _logger.error(
          'Camera capture failed (from FAB)',
          context: 'HomeScreen._capturePhoto',
          error: captureResult.error,
        );

        if (mounted) {
          // カメラ権限拒否の場合は設定ダイアログを表示
          if (captureResult.error is PhotoAccessException &&
              (captureResult.error as PhotoAccessException).details ==
                  'Camera permission denied') {
            await _showCameraPermissionDialog();
          }
        }
        return;
      }

      final capturedPhoto = captureResult.value;
      if (capturedPhoto != null) {
        // 撮影成功：写真を今日の写真コントローラーに追加
        _logger.info(
          'Camera capture succeeded (from FAB)',
          context: 'HomeScreen._capturePhoto',
          data: 'Asset ID: ${capturedPhoto.id}',
        );

        // 今日の写真リストを再読み込みして新しい写真を含める
        await _loadTodayPhotos();

        // 撮影した写真を自動選択状態で追加
        _photoController.refreshPhotosWithNewCapture(
          _photoController.photoAssets,
          capturedPhoto.id,
        );

        // 撮影成功のフィードバックを表示
        if (mounted) {
          _showCaptureSuccessSnackBar();
        }
      } else {
        // キャンセル時
        _logger.info(
          'Camera capture cancelled (from FAB)',
          context: 'HomeScreen._capturePhoto',
        );
      }
    } catch (e) {
      _logger.error(
        'Error during camera capture processing (from FAB)',
        context: 'HomeScreen._capturePhoto',
        error: e,
      );
    }
  }

  // 画面一覧を取得するメソッド
  List<Widget> _getScreens() {
    final screens = [
      // ホーム画面（統合後のタイムライン表示）
      HomeContentWidget(
        photoController: _photoController,
        onRequestPermission: _loadTodayPhotos,
        onSelectionLimitReached: _showSelectionLimitModal,
        onUsedPhotoSelected: _showUsedPhotoModal,
        onUsedPhotoDetail: _navigateToDiaryDetailByPhotoId,
        onLockedPhotoTapped: _showLockedPhotoModal,
        onRefresh: _refreshHome,
        onCameraPressed: _capturePhoto,
        onDiaryCreated: _onDiaryCreated,
        onLoadMorePhotos: _loadMorePhotos,
        onPreloadMorePhotos: () => _preloadMorePhotos(showLoading: false),
        scrollSignal: _homeScrollSignal,
        onDiaryTap: _openDiaryDetail,
      ),
      DiaryScreen(
        key: _homeController.diaryScreenKey,
        scrollSignal: _diaryScrollSignal,
      ),
      StatisticsScreen(key: _homeController.statsScreenKey),
    ];

    // 設定画面を追加
    screens.add(
      SettingsScreen(
        onThemeChanged: widget.onThemeChanged,
        scrollSignal: _settingsScrollSignal,
      ),
    );

    return screens;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _homeController,
      builder: (context, _) {
        final screens = _getScreens();

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: IndexedStack(
            index: _homeController.currentIndex,
            children: screens,
          ),
          floatingActionButton: null,
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: NavBarConstants.hairlineThickness,
                width: double.infinity,
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _homeController.currentIndex,
                onTap: (index) {
                  if (_homeController.currentIndex == index) {
                    // 同じタブを再タップした場合、先頭へスクロール
                    switch (index) {
                      case AppConstants.homeTabIndex:
                        _homeScrollSignal.trigger();
                        break;
                      case AppConstants.diaryTabIndex:
                        _diaryScrollSignal.trigger();
                        break;
                      case AppConstants.settingsTabIndex:
                        _settingsScrollSignal.trigger();
                        break;
                    }
                    return;
                  }

                  if (index == AppConstants.homeTabIndex) {
                    _loadUsedPhotoIds();
                  }
                  _homeController.setCurrentIndex(index);
                },
                items: _buildNavigationItems(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ナビゲーションアイテムを構築
  List<BottomNavigationBarItem> _buildNavigationItems() {
    final items = <BottomNavigationBarItem>[];
    final labels = _navigationLabels(context);

    // 全アイテムを追加
    for (int i = 0; i < AppConstants.navigationIcons.length; i++) {
      items.add(
        BottomNavigationBarItem(
          icon: Icon(AppConstants.navigationIcons[i]),
          label: labels[i],
        ),
      );
    }

    return items;
  }

  List<String> _navigationLabels(BuildContext context) {
    return [
      context.l10n.navigationHome,
      context.l10n.navigationDiary,
      context.l10n.navigationStatistics,
      context.l10n.navigationSettings,
    ];
  }
}
