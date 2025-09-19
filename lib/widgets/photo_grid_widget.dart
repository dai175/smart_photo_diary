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
import '../localization/localization_extensions.dart';

/// 写真グリッド表示ウィジェット
class PhotoGridWidget extends StatelessWidget {
  final PhotoSelectionController controller;
  final VoidCallback? onSelectionLimitReached;
  final VoidCallback? onUsedPhotoSelected;
  final VoidCallback? onRequestPermission;
  final VoidCallback? onDifferentDateSelected;

  const PhotoGridWidget({
    super.key,
    required this.controller,
    this.onSelectionLimitReached,
    this.onUsedPhotoSelected,
    this.onRequestPermission,
    this.onDifferentDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildPhotoGrid(context),
            const SizedBox(height: AppSpacing.sm),
            Center(child: _buildSelectionCounter(context)),
          ],
        );
      },
    );
  }

  Widget _buildPhotoGrid(BuildContext context) {
    final crossAxisCount = _getCrossAxisCount(context);
    final gridHeight = _getGridHeight(context, crossAxisCount);

    if (controller.isLoading) {
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
          itemCount: 9,
          itemBuilder: (context, index) => const CardShimmer(),
        ),
      );
    }

    if (!controller.hasPermission) {
      return SizedBox(
        height: gridHeight,
        child: _buildPermissionRequest(context),
      );
    }

    if (controller.photoAssets.isEmpty) {
      return SizedBox(height: gridHeight, child: _buildEmptyState(context));
    }

    return SizedBox(height: gridHeight, child: _buildGrid(context));
  }

  Widget _buildPermissionRequest(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
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
          context.l10n.photoPermissionMessage,
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          onPressed: onRequestPermission,
          text: context.l10n.photoRequestPermission,
          icon: Icons.camera_alt,
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
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
            context.l10n.photoNoPhotosMessage,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final crossAxisCount = _getCrossAxisCount(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _getMaxGridWidth(context)),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.0,
          ),
          itemCount: controller.photoAssets.length,
          itemBuilder: (context, index) => _buildPhotoItem(context, index),
        ),
      ),
    );
  }

  /// グリッドの最大幅を計算（縦向きと同じ配置を維持）
  double _getMaxGridWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;

    // 横向き時は縦向きの幅に相当するサイズに制限
    if (orientation == Orientation.landscape) {
      return screenHeight * 0.9; // 少し余裕を持たせる
    }

    return screenWidth;
  }

  Widget _buildPhotoItem(BuildContext context, int index) {
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
                if (isUsed) _buildUsedLabel(context),
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
        future: ServiceRegistration.get<IPhotoService>().getThumbnail(
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

  Widget _buildUsedLabel(BuildContext context) {
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
          context.l10n.photoUsedLabel,
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
            context.l10n.photoSelectionStatus(
              controller.selectedCount,
              AppConstants.maxPhotosSelection,
            ),
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

    // 現在の選択状態を保存
    final wasSelected = controller.selected[index];

    // 選択解除の場合は制限チェック不要
    if (wasSelected) {
      controller.toggleSelect(index);
      return;
    }

    // 選択可能かチェック
    if (!controller.canSelectPhoto(index)) {
      // 選択上限に達している場合
      if (controller.selectedCount >= 5) {
        onSelectionLimitReached?.call();
      }
      // 日付が異なる場合（日付制限が有効かつ選択済み写真がある場合）
      else if (onDifferentDateSelected != null) {
        onDifferentDateSelected!();
      }
      return;
    }

    controller.toggleSelect(index);
  }

  /// 画面の向きに関係なく3カラムで統一
  int _getCrossAxisCount(BuildContext context) {
    // 縦向き・横向き問わず3カラムで統一して、写真の位置関係を保持
    return AppConstants.photoGridCrossAxisCount;
  }

  /// グリッドの高さを動的に計算（縦横で同じアイテムサイズを維持）
  double _getGridHeight(BuildContext context, int crossAxisCount) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;

    final padding =
        AppSpacing.screenPadding.horizontal + AppSpacing.cardPadding.horizontal;

    // 縦向きと横向きで同じアイテムサイズを維持するために、
    // より小さい画面幅を基準にアイテムサイズを計算
    final baseWidth = orientation == Orientation.landscape
        ? screenHeight // 横向き時は縦向きの幅（screenHeight）を基準に
        : screenWidth; // 縦向き時はそのまま

    final availableWidth = baseWidth - padding;
    final spacing = AppSpacing.sm * (crossAxisCount - 1);
    final itemWidth = (availableWidth - spacing) / crossAxisCount;

    // アイテムのアスペクト比を1:1として、3行分の高さを計算
    final rowHeight = itemWidth;
    final totalHeight = rowHeight * 3 + AppSpacing.sm * 2; // 3行 + 間のスペース

    return totalHeight;
  }
}
