import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';

/// 写真の取得と管理を担当するサービスクラス
class PhotoService {
  /// 写真アクセス権限をリクエストする
  ///
  /// 戻り値: 権限が付与されたかどうか
  static Future<bool> requestPermission() async {
    final PermissionState result = await PhotoManager.requestPermissionExtend();
    return result.isAuth;
  }

  /// 今日撮影された写真を取得する
  ///
  /// [limit]: 取得する写真の最大数
  /// 戻り値: 写真アセットのリスト
  static Future<List<AssetEntity>> getTodayPhotos({int limit = 20}) async {
    // 権限チェック
    final bool hasPermission = await requestPermission();
    if (!hasPermission) {
      return [];
    }

    // 今日の日付の範囲を計算
    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(now.year, now.month, now.day);
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    // 写真を取得
    final FilterOptionGroup filterOption = FilterOptionGroup(
      orders: [const OrderOption(type: OrderOptionType.createDate)],
      createTimeCond: DateTimeCond(min: startOfDay, max: endOfDay),
    );

    // アルバムを取得（最近の写真）
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      onlyAll: true,
      filterOption: filterOption,
    );

    if (albums.isEmpty) {
      return [];
    }

    // 最近の写真アルバムから写真を取得
    final AssetPathEntity recentAlbum = albums.first;
    final List<AssetEntity> assets = await recentAlbum.getAssetListRange(
      start: 0,
      end: limit,
    );

    return assets;
  }

  /// 特定の日付の写真を取得する
  ///
  /// [date]: 取得したい日付
  /// [limit]: 取得する写真の最大数
  /// 戻り値: 写真アセットのリスト
  static Future<List<AssetEntity>> getPhotosByDate(
    DateTime date, {
    int limit = 20,
  }) async {
    // 権限チェック
    final bool hasPermission = await requestPermission();
    if (!hasPermission) {
      return [];
    }

    // 指定日の日付範囲を計算
    final DateTime startOfDay = DateTime(date.year, date.month, date.day);
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    // 写真を取得
    final FilterOptionGroup filterOption = FilterOptionGroup(
      orders: [const OrderOption(type: OrderOptionType.createDate)],
      createTimeCond: DateTimeCond(min: startOfDay, max: endOfDay),
    );

    // アルバムを取得
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      onlyAll: true,
      filterOption: filterOption,
    );

    if (albums.isEmpty) {
      return [];
    }

    // アルバムから写真を取得
    final AssetPathEntity album = albums.first;
    final List<AssetEntity> assets = await album.getAssetListRange(
      start: 0,
      end: limit,
    );

    return assets;
  }

  /// 写真のサムネイルを取得する
  ///
  /// [asset]: 写真アセット
  /// [width]: サムネイルの幅
  /// [height]: サムネイルの高さ
  /// 戻り値: サムネイル画像
  static Future<Uint8List?> getThumbnail(
    AssetEntity asset, {
    int width = 200,
    int height = 200,
  }) async {
    return asset.thumbnailDataWithSize(ThumbnailSize(width, height));
  }

  /// 写真の元画像を取得する
  ///
  /// [asset]: 写真アセット
  /// 戻り値: 元の画像ファイル
  static Future<Uint8List?> getOriginalFile(AssetEntity asset) async {
    return asset.originBytes;
  }
}
