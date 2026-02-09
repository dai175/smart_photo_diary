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
import '../controllers/scroll_signal.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/component_constants.dart';
import '../models/diary_change.dart';
import '../localization/localization_extensions.dart';
import 'dart:async';

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

  // ホームタブ再タップで先頭へスクロールさせるためのシグナル
  final ScrollSignal _homeScrollSignal = ScrollSignal();
  // 日記タブ・設定タブ再タップで先頭へスクロールさせるためのシグナル
  final ScrollSignal _diaryScrollSignal = ScrollSignal();
  final ScrollSignal _settingsScrollSignal = ScrollSignal();

  // Diaryタブの再構築用キー（作成直後の一覧更新のため）
  Key _diaryScreenKey = UniqueKey();
  // 統計タブの再構築用キー（フォールバック再読込）
  Key _statsScreenKey = UniqueKey();

  // 日記変更イベント購読
  StreamSubscription<DiaryChange>? _diarySub;

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
    _subscribeDiaryChanges();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _diarySub?.cancel();
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _subscribeDiaryChanges() async {
    try {
      final diaryService = await ServiceRegistration.getAsync<IDiaryService>();
      _diarySub = diaryService.changes.listen((change) {
        switch (change.type) {
          case DiaryChangeType.created:
            _photoController.addUsedPhotoIds(change.addedPhotoIds);
            break;
          case DiaryChangeType.updated:
            if (change.removedPhotoIds.isNotEmpty) {
              _photoController.removeUsedPhotoIds(change.removedPhotoIds);
            }
            if (change.addedPhotoIds.isNotEmpty) {
              _photoController.addUsedPhotoIds(change.addedPhotoIds);
            }
            break;
          case DiaryChangeType.deleted:
            _photoController.removeUsedPhotoIds(change.removedPhotoIds);
            break;
        }
      });
    } catch (_) {
      // 失敗時はフォールバックで定期的に再読込してもよいが、ここでは無視
    }
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
    _showSimpleDialog(
      context.l10n.photoSelectionLimitMessage(AppConstants.maxPhotosSelection),
    );
  }

  void _showUsedPhotoModal() {
    _showSimpleDialog(context.l10n.photoUsedPhotoMessage);
  }

  /// 日記詳細画面を開いた結果を共通で処理
  Future<void> _handleDiaryDetailResult(dynamic result) async {
    if (result == true) {
      _photoController.clearSelection();
      await _loadUsedPhotoIds();
      if (mounted) {
        setState(() {
          _diaryScreenKey = UniqueKey();
          _statsScreenKey = UniqueKey();
        });
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
      final diaryEntry = await diaryService.getDiaryEntryByPhotoId(photoId);

      if (diaryEntry != null) {
        _logger.info('写真ID: $photoId の日記詳細に遷移: ${diaryEntry.id}');
        await _openDiaryDetail(diaryEntry.id);
      } else {
        _logger.warning('写真ID: $photoId に対応する日記が見つかりません');
        if (mounted) {
          _showSimpleDialog(context.l10n.homeLinkedDiaryNotFound);
        }
      }
    } catch (e) {
      _logger.error('写真IDから日記取得エラー', error: e);
      if (mounted) {
        _showSimpleDialog('${context.l10n.homeDiaryLoadError}\n$e');
      }
    }
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
          title: context.l10n.homePermissionDialogTitle,
          message: context.l10n.homePermissionDialogMessage,
          actions: [
            CustomDialogAction(
              text: context.l10n.commonCancel,
              onPressed: () => Navigator.of(context).pop(),
            ),
            CustomDialogAction(
              text: context.l10n.commonOpenSettings,
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
          title: context.l10n.homeLimitedAccessTitle,
          message: context.l10n.homeLimitedAccessMessage,
          actions: [
            CustomDialogAction(
              text: context.l10n.commonLater,
              onPressed: () => Navigator.of(context).pop(),
            ),
            CustomDialogAction(
              text: context.l10n.photoSelectAction,
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

      // プラン制限に応じた過去日数を計算
      final allowedDays = await _getAllowedDays();

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

  // 日記作成完了時の処理：使用済み写真更新 + Diary画面を再構築
  Future<void> _onDiaryCreated() async {
    setState(() {
      _diaryScreenKey = UniqueKey();
    });
    await _loadUsedPhotoIds();
  }

  // プラン情報を取得
  Future<int> _getAllowedDays() async {
    int allowedDays = 1; // デフォルトはBasicプラン
    try {
      final subscriptionService =
          await ServiceRegistration.getAsync<ISubscriptionService>();
      final planResult = await subscriptionService.getCurrentPlanClass();
      if (planResult.isSuccess) {
        final plan = planResult.value;
        allowedDays = plan.isPremium ? 365 : 1;
      }
    } catch (e) {
      _logger.error(
        'プラン情報取得エラー',
        error: e,
        context: 'HomeScreen._getCachedAllowedDays',
      );
    }

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

      // プラン情報を取得
      final allowedDays = await _getAllowedDays();

      // シンプルな先読み戦略
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
        onUsedPhotoDetail: _navigateToDiaryDetailByPhotoId,
        onRefresh: _refreshHome,
        onCameraPressed: _capturePhoto,
        onDiaryCreated: _onDiaryCreated,
        onLoadMorePhotos: _loadMorePhotos,
        onPreloadMorePhotos: () => _preloadMorePhotos(showLoading: false),
        scrollSignal: _homeScrollSignal,
        onDiaryTap: _openDiaryDetail,
      ),
      DiaryScreen(key: _diaryScreenKey, scrollSignal: _diaryScrollSignal),
      StatisticsScreen(key: _statsScreenKey),
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
    final screens = _getScreens();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: IndexedStack(index: _currentIndex, children: screens),
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
            currentIndex: _currentIndex,
            onTap: (index) {
              if (_currentIndex == index) {
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

              // フォールバック: タブ切替時に必要な再同期を実施
              if (index == AppConstants.homeTabIndex) {
                // Home を表示する際に使用済みIDを再同期
                _loadUsedPhotoIds();
              } else if (index == AppConstants.statisticsTabIndex) {
                // Statistics を表示する直前に再構築し再計算を促す
                setState(() {
                  _statsScreenKey = UniqueKey();
                });
              }

              setState(() {
                _currentIndex = index;
              });
            },
            items: _buildNavigationItems(),
          ),
        ],
      ),
    );
  }

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
        title: context.l10n.cameraPermissionDialogTitle,
        message: context.l10n.cameraPermissionDialogMessage,
        actions: [
          CustomDialogAction(
            text: context.l10n.commonCancel,
            onPressed: () => Navigator.of(context).pop(),
          ),
          CustomDialogAction(
            text: context.l10n.commonOpenSettings,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.cameraCaptureSuccess),
        duration: const Duration(seconds: 2),
      ),
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
