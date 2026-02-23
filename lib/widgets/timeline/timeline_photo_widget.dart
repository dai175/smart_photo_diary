import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../constants/app_constants.dart';
import '../../controllers/photo_selection_controller.dart';
import '../../controllers/scroll_signal.dart';
import '../../core/service_locator.dart';
import '../../localization/localization_extensions.dart';
import '../../ui/components/fullscreen_photo_viewer.dart';
import '../../models/timeline_photo_group.dart';
import '../../services/interfaces/logging_service_interface.dart';
import '../../services/timeline_grouping_service.dart';
import '../../ui/design_system/app_spacing.dart';
import 'timeline_cache_manager.dart';
import 'timeline_constants.dart';
import 'timeline_components.dart';
import 'timeline_scroll_manager.dart';

/// タイムライン表示用の写真ウィジェット
///
/// ホーム画面タブ統合後のメインコンポーネント。
/// - 日付別グルーピング（今日/昨日/月単位）
/// - スティッキーヘッダー付きスクロール表示
/// - 写真選択・薄化表示機能
/// - パフォーマンス最適化（SliverGridによる遅延構築）
class TimelinePhotoWidget extends StatefulWidget {
  /// 写真選択コントローラー
  final PhotoSelectionController controller;

  /// 選択上限到達時のコールバック
  final VoidCallback? onSelectionLimitReached;

  /// 使用済み写真選択時のコールバック
  final VoidCallback? onUsedPhotoSelected;

  /// 使用済み写真詳細表示コールバック
  final Function(String photoId)? onUsedPhotoDetail;

  /// 権限要求コールバック
  final VoidCallback? onRequestPermission;

  /// 異なる日付選択時のコールバック
  final VoidCallback? onDifferentDateSelected;

  /// ロック写真タップ時のコールバック
  final VoidCallback? onLockedPhotoTapped;

  /// カメラ撮影コールバック
  final VoidCallback? onCameraPressed;

  /// スマートFAB表示制御
  final bool showFAB;

  /// 追加写真読み込み要求コールバック
  final VoidCallback? onLoadMorePhotos;

  /// バックグラウンド先読み要求コールバック
  final VoidCallback? onPreloadMorePhotos;

  /// 外部から先頭へスクロールさせるためのシグナル
  final ScrollSignal? scrollSignal;

  const TimelinePhotoWidget({
    super.key,
    required this.controller,
    this.onSelectionLimitReached,
    this.onUsedPhotoSelected,
    this.onUsedPhotoDetail,
    this.onRequestPermission,
    this.onDifferentDateSelected,
    this.onLockedPhotoTapped,
    this.onCameraPressed,
    this.onLoadMorePhotos,
    this.onPreloadMorePhotos,
    this.showFAB = true,
    this.scrollSignal,
  });

  @override
  State<TimelinePhotoWidget> createState() => _TimelinePhotoWidgetState();
}

class _TimelinePhotoWidgetState extends State<TimelinePhotoWidget> {
  final TimelineGroupingService _groupingService = TimelineGroupingService();
  final ScrollController _scrollController = ScrollController();
  List<TimelinePhotoGroup> _photoGroups = [];
  Map<DateTime, bool> _groupFullyLockedCache = {};

  // ログサービス
  ILoggingService get _logger => serviceLocator.get<ILoggingService>();

  // ヘルパーインスタンス
  late final TimelineCacheManager _cacheManager = TimelineCacheManager();

  late final TimelineScrollManager _scrollManager = TimelineScrollManager(
    scrollController: _scrollController,
    logger: _logger,
    updateState: (fn) {
      if (mounted) setState(fn);
    },
    isMounted: () => mounted,
  );

