import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import '../../core/result/result.dart';

/// 写真キャッシュサービスのインターフェース
abstract class IPhotoCacheService {
  /// サムネイルを取得（キャッシュがあればキャッシュから、なければ生成してキャッシュ）
  ///
  /// [asset] 対象のアセット
  /// [width] サムネイル幅（デフォルト: 200）
  /// [height] サムネイル高さ（デフォルト: 200）
  /// [quality] JPEG品質（デフォルト: 80）
  /// 戻り値: サムネイルのバイトデータのResult。エラー時は Failure(PhotoAccessException)。
  Future<Result<Uint8List>> getThumbnail(
    AssetEntity asset, {
    int width = 200,
    int height = 200,
    int quality = 80,
  });

  /// メモリキャッシュをクリア
  ///
  /// 全てのキャッシュエントリーを削除する。
  void clearMemoryCache();

  /// 特定のアセットのキャッシュをクリア
  ///
  /// [assetId] 対象のアセットID
  void clearCacheForAsset(String assetId);

  /// キャッシュサイズを取得（デバッグ用）
  ///
  /// 戻り値: 現在キャッシュされているエントリー数。
  int getCacheSize();

  /// プリロード：指定された写真のサムネイルを事前に読み込み
  ///
  /// [assets] プリロード対象のアセットリスト
  /// [width] サムネイル幅（デフォルト: 200）
  /// [height] サムネイル高さ（デフォルト: 200）
  /// [quality] JPEG品質（デフォルト: 80）
  ///
  /// 個々のアセットの読み込み失敗は無視され、処理は継続される。
  Future<void> preloadThumbnails(
    List<AssetEntity> assets, {
    int width = 200,
    int height = 200,
    int quality = 80,
  });

  /// 期限切れエントリーのクリーンアップ
  ///
  /// TTLを超過したキャッシュエントリーを削除する。
  void cleanupExpiredEntries();
}
