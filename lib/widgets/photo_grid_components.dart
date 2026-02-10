import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../localization/localization_extensions.dart';
import '../controllers/photo_selection_controller.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/animated_button.dart';
import '../ui/components/loading_shimmer.dart';

// ---------------------------------------------------------------------------
// Shared layout helpers for PhotoGridWidget and OptimizedPhotoGridWidget
// ---------------------------------------------------------------------------

/// 写真グリッドの共通レイアウト計算ヘルパー
class PhotoGridLayout {
  PhotoGridLayout._();

  /// 画面の向きに関係なく3カラムで統一
  static int getCrossAxisCount() {
    return AppConstants.photoGridCrossAxisCount;
  }

  /// グリッドの最大幅を計算（縦向きと同じ配置を維持）
  static double getMaxGridWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;

    if (orientation == Orientation.landscape) {
      return screenHeight * 0.9;
    }

    return screenWidth;
  }

  /// グリッドの高さを動的に計算（縦横で同じアイテムサイズを維持）
  static double getGridHeight(
    BuildContext context, {
    required int crossAxisCount,
    int rowCount = 3,
  }) {
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
    final totalHeight = rowHeight * rowCount + AppSpacing.sm * (rowCount - 1);

    return totalHeight;
  }

  /// グリッドのデリゲートを生成
  static SliverGridDelegateWithFixedCrossAxisCount gridDelegate({
    required int crossAxisCount,
  }) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.0,
    );
  }

  /// アクセシビリティ用のセマンティックラベルを構築
  static String buildSemanticLabel(
    BuildContext context, {
    required int index,
    required bool isUsed,
    required bool isSelected,
  }) {
    final l10n = context.l10n;
    final separator = l10n.localeName.startsWith('ja') ? '、' : ', ';
    final parts = <String>[l10n.photoSemanticIndex(index + 1)];
    if (isUsed) {
      parts.add(l10n.photoUsedLabel);
    }
    parts.add(
      isSelected ? l10n.photoSemanticSelected : l10n.photoSemanticNotSelected,
    );
    return parts.join(separator);
  }
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

/// 写真選択インジケーター（チェックマーク円形アイコン）
class PhotoGridSelectionIndicator extends StatelessWidget {
  final bool isUsed;
  final bool isSelected;

  const PhotoGridSelectionIndicator({
    super.key,
    required this.isUsed,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
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
        child: _buildIcon(),
      ),
    );
  }

  Widget _buildIcon() {
    if (isUsed) {
      return Icon(Icons.done_rounded, color: AppColors.warning, size: 18);
    }
    return Icon(
      isSelected
          ? Icons.check_circle_rounded
          : Icons.radio_button_unchecked_rounded,
      color: isSelected ? AppColors.success : AppColors.onSurfaceVariant,
      size: 18,
    );
  }
}

/// 「使用済み」ラベル
class PhotoGridUsedLabel extends StatelessWidget {
  const PhotoGridUsedLabel({super.key});

  @override
  Widget build(BuildContext context) {
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
}

/// 写真アクセス権限リクエスト表示
class PhotoGridPermissionRequest extends StatelessWidget {
  final VoidCallback? onRequestPermission;

  const PhotoGridPermissionRequest({super.key, this.onRequestPermission});

  @override
  Widget build(BuildContext context) {
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
}

/// 写真がない場合の空状態表示
class PhotoGridEmptyState extends StatelessWidget {
  const PhotoGridEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
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
}

/// 選択カウンター表示
class PhotoGridSelectionCounter extends StatelessWidget {
  final int selectedCount;

  const PhotoGridSelectionCounter({super.key, required this.selectedCount});

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;
    final theme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: hasSelection ? theme.primaryContainer : theme.surfaceVariant,
        borderRadius: AppSpacing.chipRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_library_rounded,
            size: AppSpacing.iconSm,
            color: hasSelection ? theme.primary : theme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            context.l10n.photoSelectionStatus(
              selectedCount,
              AppConstants.maxPhotosSelection,
            ),
            style: AppTypography.withColor(
              AppTypography.labelMedium,
              hasSelection ? theme.onPrimaryContainer : theme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// ローディング中のシマーグリッド
class PhotoGridShimmer extends StatelessWidget {
  final int crossAxisCount;
  final double height;

  const PhotoGridShimmer({
    super.key,
    required this.crossAxisCount,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: PhotoGridLayout.gridDelegate(
          crossAxisCount: crossAxisCount,
        ),
        itemCount: 9,
        itemBuilder: (context, index) => const CardShimmer(),
      ),
    );
  }
}

/// サムネイル読み込み中のプレースホルダー
class PhotoThumbnailPlaceholder extends StatelessWidget {
  const PhotoThumbnailPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
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
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
    );
  }
}

/// 写真アイテムの共通ラッパー（セマンティクス、タップ、アニメーション、選択UI）
class PhotoGridItemWrapper extends StatelessWidget {
  final int index;
  final bool isSelected;
  final bool isUsed;
  final VoidCallback onTap;
  final Widget thumbnail;

  const PhotoGridItemWrapper({
    super.key,
    required this.index,
    required this.isSelected,
    required this.isUsed,
    required this.onTap,
    required this.thumbnail,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = PhotoGridLayout.buildSemanticLabel(
      context,
      index: index,
      isUsed: isUsed,
      isSelected: isSelected,
    );

    return RepaintBoundary(
      child: Semantics(
        label: semanticLabel,
        button: true,
        selected: isSelected,
        enabled: !isUsed,
        onTap: isUsed ? null : onTap,
        child: GestureDetector(
          onTap: onTap,
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
                thumbnail,
                PhotoGridSelectionIndicator(
                  isUsed: isUsed,
                  isSelected: isSelected,
                ),
                if (isUsed) const PhotoGridUsedLabel(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 写真タップ時の共通ハンドリングロジック
///
/// [controller] を使って選択状態を判定し、適切なコールバックを呼ぶ。
void handlePhotoTap({
  required int index,
  required PhotoSelectionController controller,
  VoidCallback? onUsedPhotoSelected,
  VoidCallback? onSelectionLimitReached,
  VoidCallback? onDifferentDateSelected,
}) {
  if (controller.isPhotoUsed(index)) {
    onUsedPhotoSelected?.call();
    return;
  }

  final wasSelected = controller.selected[index];

  if (wasSelected) {
    controller.toggleSelect(index);
    return;
  }

  if (!controller.canSelectPhoto(index)) {
    if (controller.selectedCount >= AppConstants.maxPhotosSelection) {
      onSelectionLimitReached?.call();
      return;
    }

    if (onDifferentDateSelected != null) {
      onDifferentDateSelected();
    }
    return;
  }

  controller.toggleSelect(index);
}
