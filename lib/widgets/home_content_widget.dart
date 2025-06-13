import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../controllers/photo_selection_controller.dart';
import '../models/diary_entry.dart';
import '../screens/diary_preview_screen.dart';
import '../widgets/photo_grid_widget.dart';
import '../widgets/recent_diaries_widget.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/animated_button.dart';
import '../ui/animations/page_transitions.dart';
import '../ui/animations/list_animations.dart';
import '../ui/animations/micro_interactions.dart';

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
      appBar: _buildHeader(),
      body: onRefresh != null
          ? MicroInteractions.pullToRefresh(
              onRefresh: onRefresh!,
              color: AppColors.primary,
              child: _buildMainContent(context),
            )
          : _buildMainContent(context),
    );
  }
  
  PreferredSizeWidget _buildHeader() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text('${DateTime.now().year}年${DateTime.now().month}月${DateTime.now().day}日'),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      actions: onRefresh != null
          ? [
              Container(
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                child: IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => onRefresh!(),
                  tooltip: 'ホーム画面を更新',
                ),
              ),
            ]
          : null,
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
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppSpacing.cardRadiusLarge,
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_camera_rounded,
                color: AppColors.primary,
                size: AppSpacing.iconMd,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '今日の写真',
                style: AppTypography.titleLarge,
              ),
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
        return AnimatedButton(
          onPressed: photoController.selectedCount > 0
              ? () => _navigateToDiaryPreview(context)
              : null,
          width: double.infinity,
          height: AppSpacing.buttonHeightLg,
          backgroundColor: photoController.selectedCount > 0 
              ? AppColors.primary 
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          foregroundColor: photoController.selectedCount > 0 
              ? Colors.white 
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          shadowColor: photoController.selectedCount > 0 
              ? AppColors.primary.withValues(alpha: 0.3) 
              : null,
          elevation: photoController.selectedCount > 0 ? AppSpacing.elevationSm : 0,
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
                    : '写真を選択してください',
                style: AppTypography.labelLarge,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentDiariesSection(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppSpacing.cardRadiusLarge,
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.book_rounded,
                color: AppColors.primary,
                size: AppSpacing.iconMd,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '最近の日記',
                style: AppTypography.titleLarge,
              ),
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

  void _navigateToDiaryPreview(BuildContext context) {
    Navigator.push(
      context,
      DiaryPreviewScreen(
        selectedAssets: photoController.selectedPhotos,
      ).customRoute(),
    ).then((_) {
      onLoadRecentDiaries();
      photoController.clearSelection();
    });
  }
}