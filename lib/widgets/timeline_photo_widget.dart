import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import '../models/timeline_photo_group.dart';
import '../services/timeline_grouping_service.dart';
import '../controllers/photo_selection_controller.dart';
import '../ui/design_system/app_spacing.dart';
import '../constants/app_constants.dart';
import '../services/logging_service.dart';
import '../core/service_locator.dart';
import '../services/interfaces/photo_cache_service_interface.dart';
import '../services/photo_cache_service.dart';

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

  const TimelinePhotoWidget({
    super.key,
    required this.controller,
    this.onSelectionLimitReached,
    this.onUsedPhotoSelected,
    this.onRequestPermission,
    this.onDifferentDateSelected,
    this.onCameraPressed,
    this.onLoadMorePhotos,
    this.onPreloadMorePhotos,
    this.showFAB = true,
  });

  @override
  State<TimelinePhotoWidget> createState() => _TimelinePhotoWidgetState();
}

class _TimelinePhotoWidgetState extends State<TimelinePhotoWidget> {
  final TimelineGroupingService _groupingService = TimelineGroupingService();
  final ScrollController _scrollController = ScrollController();
  List<TimelinePhotoGroup> _photoGroups = [];

  // ログサービス
  LoggingService get _logger => serviceLocator.get<LoggingService>();

  // 無限スクロール用状態（シンプル版）
  bool _isLoadingMore = false;
  int _placeholderPages = 1; // スケルトンを段階的に増やす
  int _lastAssetsCount = 0; // 差分検出用

  // デバッグ用状態
  DateTime? _lastPreloadCall;
  DateTime? _lastLoadMoreCall;

  // 無限スクロール用の定数（実機最適化）
  static const double _preloadThreshold =
      AppConstants.timelinePreloadThresholdPx;
  static const double _loadMoreThreshold =
      AppConstants.timelineLoadMoreThresholdPx;
  static const double _scrollCheckThreshold = 200.0; // スクロール可能性チェックの閾値（px）

  // スクロール判定とタイミング関連の定数
  static const int _scrollCheckIntervalMs =
      AppConstants.timelineScrollCheckIntervalMs; // スクロール判定の間隔（ミリ秒）
  static const int _layoutCompleteDelayMs = 100; // レイアウト完了待機時間（ミリ秒）
  static const int _initializationCompleteDelayMs = 500; // 初期化完了待機時間（ミリ秒）
  static const int _maxPhotosForAutoLoad = 60; // 自動追加読み込みする最大写真数（実機最適化）

  // パフォーマンス最適化用の定数
  static const double _crossAxisSpacing = 2.0;
  static const double _mainAxisSpacing = 2.0;
  static const int _crossAxisCount = 4;
  static const double _childAspectRatio = 1.0;

  // UI関連の定数
  static const double _stickyHeaderHeight = 48.0;
  static const double _emptyStateHeight = 100.0;
  static const double _loadingIndicatorSize = 24.0;
  static const double _loadingIndicatorStrokeWidth = 2.0;
  static const int _animationDurationMs = 150;

  // 選択インジケーター関連の定数
  static const double _selectionIndicatorSize = 20.0;
  static const double _selectionIconSize = 19.0;
  static const double _selectionBorderWidth = 2.0;

  // サムネイル関連（AppConstantsに集約）
  static const int _thumbnailSize = AppConstants.timelineThumbnailSizePx;
  static const int _thumbnailQuality = AppConstants.timelineThumbnailQuality;

  // 画像キャッシュ（Service + Futureインスタンスのメモ化で再描画時の再フェッチを防止）
  late final IPhotoCacheService _cacheService = PhotoCacheService.getInstance();
  final Map<String, Future<Uint8List?>> _thumbFutureCache = {};

  // ビューポート先読み（高速スクロール対策）
  Timer? _prefetchDebounce;
  int _lastPrefetchStartIndex = -1;
  bool _isViewportPrefetching = false;

  // レイアウト関連の定数
  static const double _borderRadius = 4.0;
  static const double _selectionIndicatorTop = 8.0;
  static const double _selectionIndicatorRight = 8.0;
  static const double _usedLabelBottom = 4.0;
  static const double _usedLabelLeft = 4.0;
  static const double _usedLabelHorizontalPadding = 4.0;
  static const double _usedLabelVerticalPadding = 2.0;

