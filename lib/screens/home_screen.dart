import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import '../constants/app_constants.dart';
import '../controllers/photo_selection_controller.dart';
import '../models/diary_entry.dart';
import '../screens/diary_screen.dart';
import '../screens/diary_detail_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/statistics_screen.dart';
import '../services/interfaces/diary_service_interface.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../core/service_registration.dart';
import '../core/service_locator.dart';
import '../services/logging_service.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  // サービス
  late final LoggingService _logger;

  // 統合後の単一コントローラー
  late final PhotoSelectionController _photoController;

  // 権限リクエスト中フラグ
  bool _isRequestingPermission = false;

  // 追加読み込み関連
  int _currentPhotoOffset = 0;
  static const int _photosPerPage =
      AppConstants.timelinePageSize; // タイムライン用ページサイズ
  bool _isPreloading = false; // 先読み中フラグ（UIブロッキングなし）

  // プラン情報のキャッシュ（先読み最適化用）
  int? _cachedAllowedDays;
  DateTime? _planCacheExpiry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _logger = serviceLocator.get<LoggingService>();
    _photoController = PhotoSelectionController();
    // 統合後は日付制限を常時有効化
    _photoController.setDateRestrictionEnabled(true);

    _currentPhotoOffset = 0; // オフセットをリセット
    _isPreloading = false; // 先読みフラグをリセット
    _photoController.setHasMorePhotos(true); // コントローラーにも設定
    _loadTodayPhotos();
    _loadUsedPhotoIds();
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
                final photoService = ServiceRegistration.get<IPhotoService>();
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
    _currentPhotoOffset = 0; // オフセットをリセット
    _isPreloading = false; // 先読みフラグをリセット
    _photoController.setHasMorePhotos(true); // コントローラーにも設定
    // プランキャッシュもクリア
    _cachedAllowedDays = null;
    _planCacheExpiry = null;
    await _loadTodayPhotos();
    await _loadUsedPhotoIds();
  }

  // 使用済み写真IDを読み込む
  Future<void> _loadUsedPhotoIds() async {
    try {
      final diaryService = await ServiceRegistration.getAsync<IDiaryService>();
      final allEntries = await diaryService.getSortedDiaryEntries();
      _collectUsedPhotoIds(allEntries);
    } catch (e) {
      _logger.error('使用済み写真IDの読み込みエラー', error: e, context: 'HomeScreen');
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

  // 統合後のタイムライン写真読み込み
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
      final photoService = ServiceRegistration.get<IPhotoService>();
      final hasPermission = await photoService.requestPermission();

      if (!mounted) return;

      _photoController.setPermission(hasPermission);

      if (!hasPermission) {
        _photoController.setLoading(false);
        // 権限が拒否された場合は説明ダイアログを表示
        await _showPermissionDeniedDialog();
        return;
      }

      // 統合後：今日を含む過去の写真を全て取得（タイムライン用）
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      // プラン制限に応じた過去日数を計算（キャッシュ使用）
      final allowedDays = await _getCachedAllowedDays();

      final photos = await photoService.getPhotosInDateRange(
        startDate: todayStart.subtract(Duration(days: allowedDays)),
        endDate: todayStart.add(const Duration(days: 1)), // 今日を含む
        limit: _photosPerPage, // 初回読み込み分のみ
      );

      if (!mounted) return;

      // Limited Access で写真が少ない場合は追加選択を提案
      if (photos.isEmpty) {
        final isLimited = await photoService.isLimitedAccess();
        if (isLimited) {
          await _showLimitedAccessDialog();
        }
      }

      _photoController.setPhotoAssets(photos);
      _currentPhotoOffset = photos.length; // 次回読み込み用にオフセット更新
      // 初回読み込み時点で末尾到達か判定
      if (photos.length < _photosPerPage) {
        _photoController.setHasMorePhotos(false);
      } else {
        _photoController.setHasMorePhotos(true);
      }
      _photoController.setLoading(false);

      // 初回描画後にバックグラウンド先読みを即時トリガー
      // ユーザー体感のスクロール待ち時間を低減
      if (mounted && _photoController.hasMorePhotos) {
        Future.microtask(() => _preloadMorePhotos(showLoading: false));
      }
    } catch (e) {
      if (mounted) {
        _photoController.setPhotoAssets([]);
        _photoController.setLoading(false);
      }
    } finally {
      _isRequestingPermission = false;
    }
  }

  // 追加写真読み込み（無限スクロール用）
  Future<void> _loadMorePhotos() async {
    // 先読み版を呼び出し（UIブロッキングあり）
    await _preloadMorePhotos(showLoading: true);
  }

  // プラン情報を取得（キャッシュ付き）
  Future<int> _getCachedAllowedDays() async {
    final now = DateTime.now();

    // キャッシュが有効な場合はそれを使用（5分間キャッシュ）
    if (_cachedAllowedDays != null &&
        _planCacheExpiry != null &&
        now.isBefore(_planCacheExpiry!)) {
      return _cachedAllowedDays!;
    }

    // キャッシュが無効な場合は新しく取得
    int allowedDays = 1; // デフォルトはBasicプラン
    try {
      final subscriptionService =
          await ServiceRegistration.getAsync<ISubscriptionService>();
      final planResult = await subscriptionService.getCurrentPlanClass();
      if (planResult.isSuccess) {
        final plan = planResult.value;
        allowedDays = plan.displayName.contains('Premium') ? 365 : 1;
      }
    } catch (e) {
      _logger.error(
        'プラン情報取得エラー',
        error: e,
        context: 'HomeScreen._getCachedAllowedDays',
      );
    }

    // キャッシュを更新（5分間有効）
    _cachedAllowedDays = allowedDays;
    _planCacheExpiry = now.add(const Duration(minutes: 5));

    return allowedDays;
  }

  // 先読み機能付き追加写真読み込み（最適化版）
  Future<void> _preloadMorePhotos({bool showLoading = false}) async {
    if (!mounted ||
        _isRequestingPermission ||
        !_photoController.hasMorePhotos) {
      if (!showLoading) {
        _logger.info(
          '先読みスキップ: mounted=$mounted, requesting=$_isRequestingPermission, hasMore=${_photoController.hasMorePhotos}',
          context: 'HomeScreen._preloadMorePhotos',
        );
      }
      return;
    }

    // 既に先読み中の場合はスキップ
    if (_isPreloading) {
      if (!showLoading) {
        _logger.info(
          '先読みスキップ: 既に先読み中',
          context: 'HomeScreen._preloadMorePhotos',
        );
      }
      return;
    }

    _isPreloading = true;

    if (!showLoading) {
      _logger.info('先読み開始', context: 'HomeScreen._preloadMorePhotos');
    }

    // UIにローディング状態を反映（必要な場合のみ）
    if (showLoading) {
      _photoController.setLoading(true);
    }

    try {
      final photoService = ServiceRegistration.get<IPhotoService>();
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      // キャッシュされたプラン情報を使用
      final allowedDays = await _getCachedAllowedDays();

      // 現在の末尾オフセットから必要分だけを追加で取得（ビューポート直下のスケルトンを優先的に埋める）
      final preloadPages = showLoading ? 1 : AppConstants.timelinePreloadPages;
      final requested = _photosPerPage * preloadPages;

      final newPhotos = await photoService.getPhotosEfficient(
        startDate: todayStart.subtract(Duration(days: allowedDays)),
        endDate: todayStart.add(const Duration(days: 1)),
        offset: _currentPhotoOffset,
        limit: requested,
      );

      if (!mounted) return;

      final currentCount = _photoController.photoAssets.length;

      if (!showLoading) {
        _logger.info(
          '先読み結果: 現在=$currentCount, 新規=${newPhotos.length}, offset=$_currentPhotoOffset, req=$requested',
          context: 'HomeScreen._preloadMorePhotos',
        );
      }

      if (newPhotos.isNotEmpty) {
        final combined = <AssetEntity>[
          ..._photoController.photoAssets,
          ...newPhotos,
        ];
        _photoController.setPhotoAssetsPreservingSelection(combined);
        _currentPhotoOffset += newPhotos.length;
        // 追加分が要求数に満たない場合は末尾まで到達
        final reachedEnd = newPhotos.length < requested;
        _photoController.setHasMorePhotos(!reachedEnd);
      } else {
        // 追加なし→これ以上は存在しない
        _photoController.setHasMorePhotos(false);

        if (!showLoading) {
          _logger.info(
            '先読み終了: これ以上写真がありません',
            context: 'HomeScreen._preloadMorePhotos',
          );
        }
      }
    } catch (e) {
      _logger.error(
        '先読み写真読み込みエラー',
        context: 'HomeScreen._preloadMorePhotos',
        error: e,
      );
    } finally {
      _isPreloading = false;
      if (showLoading) {
        _photoController.setLoading(false);
      }
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
        onRefresh: _refreshHome,
        onCameraPressed: _capturePhoto,
        onDiaryCreated: _loadUsedPhotoIds,
        onLoadMorePhotos: _loadMorePhotos,
        onPreloadMorePhotos: () => _preloadMorePhotos(showLoading: false),
        onDiaryTap: (diaryId) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiaryDetailScreen(diaryId: diaryId),
            ),
          ).then((result) {
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
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          // ホームタブに戻った時にタイムライン表示を再読み込み
          if (index == 0) {
            _loadTodayPhotos();
            _loadUsedPhotoIds();
          }
        },
        items: _buildNavigationItems(),
      ),
    );
  }

  // FloatingActionButtonを構築（統合後は非表示、TimelineFABIntegrationで管理）
  Widget? _buildFloatingActionButton() {
    // 統合後はFABをTimelineFABIntegrationで管理するため、ここでは非表示
    return _currentIndex == 0 ? null : null;
  }

  // 統合後：カメラ撮影処理（TimelineFABIntegrationから呼び出される）

  // カメラ撮影処理
  Future<void> _capturePhoto() async {
    try {
      final photoService = ServiceRegistration.get<IPhotoService>();

      _logger.info('カメラ撮影を開始（FABから）', context: 'HomeScreen._capturePhoto');

      // カメラで撮影（権限チェックはcapturePhoto内で実行）
      final captureResult = await photoService.capturePhoto();

      if (captureResult.isFailure) {
        _logger.error(
          'カメラ撮影に失敗（FABから）',
          context: 'HomeScreen._capturePhoto',
          error: captureResult.error,
        );

        if (mounted) {
          // カメラ権限拒否の場合は設定ダイアログを表示
          if (captureResult.error.toString().contains('権限が拒否されています')) {
            await _showCameraPermissionDialog();
          }
        }
        return;
      }

      final capturedPhoto = captureResult.value;
      if (capturedPhoto != null) {
        // 撮影成功：写真を今日の写真コントローラーに追加
        _logger.info(
          'カメラ撮影成功（FABから）',
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
        _logger.info('カメラ撮影をキャンセル（FABから）', context: 'HomeScreen._capturePhoto');
      }
    } catch (e) {
      _logger.error(
        'カメラ撮影処理中にエラーが発生（FABから）',
        context: 'HomeScreen._capturePhoto',
        error: e,
      );
    }
  }

  // カメラ権限拒否時のダイアログを表示
  Future<void> _showCameraPermissionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => CustomDialog(
        icon: Icons.camera_alt_outlined,
        iconColor: Theme.of(context).colorScheme.primary,
        title: 'カメラへのアクセス許可が必要です',
        message: '写真を撮影するには、カメラへのアクセスを許可してください。設定アプリからカメラの権限を有効にできます。',
        actions: [
          CustomDialogAction(
            text: 'キャンセル',
            onPressed: () => Navigator.of(context).pop(),
          ),
          CustomDialogAction(
            text: '設定を開く',
            isPrimary: true,
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  // 撮影成功のフィードバックを表示
  void _showCaptureSuccessSnackBar() {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: theme.colorScheme.onInverseSurface,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '写真を撮影しました',
              style: TextStyle(color: theme.colorScheme.onInverseSurface),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.inverseSurface,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
