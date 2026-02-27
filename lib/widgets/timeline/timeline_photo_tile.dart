import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../constants/app_constants.dart';
import '../../controllers/photo_selection_controller.dart';
import '../../ui/components/fullscreen_photo_viewer.dart';
import 'timeline_cache_manager.dart';
import 'timeline_constants.dart';
import 'timeline_components.dart';

/// 個別の写真タイルウィジェット
///
/// 写真のサムネイル表示、選択状態、ロック状態、使用済み状態を管理し、
/// タップ・長押しのインタラクションを処理する。
class TimelinePhotoTile extends StatelessWidget {
  final PhotoSelectionController controller;
  final AssetEntity photo;
  final int mainIndex;
  final DateTime? selectedDate;
  final TimelineCacheManager cacheManager;
  final VoidCallback? onSelectionLimitReached;
  final VoidCallback? onUsedPhotoSelected;
  final Function(String photoId)? onUsedPhotoDetail;
  final VoidCallback? onDifferentDateSelected;
  final VoidCallback? onLockedPhotoTapped;

  const TimelinePhotoTile({
    super.key,
    required this.controller,
    required this.photo,
    required this.mainIndex,
    required this.selectedDate,
    required this.cacheManager,
    this.onSelectionLimitReached,
    this.onUsedPhotoSelected,
    this.onUsedPhotoDetail,
    this.onDifferentDateSelected,
    this.onLockedPhotoTapped,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = mainIndex >= 0 && mainIndex < controller.selected.length
        ? controller.selected[mainIndex]
        : false;
    final isUsed = mainIndex >= 0 ? controller.isPhotoUsed(mainIndex) : false;
    final isLocked = controller.isPhotoLocked(photo);

    final shouldDim =
        !isLocked &&
        _shouldDimPhoto(isSelected: isSelected, selectedDate: selectedDate);

    final heroTag = 'asset-${photo.id}';
    final thumbnail = TimelinePhotoThumbnail(
      photo: photo,
      future: cacheManager.getThumbnailFuture(photo),
      thumbnailSize: TimelineLayoutConstants.thumbnailSize,
      thumbnailQuality: TimelineLayoutConstants.thumbnailQuality,
      borderRadius: TimelineLayoutConstants.borderRadius,
      strokeWidth: TimelineLayoutConstants.loadingIndicatorStrokeWidth,
      key: ValueKey(photo.id),
    );

    return GestureDetector(
      onTap: isLocked
          ? () => onLockedPhotoTapped?.call()
          : () => _handlePhotoTap(mainIndex),
      onLongPress: isLocked
          ? () => onLockedPhotoTapped?.call()
          : () => _handlePhotoLongPress(context, heroTag, isUsed),
      child: Stack(
        children: [
          AnimatedOpacity(
            opacity: shouldDim ? 0.6 : 1.0,
            duration: const Duration(
              milliseconds: TimelineLayoutConstants.animationDurationMs,
            ),
            curve: Curves.easeInOut,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.all(
                  Radius.circular(TimelineLayoutConstants.borderRadius),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(TimelineLayoutConstants.borderRadius),
                ),
                child: Hero(
                  tag: heroTag,
                  child: isLocked
                      ? ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: TimelineLayoutConstants.lockedBlurSigma,
                            sigmaY: TimelineLayoutConstants.lockedBlurSigma,
                          ),
                          child: thumbnail,
                        )
                      : thumbnail,
                ),
              ),
            ),
          ),
          if (isLocked)
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(
                    TimelineLayoutConstants.lockedIconPadding,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: TimelineLayoutConstants.lockedIconSize,
                  ),
                ),
              ),
            ),
          if (!isLocked)
            Positioned(
              top: TimelineLayoutConstants.selectionIndicatorTop,
              right: TimelineLayoutConstants.selectionIndicatorRight,
              child: TimelineSelectionIndicator(
                isSelected: isSelected,
                isUsed: isUsed,
                shouldDimPhoto: shouldDim,
                primaryColor: Theme.of(context).colorScheme.primary,
                indicatorSize: TimelineLayoutConstants.selectionIndicatorSize,
                iconSize: TimelineLayoutConstants.selectionIconSize,
                borderWidth: TimelineLayoutConstants.selectionBorderWidth,
              ),
            ),
          if (isUsed && !isLocked)
            const TimelineUsedLabel(
              bottom: TimelineLayoutConstants.usedLabelBottom,
              left: TimelineLayoutConstants.usedLabelLeft,
              horizontalPadding:
                  TimelineLayoutConstants.usedLabelHorizontalPadding,
              verticalPadding: TimelineLayoutConstants.usedLabelVerticalPadding,
              borderRadius: TimelineLayoutConstants.borderRadius,
            ),
        ],
      ),
    );
  }

  /// 写真タップ時の処理
  void _handlePhotoTap(int mainIndex) {
    if (mainIndex < 0 || mainIndex >= controller.selected.length) return;

    if (controller.isPhotoUsed(mainIndex)) {
      onUsedPhotoSelected?.call();
      return;
    }

    final wasSelected = controller.selected[mainIndex];

    if (wasSelected) {
      controller.toggleSelect(mainIndex);
      return;
    }

    if (!controller.canSelectPhoto(mainIndex)) {
      if (controller.selectedCount >= AppConstants.maxPhotosSelection) {
        onSelectionLimitReached?.call();
        return;
      }
      onDifferentDateSelected?.call();
      return;
    }

    controller.toggleSelect(mainIndex);
  }

  /// 写真長押し時の処理（使用済み/未使用で分岐）
  void _handlePhotoLongPress(
    BuildContext context,
    String heroTag,
    bool isUsed,
  ) {
    if (isUsed && onUsedPhotoDetail != null) {
      onUsedPhotoDetail!(photo.id);
    } else {
      FullscreenPhotoViewer.show(context, asset: photo, heroTag: heroTag);
    }
  }

  /// 写真を薄く表示するかどうかを判定
  bool _shouldDimPhoto({
    required bool isSelected,
    required DateTime? selectedDate,
  }) {
    if (isSelected) return false;
    if (selectedDate == null) return false;
    if (controller.selectedCount >= AppConstants.maxPhotosSelection) {
      return true;
    }
    return !_isSameDateAsPhoto(selectedDate);
  }

  /// 指定日付が写真と同じ日付かどうかを判定
  bool _isSameDateAsPhoto(DateTime date) {
    final photoDate = photo.createDateTime;
    return date.year == photoDate.year &&
        date.month == photoDate.month &&
        date.day == photoDate.day;
  }
}