  // インデックスキャッシュ（メインインデックス検索の最適化）
  final Map<String, int> _photoIndexCache = {};

  // 薄化計算結果のキャッシュ
  final Map<String, bool> _dimPhotoCache = {};
  DateTime? _lastSelectedDate;
  int _lastSelectedCount = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _scrollController.addListener(_onScroll);
    _updatePhotoGroups();

    // 初期ビューポート分を軽くプリフェッチ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleViewportPrefetch();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  /// スクロール検知（2段階先読み版）
  void _onScroll() {
    if (!_scrollController.hasClients || !widget.controller.hasMorePhotos)
      return;

    final position = _scrollController.position;
    final pixels = position.pixels;
    final maxScrollExtent = position.maxScrollExtent;

    if (maxScrollExtent <= 0) return;

    final now = DateTime.now();

    // これ以上読み込む写真がない場合は、残っているスケルトンを即座に消す
    if (!widget.controller.hasMorePhotos && _placeholderPages != 0) {
      setState(() {
        _placeholderPages = 0;
      });
    }

    // 段階1: 先読み開始（UIブロッキングなし）
    if (pixels >= maxScrollExtent - _preloadThreshold) {
      // 短時間の重複呼び出しを防ぐ
      if (_lastPreloadCall == null ||
          now.difference(_lastPreloadCall!).inMilliseconds >
              _scrollCheckIntervalMs) {
        _lastPreloadCall = now;
        _logger.info(
          '先読みトリガー: pixels=$pixels, max=$maxScrollExtent, threshold=$_preloadThreshold',
          context: 'TimelinePhotoWidget._onScroll',
        );
        widget.onPreloadMorePhotos?.call();
        _increasePlaceholderPages();
      }
    }

    // ビューポート先読み（サムネイル）
    _scheduleViewportPrefetch();

    // 段階2: 確実な読み込み（UIフィードバックあり）
    if (pixels >= maxScrollExtent - _loadMoreThreshold) {
      if (!_isLoadingMore &&
          (_lastLoadMoreCall == null ||
              now.difference(_lastLoadMoreCall!).inMilliseconds >
                  _scrollCheckIntervalMs)) {
        _lastLoadMoreCall = now;
        _logger.info(
          '追加読み込みトリガー: pixels=$pixels, max=$maxScrollExtent, threshold=$_loadMoreThreshold',
          context: 'TimelinePhotoWidget._onScroll',
        );
        _requestMorePhotos();
      }
    }
  }

  /// 追加写真読み込み要求（HomeScreenに委譲）
  void _requestMorePhotos() {
    setState(() {
      _isLoadingMore = true;
    });
    // HomeScreenに追加読み込み要求を送信
    widget.onLoadMorePhotos?.call();
    _increasePlaceholderPages();
  }

