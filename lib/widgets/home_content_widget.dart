import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../controllers/photo_selection_controller.dart';
import '../models/diary_entry.dart';
import '../screens/diary_preview_screen.dart';
import '../widgets/photo_grid_widget.dart';
import '../widgets/recent_diaries_widget.dart';

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
      padding: const EdgeInsets.only(
        top: AppConstants.headerTopPadding,
        bottom: AppConstants.headerBottomPadding,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppConstants.headerGradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Text(
            AppConstants.appTitle,
            style: TextStyle(
              fontSize: AppConstants.titleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            '${DateTime.now().year}年${DateTime.now().month}月${DateTime.now().day}日',
            style: const TextStyle(
              fontSize: AppConstants.subtitleFontSize,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: ThemeConstants.defaultScreenPadding,
        children: [
          PhotoGridWidget(
            controller: photoController,
            onSelectionLimitReached: onSelectionLimitReached,
            onUsedPhotoSelected: onUsedPhotoSelected,
            onRequestPermission: onRequestPermission,
          ),
          const SizedBox(height: AppConstants.smallPadding),
          _buildCreateDiaryButton(context),
          const SizedBox(height: AppConstants.largePadding),
          RecentDiariesWidget(
            recentDiaries: recentDiaries,
            isLoading: isLoadingDiaries,
            onDiaryTap: onDiaryTap,
          ),
          const SizedBox(height: AppConstants.bottomNavPadding),
        ],
      ),
    );
  }

  Widget _buildCreateDiaryButton(BuildContext context) {
    return ListenableBuilder(
      listenable: photoController,
      builder: (context, child) {
        return ElevatedButton(
          onPressed: photoController.selectedCount > 0
              ? () => _navigateToDiaryPreview(context)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            minimumSize: const Size.fromHeight(AppConstants.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ThemeConstants.borderRadius),
            ),
          ),
          child: Text('✨ ${photoController.selectedCount}枚の写真で日記を作成'),
        );
      },
    );
  }

  void _navigateToDiaryPreview(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryPreviewScreen(
          selectedAssets: photoController.selectedPhotos,
        ),
      ),
    ).then((_) {
      onLoadRecentDiaries();
      photoController.clearSelection();
    });
  }
}