import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../controllers/photo_selection_controller.dart';
import '../models/diary_entry.dart';
import '../screens/diary_preview_screen.dart';
import '../widgets/photo_grid_widget.dart';
import '../widgets/recent_diaries_widget.dart';
import '../widgets/prompt_selection_modal.dart';
import '../models/writing_prompt.dart';
import '../models/plans/plan.dart';
import '../services/interfaces/photo_access_control_service_interface.dart';
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
  // アクセス制御関連
  Plan? _currentPlan;
  DateTime? _accessibleDate;
  bool _isCalendarView = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPlan();
    _loadUsedPhotoIds();
    widget.tabController.addListener(() {
      if (widget.tabController.index == 1 &&
          widget.pastPhotoController.photoAssets.isEmpty) {
        _loadPastPhotos();
      }
    });
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
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        FadeInWidget(
          delay: const Duration(milliseconds: 100),
          child: _buildPhotoSection(context),
        ),
        const SizedBox(height: AppSpacing.md),
        FadeInWidget(
          delay: const Duration(milliseconds: 200),
          child: _buildCreateDiaryButton(context),
        ),
        const SizedBox(height: AppSpacing.xl),
        FadeInWidget(
          delay: const Duration(milliseconds: 300),
          child: _buildRecentDiariesSection(context),
        ),
        const SizedBox(height: AppConstants.bottomNavPadding),
      ],
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
                      Icon(Icons.today_rounded, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Text('今日'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Text('過去の写真'),
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
          SizedBox(
            height: widget.tabController.index == 1 && _isCalendarView
                ? 600
                : 400,
            child: TabBarView(
              controller: widget.tabController,
              children: [_buildTodayPhotosTab(), _buildPastPhotosTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayPhotosTab() {
    return Padding(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          PhotoGridWidget(
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
    return SingleChildScrollView(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          if (_currentPlan != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildAccessRangeInfo()),
                IconButton(
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
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_isCalendarView)
            PastPhotoCalendarWidget(
              currentPlan: _currentPlan,
              accessibleDate: _accessibleDate,
              usedPhotoIds: widget.pastPhotoController.usedPhotoIds,
              onPhotosSelected: (photos) {
                widget.pastPhotoController.setPhotoAssets(photos);
                setState(() {
                  _isCalendarView = false;
                });
              },
            )
          else
            PhotoGridWidget(
              controller: widget.pastPhotoController,
              onSelectionLimitReached: widget.onSelectionLimitReached,
              onUsedPhotoSelected: widget.onUsedPhotoSelected,
              onRequestPermission: _loadPastPhotos,
            ),
        ],
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
      debugPrint('使用量状況取得エラー: $e');
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
          ServiceRegistration.get<PhotoAccessControlServiceInterface>();

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
      final diaryService =
          await ServiceRegistration.getAsync<DiaryServiceInterface>();
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

  Future<void> _loadPastPhotos() async {
    if (!mounted) return;

    widget.pastPhotoController.setLoading(true);

    try {
      final photoService = ServiceRegistration.get<PhotoServiceInterface>();

      // 権限チェック
      final hasPermission = await photoService.requestPermission();

      if (!mounted) return;

      widget.pastPhotoController.setPermission(hasPermission);

      if (!hasPermission) {
        widget.pastPhotoController.setLoading(false);
        return;
      }

      // プランに基づいて過去の写真を取得（今日は除外）
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      DateTime startDate;
      if (_currentPlan != null && _accessibleDate != null) {
        startDate = _accessibleDate!;
      } else {
        // フォールバック: 昨日の00:00:00から取得
        startDate = today.subtract(const Duration(days: 1));
      }

      // 今日の00:00:00を終了日として設定（今日は除外）
      final endDate = today;

      final photos = await photoService.getPhotosInDateRange(
        startDate: startDate,
        endDate: endDate,
        limit: 50,
      );

      if (!mounted) return;

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

    final accessControlService =
        ServiceRegistration.get<PhotoAccessControlServiceInterface>();
    final rangeDescription = accessControlService.getAccessRangeDescription(
      _currentPlan!,
    );

    final isBasic = _currentPlan!.runtimeType.toString().contains('Basic');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isBasic
            ? AppColors.warning.withValues(alpha: 0.1)
            : AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        children: [
          Icon(
            isBasic ? Icons.schedule_rounded : Icons.history_rounded,
            color: isBasic ? AppColors.warning : AppColors.success,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              '${_currentPlan!.displayName}: $rangeDescription',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: isBasic ? AppColors.warning : AppColors.success,
              ),
            ),
          ),
          if (isBasic)
            TextButton(
              onPressed: () => _navigateToUpgrade(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.warning,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
              ),
              child: const Text(
                'アップグレード',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}
