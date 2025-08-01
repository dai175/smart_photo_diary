/// 写真キャッシュ関連の定数
class PhotoCacheConstants {
  // サムネイルサイズ設定
  static const int thumbnailSizeSmall = 100; // 小サイズ（グリッド表示用）
  static const int thumbnailSizeMedium = 200; // 中サイズ（詳細表示用）
  static const int thumbnailSizeLarge = 400; // 大サイズ（プレビュー用）

  // サムネイル品質設定
  static const int thumbnailQualityLow = 50; // 低品質（高速読み込み）
  static const int thumbnailQualityMedium = 70; // 中品質（バランス）
  static const int thumbnailQualityHigh = 90; // 高品質（高画質）

  // キャッシュ設定
  static const int maxMemoryCacheSizeMB = 100; // メモリキャッシュの最大サイズ（MB）
  static const int maxCacheEntries = 500; // 最大キャッシュエントリー数
  static const Duration cacheExpiration = Duration(hours: 1); // キャッシュ有効期限

  // 遅延読み込み設定
  static const int itemsPerPage = 30; // 1ページあたりのアイテム数
  static const int preloadThreshold = 200; // プリロード開始のスクロール閾値（ピクセル）
  static const int maxConcurrentLoads = 5; // 同時読み込み最大数

  // デバイスごとの最適化設定
  static int getOptimalThumbnailSize(double devicePixelRatio) {
    if (devicePixelRatio <= 1.0) {
      return thumbnailSizeSmall;
    } else if (devicePixelRatio <= 2.0) {
      return thumbnailSizeMedium;
    } else {
      // Retina以上のディスプレイ
      return thumbnailSizeLarge;
    }
  }

  static int getOptimalQuality(double devicePixelRatio) {
    if (devicePixelRatio <= 1.0) {
      return thumbnailQualityLow;
    } else if (devicePixelRatio <= 2.0) {
      return thumbnailQualityMedium;
    } else {
      return thumbnailQualityHigh;
    }
  }
}
