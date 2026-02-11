import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../constants/app_constants.dart';
import '../../services/interfaces/logging_service_interface.dart';
import 'timeline_constants.dart';

/// タイムラインのスクロール制御・無限スクロール管理ヘルパー
class TimelineScrollManager {
  final ScrollController scrollController;
  final ILoggingService logger;

  /// setState プロキシ（mounted チェック付き）
  final void Function(void Function()) updateState;

  /// mounted 状態チェック
  final bool Function() isMounted;

  /// 追加写真読み込みコールバック
  VoidCallback? onLoadMorePhotos;

  /// バックグラウンド先読みコールバック
  VoidCallback? onPreloadMorePhotos;

  /// ビューポート先読みコールバック（キャッシュマネージャーへの委譲用）
  VoidCallback? onViewportPrefetch;

  /// 追加写真があるかどうか
  bool Function() hasMorePhotos = () => false;

  /// 現在の写真数
  int Function() photoCount = () => 0;

  // 無限スクロール用状態
  bool isLoadingMore = false;
  int placeholderPages = 0;
  int lastAssetsCount = 0;
  bool isInitialLoad = true;
  DateTime? _lastPlaceholderIncrease;
  DateTime? _lastPreloadCall;
  DateTime? _lastLoadMoreCall;

  TimelineScrollManager({
    required this.scrollController,
    required this.logger,
    required this.updateState,
    required this.isMounted,
  });