  /// 追加読み込み完了時に呼び出される（コントローラー更新時に自動実行）
  void _onLoadMoreCompleted() {
    if (_isLoadingMore) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  /// スクロール可能でない場合に追加読み込みを要求（改良版）
  void _checkIfNeedsMorePhotos() {
    // 初回チェック（即座に実行）
    _performPhotoCheck();

    // 遅延チェック（レイアウト完了を待つ）
    Future.delayed(Duration(milliseconds: _layoutCompleteDelayMs), () {
      if (mounted) {
        _performPhotoCheck();
      }
    });

    // さらなる遅延チェック（完全な初期化を待つ）
    Future.delayed(Duration(milliseconds: _initializationCompleteDelayMs), () {
      if (mounted) {
        _performPhotoCheck();
      }
    });
  }

  /// 実際の写真不足チェックロジック
  void _performPhotoCheck() {
    if (!_scrollController.hasClients ||
        _isLoadingMore ||
        !widget.controller.hasMorePhotos)
      return;

    final position = _scrollController.position;
    final photoCount = widget.controller.photoAssets.length;

    _logger.info(
      'スクロール可能性チェック: maxScrollExtent=${position.maxScrollExtent.toStringAsFixed(1)}, '
      'photoCount=$photoCount, hasMorePhotos=${widget.controller.hasMorePhotos}',
      context: 'TimelinePhotoWidget._performPhotoCheck',
    );

    // 条件を緩和：スクロール範囲が閾値以下で写真が上限未満の場合
    if (position.maxScrollExtent <= _scrollCheckThreshold &&
        photoCount > 0 &&
        photoCount < _maxPhotosForAutoLoad) {
      _logger.info(
        'スクロール不可のため追加読み込み要求: maxScrollExtent=${position.maxScrollExtent.toStringAsFixed(1)}, threshold=$_scrollCheckThreshold',
        context: 'TimelinePhotoWidget._performPhotoCheck',
      );

      if (widget.onLoadMorePhotos != null && !_isLoadingMore) {
        _requestMorePhotos();
      }
    }
  }

  void _onControllerChanged() {
    // 薄化キャッシュをクリア（選択状態変更時のみ）
    final currentSelectedDate = _groupingService.getSelectedDate(
      widget.controller.selectedPhotos,
    );
    final currentSelectedCount = widget.controller.selectedCount;

    // 選択状態の実質的変更をチェック（先読み時の不要なクリアを防ぐ）
    bool shouldClearCache = false;
    if (_lastSelectedDate != currentSelectedDate ||
        _lastSelectedCount != currentSelectedCount) {
      // 日付変更または選択数変更の場合のみクリア
      shouldClearCache = true;
      _lastSelectedDate = currentSelectedDate;
      _lastSelectedCount = currentSelectedCount;
    }

    // UI更新を次のフレームに延期（キャッシュ準備完了を待つ）
    Future.microtask(() {
      if (mounted) {
        // キャッシュクリアもUI更新と同じタイミングで実行
        if (shouldClearCache) {
          _dimPhotoCache.clear();
        }
        _updatePhotoGroups();
        // 取得枚数が増えたらスケルトンは最小に戻す（描画コスト抑制）
        final currentCount = widget.controller.photoAssets.length;
        if (currentCount > _lastAssetsCount) {
          _placeholderPages = 1;
        }
        // これ以上の写真がないときはスケルトンを完全に消す
        if (!widget.controller.hasMorePhotos) {
          _placeholderPages = 0;
        }
        _lastAssetsCount = currentCount;
      }
    });

    // 追加読み込み完了チェック
    _onLoadMoreCompleted();
  }

  void _updatePhotoGroups() {
    final groups = _groupingService.groupPhotosForTimeline(
      widget.controller.photoAssets,
    );

    // インデックスキャッシュを先に完全に再構築してからUI更新
    _rebuildPhotoIndexCache();

    // サムネイルFutureキャッシュの簡易クリーンアップ（非表示アセットを間引く）
    final visibleIds = groups.expand((g) => g.photos).map((a) => a.id).toSet();
    if (_thumbFutureCache.length >
        AppConstants.thumbnailFutureCachePruneThreshold) {
      _thumbFutureCache.removeWhere((key, _) {
        final id = key.split(':').first;
        return !visibleIds.contains(id);
      });
    }

    if (mounted) {
      // キャッシュ再構築完了後に安全にUI更新
      setState(() {
        _photoGroups = groups;
        // 取得枚数が増えたらスケルトン行数を最小化
        final currentCount = widget.controller.photoAssets.length;
        if (currentCount > _lastAssetsCount) {
          _placeholderPages = 1;
        }
        // これ以上読み込む写真がないならスケルトンを即座に消す
        if (!widget.controller.hasMorePhotos) {
          _placeholderPages = 0;
        }
        _lastAssetsCount = currentCount;
      });

      // 写真更新後、スクロール可能かチェック
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkIfNeedsMorePhotos();
        _scheduleViewportPrefetch();
      });
    }
  }

  /// 現在のスクロール位置をもとにサムネイルを先読み
  void _scheduleViewportPrefetch() {
    _prefetchDebounce?.cancel();
    _prefetchDebounce = Timer(const Duration(milliseconds: 220), () async {
      if (!mounted || _isViewportPrefetching) return;
      if (_photoGroups.isEmpty || widget.controller.photoAssets.isEmpty) return;
      if (!_scrollController.hasClients) return;

      final position = _scrollController.position;
      final max = position.maxScrollExtent;
      // max==0 のときは上端。端末やレイアウトにより0のこともある
      final frac = max > 0 ? (position.pixels / max).clamp(0.0, 1.0) : 0.0;

      final total = widget.controller.photoAssets.length;
      final start = (frac * total).floor();
      // 先読みウィンドウ
      final window = AppConstants.timelinePrefetchAheadCount;
      final batch = AppConstants.timelinePrefetchBatchSize;
      final end = (start + window).clamp(0, total);

      // 過剰な重複実行を抑制
      if (_lastPrefetchStartIndex >= 0 &&
          (start - _lastPrefetchStartIndex).abs() < batch ~/ 2) {
        return;
      }

      _lastPrefetchStartIndex = start;
      _isViewportPrefetching = true;

      try {
        // バッチ分割してプリロード（キャッシュ済みはスキップされる）
        for (int i = start; i < end; i += batch) {
          final j = (i + batch).clamp(0, total);
          final slice = widget.controller.photoAssets.sublist(i, j);
          if (slice.isEmpty) break;
          await _cacheService.preloadThumbnails(
            slice,
            width: _thumbnailSize,
            height: _thumbnailSize,
            quality: _thumbnailQuality,
          );
        }
      } finally {
        _isViewportPrefetching = false;
      }
    });
  }

  void _increasePlaceholderPages() {
    if (_placeholderPages >= AppConstants.timelinePlaceholderMaxPages) return;
    setState(() {
      _placeholderPages += 1;
    });
  }

  /// 指定アセットのサムネイルFutureをサイズ/品質込みのキーでメモ化
  Future<Uint8List?> _getThumbnailFuture(AssetEntity asset) {
    final key =
        '${asset.id}:${_thumbnailSize}x$_thumbnailSize:q$_thumbnailQuality';
    return _thumbFutureCache.putIfAbsent(
      key,
      () => _cacheService.getThumbnail(
        asset,
        width: _thumbnailSize,
        height: _thumbnailSize,
        quality: _thumbnailQuality,
      ),
    );
  }

  /// 写真インデックスキャッシュを再構築（パフォーマンス最適化）
  void _rebuildPhotoIndexCache() {
    // 新しいキャッシュを作成（既存キャッシュを破壊しない）
    final newCache = <String, int>{};
    final assets = widget.controller.photoAssets;
    for (int i = 0; i < assets.length; i++) {
      newCache[assets[i].id] = i;
    }

    // 原子的操作でキャッシュを置き換え
    _photoIndexCache.clear();
    _photoIndexCache.addAll(newCache);
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

    // flutter_sticky_headerを使ったシンプルな実装
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        ..._photoGroups.map((group) {
          return SliverStickyHeader(
            header: _buildStickyHeader(group),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildPhotoGridForGroup(
                  group,
                  selectedDate,
                  isLastGroup: identical(
                    group,
                    _photoGroups.isNotEmpty ? _photoGroups.last : group,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ]),
            ),
          );
        }),
        // 追加読み込みインジケーター（追加写真がある場合のみ）
        if (_isLoadingMore && widget.controller.hasMorePhotos)
          SliverToBoxAdapter(
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: SizedBox(
                  width: _loadingIndicatorSize,
                  height: _loadingIndicatorSize,
                  child: CircularProgressIndicator(
                    strokeWidth: _loadingIndicatorStrokeWidth,
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
      height: _stickyHeaderHeight,
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

  /// グループ用の写真グリッドを構築
  Widget _buildPhotoGridForGroup(
    TimelinePhotoGroup group,
    DateTime? selectedDate, {
    required bool isLastGroup,
  }) {
    if (group.photos.isEmpty) {
      return SizedBox(
        height: _emptyStateHeight,
        child: Center(
          child: Text('写真がありません', style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    // スケルトンを末尾グループにだけ追加してスクロール継続を可能に
    final bool showPlaceholders = isLastGroup;
    final int placeholderRows = AppConstants.timelinePlaceholderRows;
    final int placeholderCountPerPage = _crossAxisCount * placeholderRows;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount,
        crossAxisSpacing: _crossAxisSpacing,
        mainAxisSpacing: _mainAxisSpacing,
        childAspectRatio: _childAspectRatio,
      ),
      itemCount:
          group.photos.length +
          (showPlaceholders
              ? (placeholderCountPerPage * _placeholderPages)
              : 0),
      itemBuilder: (context, index) {
        // プレースホルダー領域
        if (index >= group.photos.length) {
          return _SkeletonTile(
            borderRadius: _borderRadius,
            strokeWidth: _loadingIndicatorStrokeWidth,
            indicatorSize: _loadingIndicatorSize,
          );
        }

        final photo = group.photos[index];

        // キャッシュを使用してメインインデックスを高速取得
        final mainIndex = _photoIndexCache[photo.id] ?? -1;
        final isSelected =
            mainIndex >= 0 && mainIndex < widget.controller.selected.length
            ? widget.controller.selected[mainIndex]
            : false;
        final isUsed = mainIndex >= 0
            ? widget.controller.isPhotoUsed(mainIndex)
            : false;

        // キャッシュを使用した薄化判定（パフォーマンス最適化）
        final shouldDimPhoto = _shouldDimPhotoWithCache(
          photo: photo,
          selectedDate: selectedDate,
          isSelected: isSelected,
        );

        return GestureDetector(
          onTap: () => _handlePhotoTap(mainIndex),
          child: Stack(
            children: [
              // アニメーション最適化: AnimatedOpacityでスムーズな薄化切替
              AnimatedOpacity(
                opacity: shouldDimPhoto ? 0.6 : 1.0,
                duration: Duration(milliseconds: _animationDurationMs),
                curve: Curves.easeInOut,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0), // 固定値でパフォーマンス最適化
                    borderRadius: BorderRadius.all(
                      Radius.circular(_borderRadius),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(
                      Radius.circular(_borderRadius),
                    ),
                    child: _OptimizedPhotoThumbnail(
                      photo: photo,
                      future: _getThumbnailFuture(photo),
                      thumbnailSize: _thumbnailSize,
                      thumbnailQuality: _thumbnailQuality,
                      borderRadius: _borderRadius,
                      strokeWidth: _loadingIndicatorStrokeWidth,
                      key: ValueKey(photo.id), // キーでWidgetの再利用を促進
                    ),
                  ),
                ),
              ),
              // パフォーマンス最適化された選択インジケーター
              Positioned(
                top: _selectionIndicatorTop,
                right: _selectionIndicatorRight,
                child: _OptimizedSelectionIndicator(
                  isSelected: isSelected,
                  isUsed: isUsed,
                  shouldDimPhoto: shouldDimPhoto,
                  primaryColor: Theme.of(context).colorScheme.primary,
                  indicatorSize: _selectionIndicatorSize,
                  iconSize: _selectionIconSize,
                  borderWidth: _selectionBorderWidth,
                ),
              ),
              // パフォーマンス最適化された使用済みラベル
              if (isUsed)
                _OptimizedUsedLabel(
                  bottom: _usedLabelBottom,
                  left: _usedLabelLeft,
                  horizontalPadding: _usedLabelHorizontalPadding,
                  verticalPadding: _usedLabelVerticalPadding,
                  borderRadius: _borderRadius,
                ),
            ],
          ),
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
            size: AppConstants.emptyStateIconSize,
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
            size: AppConstants.emptyStateIconSize,
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

  /// キャッシュ機能付きの薄化判定（パフォーマンス最適化）
  bool _shouldDimPhotoWithCache({
    required AssetEntity photo,
    required DateTime? selectedDate,
    required bool isSelected,
  }) {
    // 選択済みの写真は薄くしない
    if (isSelected) return false;

    // キャッシュから取得を試行
    final cacheKey =
        '${photo.id}_${selectedDate?.millisecondsSinceEpoch}_${widget.controller.selectedCount}';
    if (_dimPhotoCache.containsKey(cacheKey)) {
      return _dimPhotoCache[cacheKey]!;
    }

    // 計算して結果をキャッシュ
    final result = _calculateShouldDimPhoto(
      photo: photo,
      selectedDate: selectedDate,
      isSelected: isSelected,
    );
    _dimPhotoCache[cacheKey] = result;

    return result;
  }

  /// 写真を薄く表示するかどうかを判定（実際の計算ロジック）
  bool _calculateShouldDimPhoto({
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
}

/// パフォーマンス最適化された写真サムネイルウィジェット
class _OptimizedPhotoThumbnail extends StatelessWidget {
  const _OptimizedPhotoThumbnail({
    super.key,
    required this.photo,
    required this.future,
    required this.thumbnailSize,
    required this.thumbnailQuality,
    required this.borderRadius,
    required this.strokeWidth,
  });

  final AssetEntity photo;
  final Future<Uint8List?> future;
  final int thumbnailSize;
  final int thumbnailQuality;
  final double borderRadius;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      // メモ化されたFutureを使用して再描画時の待機→ローディング表示を防止
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
          return RepaintBoundary(
            child: Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              // デコードサイズを端末密度に合わせて固定（キャッシュヒット向上）
              cacheWidth: (thumbnailSize * devicePixelRatio).round(),
              cacheHeight: (thumbnailSize * devicePixelRatio).round(),
              gaplessPlayback: true, // 再描画間のちらつきを防止
              isAntiAlias: false,
              filterQuality: FilterQuality.low,
              frameBuilder: (context, child, frame, wasSync) {
                if (wasSync || frame != null) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: AppConstants.shortAnimationDuration,
                  curve: Curves.easeOut,
                  child: child,
                );
              },
            ),
          );
        } else {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFBDBDBD),
              borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: strokeWidth,
                color: const Color(0xFF9E9E9E),
              ),
            ),
          );
        }
      },
    );
  }
}

