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

  // Phase 6.1: スクロール監視用コントローラー追加
  late final ScrollController _scrollController;

  // Phase 6.2: スクロール位置監視とグループ特定用の状態変数
  int _currentVisibleGroupIndex = 0;
  final List<double> _groupHeights = [];
  final List<double> _groupOffsets = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScrollChanged); // Phase 6.2: スクロールリスナー追加
    widget.controller.addListener(_onControllerChanged);
    _updatePhotoGroups();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _scrollController.removeListener(
      _onScrollChanged,
    ); // Phase 6.2: スクロールリスナー削除
    _scrollController.dispose();
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
      // Phase 6.2: グループ更新時に高さとオフセットを再計算
      _calculateGroupBoundaries();
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

    // Phase 6.1-6.3: ListView.builder → CustomScrollView + SliverList + スティッキーヘッダー
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Phase 6.3: スティッキーヘッダーを最初に追加
        // プルトゥリフレッシュ中（スクロール位置が負の値）の場合は表示しない
        if (_photoGroups.isNotEmpty &&
            _currentVisibleGroup != null &&
            _scrollController.hasClients &&
            _scrollController.offset >= 0)
          SliverPersistentHeader(
            pinned: true, // 画面上部に固定
            delegate: _StickyDateHeaderDelegate(
              currentGroup: _currentVisibleGroup,
              context: context,
            ),
          ),

        // 既存のSliverList（通常の日付ヘッダー + 写真グリッド）
        SliverList.builder(
          itemCount: _photoGroups.length,
          itemBuilder: (context, index) {
            final group = _photoGroups[index];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 日付ヘッダー（既存と同じスタイルを保持）
                Container(
                  height: 48.0,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
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

                // 写真グリッド表示（既存の実装を保持）
                _buildPhotoGridForGroup(group, selectedDate),

                const SizedBox(height: AppSpacing.md),
              ],
            );
          },
        ),
      ],
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
            crossAxisCount: 4,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
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
            final shouldDimPhoto = _shouldDimPhoto(
              photo: photo,
              selectedDate: selectedDate,
              isSelected: isSelected,
            );

            return GestureDetector(
              onTap: () => _handlePhotoTap(mainIndex),
              child: Stack(
                children: [
                  Opacity(
                    opacity: shouldDimPhoto ? 0.6 : 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Stack(
                        children: [
                          // 写真表示
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
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
                                      borderRadius: BorderRadius.circular(4),
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
                        ],
                      ),
                    ),
                  ),
                  // 選択インジケーター（薄化の対象外）
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isSelected || isUsed
                            ? Colors.white
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: !isSelected && !isUsed && !shouldDimPhoto
                            ? Border.all(
                                color: Colors.white.withOpacity(0.7),
                                width: 2,
                              )
                            : null,
                        boxShadow: shouldDimPhoto
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: (isSelected || isUsed)
                          ? Icon(
                              isUsed ? Icons.done : Icons.check_circle,
                              size: 19,
                              color: isUsed
                                  ? Colors.orange
                                  : Theme.of(context).colorScheme.primary,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  // 使用済みラベル（薄化の対象外）
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
      // 使用済み写真はタップしても何もしない（視覚的なラベルで十分）
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
      // 選択上限に達している場合はダイアログを表示せず、何もしない
      if (widget.controller.selectedCount >= AppConstants.maxPhotosSelection) {
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

  /// 写真を薄く表示するかどうかを判定
  bool _shouldDimPhoto({
    required AssetEntity photo,
    required DateTime? selectedDate,
    required bool isSelected,
  }) {
    // 選択済みの写真は薄くしない
    if (isSelected) return false;

    // 選択がない場合は薄くしない
    if (selectedDate == null) return false;

    // 3枚選択済みの場合は、未選択の写真をすべて薄くする
    if (widget.controller.selectedCount >= 3) return true;

    // そうでなければ、異なる日付の写真のみ薄くする
    return !_isSameDateAsPhoto(selectedDate, photo);
  }

  // ======== Phase 6.2: スクロール位置監視とグループ特定システム ========

  /// 各グループの高さとオフセット位置を計算
  void _calculateGroupBoundaries() {
    _groupHeights.clear();
    _groupOffsets.clear();

    double currentOffset = 0.0;

    for (int i = 0; i < _photoGroups.length; i++) {
      final group = _photoGroups[i];

      // グループの高さを計算
      final groupHeight = _calculateSingleGroupHeight(group);

      _groupOffsets.add(currentOffset);
      _groupHeights.add(groupHeight);

      currentOffset += groupHeight;
    }
  }

  /// 単一グループの高さを計算
  double _calculateSingleGroupHeight(TimelinePhotoGroup group) {
    const double headerHeight = 48.0; // 日付ヘッダーの固定高さ
    const double bottomSpacing = 16.0; // AppSpacing.md = 16.0

    if (group.photos.isEmpty) {
      return headerHeight + 100.0 + bottomSpacing; // 空状態表示の高さ
    }

    // 写真グリッドの高さを計算
    const int crossAxisCount = 4; // グリッドの列数
    const double mainAxisSpacing = 2.0;
    const double childAspectRatio = 1.0; // 正方形

    final int photoCount = group.photos.length;
    final int rowCount = (photoCount / crossAxisCount).ceil();

    // GridViewの高さ計算（shrinkWrap: trueの場合）
    // 各行の高さ = セル幅（画面幅に基づく） + mainAxisSpacing
    // 実際のセル幅は実行時に決まるため、ここでは近似値を使用
    const double approximateCellWidth = 80.0; // 近似値（実際は画面幅/4）
    const double cellHeight = approximateCellWidth / childAspectRatio;

    final double gridHeight =
        rowCount * cellHeight + (rowCount - 1) * mainAxisSpacing;

    return headerHeight + gridHeight + bottomSpacing;
  }

  /// スクロールイベント処理
  void _onScrollChanged() {
    if (_photoGroups.isEmpty || _groupOffsets.isEmpty) return;

    final double scrollOffset = _scrollController.offset;
    final int newVisibleGroupIndex = _findVisibleGroupIndex(scrollOffset);

    if (newVisibleGroupIndex != _currentVisibleGroupIndex) {
      if (mounted) {
        setState(() {
          _currentVisibleGroupIndex = newVisibleGroupIndex;
        });
      }
    }
  }

  /// スクロール位置から現在表示中のグループインデックスを特定
  int _findVisibleGroupIndex(double scrollOffset) {
    const double headerHeight = 48.0; // 日付ヘッダーの固定高さ

    // 各グループの開始位置と比較して、現在のスクロール位置がどのグループにあるかを判定
    // スティッキーヘッダーの切り替わりタイミングを調整するため、ヘッダー高さ分のオフセットを追加
    for (int i = 0; i < _groupOffsets.length; i++) {
      final groupStart = _groupOffsets[i] + headerHeight;
      final groupEnd = groupStart + _groupHeights[i];

      // スクロール位置がこのグループの範囲内にある場合
      if (scrollOffset >= groupStart && scrollOffset < groupEnd) {
        return i;
      }
    }

    // 最下部までスクロールした場合は最後のグループ
    return (_photoGroups.length - 1).clamp(0, _photoGroups.length - 1);
  }

  /// 現在表示中のグループを取得（Phase 6.3で使用）
  TimelinePhotoGroup? get _currentVisibleGroup {
    if (_photoGroups.isEmpty ||
        _currentVisibleGroupIndex >= _photoGroups.length) {
      return null;
    }
    return _photoGroups[_currentVisibleGroupIndex];
  }
}

// ======== Phase 6.3: スティッキーヘッダーデリゲート実装 ========

/// スティッキー日付ヘッダー用のカスタムデリゲート
class _StickyDateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TimelinePhotoGroup? currentGroup;
  final BuildContext context;

  const _StickyDateHeaderDelegate({
    required this.currentGroup,
    required this.context,
  });

  @override
  double get minExtent => 48.0; // 日付ヘッダーの固定高さ

  @override
  double get maxExtent => 48.0; // 日付ヘッダーの固定高さ

  @override
  bool shouldRebuild(covariant _StickyDateHeaderDelegate oldDelegate) {
    // グループが変更された場合のみリビルド
    return currentGroup != oldDelegate.currentGroup;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // 現在のグループが存在しない場合は空コンテナ
    if (currentGroup == null) {
      return const SizedBox.shrink();
    }

    // 既存の日付ヘッダーと同じスタイルを適用
    return Container(
      height: 48.0,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        // スティッキーヘッダーとして識別しやすくするため、軽い影を追加
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          currentGroup!.displayName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }
}