  /// 外部指示で先頭へスクロール
  void scrollToTop() {
    // スクロール中にスケルトンが視界に入らないよう一時的に最小化
    if (placeholderPages > TimelineScrollConstants.scrollTopPlaceholderLimit) {
      updateState(() {
        placeholderPages = TimelineScrollConstants.scrollTopPlaceholderLimit;
      });
    }

    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// スクロール検知（2段階先読み版）
  void onScroll() {
    if (!scrollController.hasClients) return;

    // これ以上読み込む写真がない場合は、段階的にスケルトンを減らす
    if (!hasMorePhotos()) {
      decreasePlaceholderPages();
      return;
    }

    final position = scrollController.position;
    final pixels = position.pixels;
    final maxScrollExtent = position.maxScrollExtent;

    if (maxScrollExtent <= 0) return;

    final now = DateTime.now();

    // 段階1: 先読み開始（UIブロッキングなし）
    if (pixels >= maxScrollExtent - TimelineScrollConstants.preloadThreshold) {
      // 短時間の重複呼び出しを防ぐ
      if (_lastPreloadCall == null ||
          now.difference(_lastPreloadCall!).inMilliseconds >
              TimelineScrollConstants.scrollCheckIntervalMs) {
        _lastPreloadCall = now;
        logger.info(
          '先読みトリガー: pixels=$pixels, max=$maxScrollExtent, threshold=${TimelineScrollConstants.preloadThreshold}',
          context: 'TimelinePhotoWidget._onScroll',
        );
        onPreloadMorePhotos?.call();
        increasePlaceholderPages();
      }

      // 底付き状態なら継続的に先読みを試みる
      ensureProgressiveLoadingIfPinned();
    }

    // ビューポート先読み（サムネイル）
    onViewportPrefetch?.call();

    // 段階2: 確実な読み込み（UIフィードバックあり）
    if (pixels >= maxScrollExtent - TimelineScrollConstants.loadMoreThreshold) {
      if (!isLoadingMore &&
          (_lastLoadMoreCall == null ||
              now.difference(_lastLoadMoreCall!).inMilliseconds >
                  TimelineScrollConstants.scrollCheckIntervalMs)) {
        _lastLoadMoreCall = now;
        logger.info(
          '追加読み込みトリガー: pixels=$pixels, max=$maxScrollExtent, threshold=${TimelineScrollConstants.loadMoreThreshold}',
          context: 'TimelinePhotoWidget._onScroll',
        );
        requestMorePhotos();
      }
    }
  }

  /// スクロール末端に張り付いたままでも先読みを進める
  void ensureProgressiveLoadingIfPinned() {
    if (!scrollController.hasClients) return;
    if (!hasMorePhotos()) {
      return;
    }

    final pos = scrollController.position;
    final isPinned = (pos.maxScrollExtent - pos.pixels).abs() < 4.0;
    if (!isPinned) {
      return;
    }

    // 連続トリガー（軽いデバウンス）
    Timer(
      Duration(
        milliseconds: TimelineScrollConstants.scrollCheckIntervalMs ~/ 2,
      ),
      () {
        if (!isMounted()) return;
        if (!scrollController.hasClients) return;
        final againPinned =
            (scrollController.position.maxScrollExtent -
                    scrollController.position.pixels)
                .abs() <
            4.0;
        if (againPinned && hasMorePhotos()) {
          onPreloadMorePhotos?.call();
          increasePlaceholderPages();
          // 次も必要かもしれないので再スケジュール
          ensureProgressiveLoadingIfPinned();
        }
      },
    );
  }

  /// 追加写真読み込み要求（HomeScreenに委譲）
  void requestMorePhotos() {
    // スケルトンを先に表示してから読み込み開始
    increasePlaceholderPages();
    updateState(() {
      isLoadingMore = true;
    });
    // HomeScreenに追加読み込み要求を送信
    onLoadMorePhotos?.call();
  }

  /// 追加読み込み完了時に呼び出される（コントローラー更新時に自動実行）
  void onLoadMoreCompleted() {
    if (isLoadingMore) {
      updateState(() {
        isLoadingMore = false;
      });
    }
  }

  /// スクロール可能でない場合に追加読み込みを要求（改良版）
  void checkIfNeedsMorePhotos() {
    // 初回チェック（即座に実行）
    _performPhotoCheck();

    // 遅延チェック（レイアウト完了を待つ）
    Future.delayed(
      Duration(milliseconds: TimelineScrollConstants.layoutCompleteDelayMs),
      () {
        if (isMounted()) {
          _performPhotoCheck();
        }
      },
    );

    // さらなる遅延チェック（完全な初期化を待つ）
    Future.delayed(
      Duration(
        milliseconds: TimelineScrollConstants.initializationCompleteDelayMs,
      ),
      () {
        if (isMounted()) {
          _performPhotoCheck();
        }
      },
    );
  }

  /// 実際の写真不足チェックロジック
  void _performPhotoCheck() {
    if (!scrollController.hasClients || isLoadingMore || !hasMorePhotos()) {
      return;
    }

    final position = scrollController.position;
    final count = photoCount();

    logger.info(
      'スクロール可能性チェック: maxScrollExtent=${position.maxScrollExtent.toStringAsFixed(1)}, '
      'photoCount=$count, hasMorePhotos=${hasMorePhotos()}',
      context: 'TimelinePhotoWidget._performPhotoCheck',
    );

    // 条件を緩和：スクロール範囲が閾値以下で写真が上限未満の場合
    if (position.maxScrollExtent <=
            TimelineScrollConstants.scrollCheckThreshold &&
        count > 0 &&
        count < TimelineScrollConstants.maxPhotosForAutoLoad) {
      logger.info(
        'スクロール不可のため追加読み込み要求: maxScrollExtent=${position.maxScrollExtent.toStringAsFixed(1)}, threshold=${TimelineScrollConstants.scrollCheckThreshold}',
        context: 'TimelinePhotoWidget._performPhotoCheck',
      );

      if (onLoadMorePhotos != null && !isLoadingMore) {
        requestMorePhotos();
      }
    }
  }

  /// スケルトンページ数を増加
  void increasePlaceholderPages() {
    if (placeholderPages >= AppConstants.timelinePlaceholderMaxPages) return;

    // 短時間での連続増加を防ぐ（スムーズなUX）
    final now = DateTime.now();
    if (_lastPlaceholderIncrease != null &&
        now.difference(_lastPlaceholderIncrease!).inMilliseconds <
            TimelineScrollConstants.placeholderIncreaseDebounceMs) {
      return;
    }

    updateState(() {
      // 最低でも1ページは表示する
      if (placeholderPages == 0) {
        placeholderPages = 1;
      } else {
        placeholderPages += 1;
      }
    });
    _lastPlaceholderIncrease = now;
  }

  /// スケルトンページ数を段階的に減らす
  void decreasePlaceholderPages() {
    if (placeholderPages <= 0) return;

    updateState(() {
      placeholderPages = (placeholderPages - 1).clamp(
        0,
        AppConstants.timelinePlaceholderMaxPages,
      );
    });

    logger.info(
      'スケルトンページ数を減少: $placeholderPages',
      context: 'TimelinePhotoWidget._decreasePlaceholderPages',
    );
  }

  /// 写真数増加時の処理
  void handlePhotoCountIncrease(int currentCount) {
    // 初回読み込み完了時
    if (isInitialLoad) {
      isInitialLoad = false;
      // 初回はスケルトンを段階的に減らす（急激な変化を避ける）
      if (placeholderPages >
          TimelineScrollConstants.initialLoadPlaceholderLimit) {
        placeholderPages = TimelineScrollConstants.initialLoadPlaceholderLimit;
      }
      return;
    }

    // 継続的な先読み時は、大幅な増加時のみスケルトンを調整
    final increaseAmount = currentCount - lastAssetsCount;

    // 大量の写真が一度に読み込まれた場合のみスケルトンを減らす
    if (increaseAmount >= TimelineScrollConstants.bulkLoadThreshold) {
      placeholderPages = (placeholderPages - 1).clamp(
        1,
        AppConstants.timelinePlaceholderMaxPages,
      );
      logger.info(
        '大量読み込み完了でスケルトン調整: 増加数=$increaseAmount, 新スケルトン数=$placeholderPages',
        context: 'TimelinePhotoWidget._handlePhotoCountIncrease',
      );
    }
  }
}
