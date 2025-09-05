import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/timeline_photo_group.dart';
import '../services/timeline_grouping_service.dart';
import '../controllers/photo_selection_controller.dart';
import '../ui/design_system/app_spacing.dart';
import '../constants/app_constants.dart';

/// タイムライン表示用の写真ウィジェット
class TimelinePhotoWidget extends StatefulWidget {
  /// 写真選択コントローラー
  final PhotoSelectionController controller;

  /// 選択上限到達時のコールバック
  final VoidCallback? onSelectionLimitReached;

  /// 使用済み写真選択時のコールバック
  final VoidCallback? onUsedPhotoSelected;

  /// 権限要求コールバック
  final VoidCallback? onRequestPermission;

  /// 異なる日付選択時のコールバック
  final VoidCallback? onDifferentDateSelected;

  /// カメラ撮影コールバック
  final VoidCallback? onCameraPressed;

  /// スマートFAB表示制御
  final bool showFAB;

  const TimelinePhotoWidget({
    super.key,
    required this.controller,
    this.onSelectionLimitReached,
    this.onUsedPhotoSelected,
    this.onRequestPermission,
    this.onDifferentDateSelected,
    this.onCameraPressed,
    this.showFAB = true,
  });

  @override
  State<TimelinePhotoWidget> createState() => _TimelinePhotoWidgetState();
}

class _TimelinePhotoWidgetState extends State<TimelinePhotoWidget> {
  final TimelineGroupingService _groupingService = TimelineGroupingService();
  List<TimelinePhotoGroup> _photoGroups = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _updatePhotoGroups();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    _updatePhotoGroups();
  }

  void _updatePhotoGroups() {
    final groups = _groupingService.groupPhotosForTimeline(
      widget.controller.photoAssets,
    );

    if (mounted) {
      setState(() {
        _photoGroups = groups;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        if (widget.controller.isLoading) {
          return _buildLoadingState();
        }

        if (!widget.controller.hasPermission) {
          return _buildPermissionDeniedState();
        }

        if (_photoGroups.isEmpty) {
          return _buildEmptyState();
        }
        return _buildTimelineContent();
      },
    );
  }

  /// タイムラインコンテンツを構築
  Widget _buildTimelineContent() {
    final selectedDate = _groupingService.getSelectedDate(
      widget.controller.selectedPhotos,
    );

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _photoGroups.length,
      itemBuilder: (context, index) {
        final group = _photoGroups[index];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日付ヘッダー
            Container(
              height: 48.0,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.95),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  group.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ),

            // 写真グリッド表示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _buildPhotoGridForGroup(group, selectedDate),
            ),

            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }

  /// グループ用の写真グリッドを構築
  Widget _buildPhotoGridForGroup(
    TimelinePhotoGroup group,
    DateTime? selectedDate,
  ) {
    if (group.photos.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text('写真がありません', style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemCount: group.photos.length,
          itemBuilder: (context, index) {
            final photo = group.photos[index];

            // メインコントローラーから該当する写真のインデックスと選択状態を取得
            final mainIndex = widget.controller.photoAssets.indexOf(photo);
            final isSelected =
                mainIndex >= 0 && mainIndex < widget.controller.selected.length
                ? widget.controller.selected[mainIndex]
                : false;
            final isUsed = mainIndex >= 0
                ? widget.controller.isPhotoUsed(mainIndex)
                : false;

            // 個別写真レベルでの薄化制御
            final shouldDimPhoto =
                selectedDate != null &&
                !_isSameDateAsPhoto(selectedDate, photo);

            return GestureDetector(
              onTap: () => _handlePhotoTap(mainIndex),
              child: Opacity(
                opacity: shouldDimPhoto ? 0.3 : 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 3,
                          )
                        : null,
                  ),
                  child: Stack(
                    children: [
                      // 写真表示
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FutureBuilder(
                          future: photo.thumbnailData,
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return SizedBox(
                                width: double.infinity,
                                height: double.infinity,
                                child: Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                ),
                              );
                            } else {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),

                      // 選択インジケーター
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isUsed
                                ? Icons.done
                                : isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 16,
                            color: isUsed
                                ? Colors.orange
                                : isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                        ),
                      ),

                      // 使用済みラベル
                      if (isUsed)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '使用済み',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// ローディング状態を構築
  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  /// 権限拒否状態を構築
  Widget _buildPermissionDeniedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '写真へのアクセス許可が必要です',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (widget.onRequestPermission != null)
            TextButton(
              onPressed: widget.onRequestPermission,
              child: const Text('許可する'),
            ),
        ],
      ),
    );
  }

  /// 空状態を構築
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '写真がありません',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 写真タップ時の処理
  void _handlePhotoTap(int mainIndex) {
    if (mainIndex < 0) return;

    if (widget.controller.isPhotoUsed(mainIndex)) {
      widget.onUsedPhotoSelected?.call();
      return;
    }

    // 現在の選択状態を保存
    final wasSelected = widget.controller.selected[mainIndex];

    // 選択解除の場合は制限チェック不要
    if (wasSelected) {
      widget.controller.toggleSelect(mainIndex);
      return;
    }

    // 選択可能かチェック
    if (!widget.controller.canSelectPhoto(mainIndex)) {
      // 選択上限に達している場合
      if (widget.controller.selectedCount >= AppConstants.maxPhotosSelection) {
        widget.onSelectionLimitReached?.call();
        return;
      }

      // 日付が異なる場合のチェック
      if (widget.onDifferentDateSelected != null) {
        widget.onDifferentDateSelected!();
      }
      return;
    }

    widget.controller.toggleSelect(mainIndex);
  }

  /// 指定日付が写真と同じ日付かどうかを判定
  bool _isSameDateAsPhoto(DateTime date, AssetEntity photo) {
    final photoDate = photo.createDateTime;
    return date.year == photoDate.year &&
        date.month == photoDate.month &&
        date.day == photoDate.day;
  }
}
