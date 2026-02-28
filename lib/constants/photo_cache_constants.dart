/// 写真キャッシュ関連の定数
class PhotoCacheConstants {
  // キャッシュ設定
  static const int maxMemoryCacheSizeMB = 100; // メモリキャッシュの最大サイズ（MB）
  static const int maxCacheEntries = 500; // 最大キャッシュエントリー数
  static const Duration cacheExpiration = Duration(hours: 1); // キャッシュ有効期限

  // 遅延読み込み設定
  static const int itemsPerPage = 30; // 1ページあたりのアイテム数
  static const int preloadThreshold = 200; // プリロード開始のスクロール閾値（ピクセル）
  static const int maxConcurrentLoads = 5; // 同時読み込み最大数
}
