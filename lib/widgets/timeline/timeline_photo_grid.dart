import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../constants/app_constants.dart';
import '../../controllers/photo_selection_controller.dart';
import '../../localization/localization_extensions.dart';
import '../../models/timeline_photo_group.dart';
import '../../ui/component_constants.dart';
import 'timeline_cache_manager.dart';
import 'timeline_components.dart';
import 'timeline_constants.dart';

/// タイムラインの写真グリッドウィジェット
///
/// グループ単位の写真グリッド表示、タップ/ロングプレス処理、
/// 薄化判定ロジックを担当する。
class TimelinePhotoGrid extends StatelessWidget {
  const TimelinePhotoGrid({
    super.key,
    required this.group,
    required this.selectedDate,
    required this.isLastGroup,
    required this.hasMorePhotos,
    required this.placeholderPages,
    required this.controller,
    required this.cacheManager,
    this.onDifferentDateSelected,
    this.onUsedPhotoDetail,
  });

  /// 表示対象のフォトグループ
  final TimelinePhotoGroup group;

  /// 選択中の日付（薄化判定用）
  final DateTime? selectedDate;

  /// 末尾グループかどうか（スケルトン表示判定用）
  final bool isLastGroup;

  /// 追加写真があるかどうか
  final bool hasMorePhotos;

  /// スケルトンページ数
  final int placeholderPages;

  /// 写真選択コントローラー
  final PhotoSelectionController controller;

  /// キャッシュマネージャー
  final TimelineCacheManager cacheManager;

  /// 異なる日付選択時のコールバック
  final VoidCallback? onDifferentDateSelected;

  /// 使用済み写真詳細表示コールバック
  final Function(String photoId)? onUsedPhotoDetail;

