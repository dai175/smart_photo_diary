import 'dart:async';

import 'package:flutter/widgets.dart';

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

  /// 現在の実写真数
  int Function() photoCount = () => 0;

  /// プレースホルダー込みの総アイテム数
  int Function() totalItemCount = () => 0;

  /// ビューポート幅（タイルサイズ算出用）
  double Function() viewportWidth = () => 0;

  // 無限スクロール用状態
  bool isLoadingMore = false;
  int lastAssetsCount = 0;
  bool isInitialLoad = true;
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
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// 実写真の末端に対応するスクロール位置を推定
  ///
  /// プレースホルダーは最後のグループにのみ追加されるため、
  /// プレースホルダーのスクロール高さを算出し maxScrollExtent から差し引く。
  /// ヘッダーや余白はプレースホルダーの有無に関わらず同じなので影響しない。
  double _estimateRealContentEnd() {
    final position = scrollController.position;
    final total = totalItemCount();
    final real = photoCount();
    if (total <= 0 || real <= 0) return position.maxScrollExtent;

    final placeholderCount = total - real;
    if (placeholderCount <= 0) return position.maxScrollExtent;

    final vw = viewportWidth();
    if (vw <= 0) return position.maxScrollExtent;

    // タイルサイズ算出（aspectRatio=1.0 なので幅=高さ）
    const cols = TimelineLayoutConstants.crossAxisCount;
    const spacing = TimelineLayoutConstants.crossAxisSpacing;
    final tileSize = (vw - spacing * (cols - 1)) / cols;

    const mainSpacing = TimelineLayoutConstants.mainAxisSpacing;
    final placeholderRows = (placeholderCount / cols).ceil();
    final placeholderHeight =
        placeholderRows * tileSize + (placeholderRows - 1) * mainSpacing;

    return position.maxScrollExtent - placeholderHeight;
  }

  /// スクロール検知（実写真末端基準の2段階先読み）
  void onScroll() {
    if (!scrollController.hasClients) return;

    final position = scrollController.position;
    final pixels = position.pixels;
    final maxScrollExtent = position.maxScrollExtent;

    // ビューポート先読み（サムネイル）— データ追加読み込みとは独立
    onViewportPrefetch?.call();

    if (!hasMorePhotos() || maxScrollExtent <= 0) return;

    // 実写真の末端位置を基準に閾値を判定
    final realContentEnd = _estimateRealContentEnd();

    final now = DateTime.now();

    // 段階1: 先読み開始（UIブロッキングなし）
    if (pixels >= realContentEnd - TimelineScrollConstants.preloadThreshold) {
      // 短時間の重複呼び出しを防ぐ
      if (_lastPreloadCall == null ||
          now.difference(_lastPreloadCall!).inMilliseconds >
              TimelineScrollConstants.scrollCheckIntervalMs) {
        _lastPreloadCall = now;
        logger.info(
          '先読みトリガー: pixels=$pixels, realContentEnd=${realContentEnd.toStringAsFixed(0)}, threshold=${TimelineScrollConstants.preloadThreshold}',
          context: 'TimelineScrollManager.onScroll',
        );
        onPreloadMorePhotos?.call();
      }
    }

    // 段階2: 確実な読み込み（UIフィードバックあり）
    if (pixels >= realContentEnd - TimelineScrollConstants.loadMoreThreshold) {
      if (!isLoadingMore &&
          (_lastLoadMoreCall == null ||
              now.difference(_lastLoadMoreCall!).inMilliseconds >
                  TimelineScrollConstants.scrollCheckIntervalMs)) {
        _lastLoadMoreCall = now;
        logger.info(
          '追加読み込みトリガー: pixels=$pixels, realContentEnd=${realContentEnd.toStringAsFixed(0)}, threshold=${TimelineScrollConstants.loadMoreThreshold}',
          context: 'TimelineScrollManager.onScroll',
        );
        requestMorePhotos();
      }
    }
  }

  /// 追加写真読み込み要求（HomeScreenに委譲）
  void requestMorePhotos() {
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
      const Duration(
        milliseconds: TimelineScrollConstants.layoutCompleteDelayMs,
      ),
      () {
        if (isMounted()) {
          _performPhotoCheck();
        }
      },
    );

    // さらなる遅延チェック（完全な初期化を待つ）
    Future.delayed(
      const Duration(
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

    final count = photoCount();

    // 実写真だけでスクロール可能なら追加読み込み不要
    // realContentEnd ≈ realContentHeight - viewportDimension なので > 0 で判定
    final realContentEnd = _estimateRealContentEnd();
    if (realContentEnd > 0) {
      return;
    }

    // 実写真がビューポートに収まる（スクロール不要）場合は自動読み込み
    if (count > 0 && count < TimelineScrollConstants.maxPhotosForAutoLoad) {
      logger.info(
        '写真数不足のため追加読み込み要求: photoCount=$count',
        context: 'TimelineScrollManager._performPhotoCheck',
      );

      if (onLoadMorePhotos != null && !isLoadingMore) {
        requestMorePhotos();
      }
    }
  }

  /// 写真数増加時の処理
  void handlePhotoCountIncrease(int currentCount) {
    if (isInitialLoad) {
      isInitialLoad = false;
    }
  }
}
