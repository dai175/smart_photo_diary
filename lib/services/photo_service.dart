import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';

/// 写真の取得と管理を担当するサービスクラス
class PhotoService {
  /// 写真アクセス権限をリクエストする
  ///
  /// 戻り値: 権限が付与されたかどうか
  static Future<bool> requestPermission() async {
    // permission_handlerを使用して権限をリクエスト
    // Android 13以上とそれ以前で権限が異なる
    if (await Permission.photos.request().isGranted) {
      debugPrint('写真権限が許可されました');
      return true;
    }

    // 写真権限をリクエスト
    var status = await Permission.photos.request();
    debugPrint('写真権限ステータス: $status');

    if (status.isGranted) {
      // 権限が許可された
      return true;
    } else if (status.isPermanentlyDenied) {
      // 権限が永続的に拒否された場合は設定画面を開くように促す
      debugPrint('権限が永続的に拒否されました。設定から有効にしてください。');
      return false;
    }

    // 後方互換性のためにPhotoManagerの権限もチェック
    final PermissionState pmResult =
        await PhotoManager.requestPermissionExtend();
    debugPrint('PhotoManager権限状態: ${pmResult.isAuth}');

    return status.isGranted || pmResult.isAuth;
  }

  /// 今日撮影された写真を取得する
  ///
  /// [limit]: 取得する写真の最大数
  /// 戻り値: 写真アセットのリスト
  static Future<List<AssetEntity>> getTodayPhotos({int limit = 20}) async {
    // 権限チェック
    final bool hasPermission = await requestPermission();
    debugPrint('写真アクセス権限: $hasPermission');
    if (!hasPermission) {
      return [];
    }

    try {
      // 今日の日付の範囲を計算
      final DateTime now = DateTime.now();
      final DateTime startOfDay = DateTime(now.year, now.month, now.day);
      final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      debugPrint('日付範囲: $startOfDay - $endOfDay');

      // 写真を取得
      final FilterOptionGroup filterOption = FilterOptionGroup(
        orders: [const OrderOption()],
        createTimeCond: DateTimeCond(min: startOfDay, max: endOfDay),
      );

      // アルバムを取得（最近の写真）
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        filterOption: filterOption,
      );

      debugPrint('取得したアルバム数: ${albums.length}');

      if (albums.isEmpty) {
        debugPrint('アルバムが見つかりません');
        return [];
      }

      // 最近の写真アルバムから写真を取得
      final AssetPathEntity recentAlbum = albums.first;
      debugPrint('アルバム名: ${recentAlbum.name}');

      final List<AssetEntity> assets = await recentAlbum.getAssetListRange(
        start: 0,
        end: limit,
      );

      debugPrint('取得した写真数: ${assets.length}');
      return assets;
    } catch (e) {
      debugPrint('写真取得エラー: $e');
      return [];
    }
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
    debugPrint('写真アクセス権限: $hasPermission');
    if (!hasPermission) {
      return [];
    }

    try {
      // 指定日の日付範囲を計算
      final DateTime startOfDay = DateTime(date.year, date.month, date.day);
      final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      debugPrint('日付範囲: $startOfDay - $endOfDay');

      // 写真を取得
      final FilterOptionGroup filterOption = FilterOptionGroup(
        orders: [const OrderOption()],
        createTimeCond: DateTimeCond(min: startOfDay, max: endOfDay),
      );

      // アルバムを取得
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        filterOption: filterOption,
      );

      debugPrint('取得したアルバム数: ${albums.length}');

      if (albums.isEmpty) {
        debugPrint('アルバムが見つかりません');
        return [];
      }

      // アルバムから写真を取得
      final AssetPathEntity album = albums.first;
      debugPrint('アルバム名: ${album.name}');

      final List<AssetEntity> assets = await album.getAssetListRange(
        start: 0,
        end: limit,
      );

      debugPrint('取得した写真数: ${assets.length}');
      return assets;
    } catch (e) {
      debugPrint('写真取得エラー: $e');
      return [];
    }
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
    try {
      return await asset.thumbnailDataWithSize(ThumbnailSize(width, height));
    } catch (e) {
      debugPrint('サムネイル取得エラー: $e');
      return null;
    }
  }

  /// 写真の元画像を取得する
  ///
  /// [asset]: 写真アセット
  /// 戻り値: 元の画像ファイル
  static Future<Uint8List?> getOriginalFile(AssetEntity asset) async {
    try {
      return await asset.originBytes;
    } catch (e) {
      debugPrint('元画像取得エラー: $e');
      return null;
    }
  }

  /// すべての写真を取得する（日付フィルターなし）
  ///
  /// [limit]: 取得する写真の最大数
  /// 戻り値: 写真アセットのリスト
  static Future<List<AssetEntity>> getAllPhotos({int limit = 100}) async {
    // 権限チェック
    final bool hasPermission = await requestPermission();
    debugPrint('写真アクセス権限: $hasPermission');
    if (!hasPermission) {
      return [];
    }

    try {
      // 写真を取得するためのフィルターオプション
      final FilterOptionGroup filterOption = FilterOptionGroup(
        orders: [const OrderOption()],
      );

      // アルバムを取得
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        filterOption: filterOption,
      );

      debugPrint('取得したアルバム数: ${albums.length}');

      if (albums.isEmpty) {
        debugPrint('アルバムが見つかりません');
        return [];
      }

      // アルバムから写真を取得
      final AssetPathEntity album = albums.first;
      debugPrint('アルバム名: ${album.name}');

      final List<AssetEntity> assets = await album.getAssetListRange(
        start: 0,
        end: limit,
      );

      debugPrint('取得した写真数: ${assets.length}');
      return assets;
    } catch (e) {
      debugPrint('写真取得エラー: $e');
      return [];
    }
  }
}