  @override
  Widget build(BuildContext context) {
    if (group.photos.isEmpty) {
      return SizedBox(
        height: TimelineLayoutConstants.emptyStateHeight,
        child: Center(
          child: Text(
            context.l10n.photoNoPhotosMessage,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    // スケルトンは「末尾グループ かつ まだ追加がある場合」にのみ表示
    final bool showPlaceholders =
        isLastGroup && hasMorePhotos && placeholderPages > 0;
    final int placeholderRows = AppConstants.timelinePlaceholderRows;
    final int placeholderCountPerPage =
        TimelineLayoutConstants.crossAxisCount * placeholderRows;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: TimelineLayoutConstants.crossAxisCount,
        crossAxisSpacing: TimelineLayoutConstants.crossAxisSpacing,
        mainAxisSpacing: TimelineLayoutConstants.mainAxisSpacing,
        childAspectRatio: TimelineLayoutConstants.childAspectRatio,
      ),
      itemCount:
          group.photos.length +
          (showPlaceholders ? (placeholderCountPerPage * placeholderPages) : 0),
      itemBuilder: (context, index) {
        // プレースホルダー領域
        if (index >= group.photos.length) {
          return const TimelineSkeletonTile(
            borderRadius: TimelineLayoutConstants.borderRadius,
            strokeWidth: TimelineLayoutConstants.loadingIndicatorStrokeWidth,
            indicatorSize: TimelineLayoutConstants.loadingIndicatorSize,
          );
        }

        final photo = group.photos[index];

        // キャッシュを使用してメインインデックスを高速取得
        final mainIndex = cacheManager.photoIndexCache[photo.id] ?? -1;
        final isSelected =
            mainIndex >= 0 && mainIndex < controller.selected.length
            ? controller.selected[mainIndex]
            : false;
        final isUsed = mainIndex >= 0
            ? controller.isPhotoUsed(mainIndex)
            : false;

        // キャッシュを使用した薄化判定（パフォーマンス最適化）
        final shouldDimPhoto = _shouldDimPhoto(
          photo: photo,
          isSelected: isSelected,
        );

        final heroTag = 'asset-${photo.id}';
        return GestureDetector(
          onTap: () => _handlePhotoTap(mainIndex),
          onLongPress: () =>
              _handlePhotoLongPress(context, photo, heroTag, isUsed),
          child: Stack(
            children: [
              // アニメーション最適化: AnimatedOpacityでスムーズな薄化切替
              AnimatedOpacity(
                opacity: shouldDimPhoto ? 0.6 : 1.0,
                duration: const Duration(
                  milliseconds: TimelineLayoutConstants.animationDurationMs,
                ),
                curve: Curves.easeInOut,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0E0E0), // 固定値でパフォーマンス最適化
                    borderRadius: BorderRadius.all(
                      Radius.circular(TimelineLayoutConstants.borderRadius),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(TimelineLayoutConstants.borderRadius),
                    ),
                    child: Hero(
                      tag: heroTag,
                      child: TimelinePhotoThumbnail(
                        photo: photo,
                        future: cacheManager.getThumbnailFuture(photo),
                        thumbnailSize: TimelineLayoutConstants.thumbnailSize,
                        thumbnailQuality:
                            TimelineLayoutConstants.thumbnailQuality,
                        borderRadius: TimelineLayoutConstants.borderRadius,
                        strokeWidth:
                            TimelineLayoutConstants.loadingIndicatorStrokeWidth,
                        key: ValueKey(photo.id), // キーでWidgetの再利用を促進
                      ),
                    ),
                  ),
                ),
              ),
              // パフォーマンス最適化された選択インジケーター
              Positioned(
                top: TimelineLayoutConstants.selectionIndicatorTop,
                right: TimelineLayoutConstants.selectionIndicatorRight,
                child: TimelineSelectionIndicator(
                  isSelected: isSelected,
                  isUsed: isUsed,
                  shouldDimPhoto: shouldDimPhoto,
                  primaryColor: Theme.of(context).colorScheme.primary,
                  indicatorSize: TimelineLayoutConstants.selectionIndicatorSize,
                  iconSize: TimelineLayoutConstants.selectionIconSize,
                  borderWidth: TimelineLayoutConstants.selectionBorderWidth,
                ),
              ),
              // パフォーマンス最適化された使用済みラベル
              if (isUsed)
                const TimelineUsedLabel(
                  bottom: TimelineLayoutConstants.usedLabelBottom,
                  left: TimelineLayoutConstants.usedLabelLeft,
                  horizontalPadding:
                      TimelineLayoutConstants.usedLabelHorizontalPadding,
                  verticalPadding:
                      TimelineLayoutConstants.usedLabelVerticalPadding,
                  borderRadius: TimelineLayoutConstants.borderRadius,
                ),
            ],
          ),
        );
      },
    );
  }

  /// 写真タップ時の処理
  void _handlePhotoTap(int mainIndex) {
    if (mainIndex < 0) return;

    if (controller.isPhotoUsed(mainIndex)) {
      // 使用済み写真はタップしても何もしない（視覚的なラベルで十分）
      return;
    }

    // 現在の選択状態を保存
    final wasSelected = controller.selected[mainIndex];

    // 選択解除の場合は制限チェック不要
    if (wasSelected) {
      controller.toggleSelect(mainIndex);
      return;
    }

    // 選択可能かチェック
    if (!controller.canSelectPhoto(mainIndex)) {
      // 選択上限に達している場合はダイアログを表示せず、何もしない
      if (controller.selectedCount >= AppConstants.maxPhotosSelection) {
        return;
      }

      // 日付が異なる場合のチェック
      onDifferentDateSelected?.call();
      return;
    }

    controller.toggleSelect(mainIndex);
  }

  /// 写真長押し時の処理（使用済み/未使用で分岐）
  void _handlePhotoLongPress(
    BuildContext context,
    AssetEntity photo,
    String heroTag,
    bool isUsed,
  ) {
    if (isUsed && onUsedPhotoDetail != null) {
      // 使用済み写真の場合は日記詳細に遷移
      onUsedPhotoDetail!(photo.id);
    } else {
      // 未使用写真の場合は拡大表示
      _showPhotoPreview(context, photo, heroTag);
    }
  }

  /// 長押しで拡大プレビューを表示
  void _showPhotoPreview(BuildContext context, AssetEntity asset, String tag) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: context.l10n.commonClose,
      barrierColor: Colors.black.withValues(alpha: AppConstants.opacityHigh),
      transitionDuration: AppConstants.defaultAnimationDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        return GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Hero(
              tag: tag,
              child: FutureBuilder<Uint8List?>(
                future: cacheManager.getLargePreviewFuture(asset),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: PhotoPreviewConstants.progressStrokeWidth,
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const SizedBox.shrink();
                  }
                  return InteractiveViewer(
                    minScale: ViewerConstants.minScale,
                    maxScale: ViewerConstants.maxScale,
                    child: Image.memory(snapshot.data!, fit: BoxFit.contain),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// 写真を薄く表示するかどうかを判定
  bool _shouldDimPhoto({required AssetEntity photo, required bool isSelected}) {
    // 選択済みの写真は薄くしない
    if (isSelected) return false;

    // 選択がない場合は薄くしない
    if (selectedDate == null) return false;

    // 3枚選択済みの場合は、未選択の写真をすべて薄くする
    if (controller.selectedCount >= 3) return true;

    // そうでなければ、異なる日付の写真のみ薄くする
    return !_isSameDateAsPhoto(selectedDate!, photo);
  }

  /// 指定日付が写真と同じ日付かどうかを判定
  bool _isSameDateAsPhoto(DateTime date, AssetEntity photo) {
    final photoDate = photo.createDateTime;
    return date.year == photoDate.year &&
        date.month == photoDate.month &&
        date.day == photoDate.day;
  }
}
