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

class HomeContentWidget extends StatelessWidget {
  final PhotoSelectionController photoController;
  final List<DiaryEntry> recentDiaries;
  final bool isLoadingDiaries;
  final VoidCallback onRequestPermission;
  final VoidCallback onLoadRecentDiaries;
  final VoidCallback onSelectionLimitReached;
  final VoidCallback onUsedPhotoSelected;
  final Function(String) onDiaryTap;

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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildMainContent(context),
      ],
    );
  }
  
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: AppConstants.headerTopPadding,
        bottom: AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: AppSpacing.cardRadius,
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: AppColors.onPrimaryContainer,
                size: AppSpacing.iconMd,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '${DateTime.now().year}年${DateTime.now().month}月${DateTime.now().day}日',
                style: AppTypography.withColor(
                  AppTypography.headlineSmall,
                  AppColors.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Expanded(
      child: ListView(
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
      ),
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
                style: AppTypography.headlineSmall,
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
                style: AppTypography.headlineSmall,
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