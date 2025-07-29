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

/// 過去の写真グリッド表示ウィジェット（日付ヘッダー付き）
class PastPhotoGridWidget extends StatelessWidget {
  final PhotoSelectionController controller;
  final VoidCallback? onSelectionLimitReached;
  final VoidCallback? onUsedPhotoSelected;
  final VoidCallback? onAccessDenied;
  final VoidCallback? onRequestPermission;
  final List<PhotoDateGroup>? photoGroups;

  const PastPhotoGridWidget({
    super.key,
    required this.controller,
    this.onSelectionLimitReached,
    this.onUsedPhotoSelected,
    this.onAccessDenied,
    this.onRequestPermission,
    this.photoGroups,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return Column(
          children: [
            _buildPhotoContent(context),
            const SizedBox(height: AppSpacing.md),
            _buildSelectionCounter(context),
          ],
        );
      },
    );
  }

  Widget _buildPhotoContent(BuildContext context) {
    if (controller.isLoading) {
      return _buildLoadingState(context);
    }

    if (!controller.hasPermission) {
      return _buildPermissionRequest();
    }

    if (photoGroups?.isEmpty ?? true) {
      return _buildEmptyState(context);
    }

    return _buildGroupedPhotoGrid(context);
  }

  Widget _buildLoadingState(BuildContext context) {
    final crossAxisCount = _getCrossAxisCount(context);
    final gridHeight = _getGridHeight(context, crossAxisCount);

    return SizedBox(
      height: gridHeight,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.0,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => const CardShimmer(),
      ),
    );
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
            icon: Icons.camera_alt,
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
              Icons.history_rounded,
              size: AppSpacing.iconLg,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '過去の写真がありません',
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'プレミアムプランで\n1年前までの写真にアクセスできます',
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedPhotoGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: photoGroups!
          .map((group) => _buildPhotoGroup(context, group))
          .toList(),
    );
  }

  Widget _buildPhotoGroup(BuildContext context, PhotoDateGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateHeader(context, group),
        const SizedBox(height: AppSpacing.md),
        _buildPhotosGrid(context, group),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildDateHeader(BuildContext context, PhotoDateGroup group) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: AppSpacing.chipRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: AppSpacing.iconSm,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _formatDateHeader(group.date),
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (!group.isAccessible) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(AppSpacing.xs),
              ),
              child: Text(
                'Premium',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotosGrid(BuildContext context, PhotoDateGroup group) {
    final crossAxisCount = _getCrossAxisCount(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.0,
      ),
      itemCount: group.photos.length,
      itemBuilder: (context, index) =>
          _buildPhotoItem(group.photos[index], group.isAccessible),
    );
  }

  Widget _buildPhotoItem(PhotoItem photo, bool isAccessible) {
    final isSelected = photo.isSelected;
    final isUsed = photo.isUsed;

    // アクセシビリティ用のラベル作成
    String semanticLabel = '写真';
    if (!isAccessible) {
      semanticLabel += '、Premium限定';
    } else if (isUsed) {
      semanticLabel += '、使用済み';
    } else if (isSelected) {
      semanticLabel += '、選択中';
    } else {
      semanticLabel += '、未選択';
    }

    return RepaintBoundary(
      child: Semantics(
        label: semanticLabel,
        button: true,
        selected: isSelected,
        enabled: isAccessible && !isUsed,
        onTap: (!isAccessible || isUsed) ? null : () => _handlePhotoTap(photo),
        child: GestureDetector(
          onTap: () => _handlePhotoTap(photo),
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
                _buildPhotoThumbnail(photo, isAccessible),
                _buildSelectionIndicator(photo, isAccessible),
                if (!isAccessible) _buildLockOverlay(),
                if (isUsed && isAccessible) _buildUsedLabel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(PhotoItem photo, bool isAccessible) {
    return ClipRRect(
      borderRadius: AppSpacing.photoRadius,
      child: FutureBuilder<dynamic>(
        future: ServiceRegistration.get<PhotoServiceInterface>().getThumbnail(
          photo.asset,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            Widget imageWidget = RepaintBoundary(
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

            // アクセスできない場合はグレーアウト
            if (!isAccessible) {
              imageWidget = ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.grey.withValues(alpha: 0.7),
                  BlendMode.saturation,
                ),
                child: imageWidget,
              );
            }

            return imageWidget;
          } else {
            return Container(
              height: AppConstants.photoThumbnailSize,
              width: AppConstants.photoThumbnailSize,
              decoration: BoxDecoration(
                color: isAccessible
                    ? AppColors.surfaceVariant
                    : AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: AppSpacing.photoRadius,
              ),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isAccessible
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.5),
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

  Widget _buildSelectionIndicator(PhotoItem photo, bool isAccessible) {
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
        child: _getSelectionIcon(photo, isAccessible),
      ),
    );
  }

  Widget _getSelectionIcon(PhotoItem photo, bool isAccessible) {
    if (!isAccessible) {
      return Icon(Icons.lock, color: AppColors.warning, size: 18);
    } else if (photo.isUsed) {
      return Icon(Icons.done_rounded, color: AppColors.warning, size: 18);
    } else {
      return Icon(
        photo.isSelected
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: photo.isSelected
            ? AppColors.success
            : AppColors.onSurfaceVariant,
        size: 18,
      );
    }
  }

  Widget _buildLockOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: AppSpacing.photoRadius,
        ),
      ),
    );
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

  void _handlePhotoTap(PhotoItem photo) {
    if (!photo.isAccessible) {
      onAccessDenied?.call();
      return;
    }

    if (photo.isUsed) {
      onUsedPhotoSelected?.call();
      return;
    }

    // TODO: 写真選択ロジックをPhotoSelectionControllerに実装
    // controller.toggleSelectPhoto(photo);
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(targetDate).inDays;

    if (difference == 1) {
      return '昨日';
    } else if (difference < 7) {
      return '$difference日前';
    } else if (difference < 30) {
      return '${(difference / 7).floor()}週間前';
    } else {
      return '${date.year}年${date.month}月${date.day}日';
    }
  }

  int _getCrossAxisCount(BuildContext context) {
    return AppConstants.photoGridCrossAxisCount;
  }

  double _getGridHeight(BuildContext context, int crossAxisCount) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;

    final padding =
        AppSpacing.screenPadding.horizontal + AppSpacing.cardPadding.horizontal;

    final baseWidth = orientation == Orientation.landscape
        ? screenHeight
        : screenWidth;

    final availableWidth = baseWidth - padding;
    final spacing = AppSpacing.sm * (crossAxisCount - 1);
    final itemWidth = (availableWidth - spacing) / crossAxisCount;

    final rowHeight = itemWidth;
    final totalHeight = rowHeight * 2 + AppSpacing.sm;

    return totalHeight;
  }
}

/// 日付ごとの写真グループ
class PhotoDateGroup {
  final DateTime date;
  final List<PhotoItem> photos;
  final bool isAccessible;

  const PhotoDateGroup({
    required this.date,
    required this.photos,
    required this.isAccessible,
  });
}

/// 写真アイテム
class PhotoItem {
  final dynamic asset; // AssetEntity
  final bool isSelected;
  final bool isUsed;
  final bool isAccessible;

  const PhotoItem({
    required this.asset,
    required this.isSelected,
    required this.isUsed,
    required this.isAccessible,
  });

  PhotoItem copyWith({
    dynamic asset,
    bool? isSelected,
    bool? isUsed,
    bool? isAccessible,
  }) {
    return PhotoItem(
      asset: asset ?? this.asset,
      isSelected: isSelected ?? this.isSelected,
      isUsed: isUsed ?? this.isUsed,
      isAccessible: isAccessible ?? this.isAccessible,
    );
  }
}
