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
import 'timeline_photo_grid.dart';
import 'timeline_scroll_manager.dart';

/// タイムライン表示用の写真ウィジェット
///
/// ホーム画面タブ統合後のメインコンポーネント。
/// - 日付別グルーピング（今日/昨日/月単位）
/// - スティッキーヘッダー付きスクロール表示
/// - 写真選択・薄化表示機能
/// - パフォーマンス最適化（インデックスキャッシュ・薄化判定キャッシュ）
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

    if (mounted) {
      // キャッシュ再構築完了後に安全にUI更新
      setState(() {
        _photoGroups = groups;
        // 取得枚数が増えた場合の処理を改善
        final currentCount = widget.controller.photoAssets.length;
        if (currentCount > _scrollManager.lastAssetsCount) {
          _scrollManager.handlePhotoCountIncrease(currentCount);
        }
        // これ以上読み込む写真がないなら段階的にスケルトンを減らす
        if (!widget.controller.hasMorePhotos) {
          _scrollManager.decreasePlaceholderPages();
        }
        _scrollManager.lastAssetsCount = currentCount;
      });

      // 写真更新後、スクロール可能かチェック
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollManager.checkIfNeedsMorePhotos();
        _scheduleViewportPrefetch();
        // 底付き時の保険をもう一度
        _scrollManager.ensureProgressiveLoadingIfPinned();
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
        ...localizedGroups.map((group) {
          return SliverStickyHeader(
            header: _buildStickyHeader(group),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                TimelinePhotoGrid(
                  group: group,
                  selectedDate: selectedDate,
                  isLastGroup: identical(
                    group,
                    _photoGroups.isNotEmpty ? _photoGroups.last : group,
                  ),
                  hasMorePhotos: widget.controller.hasMorePhotos,
                  placeholderPages: _scrollManager.placeholderPages,
                  controller: widget.controller,
                  cacheManager: _cacheManager,
                  onDifferentDateSelected: widget.onDifferentDateSelected,
                  onUsedPhotoDetail: widget.onUsedPhotoDetail,
                ),
                const SizedBox(height: AppSpacing.md),
              ]),
            ),
          );
        }),
        // 追加読み込みインジケーター（追加写真がある場合のみ）
        if (_scrollManager.isLoadingMore && widget.controller.hasMorePhotos)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
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

  /// スティッキーヘッダーを構築
  Widget _buildStickyHeader(TimelinePhotoGroup group) {
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
    );
  }

  /// シンプルなローディング状態を構築（スケルトンなし）
  Widget _buildSimpleLoadingState() {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2.0));
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