/// パフォーマンス最適化された選択インジケーター
class _OptimizedSelectionIndicator extends StatelessWidget {
  const _OptimizedSelectionIndicator({
    required this.isSelected,
    required this.isUsed,
    required this.shouldDimPhoto,
    required this.primaryColor,
    required this.indicatorSize,
    required this.iconSize,
    required this.borderWidth,
  });

  final bool isSelected;
  final bool isUsed;
  final bool shouldDimPhoto;
  final Color primaryColor;
  final double indicatorSize;
  final double iconSize;
  final double borderWidth;

  // 選択インジケーターの色とスタイル定数
  static const Color _borderColor = Color(0xB3FFFFFF); // 境界線の色（透明度70%白色）
  static const Color _shadowColor = Color(0x1A000000); // 影の色（透明度10%黒色）
  static const double _shadowBlurRadius = 2.0; // 影のぼかし半径
  static const Offset _shadowOffset = Offset(0, 1); // 影のオフセット

  @override
  Widget build(BuildContext context) {
    if (!isSelected && !isUsed) {
      // 未選択時は完全透明な境界線のみ
      return Container(
        width: indicatorSize,
        height: indicatorSize,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: !shouldDimPhoto
              ? Border.all(color: _borderColor, width: borderWidth)
              : null,
          boxShadow: null, // 未選択時は影なし
        ),
      );
    }

