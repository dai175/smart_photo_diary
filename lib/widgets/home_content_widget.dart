import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../controllers/photo_selection_controller.dart';
import '../models/diary_entry.dart';
import '../screens/diary_preview_screen.dart';
import '../widgets/optimized_photo_grid_widget.dart';
import '../widgets/recent_diaries_widget.dart';
import '../widgets/prompt_selection_modal.dart';
import '../models/writing_prompt.dart';
import '../models/plans/plan.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../services/interfaces/photo_access_control_service_interface.dart';
import '../services/interfaces/diary_service_interface.dart';
import '../widgets/past_photo_calendar_widget.dart';
import '../core/errors/error_handler.dart';
import '../services/logging_service.dart';
import '../ui/error_display/error_display_service.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/animated_button.dart';
import '../ui/components/custom_dialog.dart';
import '../ui/animations/list_animations.dart';
import '../ui/animations/micro_interactions.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../core/service_registration.dart';
import '../utils/upgrade_dialog_utils.dart';
import '../ui/design_system/app_colors.dart';
import '../services/photo_cache_service.dart';
import '../core/service_locator.dart';

class HomeContentWidget extends StatefulWidget {
  final PhotoSelectionController photoController;
  final PhotoSelectionController pastPhotoController;
  final TabController tabController;
  final List<DiaryEntry> recentDiaries;
  final bool isLoadingDiaries;
  final VoidCallback onRequestPermission;
  final VoidCallback onLoadRecentDiaries;
  final VoidCallback onSelectionLimitReached;
  final VoidCallback onUsedPhotoSelected;
  final Function(String) onDiaryTap;
  final Future<void> Function()? onRefresh;

  const HomeContentWidget({
    super.key,
    required this.photoController,
    required this.pastPhotoController,
    required this.tabController,
    required this.recentDiaries,
    required this.isLoadingDiaries,
    required this.onRequestPermission,
    required this.onLoadRecentDiaries,
    required this.onSelectionLimitReached,
    required this.onUsedPhotoSelected,
    required this.onDiaryTap,
    this.onRefresh,
  });

  @override
  State<HomeContentWidget> createState() => _HomeContentWidgetState();
}

class _HomeContentWidgetState extends State<HomeContentWidget> {
  // LoggingService getter
  LoggingService get _logger => serviceLocator.get<LoggingService>();

  // アクセス制御関連
  Plan? _currentPlan;
  DateTime? _accessibleDate;
  bool _isCalendarView = false;
  // 過去タブの表示モード管理
  DateTime? _selectedPastDate; // 選択された日付
  bool _showAllPastPhotos = true; // すべての写真を表示するかどうか

  @override
  void initState() {
    super.initState();
    _loadCurrentPlan();
    _loadUsedPhotoIds();
    widget.tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    if (widget.tabController.index == 1 &&
        widget.pastPhotoController.photoAssets.isEmpty) {
      _loadPastPhotos();
    }

    // タブ切り替え時にキャッシュクリーンアップ
    if (widget.tabController.index == 0) {
      // 過去タブから今日タブに戻った時
      _cleanupPastPhotosCache();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildHeader(context),
      body: widget.onRefresh != null
          ? MicroInteractions.pullToRefresh(
              onRefresh: widget.onRefresh!,
              color: Theme.of(context).colorScheme.primary,
              child: _buildMainContent(context),
            )
          : _buildMainContent(context),
    );
  }

