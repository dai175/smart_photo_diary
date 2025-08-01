import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';

/// 写真キャッシュサービスのインターフェース
abstract class PhotoCacheServiceInterface {
  /// サムネイルを取得（キャッシュがあればキャッシュから、なければ生成してキャッシュ）
  Future<Uint8List?> getThumbnail(
    AssetEntity asset, {
    int width = 200,
    int height = 200,
    int quality = 80,
  });

  /// メモリキャッシュをクリア
  void clearMemoryCache();

  /// 特定のアセットのキャッシュをクリア
  void clearCacheForAsset(String assetId);

  /// キャッシュサイズを取得（デバッグ用）
  int getCacheSize();

  /// プリロード：指定された写真のサムネイルを事前に読み込み
  Future<void> preloadThumbnails(
    List<AssetEntity> assets, {
    int width = 200,
    int height = 200,
    int quality = 80,
  });
}
