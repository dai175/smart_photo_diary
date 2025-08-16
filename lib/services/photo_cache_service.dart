import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'interfaces/photo_cache_service_interface.dart';
import 'logging_service.dart';
import '../core/errors/error_handler.dart';

/// メモリキャッシュのエントリー
class _CacheEntry {
  final Uint8List data;
  final DateTime timestamp;
  final int size;

  _CacheEntry({
    required this.data,
    required this.timestamp,
    required this.size,
  });
}

/// 写真のサムネイルキャッシュを管理するサービス
class PhotoCacheService implements IPhotoCacheService {
  // シングルトンパターン
  static PhotoCacheService? _instance;

  PhotoCacheService._();

  static PhotoCacheService getInstance() {
    _instance ??= PhotoCacheService._();
    return _instance!;
  }

  // メモリキャッシュ
  final Map<String, _CacheEntry> _memoryCache = {};

  // キャッシュ設定
  static const int _maxMemoryCacheSizeInBytes = 100 * 1024 * 1024; // 100MB
  static const int _maxCacheEntries = 500; // 最大500エントリー
  static const Duration _cacheExpiration = Duration(hours: 1); // 1時間でキャッシュ期限切れ

  // メモリ警告閾値
  static const int _memoryWarningThreshold = 80 * 1024 * 1024; // 80MB
  static const int _memoryCriticalThreshold = 90 * 1024 * 1024; // 90MB

  // 現在のキャッシュサイズ（バイト）
  int _currentCacheSizeInBytes = 0;

  // メモリ監視用
  DateTime? _lastMemoryCheck;
  static const Duration _memoryCheckInterval = Duration(seconds: 30);

