import 'package:photo_manager/photo_manager.dart';

/// 写真サービスのインターフェース
abstract class PhotoServiceInterface {
  /// 写真アクセス権限をリクエストする
  Future<bool> requestPermission();

  /// 今日撮影された写真を取得する
  Future<List<AssetEntity>> getTodayPhotos({int limit = 20});

  /// 指定された日付範囲の写真を取得する
  Future<List<AssetEntity>> getPhotosInDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  });

  /// 写真のバイナリデータを取得する
  Future<List<int>?> getPhotoData(AssetEntity asset);

  /// 写真のサムネイルデータを取得する
  Future<List<int>?> getThumbnailData(AssetEntity asset);

  /// 写真の元画像を取得する（後方互換性）
  Future<dynamic> getOriginalFile(AssetEntity asset);

  /// 写真のサムネイルを取得する（後方互換性）
  Future<dynamic> getThumbnail(AssetEntity asset, {int width = 200, int height = 200});
}