  PreferredSizeWidget _buildHeader(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        '${DateTime.now().year}年${DateTime.now().month}月${DateTime.now().day}日',
      ),
      centerTitle: false,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      elevation: 2,
      actions: [
        // Phase 1.7.2.3: 使用量カウンター表示ボタン
        Container(
          margin: const EdgeInsets.only(right: AppSpacing.xs),
          child: IconButton(
            icon: Icon(
              Icons.analytics_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => _showUsageStatus(context),
            tooltip: 'AI生成の使用状況',
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.tabController,
      builder: (context, child) {
        return ListView(
          padding: AppSpacing.screenPadding,
          children: [
            FadeInWidget(
              delay: const Duration(milliseconds: 100),
              child: _buildPhotoSection(context),
            ),
            const SizedBox(height: AppSpacing.md),
            // カレンダー表示時は日記作成ボタンを非表示
            if (!(widget.tabController.index == 1 && _isCalendarView))
              FadeInWidget(
                delay: const Duration(milliseconds: 200),
                child: _buildCreateDiaryButton(context),
              ),
            FadeInWidget(
              delay: const Duration(milliseconds: 300),
              child: _buildRecentDiariesSection(context),
            ),
            const SizedBox(height: AppConstants.bottomNavPadding),
          ],
        );
      },
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タブバー
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: TabBar(
              controller: widget.tabController,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.today_rounded),
                      const SizedBox(width: AppSpacing.sm),
                      Text('今日', style: AppTypography.titleMedium),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded),
                      const SizedBox(width: AppSpacing.sm),
                      Text('過去', style: AppTypography.titleMedium),
                    ],
                  ),
                ),
              ],
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 3,
            ),
          ),
          // タブビュー
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _getTabViewHeight(),
            child: TabBarView(
              controller: widget.tabController,
              physics: const BouncingScrollPhysics(),
              children: [_buildTodayPhotosTab(), _buildPastPhotosTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayPhotosTab() {
    return SingleChildScrollView(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          // カメラ撮影ボタンとフォトグリッドのセット
          Row(
            children: [
              // カメラ撮影ボタン
              _buildCameraButton(context),
              const SizedBox(width: AppSpacing.sm),
              // 説明テキスト
              Expanded(
                child: Text(
                  '写真を撮影するか、ギャラリーから選択',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          OptimizedPhotoGridWidget(
            controller: widget.photoController,
            onSelectionLimitReached: widget.onSelectionLimitReached,
            onUsedPhotoSelected: widget.onUsedPhotoSelected,
            onRequestPermission: widget.onRequestPermission,
          ),
        ],
      ),
    );
  }

  Widget _buildPastPhotosTab() {
    // Basicプランかどうかチェック
    final isBasicPlan =
        _currentPlan != null &&
        _currentPlan!.runtimeType.toString().contains('Basic');

    return SingleChildScrollView(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentPlan != null) ...[
            // Basicプランの場合のみアクセス範囲情報を表示
            if (isBasicPlan) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [_buildAccessRangeInfo()],
              ),
              const SizedBox(height: AppSpacing.md),
            ] else ...[
              // プレミアムプランの場合は表示切り替えのみ
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [_buildViewToggle()],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
          // カレンダー表示とグリッド表示の切り替え
          _isCalendarView && !isBasicPlan
              ? PastPhotoCalendarWidget(
                  key: const ValueKey('calendar'),
                  currentPlan: _currentPlan,
                  accessibleDate: _accessibleDate,
                  usedPhotoIds: widget.pastPhotoController.usedPhotoIds,
                  onPhotosSelected: (photos) {
                    // 新しい日付の写真を設定する前に選択をクリア
                    widget.pastPhotoController.clearSelection();
                    widget.pastPhotoController.setPhotoAssets(photos);
                    setState(() {
                      _selectedPastDate = photos.isNotEmpty
                          ? DateTime(
                              photos.first.createDateTime.year,
                              photos.first.createDateTime.month,
                              photos.first.createDateTime.day,
                            )
                          : null;
                      _showAllPastPhotos = false;
                      _isCalendarView = false;
                    });
                  },
                  onSelectionCleared: () {
                    setState(() {
                      _selectedPastDate = null;
                      _showAllPastPhotos = true;
                    });
                    _loadPastPhotos();
                  },
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.05),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        child: child,
                      ),
                    );
                  },
                  child: OptimizedPhotoGridWidget(
                    key: ValueKey('grid-$_showAllPastPhotos'),
                    controller: widget.pastPhotoController,
                    onSelectionLimitReached: widget.onSelectionLimitReached,
                    onUsedPhotoSelected: widget.onUsedPhotoSelected,
                    onRequestPermission: _loadPastPhotos,
                    onDifferentDateSelected: _showDifferentDateDialog,
                  ),
                ),
        ],
      ),
    );
  }

  /// カメラ撮影ボタンを構築
  Widget _buildCameraButton(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: MicroInteractions.bounceOnTap(
        onTap: _onCameraButtonTapped,
        child: Icon(
          Icons.photo_camera_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildCreateDiaryButton(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.photoController,
        widget.pastPhotoController,
        widget.tabController,
      ]),
      builder: (context, child) {
        final activeController = widget.tabController.index == 0
            ? widget.photoController
            : widget.pastPhotoController;
        final theme = Theme.of(context);
        return AnimatedButton(
          onPressed: activeController.selectedCount > 0
              ? () => _showPromptSelectionModal(context)
              : null,
          width: double.infinity,
          height: AppSpacing.buttonHeightLg,
          backgroundColor: activeController.selectedCount > 0
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          foregroundColor: activeController.selectedCount > 0
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          shadowColor: activeController.selectedCount > 0
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : null,
          elevation: activeController.selectedCount > 0
              ? AppSpacing.elevationSm
              : 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                activeController.selectedCount > 0
                    ? Icons.auto_awesome_rounded
                    : Icons.photo_camera_outlined,
                size: AppSpacing.iconSm,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                activeController.selectedCount > 0
                    ? '${activeController.selectedCount}枚の写真で日記を作成'
                    : '写真を選んでください',
                style: AppTypography.labelLarge,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentDiariesSection(BuildContext context) {
    return Padding(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.book_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: AppSpacing.iconMd,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('最近の日記', style: AppTypography.titleLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          RecentDiariesWidget(
            recentDiaries: widget.recentDiaries,
            isLoading: widget.isLoadingDiaries,
            onDiaryTap: widget.onDiaryTap,
          ),
        ],
      ),
    );
  }

  void _showPromptSelectionModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PromptSelectionModal(
        onPromptSelected: (prompt) {
          Navigator.of(context).pop();
          _navigateToDiaryPreview(context, prompt);
        },
        onSkip: () {
          Navigator.of(context).pop();
          _navigateToDiaryPreview(context, null);
        },
      ),
    );
  }

  void _navigateToDiaryPreview(
    BuildContext context,
    WritingPrompt? selectedPrompt,
  ) {
    final activeController = widget.tabController.index == 0
        ? widget.photoController
        : widget.pastPhotoController;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryPreviewScreen(
          selectedAssets: activeController.selectedPhotos,
          selectedPrompt: selectedPrompt,
        ),
      ),
    ).then((_) {
      widget.onLoadRecentDiaries();
      widget.photoController.clearSelection();
      widget.pastPhotoController.clearSelection();
    });
  }

  /// カメラボタンがタップされた時の処理
  Future<void> _onCameraButtonTapped() async {
    try {
      final photoService = ServiceRegistration.get<IPhotoService>();

      _logger.info(
        'カメラ撮影を開始',
        context: 'HomeContentWidget._onCameraButtonTapped',
      );

      // カメラ権限をチェック
      final permissionResult = await photoService.requestCameraPermission();

      if (permissionResult.isFailure) {
        _logger.error(
          'カメラ権限チェックに失敗',
          context: 'HomeContentWidget._onCameraButtonTapped',
          error: permissionResult.error,
        );

        if (mounted) {
          ErrorDisplayService().showError(context, permissionResult.error);
        }
        return;
      }

      if (!permissionResult.value) {
        // 権限拒否時のダイアログ表示
        if (mounted) {
          await _showCameraPermissionDialog();
        }
        return;
      }

      // カメラで撮影
      final captureResult = await photoService.capturePhoto();

      if (captureResult.isFailure) {
        _logger.error(
          'カメラ撮影に失敗',
          context: 'HomeContentWidget._onCameraButtonTapped',
          error: captureResult.error,
        );

        if (mounted) {
          ErrorDisplayService().showError(context, captureResult.error);
        }
        return;
      }

      final capturedPhoto = captureResult.value;
      if (capturedPhoto != null) {
        // 撮影成功：写真を今日の写真コントローラーに追加
        _logger.info(
          'カメラ撮影成功',
          context: 'HomeContentWidget._onCameraButtonTapped',
          data: 'Asset ID: ${capturedPhoto.id}',
        );

        // 今日の写真リストを再読み込みして新しい写真を含める
        await _refreshTodayPhotos();

        // 撮影した写真を選択状態に追加
        final photoIndex = widget.photoController.photoAssets.indexWhere(
          (asset) => asset.id == capturedPhoto.id,
        );
        if (photoIndex != -1) {
          widget.photoController.toggleSelect(photoIndex);
        }
      } else {
        // キャンセル時
        _logger.info(
          'カメラ撮影をキャンセル',
          context: 'HomeContentWidget._onCameraButtonTapped',
        );
      }
    } catch (e) {
      final appError = ErrorHandler.handleError(e, context: 'カメラ撮影');

      _logger.error(
        'カメラ撮影処理中にエラーが発生',
        context: 'HomeContentWidget._onCameraButtonTapped',
        error: appError,
      );

      if (mounted) {
        ErrorDisplayService().showError(context, appError);
      }
    }
  }

  /// カメラ権限拒否時のダイアログを表示
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
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 設定アプリを開く処理を実装
            },
          ),
        ],
      ),
    );
  }

  /// 今日の写真リストを再読み込み
  Future<void> _refreshTodayPhotos() async {
    try {
      final photoService = ServiceRegistration.get<IPhotoService>();

      // 今日の写真を再取得
      final todayPhotos = await photoService.getTodayPhotos(limit: 50);

      // 写真コントローラーに設定（選択状態はクリアしない）
      final currentSelection = widget.photoController.selectedPhotos.toList();
      widget.photoController.setPhotoAssets(todayPhotos);

      // 以前の選択状態を復元
      for (final selected in currentSelection) {
        final index = todayPhotos.indexWhere(
          (asset) => asset.id == selected.id,
        );
        if (index != -1) {
          widget.photoController.toggleSelect(index);
        }
      }

      _logger.info(
        '今日の写真リストを更新',
        context: 'HomeContentWidget._refreshTodayPhotos',
        data: '写真数: ${todayPhotos.length}',
      );
    } catch (e) {
      _logger.error(
        '今日の写真リスト更新に失敗',
        context: 'HomeContentWidget._refreshTodayPhotos',
        error: e,
      );
    }
  }

  /// Phase 1.7.2.3: 使用量状況表示メソッド
  Future<void> _showUsageStatus(BuildContext context) async {
    try {
      final subscriptionService =
          await ServiceRegistration.getAsync<ISubscriptionService>();

      // 使用量情報を取得
      final statusResult = await subscriptionService.getCurrentStatus();
      final planResult = await subscriptionService.getCurrentPlanClass();
      final remainingResult = await subscriptionService
          .getRemainingGenerations();
      final resetDateResult = await subscriptionService.getNextResetDate();

      if (statusResult.isFailure || planResult.isFailure) {
        // エラー時はフォールバック表示
        if (context.mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => PresetDialogs.error(
              title: '使用状況を取得できませんでした',
              message: 'しばらく時間をおいてから再度お試しください。',
              onConfirm: () => Navigator.of(context).pop(),
            ),
          );
        }
        return;
      }

      final plan = planResult.value;
      final remaining = remainingResult.isSuccess ? remainingResult.value : 0;
      final nextResetDate = resetDateResult.isSuccess
          ? resetDateResult.value
          : DateTime.now().add(const Duration(days: 30));

      final limit = plan.monthlyAiGenerationLimit;
      final used = limit - remaining;

      if (context.mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (context) => PresetDialogs.usageStatus(
            planName: plan.displayName,
            used: used.clamp(0, limit),
            limit: limit,
            remaining: remaining.clamp(0, limit),
            nextResetDate: nextResetDate,
            onUpgrade: plan.displayName == 'Basic'
                ? () {
                    Navigator.of(context).pop();
                    _navigateToUpgrade(context);
                  }
                : null,
            onDismiss: () => Navigator.of(context).pop(),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => PresetDialogs.error(
            title: 'エラーが発生しました',
            message: '使用状況の取得中にエラーが発生しました。',
            onConfirm: () => Navigator.of(context).pop(),
          ),
        );
      }
    }
  }

  /// Phase 1.7.2.4: プラン変更誘導機能
  void _navigateToUpgrade(BuildContext context) {
    // 共通のアップグレードダイアログを表示
    UpgradeDialogUtils.showUpgradeDialog(context);
  }

  /// 現在のプランとアクセス可能日付を読み込み
  Future<void> _loadCurrentPlan() async {
    try {
      final subscriptionService =
          await ServiceRegistration.getAsync<ISubscriptionService>();
      final accessControlService =
          ServiceRegistration.get<IPhotoAccessControlService>();

      final planResult = await subscriptionService.getCurrentPlanClass();

      if (planResult.isFailure) {
        return;
      }

      final plan = planResult.value;
      final accessibleDate = accessControlService.getAccessibleDateForPlan(
        plan,
      );

      if (mounted) {
        setState(() {
          _currentPlan = plan;
          _accessibleDate = accessibleDate;
        });
      }
    } catch (_) {
      // エラーは無視してデフォルト値を使用
    }
  }

  /// 使用済み写真IDを収集して両方のコントローラーに設定
  Future<void> _loadUsedPhotoIds() async {
    try {
      final diaryService = await ServiceRegistration.getAsync<IDiaryService>();
      final allEntries = await diaryService.getSortedDiaryEntries();

      // 使用済み写真IDを収集
      final usedIds = <String>{};
      for (final entry in allEntries) {
        usedIds.addAll(entry.photoIds);
      }

      // 両方のコントローラーに設定
      widget.photoController.setUsedPhotoIds(usedIds);
      widget.pastPhotoController.setUsedPhotoIds(usedIds);
    } catch (_) {
      // エラーは無視してデフォルト値を使用
    }
  }

  Future<void> _loadPastPhotos({DateTime? specificDate}) async {
    if (!mounted) return;

    widget.pastPhotoController.setLoading(true);

    try {
      final photoService = ServiceRegistration.get<IPhotoService>();

      // 権限チェック
      final hasPermission = await photoService.requestPermission();

      if (!mounted) return;

      widget.pastPhotoController.setPermission(hasPermission);

      if (!hasPermission) {
        widget.pastPhotoController.setLoading(false);
        return;
      }

      // 特定日付が指定されている場合はその日付の写真のみを取得
      if (specificDate != null) {
        final startOfDay = DateTime(
          specificDate.year,
          specificDate.month,
          specificDate.day,
        );
        final endOfDay = DateTime(
          specificDate.year,
          specificDate.month,
          specificDate.day,
          23,
          59,
          59,
          999,
        );

        final photos = await photoService.getPhotosInDateRange(
          startDate: startOfDay,
          endDate: endOfDay,
          limit: 200,
        );

        if (!mounted) return;

        // 新しい日付の写真を設定する前に選択をクリア
        widget.pastPhotoController.clearSelection();
        widget.pastPhotoController.setPhotoAssets(photos);
        widget.pastPhotoController.setLoading(false);
        return;
      }

      // カレンダー表示時と同じ範囲の写真を取得（今日は除外）
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // カレンダーウィジェットと同じ範囲を使用
      DateTime startDate;
      if (_currentPlan != null) {
        // プランの過去写真アクセス日数に基づいて開始日を計算
        final daysBack = _currentPlan!.pastPhotoAccessDays;
        startDate = today.subtract(Duration(days: daysBack));
      } else {
        // フォールバック: 昨日の00:00:00から取得
        startDate = today.subtract(const Duration(days: 1));
      }

      // 今日の00:00:00を終了日として設定（今日は除外）
      final endDate = today;

      final photos = await photoService.getPhotosInDateRange(
        startDate: startDate,
        endDate: endDate,
        limit: 200,
      );

      if (!mounted) return;

      // 新しい写真を設定する前に選択をクリア
      widget.pastPhotoController.clearSelection();
      widget.pastPhotoController.setPhotoAssets(photos);
      widget.pastPhotoController.setLoading(false);
    } catch (e) {
      final loggingService = await LoggingService.getInstance();
      final appError = ErrorHandler.handleError(e, context: '過去の写真読み込み');
      loggingService.error(
        '過去の写真読み込みエラー',
        context: 'HomeContentWidget._loadPastPhotos',
        error: appError,
      );

      if (mounted) {
        // エラー時も選択をクリア
        widget.pastPhotoController.clearSelection();
        widget.pastPhotoController.setPhotoAssets([]);
        widget.pastPhotoController.setLoading(false);

        // ユーザーにエラーを通知
        ErrorDisplayService().showError(context, appError);
      }
    }
  }

  Widget _buildAccessRangeInfo() {
    if (_currentPlan == null) {
      return const SizedBox.shrink();
    }

    final isBasic = _currentPlan!.runtimeType.toString().contains('Basic');

    // プレミアムプランの場合は何も表示しない
    if (!isBasic) {
      return const SizedBox.shrink();
    }

    final accessControlService =
        ServiceRegistration.get<IPhotoAccessControlService>();
    final rangeDescription = accessControlService.getAccessRangeDescription(
      _currentPlan!,
    );

    return Row(
      children: [
        // プラン情報バッジ
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: AppSpacing.xs),
              Text(
                rangeDescription,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (isBasic) ...[
          const SizedBox(width: AppSpacing.sm),
          // アップグレードボタン（タップアニメーション付き）
          MicroInteractions.bounceOnTap(
            onTap: () => _navigateToUpgrade(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'アップグレード',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 異なる日付の写真選択時のダイアログ
  /// 表示切り替えウィジェットを構築
  Widget _buildViewToggle() {
    // Basicプランではこの機能を無効化
    final isBasicPlan =
        _currentPlan != null &&
        _currentPlan!.runtimeType.toString().contains('Basic');

    if (isBasicPlan) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 日付表示（タップ可能・アニメーション付き）
        if (!_showAllPastPhotos && _selectedPastDate != null)
          MicroInteractions.bounceOnTap(
            onTap: () {
              setState(() {
                _showAllPastPhotos = true;
                _selectedPastDate = null;
              });
              _loadPastPhotos();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${_selectedPastDate!.year}年${_selectedPastDate!.month}月${_selectedPastDate!.day}日',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          )
        else if (_showAllPastPhotos)
          MicroInteractions.bounceOnTap(
            onTap: () {
              setState(() {
                _isCalendarView = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_library_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'すべての写真',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(width: AppSpacing.sm),
        // カレンダー表示切り替えボタン（アニメーション付き）
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: IconButton(
            key: ValueKey(_isCalendarView),
            onPressed: () {
              setState(() {
                _isCalendarView = !_isCalendarView;
              });
            },
            icon: Icon(
              _isCalendarView
                  ? Icons.grid_view_rounded
                  : Icons.calendar_month_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: _isCalendarView ? 'グリッド表示' : 'カレンダー表示',
          ),
        ),
      ],
    );
  }

  void _showDifferentDateDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        icon: Icons.info_outline_rounded,
        iconColor: AppColors.info,
        title: '同じ日の写真を選んでください',
        message: '過去の写真から日記を作成する場合は、同じ日付の写真のみを選択できます。',
        actions: [
          CustomDialogAction(
            text: 'OK',
            isPrimary: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// タブビューの高さを取得（表示モードに応じて調整）
  double _getTabViewHeight() {
    // 過去タブでカレンダー表示の場合 - 固定高さで上部位置を一定に保つ
    if (widget.tabController.index == 1 && _isCalendarView) {
      return 460.0; // カレンダー表示用の固定高さ（6週間分）
    }
    // 過去タブで写真表示の場合
    else if (widget.tabController.index == 1) {
      return 390.0; // 過去の写真グリッド表示用の高さ
    }
    // 今日タブの場合
    else {
      return 340.0; // 今日の写真グリッド表示用の高さ
    }
  }

  /// 過去の写真キャッシュをクリーンアップ
  void _cleanupPastPhotosCache() async {
    try {
      final cacheService = PhotoCacheService.getInstance();
      // 期限切れエントリーのクリーンアップ
      cacheService.cleanupExpiredEntries();

      final loggingService = await LoggingService.getInstance();
      loggingService.debug(
        '過去タブのキャッシュクリーンアップ実行',
        context: 'HomeContentWidget._cleanupPastPhotosCache',
        data:
            '現在のキャッシュサイズ: ${(cacheService.getCacheSize() / 1024 / 1024).toStringAsFixed(2)}MB',
      );
    } catch (e) {
      // エラーは無視（クリーンアップは必須ではない）
    }
  }
}