    // 選択済み/使用済み時は白背景とアイコン
    return Container(
      width: indicatorSize,
      height: indicatorSize,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: shouldDimPhoto
            ? null
            : [
                BoxShadow(
                  color: _shadowColor,
                  blurRadius: _shadowBlurRadius,
                  offset: _shadowOffset,
                ),
              ],
      ),
      child: Icon(
        isUsed ? Icons.done : Icons.check_circle,
        size: iconSize,
        color: isUsed ? Colors.orange : primaryColor,
      ),
    );
  }
}

/// 読み込み中に表示するスケルトンタイル（軽量）
class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile({
    required this.borderRadius,
    required this.strokeWidth,
    required this.indicatorSize,
  });

  final double borderRadius;
  final double strokeWidth;
  final double indicatorSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '読み込み中の写真',
      container: true,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE6E6E6),
          borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        ),
        child: Center(
          child: SizedBox(
            width: indicatorSize,
            height: indicatorSize,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              color: const Color(0xFFBDBDBD),
            ),
          ),
        ),
      ),
    );
  }
}

/// パフォーマンス最適化された使用済みラベル
class _OptimizedUsedLabel extends StatelessWidget {
  const _OptimizedUsedLabel({
    required this.bottom,
    required this.left,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.borderRadius,
  });

  final double bottom;
  final double left;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;

  // 使用済みラベルの色とスタイル定数
  static const Color _backgroundColor = Color(0xE6FF9800); // 背景色（オレンジ、透明度90%）
  static const double _fontSize = 10.0; // フォントサイズ

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      left: left,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Text(
          '使用済み',
          style: TextStyle(
            color: Colors.white,
            fontSize: _fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
