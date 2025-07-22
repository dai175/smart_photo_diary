import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../controllers/photo_selection_controller.dart';
import '../models/diary_entry.dart';
import '../screens/diary_preview_screen.dart';
import '../widgets/photo_grid_widget.dart';
import '../widgets/recent_diaries_widget.dart';
import '../widgets/prompt_selection_modal.dart';
import '../models/writing_prompt.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/animated_button.dart';
import '../ui/components/custom_dialog.dart';
import '../ui/animations/list_animations.dart';
import '../ui/animations/micro_interactions.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../core/service_registration.dart';
import '../utils/upgrade_dialog_utils.dart';

class HomeContentWidget extends StatelessWidget {
  final PhotoSelectionController photoController;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildHeader(context),
      body: onRefresh != null
          ? MicroInteractions.pullToRefresh(
              onRefresh: onRefresh!,
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
    return Padding(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_camera_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: AppSpacing.iconMd,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('今日の写真', style: AppTypography.titleLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          PhotoGridWidget(
            controller: photoController,
            onSelectionLimitReached: onSelectionLimitReached,
            onUsedPhotoSelected: onUsedPhotoSelected,
            onRequestPermission: onRequestPermission,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateDiaryButton(BuildContext context) {
    return ListenableBuilder(
      listenable: photoController,
      builder: (context, child) {
        final theme = Theme.of(context);
        return AnimatedButton(
          onPressed: photoController.selectedCount > 0
              ? () => _showPromptSelectionModal(context)
              : null,
          width: double.infinity,
          height: AppSpacing.buttonHeightLg,
          backgroundColor: photoController.selectedCount > 0
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          foregroundColor: photoController.selectedCount > 0
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          shadowColor: photoController.selectedCount > 0
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : null,
          elevation: photoController.selectedCount > 0
              ? AppSpacing.elevationSm
              : 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                photoController.selectedCount > 0
                    ? Icons.auto_awesome_rounded
                    : Icons.photo_camera_outlined,
                size: AppSpacing.iconSm,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                photoController.selectedCount > 0
                    ? '${photoController.selectedCount}枚の写真で日記を作成'
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
            recentDiaries: recentDiaries,
            isLoading: isLoadingDiaries,
            onDiaryTap: onDiaryTap,
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryPreviewScreen(
          selectedAssets: photoController.selectedPhotos,
          selectedPrompt: selectedPrompt,
        ),
      ),
    ).then((_) {
      onLoadRecentDiaries();
      photoController.clearSelection();
    });
  }

  /// Phase 1.7.2.3: 使用量状況表示メソッド
  Future<void> _showUsageStatus(BuildContext context) async {
    try {
      final subscriptionService =
          await ServiceRegistration.getAsync<ISubscriptionService>();

      // 使用量情報を取得
      final statusResult = await subscriptionService.getCurrentStatus();
      final planResult = await subscriptionService.getCurrentPlan();
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
}