  /// サムネイルを取得（キャッシュがあればキャッシュから、なければ生成してキャッシュ）
  @override
  Future<Uint8List?> getThumbnail(
    AssetEntity asset, {
    int width = 200,
    int height = 200,
    int quality = 80,
  }) async {
    final loggingService = await LoggingService.getInstance();
    final cacheKey = _generateCacheKey(asset.id, width, height, quality);

    try {
      // キャッシュから取得を試みる
      final cachedEntry = _memoryCache[cacheKey];
      if (cachedEntry != null) {
        // キャッシュの有効期限チェック
        if (DateTime.now().difference(cachedEntry.timestamp) <
            _cacheExpiration) {
          loggingService.debug(
            'サムネイルをキャッシュから取得',
            context: 'PhotoCacheService.getThumbnail',
            data: 'assetId: ${asset.id}, size: ${width}x$height',
          );
          return cachedEntry.data;
        } else {
          // 期限切れのキャッシュを削除
          _removeFromCache(cacheKey);
        }
      }

      // キャッシュにない場合は生成
      final thumbnail = await asset.thumbnailDataWithSize(
        ThumbnailSize(width, height),
        quality: quality,
      );

      if (thumbnail != null) {
        // キャッシュに追加
        _addToCache(cacheKey, thumbnail);

        loggingService.debug(
          'サムネイルを生成してキャッシュに追加',
          context: 'PhotoCacheService.getThumbnail',
          data:
              'assetId: ${asset.id}, size: ${width}x$height, bytes: ${thumbnail.length}',
        );
      }

      return thumbnail;
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoCacheService.getThumbnail',
      );
      loggingService.error(
        'サムネイル取得エラー',
        context: 'PhotoCacheService.getThumbnail',
        error: appError,
      );
      return null;
    }
  }

  /// メモリキャッシュをクリア
  @override
  void clearMemoryCache() {
    _memoryCache.clear();
    _currentCacheSizeInBytes = 0;

    debugPrint('PhotoCacheService: メモリキャッシュをクリアしました');
  }

  /// 特定のアセットのキャッシュをクリア
  @override
  void clearCacheForAsset(String assetId) {
    final keysToRemove = _memoryCache.keys
        .where((key) => key.startsWith('$assetId:'))
        .toList();

    for (final key in keysToRemove) {
      _removeFromCache(key);
    }

    debugPrint('PhotoCacheService: アセット $assetId のキャッシュをクリアしました');
  }

  /// キャッシュサイズを取得（デバッグ用）
  @override
  int getCacheSize() {
    return _currentCacheSizeInBytes;
  }

  /// プリロード：指定された写真のサムネイルを事前に読み込み
  @override
  Future<void> preloadThumbnails(
    List<AssetEntity> assets, {
    int width = 200,
    int height = 200,
    int quality = 80,
  }) async {
    final loggingService = await LoggingService.getInstance();

    loggingService.debug(
      'サムネイルのプリロード開始',
      context: 'PhotoCacheService.preloadThumbnails',
      data: '写真数: ${assets.length}',
    );

    // 並列処理で効率的にプリロード
    final futures = <Future>[];
    for (final asset in assets) {
      // キャッシュに既に存在する場合はスキップ
      final cacheKey = _generateCacheKey(asset.id, width, height, quality);
      if (_memoryCache.containsKey(cacheKey)) {
        continue;
      }

      // 非同期でサムネイルを取得
      futures.add(
        getThumbnail(asset, width: width, height: height, quality: quality),
      );

      // 同時実行数を制限（メモリ負荷を抑える）
      if (futures.length >= 5) {
        await Future.wait(futures);
        futures.clear();
      }
    }

    // 残りの処理を待機
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    loggingService.debug(
      'サムネイルのプリロード完了',
      context: 'PhotoCacheService.preloadThumbnails',
      data:
          'キャッシュサイズ: ${(_currentCacheSizeInBytes / 1024 / 1024).toStringAsFixed(2)}MB',
    );
  }

  /// キャッシュキーを生成
  String _generateCacheKey(String assetId, int width, int height, int quality) {
    return '$assetId:${width}x$height:q$quality';
  }

  /// キャッシュに追加
  void _addToCache(String key, Uint8List data) {
    // メモリ監視
    _checkMemoryUsage();

    // キャッシュサイズの制限チェック
    if (_currentCacheSizeInBytes + data.length > _maxMemoryCacheSizeInBytes ||
        _memoryCache.length >= _maxCacheEntries) {
      // LRU（Least Recently Used）方式で古いエントリーを削除
      _evictOldestEntries();
    }

    final entry = _CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      size: data.length,
    );

    _memoryCache[key] = entry;
    _currentCacheSizeInBytes += data.length;

    // メモリ警告チェック
    if (_currentCacheSizeInBytes > _memoryCriticalThreshold) {
      _performAggressiveCleanup();
    }
  }

  /// キャッシュから削除
  void _removeFromCache(String key) {
    final entry = _memoryCache[key];
    if (entry != null) {
      _currentCacheSizeInBytes -= entry.size;
      _memoryCache.remove(key);
    }
  }

  /// 最も古いエントリーを削除（LRU）
  void _evictOldestEntries() {
    // タイムスタンプでソート
    final sortedEntries = _memoryCache.entries.toList()
      ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

    // 削除するエントリー数を計算（全体の20%または最低10エントリー）
    final entriesToRemove = (_memoryCache.length * 0.2).ceil().clamp(10, 50);

    for (var i = 0; i < entriesToRemove && i < sortedEntries.length; i++) {
      _removeFromCache(sortedEntries[i].key);
    }

    debugPrint('PhotoCacheService: キャッシュエビクション実行 - $entriesToRemove エントリーを削除');
  }

  /// メモリ使用状況をチェック
  void _checkMemoryUsage() async {
    final now = DateTime.now();
    if (_lastMemoryCheck != null &&
        now.difference(_lastMemoryCheck!) < _memoryCheckInterval) {
      return;
    }

    _lastMemoryCheck = now;

    // メモリ使用量を記録
    final loggingService = await LoggingService.getInstance();
    loggingService.debug(
      'キャッシュメモリ使用状況',
      context: 'PhotoCacheService._checkMemoryUsage',
      data: {
        'currentSize':
            '${(_currentCacheSizeInBytes / 1024 / 1024).toStringAsFixed(2)}MB',
        'entries': _memoryCache.length,
        'threshold': _currentCacheSizeInBytes > _memoryWarningThreshold
            ? 'WARNING'
            : 'OK',
      }.toString(),
    );

    // 警告閾値を超えている場合
    if (_currentCacheSizeInBytes > _memoryWarningThreshold) {
      loggingService.warning(
        'キャッシュメモリ使用量が警告閾値を超えました',
        context: 'PhotoCacheService._checkMemoryUsage',
        data:
            '${(_currentCacheSizeInBytes / 1024 / 1024).toStringAsFixed(2)}MB / ${(_memoryWarningThreshold / 1024 / 1024)}MB',
      );
    }
  }

  /// アグレッシブなクリーンアップ
  void _performAggressiveCleanup() async {
    final loggingService = await LoggingService.getInstance();
    loggingService.warning(
      'アグレッシブクリーンアップを実行',
      context: 'PhotoCacheService._performAggressiveCleanup',
      data:
          '現在のサイズ: ${(_currentCacheSizeInBytes / 1024 / 1024).toStringAsFixed(2)}MB',
    );

    // タイムスタンプでソート
    final sortedEntries = _memoryCache.entries.toList()
      ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

    // 50%のエントリーを削除
    final entriesToRemove = (_memoryCache.length * 0.5).ceil();

    for (var i = 0; i < entriesToRemove && i < sortedEntries.length; i++) {
      _removeFromCache(sortedEntries[i].key);
    }

    loggingService.info(
      'アグレッシブクリーンアップ完了',
      context: 'PhotoCacheService._performAggressiveCleanup',
      data:
          'クリーンアップ後: ${(_currentCacheSizeInBytes / 1024 / 1024).toStringAsFixed(2)}MB',
    );
  }

  /// 期限切れエントリーのクリーンアップ
  @override
  void cleanupExpiredEntries() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    _memoryCache.forEach((key, entry) {
      if (now.difference(entry.timestamp) > _cacheExpiration) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      _removeFromCache(key);
    }

    if (keysToRemove.isNotEmpty) {
      debugPrint(
        'PhotoCacheService: ${keysToRemove.length} 件の期限切れエントリーをクリーンアップ',
      );
    }
  }
}
