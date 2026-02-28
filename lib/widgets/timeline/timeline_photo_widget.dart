import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

import '../../constants/app_constants.dart';
import '../../controllers/photo_selection_controller.dart';
import '../../controllers/scroll_signal.dart';
import '../../core/service_locator.dart';
import '../../localization/localization_extensions.dart';
import '../../models/timeline_photo_group.dart';
import '../../services/interfaces/logging_service_interface.dart';
import '../../services/timeline_grouping_service.dart';
import '../../ui/design_system/app_spacing.dart';
import 'timeline_cache_manager.dart';
import 'timeline_constants.dart';
import 'timeline_components.dart';
import 'timeline_empty_states.dart';
import 'timeline_photo_tile.dart';
import 'timeline_sticky_header.dart';
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
    // initState時はcontextが利用できない場合があるため、フォールバックラベルを使用
    final groups = _groupingService.groupPhotosForTimelineLocalized(
      widget.controller.photoAssets,
      todayLabel: 'Today',
      yesterdayLabel: 'Yesterday',
      monthYearFormatter: (year, month) => '$year/$month',
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
          return TimelinePermissionDeniedState(
            onRequestPermission: widget.onRequestPermission,
          );
        }

        // 初回ロード中で写真がまだない場合は、シンプルなローディング表示
        if (widget.controller.isLoading && _photoGroups.isEmpty) {
          return const TimelineLoadingState();
        }

        if (_photoGroups.isEmpty) {
          return const TimelineEmptyState();
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
              header: TimelineStickyHeader(
                group: localizedGroups[i],
                isFullyLocked:
                    _groupFullyLockedCache[localizedGroups[i].groupDate] ??
                    false,
              ),
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
              header: TimelineStickyHeader(
                group: localizedGroups[i],
                isFullyLocked:
                    _groupFullyLockedCache[localizedGroups[i].groupDate] ??
                    false,
              ),
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
    final mainIndex = _cacheManager.photoIndexCache[photo.id] ?? -1;

    return TimelinePhotoTile(
      controller: widget.controller,
      photo: photo,
      mainIndex: mainIndex,
      selectedDate: selectedDate,
      cacheManager: _cacheManager,
      onSelectionLimitReached: widget.onSelectionLimitReached,
      onUsedPhotoSelected: widget.onUsedPhotoSelected,
      onUsedPhotoDetail: widget.onUsedPhotoDetail,
      onDifferentDateSelected: widget.onDifferentDateSelected,
      onLockedPhotoTapped: widget.onLockedPhotoTapped,
    );
  }
}
