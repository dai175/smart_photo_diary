import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../constants/app_constants.dart';
import '../../core/result/result.dart';
import '../../core/service_locator.dart';
import '../../services/interfaces/photo_cache_service_interface.dart';
import 'timeline_constants.dart';

/// タイムラインのサムネイルキャッシュ・先読み管理ヘルパー
///
/// [IPhotoCacheService] は初回アクセス時に遅延解決される。
/// これにより、テスト環境等でサービス未登録時にもインデックスキャッシュ等の
/// 軽量操作は問題なく利用できる。
class TimelineCacheManager {
  late final IPhotoCacheService _cacheService = serviceLocator
      .get<IPhotoCacheService>();
  final Map<String, Future<Result<Uint8List>>> _thumbFutureCache = {};
  final Map<String, int> _photoIndexCache = {};

  Timer? _prefetchDebounce;
  int _lastPrefetchStartIndex = -1;
  bool _isViewportPrefetching = false;

  TimelineCacheManager();

  /// 写真インデックスキャッシュ（メインインデックス検索用）
  Map<String, int> get photoIndexCache => _photoIndexCache;

  /// 指定アセットのサムネイルFutureをサイズ/品質込みのキーでメモ化
  Future<Result<Uint8List>> getThumbnailFuture(AssetEntity asset) {
    final key =
        '${asset.id}:${TimelineLayoutConstants.thumbnailSize}x${TimelineLayoutConstants.thumbnailSize}:q${TimelineLayoutConstants.thumbnailQuality}';
    return _thumbFutureCache.putIfAbsent(
      key,
      () => _cacheService.getThumbnail(
        asset,
        width: TimelineLayoutConstants.thumbnailSize,
        height: TimelineLayoutConstants.thumbnailSize,
        quality: TimelineLayoutConstants.thumbnailQuality,
      ),
    );
  }

  /// 写真インデックスキャッシュを再構築（パフォーマンス最適化）
  void rebuildPhotoIndexCache(List<AssetEntity> assets) {
    // 新しいキャッシュを作成（既存キャッシュを破壊しない）
    final newCache = <String, int>{};
    for (int i = 0; i < assets.length; i++) {
      newCache[assets[i].id] = i;
    }

    // 原子的操作でキャッシュを置き換え
    _photoIndexCache.clear();
    _photoIndexCache.addAll(newCache);
  }

  /// サムネイルFutureキャッシュの簡易クリーンアップ（非表示アセットを間引く）
  void pruneThumbFutureCache(Set<String> visibleIds) {
    if (_thumbFutureCache.length >
        AppConstants.thumbnailFutureCachePruneThreshold) {
      _thumbFutureCache.removeWhere((key, _) {
        final id = key.split(':').first;
        return !visibleIds.contains(id);
      });
    }
  }

  /// 現在のスクロール位置をもとにサムネイルを先読み
  void scheduleViewportPrefetch({
    required ScrollController scrollController,
    required bool Function() isMounted,
    required List<AssetEntity> Function() getAssets,
  }) {
    _prefetchDebounce?.cancel();
    _prefetchDebounce = Timer(const Duration(milliseconds: 200), () async {
      if (!isMounted() || _isViewportPrefetching) return;
      final assets = getAssets();
      if (assets.isEmpty) return;
      if (!scrollController.hasClients) return;

      final position = scrollController.position;
      final max = position.maxScrollExtent;
      final frac = max > 0 ? (position.pixels / max).clamp(0.0, 1.0) : 0.0;

      final total = assets.length;
      int start = (frac * total).floor();
      final window = AppConstants.timelinePrefetchAheadCount;
      final batch = AppConstants.timelinePrefetchBatchSize;
      int end = (start + window).clamp(0, total);

      // 過剰な重複実行を抑制
      if (_lastPrefetchStartIndex >= 0 &&
          (start - _lastPrefetchStartIndex).abs() < batch ~/ 2) {
        return;
      }

      _lastPrefetchStartIndex = start;
      _isViewportPrefetching = true;

      try {
        // シンプルなバッチプリロード
        for (int i = start; i < end; i += batch) {
          final j = (i + batch).clamp(0, total);
          final slice = assets.sublist(i, j);
          if (slice.isEmpty) break;

          await _cacheService.preloadThumbnails(
            slice,
            width: TimelineLayoutConstants.thumbnailSize,
            height: TimelineLayoutConstants.thumbnailSize,
            quality: TimelineLayoutConstants.thumbnailQuality,
          );
        }
      } finally {
        _isViewportPrefetching = false;
      }
    });
  }

  void dispose() {
    _prefetchDebounce?.cancel();
  }
}