  @override
  void initState() {
    super.initState();

    // スクロールマネージャーのコールバック設定
    _scrollManager.onLoadMorePhotos = widget.onLoadMorePhotos;
    _scrollManager.onPreloadMorePhotos = widget.onPreloadMorePhotos;
    _scrollManager.onViewportPrefetch = _scheduleViewportPrefetch;
    _scrollManager.hasMorePhotos = () => widget.controller.hasMorePhotos;
    _scrollManager.photoCount = () => widget.controller.photoAssets.length;
    _scrollManager.totalItemCount = () => _totalItemCount();
    _scrollManager.viewportWidth = () => MediaQuery.sizeOf(context).width;

    widget.controller.addListener(_onControllerChanged);
    _scrollController.addListener(_scrollManager.onScroll);
    // 再タップ等のスクロール指示に対応
    widget.scrollSignal?.addListener(_scrollManager.scrollToTop);
    _updatePhotoGroups();

    // 初期ビューポート分を軽くプリフェッチ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleViewportPrefetch();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cacheManager.dispose();
    widget.controller.removeListener(_onControllerChanged);
    widget.scrollSignal?.removeListener(_scrollManager.scrollToTop);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TimelinePhotoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollSignal != widget.scrollSignal) {
      oldWidget.scrollSignal?.removeListener(_scrollManager.scrollToTop);
      widget.scrollSignal?.addListener(_scrollManager.scrollToTop);
    }
    // コールバックの更新
    _scrollManager.onLoadMorePhotos = widget.onLoadMorePhotos;
    _scrollManager.onPreloadMorePhotos = widget.onPreloadMorePhotos;
    _scrollManager.hasMorePhotos = () => widget.controller.hasMorePhotos;
    _scrollManager.photoCount = () => widget.controller.photoAssets.length;
    _scrollManager.totalItemCount = () => _totalItemCount();
    _scrollManager.viewportWidth = () => MediaQuery.sizeOf(context).width;
  }

  /// ビューポート先読みをキャッシュマネージャーに委譲
  void _scheduleViewportPrefetch() {
    _cacheManager.scheduleViewportPrefetch(
      scrollController: _scrollController,
      isMounted: () => mounted,
      getAssets: () => widget.controller.photoAssets,
    );
  }

  void _onControllerChanged() {
    // UI更新を次のフレームに延期（キャッシュ準備完了を待つ）
    Future.microtask(() {
      if (mounted) {
        _updatePhotoGroups();
      }
    });

    // 追加読み込み完了チェック
    _scrollManager.onLoadMoreCompleted();
  }

  void _updatePhotoGroups() {
    // initState時は基本的なグルーピングのみ実行（多言語化なし）
    final groups = _groupingService.groupPhotosForTimeline(
      widget.controller.photoAssets,
    );

    // インデックスキャッシュを先に完全に再構築してからUI更新
    _cacheManager.rebuildPhotoIndexCache(widget.controller.photoAssets);

    // サムネイルFutureキャッシュの簡易クリーンアップ（非表示アセットを間引く）
    final visibleIds = groups.expand((g) => g.photos).map((a) => a.id).toSet();
    _cacheManager.pruneThumbFutureCache(visibleIds);

    // グループごとの全ロック判定をキャッシュ
    final lockedCache = <DateTime, bool>{};
    for (final group in groups) {
      lockedCache[group.groupDate] =
          group.photos.isNotEmpty &&
          group.photos.every((photo) => widget.controller.isPhotoLocked(photo));
    }

    if (mounted) {
      // キャッシュ再構築完了後に安全にUI更新
      setState(() {
        _photoGroups = groups;
        _groupFullyLockedCache = lockedCache;
        final currentCount = widget.controller.photoAssets.length;
        if (currentCount > _scrollManager.lastAssetsCount) {
          _scrollManager.handlePhotoCountIncrease(currentCount);
        }
        _scrollManager.lastAssetsCount = currentCount;
      });

      // 写真更新後、スクロール可能かチェック
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollManager.checkIfNeedsMorePhotos();
        _scheduleViewportPrefetch();
      });
    }
  }

  /// 多言語化対応のフォトグルーピング（buildメソッドで使用）
  List<TimelinePhotoGroup> _getLocalizedPhotoGroups(BuildContext context) {
    return _groupingService.groupPhotosForTimelineLocalized(
      widget.controller.photoAssets,
      todayLabel: context.l10n.timelineToday,
      yesterdayLabel: context.l10n.timelineYesterday,
      monthYearFormatter: (year, month) =>
          context.l10n.timelineMonthYear(year, month),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        if (!widget.controller.hasPermission) {
          return _buildPermissionDeniedState();
        }

        // 初回ロード中で写真がまだない場合は、シンプルなローディング表示
        if (widget.controller.isLoading && _photoGroups.isEmpty) {
          return _buildSimpleLoadingState();
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

    // 多言語化されたグループを取得
    final localizedGroups = _getLocalizedPhotoGroups(context);

    // flutter_sticky_headerを使ったシンプルな実装
    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        for (var i = 0; i < localizedGroups.length; i++) ...[
          if (localizedGroups[i].photos.isEmpty)
            SliverStickyHeader(
              header: _buildStickyHeader(localizedGroups[i]),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: TimelineLayoutConstants.emptyStateHeight,
                  child: Center(
                    child: Text(
                      context.l10n.photoNoPhotosMessage,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              ),
            )
          else
            SliverStickyHeader(
              header: _buildStickyHeader(localizedGroups[i]),
              sliver: SliverMainAxisGroup(
                slivers: [
                  SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              TimelineLayoutConstants.crossAxisCount,
                          crossAxisSpacing:
                              TimelineLayoutConstants.crossAxisSpacing,
                          mainAxisSpacing:
                              TimelineLayoutConstants.mainAxisSpacing,
                          childAspectRatio:
                              TimelineLayoutConstants.childAspectRatio,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildPhotoTile(
                        context,
                        localizedGroups[i],
                        index,
                        selectedDate,
                      ),
                      childCount: _calculateChildCount(
                        localizedGroups[i],
                        isLastGroup: i == localizedGroups.length - 1,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.md),
                  ),
                ],
              ),
            ),
        ],
        // 追加読み込みインジケーター（追加写真がある場合のみ）
        if (_scrollManager.isLoadingMore && widget.controller.hasMorePhotos)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: SizedBox(
                  width: TimelineLayoutConstants.loadingIndicatorSize,
                  height: TimelineLayoutConstants.loadingIndicatorSize,
                  child: CircularProgressIndicator(
                    strokeWidth:
                        TimelineLayoutConstants.loadingIndicatorStrokeWidth,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// グループ内の表示アイテム数を計算（スケルトン含む）
  ///
  /// hasMorePhotosがtrueの場合、末尾グループに常に固定の大量プレースホルダーを表示。
  /// プレースホルダーは軽量コンテナのため、大量でもパフォーマンスに影響しない。
  /// これにより高速スクロールでもプレースホルダーに追いつかない。
  int _calculateChildCount(
    TimelinePhotoGroup group, {
    required bool isLastGroup,
  }) {
    if (!isLastGroup || !widget.controller.hasMorePhotos) {
      return group.photos.length;
    }
    // 4列 × 8行 × 30ページ = 960タイル（240行分のスクロール余地）
    const placeholderCount =
        TimelineLayoutConstants.crossAxisCount *
        AppConstants.timelinePlaceholderRows *
        AppConstants.timelinePlaceholderMaxPages;
    return group.photos.length + placeholderCount;
  }

  /// 全グループの総アイテム数（実写真+プレースホルダー）
  int _totalItemCount() {
    var total = 0;
    for (var i = 0; i < _photoGroups.length; i++) {
      total += _calculateChildCount(
        _photoGroups[i],
        isLastGroup: i == _photoGroups.length - 1,
      );
    }
    return total;
  }

  /// 個別の写真タイルを構築
  Widget _buildPhotoTile(
    BuildContext context,
    TimelinePhotoGroup group,
    int index,
    DateTime? selectedDate,
  ) {
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
    final mainIndex = _cacheManager.photoIndexCache[photo.id] ?? -1;
    final isSelected =
        mainIndex >= 0 && mainIndex < widget.controller.selected.length
        ? widget.controller.selected[mainIndex]
        : false;
    final isUsed = mainIndex >= 0
        ? widget.controller.isPhotoUsed(mainIndex)
        : false;
    final isLocked = widget.controller.isPhotoLocked(photo);

    // キャッシュを使用した薄化判定（パフォーマンス最適化）
    final shouldDimPhoto =
        !isLocked &&
        _shouldDimPhoto(
          photo: photo,
          isSelected: isSelected,
          selectedDate: selectedDate,
        );

    final heroTag = 'asset-${photo.id}';
    final thumbnail = TimelinePhotoThumbnail(
      photo: photo,
      future: _cacheManager.getThumbnailFuture(photo),
      thumbnailSize: TimelineLayoutConstants.thumbnailSize,
      thumbnailQuality: TimelineLayoutConstants.thumbnailQuality,
      borderRadius: TimelineLayoutConstants.borderRadius,
      strokeWidth: TimelineLayoutConstants.loadingIndicatorStrokeWidth,
      key: ValueKey(photo.id),
    );

    return GestureDetector(
      onTap: isLocked
          ? () => widget.onLockedPhotoTapped?.call()
          : () => _handlePhotoTap(mainIndex),
      onLongPress: isLocked
          ? () => widget.onLockedPhotoTapped?.call()
          : () => _handlePhotoLongPress(context, photo, heroTag, isUsed),
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
          // ロック写真のロックアイコンオーバーレイ
          if (isLocked)
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(
                    TimelineLayoutConstants.lockedIconPadding,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.scrim.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    color: Theme.of(context).colorScheme.onInverseSurface,
                    size: TimelineLayoutConstants.lockedIconSize,
                  ),
                ),
              ),
            ),
          // パフォーマンス最適化された選択インジケーター（ロック時は非表示）
          if (!isLocked)
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
          // パフォーマンス最適化された使用済みラベル（ロック時は非表示）
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
    if (mainIndex < 0) return;

    if (widget.controller.isPhotoUsed(mainIndex)) {
      widget.onUsedPhotoSelected?.call();
      return;
    }

    final wasSelected = widget.controller.selected[mainIndex];

    if (wasSelected) {
      widget.controller.toggleSelect(mainIndex);
      return;
    }

    if (!widget.controller.canSelectPhoto(mainIndex)) {
      if (widget.controller.selectedCount >= AppConstants.maxPhotosSelection) {
        widget.onSelectionLimitReached?.call();
        return;
      }
      widget.onDifferentDateSelected?.call();
      return;
    }

    widget.controller.toggleSelect(mainIndex);
  }

  /// 写真長押し時の処理（使用済み/未使用で分岐）
  void _handlePhotoLongPress(
    BuildContext context,
    AssetEntity photo,
    String heroTag,
    bool isUsed,
  ) {
    if (isUsed && widget.onUsedPhotoDetail != null) {
      widget.onUsedPhotoDetail!(photo.id);
    } else {
      _showPhotoPreview(context, photo, heroTag);
    }
  }

  /// 長押しで拡大プレビューを表示
  void _showPhotoPreview(BuildContext context, AssetEntity asset, String tag) {
    FullscreenPhotoViewer.show(context, asset: asset, heroTag: tag);
  }

  /// 写真を薄く表示するかどうかを判定
  bool _shouldDimPhoto({
    required AssetEntity photo,
    required bool isSelected,
    required DateTime? selectedDate,
  }) {
    if (isSelected) return false;
    if (selectedDate == null) return false;
    if (widget.controller.selectedCount >= AppConstants.maxPhotosSelection)
      return true;
    return !_isSameDateAsPhoto(selectedDate, photo);
  }

  /// 指定日付が写真と同じ日付かどうかを判定
  bool _isSameDateAsPhoto(DateTime date, AssetEntity photo) {
    final photoDate = photo.createDateTime;
    return date.year == photoDate.year &&
        date.month == photoDate.month &&
        date.day == photoDate.day;
  }

  /// スティッキーヘッダーを構築
  Widget _buildStickyHeader(TimelinePhotoGroup group) {
    final isFullyLocked = _groupFullyLockedCache[group.groupDate] ?? false;

    return Container(
      height: TimelineLayoutConstants.stickyHeaderHeight,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
      ),
      child: Row(
        children: [
          Text(
            group.displayName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.left,
          ),
          if (isFullyLocked) ...[
            const Spacer(),
            Text(
              context.l10n.timelineLockedGroupLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// シンプルなローディング状態を構築（スケルトンなし）
  Widget _buildSimpleLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: AppConstants.progressIndicatorStrokeWidth,
      ),
    );
  }

  /// 権限拒否状態を構築
  Widget _buildPermissionDeniedState() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: AppConstants.emptyStateIconSize,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.l10n.photoPermissionMessage,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (widget.onRequestPermission != null)
                  TextButton(
                    onPressed: widget.onRequestPermission,
                    child: Text(context.l10n.commonAllow),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 空状態を構築
  Widget _buildEmptyState() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_outlined,
                  size: AppConstants.emptyStateIconSize,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.l10n.photoNoPhotosMessage,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
