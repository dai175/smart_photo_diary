import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../controllers/photo_selection_controller.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../core/service_registration.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/animated_button.dart';
import '../ui/components/loading_shimmer.dart';

/// 写真グリッド表示ウィジェット
class PhotoGridWidget extends StatelessWidget {
  final PhotoSelectionController controller;
  final VoidCallback? onSelectionLimitReached;
  final VoidCallback? onUsedPhotoSelected;
  final VoidCallback? onRequestPermission;

  const PhotoGridWidget({
    super.key,
    required this.controller,
    this.onSelectionLimitReached,
    this.onUsedPhotoSelected,
    this.onRequestPermission,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return Column(
          children: [
            _buildPhotoGrid(context),
            const SizedBox(height: AppSpacing.md),
            _buildSelectionCounter(context),
          ],
        );
      },
    );
  }

  Widget _buildPhotoGrid(BuildContext context) {
    if (controller.isLoading) {
      return SizedBox(
        height: AppConstants.photoGridHeight,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: AppConstants.photoGridCrossAxisCount,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          itemCount: 6,
          itemBuilder: (context, index) => const CardShimmer(),
        ),
      );
    }

    if (!controller.hasPermission) {
      return SizedBox(
        height: AppConstants.photoGridHeight,
        child: _buildPermissionRequest(),
      );
    }

    if (controller.photoAssets.isEmpty) {
      return SizedBox(
        height: AppConstants.photoGridHeight,
        child: _buildEmptyState(context),
      );
    }

    return SizedBox(height: AppConstants.photoGridHeight, child: _buildGrid());
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: AppSpacing.cardRadius,
            ),
            child: Icon(
              Icons.photo_camera_outlined,
              size: AppSpacing.iconLg,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppConstants.permissionMessage,
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            onPressed: onRequestPermission,
            text: AppConstants.requestPermissionButton,
            icon: Icons.settings_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: AppSpacing.cardRadius,
            ),
            child: Icon(
              Icons.photo_library_outlined,
              size: AppSpacing.iconLg,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppConstants.noPhotosMessage,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppConstants.photoGridCrossAxisCount,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: controller.photoAssets.length,
      itemBuilder: (context, index) => _buildPhotoItem(index),
    );
  }

  Widget _buildPhotoItem(int index) {
    final isSelected = controller.selected[index];
    final isUsed = controller.isPhotoUsed(index);

    // アクセシビリティ用のラベル作成
    String semanticLabel = '写真 ${index + 1}';
    if (isUsed) {
      semanticLabel += '、使用済み';
    }
    if (isSelected) {
      semanticLabel += '、選択中';
    } else {
      semanticLabel += '、未選択';
    }

    return RepaintBoundary(
      child: Semantics(
        label: semanticLabel,
        button: true,
        selected: isSelected,
        enabled: !isUsed,
        onTap: isUsed ? null : () => _handlePhotoTap(index),
        child: GestureDetector(
          onTap: () => _handlePhotoTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: AppSpacing.photoRadius,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildPhotoThumbnail(index),
                _buildSelectionIndicator(index),
                if (isUsed) _buildUsedLabel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(int index) {
    return ClipRRect(
      borderRadius: AppSpacing.photoRadius,
      child: FutureBuilder<dynamic>(
        future: ServiceRegistration.get<PhotoServiceInterface>().getThumbnail(
          controller.photoAssets[index],
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return RepaintBoundary(
              child: Image.memory(
                snapshot.data!,
                height: AppConstants.photoThumbnailSize,
                width: AppConstants.photoThumbnailSize,
                fit: BoxFit.cover,
                cacheHeight:
                    (AppConstants.photoThumbnailSize *
                            MediaQuery.of(context).devicePixelRatio)
                        .round(),
                cacheWidth:
                    (AppConstants.photoThumbnailSize *
                            MediaQuery.of(context).devicePixelRatio)
                        .round(),
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
              ),
            );
          } else {
            return Container(
              height: AppConstants.photoThumbnailSize,
              width: AppConstants.photoThumbnailSize,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppSpacing.photoRadius,
              ),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSelectionIndicator(int index) {
    return Positioned(
      top: AppSpacing.xs,
      right: AppSpacing.xs,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: _getSelectionIcon(index),
      ),
    );
  }

  Widget _getSelectionIcon(int index) {
    if (controller.isPhotoUsed(index)) {
      return Icon(Icons.done_rounded, color: AppColors.warning, size: 18);
    } else {
      return Icon(
        controller.selected[index]
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: controller.selected[index]
            ? AppColors.success
            : AppColors.onSurfaceVariant,
        size: 18,
      );
    }
  }

  Widget _buildUsedLabel() {
    return Positioned(
      bottom: AppSpacing.xs,
      left: AppSpacing.xs,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppSpacing.xs),
        ),
        child: Text(
          AppConstants.usedPhotoLabel,
          style: AppTypography.withColor(
            AppTypography.labelSmall,
            Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCounter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: controller.selectedCount > 0
            ? AppColors.primaryContainer
            : AppColors.surfaceVariant,
        borderRadius: AppSpacing.chipRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_library_rounded,
            size: AppSpacing.iconSm,
            color: controller.selectedCount > 0
                ? AppColors.primary
                : AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '選択された写真: ${controller.selectedCount}/${AppConstants.maxPhotosSelection}枚',
            style: AppTypography.withColor(
              AppTypography.labelMedium,
              controller.selectedCount > 0
                  ? AppColors.onPrimaryContainer
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _handlePhotoTap(int index) {
    if (controller.isPhotoUsed(index)) {
      onUsedPhotoSelected?.call();
      return;
    }

    if (!controller.canSelectPhoto(index)) {
      onSelectionLimitReached?.call();
      return;
    }

    controller.toggleSelect(index);
  }
}
