import 'package:flutter/material.dart';
import '../controllers/photo_selection_controller.dart';
import '../models/plans/plan.dart';
import '../models/writing_prompt.dart';
import '../screens/diary_preview_screen.dart';
import '../services/interfaces/diary_service_interface.dart';
import '../services/interfaces/photo_access_control_service_interface.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../core/service_registration.dart';
import '../widgets/photo_grid_widget.dart';
import '../widgets/prompt_selection_modal.dart';
import '../widgets/past_photo_calendar_widget.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/animated_button.dart';
import '../ui/components/custom_dialog.dart';
import '../ui/animations/page_transitions.dart';
import '../utils/prompt_category_utils.dart';
import '../utils/upgrade_dialog_utils.dart';

/// 過去の写真選択画面（タブ付き）
class PastPhotosSelectionScreen extends StatefulWidget {
  final WritingPrompt? selectedPrompt;

  const PastPhotosSelectionScreen({super.key, this.selectedPrompt});

  @override
  State<PastPhotosSelectionScreen> createState() =>
      _PastPhotosSelectionScreenState();
}

class _PastPhotosSelectionScreenState extends State<PastPhotosSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PhotoSelectionController _todayPhotoController;
  late final PhotoSelectionController _pastPhotoController;

  // アクセス制御関連
  Plan? _currentPlan;
  DateTime? _accessibleDate;

  // ビューモード（グリッド or カレンダー）
  bool _isCalendarView = false;

  PhotoSelectionController get activeController =>
      _tabController.index == 0 ? _todayPhotoController : _pastPhotoController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _todayPhotoController = PhotoSelectionController();
    _pastPhotoController = PhotoSelectionController();

    _tabController.addListener(() {
      setState(() {});
    });

    _loadTodayPhotos();
    _loadUsedPhotoIds();
    _loadCurrentPlan();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _todayPhotoController.dispose();
    _pastPhotoController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayPhotos() async {
    if (!mounted) return;

    _todayPhotoController.setLoading(true);

    try {
      final photoService = ServiceRegistration.get<PhotoServiceInterface>();
      final hasPermission = await photoService.requestPermission();

      if (!mounted) return;

      _todayPhotoController.setPermission(hasPermission);

      if (!hasPermission) {
        _todayPhotoController.setLoading(false);
        return;
      }

      final photos = await photoService.getTodayPhotos();

      if (!mounted) return;

      _todayPhotoController.setPhotoAssets(photos);
      _todayPhotoController.setLoading(false);
    } catch (e) {
      debugPrint('写真読み込みエラー: $e');
      if (mounted) {
        _todayPhotoController.setPhotoAssets([]);
        _todayPhotoController.setLoading(false);
      }
    }
  }

  Future<void> _loadPastPhotos() async {
    if (!mounted) return;

    _pastPhotoController.setLoading(true);

    try {
      final photoService = ServiceRegistration.get<PhotoServiceInterface>();

      // 権限チェック
      final hasPermission = await photoService.requestPermission();

      if (!mounted) return;

      _pastPhotoController.setPermission(hasPermission);

      if (!hasPermission) {
        _pastPhotoController.setLoading(false);
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

      _pastPhotoController.setPhotoAssets(photos);
      _pastPhotoController.setLoading(false);
    } catch (e) {
      if (mounted) {
        _pastPhotoController.setPhotoAssets([]);
        _pastPhotoController.setLoading(false);
      }
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
      _todayPhotoController.setUsedPhotoIds(usedIds);
      _pastPhotoController.setUsedPhotoIds(usedIds);
    } catch (_) {
      // エラーは無視してデフォルト値を使用
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('写真を選択'),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.today_rounded), text: '今日'),
            Tab(icon: Icon(Icons.history_rounded), text: '過去の写真'),
          ],
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onPrimary.withValues(alpha: 0.7),
          onTap: (index) {
            if (index == 1 && _pastPhotoController.photoAssets.isEmpty) {
              _loadPastPhotos();
            }
            // タブを切り替えたらカレンダービューをリセット
            if (index == 0) {
              setState(() {
                _isCalendarView = false;
              });
            }
          },
        ),
      ),
      body: Column(
        children: [
          // 選択されたプロンプトの表示（ある場合）
          if (widget.selectedPrompt != null) _buildSelectedPrompt(),

          // タブビュー
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildTodayPhotosTab(), _buildPastPhotosTab()],
            ),
          ),

          // 日記作成ボタン
          _buildCreateDiaryButton(),
        ],
      ),
    );
  }

  Widget _buildSelectedPrompt() {
    final prompt = widget.selectedPrompt!;

    return Container(
      margin: AppSpacing.screenPadding,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: PromptCategoryUtils.getCategoryColor(
          prompt.category,
        ).withValues(alpha: 0.1),
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(
          color: PromptCategoryUtils.getCategoryColor(
            prompt.category,
          ).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: PromptCategoryUtils.getCategoryColor(prompt.category),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Text(
                  PromptCategoryUtils.getCategoryDisplayName(prompt.category),
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.edit_note_rounded,
                color: PromptCategoryUtils.getCategoryColor(prompt.category),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            prompt.text,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          if (prompt.description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              prompt.description!,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodayPhotosTab() {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(icon: Icons.photo_camera_rounded, title: '今日の写真'),
          const SizedBox(height: AppSpacing.lg),
          PhotoGridWidget(
            controller: _todayPhotoController,
            onSelectionLimitReached: _showSelectionLimitModal,
            onUsedPhotoSelected: _showUsedPhotoModal,
            onRequestPermission: _loadTodayPhotos,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildPastPhotosTab() {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(icon: Icons.history_rounded, title: '過去の写真'),
              // ビュー切り替えボタン
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
                  color: AppColors.primary,
                ),
                tooltip: _isCalendarView ? 'グリッド表示' : 'カレンダー表示',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // プランに基づくアクセス範囲の説明
          _buildAccessRangeInfo(),
          const SizedBox(height: AppSpacing.lg),

          // ビューモードに応じて表示を切り替え
          if (_isCalendarView)
            PastPhotoCalendarWidget(
              currentPlan: _currentPlan,
              accessibleDate: _accessibleDate,
              usedPhotoIds: _pastPhotoController.usedPhotoIds,
              onPhotosSelected: (photos) {
                // カレンダーで選択された日付の写真を設定
                _pastPhotoController.setPhotoAssets(photos);

                // 自動的にグリッドビューに切り替え
                setState(() {
                  _isCalendarView = false;
                });
              },
            )
          else
            // 過去の写真グリッド
            PhotoGridWidget(
              controller: _pastPhotoController,
              onSelectionLimitReached: _showSelectionLimitModal,
              onUsedPhotoSelected: _showUsedPhotoModal,
              onRequestPermission: _loadPastPhotos,
            ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: AppSpacing.iconMd),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: AppTypography.titleLarge),
      ],
    );
  }

  Widget _buildAccessRangeInfo() {
    if (_currentPlan == null) {
      // プラン情報がない場合もデバッグメッセージを表示
      return Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: AppSpacing.cardRadius,
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'プラン情報を読み込み中...',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final accessControlService =
        ServiceRegistration.get<PhotoAccessControlServiceInterface>();
    final rangeDescription = accessControlService.getAccessRangeDescription(
      _currentPlan!,
    );

    final isBasic = _currentPlan!.runtimeType.toString().contains('Basic');

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: isBasic
            ? AppColors.warning.withValues(alpha: 0.1)
            : AppColors.success.withValues(alpha: 0.1),
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(
          color: isBasic
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isBasic ? Icons.schedule_rounded : Icons.history_rounded,
            color: isBasic ? AppColors.warning : AppColors.success,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_currentPlan!.displayName} - $rangeDescription',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isBasic ? AppColors.warning : AppColors.success,
                  ),
                ),
                if (isBasic) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'プレミアムプランなら1年前までの写真にアクセス可能',
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isBasic)
            TextButton(
              onPressed: _showAccessDeniedModal,
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

  Widget _buildCreateDiaryButton() {
    return Container(
      padding: AppSpacing.screenPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _todayPhotoController,
            _pastPhotoController,
          ]),
          builder: (context, child) {
            final selectedCount = activeController.selectedCount;

            return AnimatedButton(
              onPressed: selectedCount > 0 ? _showPromptSelectionModal : null,
              width: double.infinity,
              height: AppSpacing.buttonHeightLg,
              backgroundColor: selectedCount > 0
                  ? AppColors.primary
                  : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
              foregroundColor: selectedCount > 0
                  ? Colors.white
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
              shadowColor: selectedCount > 0
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : null,
              elevation: selectedCount > 0 ? AppSpacing.elevationSm : 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selectedCount > 0
                        ? Icons.auto_awesome_rounded
                        : Icons.photo_camera_outlined,
                    size: AppSpacing.iconSm,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    selectedCount > 0
                        ? '$selectedCount枚の写真で日記を作成'
                        : '写真を選んでください',
                    style: AppTypography.labelLarge,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showPromptSelectionModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PromptSelectionModal(
        onPromptSelected: (prompt) {
          Navigator.of(context).pop();
          _navigateToDiaryPreview(prompt);
        },
        onSkip: () {
          Navigator.of(context).pop();
          _navigateToDiaryPreview(null);
        },
      ),
    );
  }

  void _navigateToDiaryPreview(WritingPrompt? selectedPrompt) {
    Navigator.push(
      context,
      DiaryPreviewScreen(
        selectedAssets: activeController.selectedPhotos,
        selectedPrompt: selectedPrompt,
      ).customRoute(),
    ).then((_) {
      if (mounted) {
        // 日記作成後、使用済み写真IDとプラン情報を再読み込みして両方のコントローラーを更新
        _loadUsedPhotoIds();
        _loadCurrentPlan();
        Navigator.pop(context);
      }
    });
  }

  void _showSelectionLimitModal() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => PresetDialogs.error(
        title: '選択枚数の上限',
        message: '一度に選択できる写真は3枚までです。\n他の写真を選択する場合は、先に選択を解除してください。',
        onConfirm: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showUsedPhotoModal() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => PresetDialogs.error(
        title: '使用済み写真',
        message: 'この写真は既に他の日記で使用されています。\n同じ写真を複数の日記で使用することはできません。',
        onConfirm: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showAccessDeniedModal() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => PresetDialogs.confirmation(
        title: 'プレミアムプラン限定',
        message:
            'この写真にアクセスするには\nプレミアムプランが必要です。\n\nプレミアムプランなら1年前までの\n写真から日記を作成できます。',
        confirmText: 'プレミアムを見る',
        cancelText: '閉じる',
        onConfirm: () async {
          Navigator.of(context).pop();
          await UpgradeDialogUtils.showUpgradeDialog(context);
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }
}
