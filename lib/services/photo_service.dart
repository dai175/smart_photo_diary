import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_constants.dart';
import 'interfaces/photo_service_interface.dart';

/// 写真の取得と管理を担当するサービスクラス
class PhotoService implements PhotoServiceInterface {
  // シングルトンパターン
  static PhotoService? _instance;

  PhotoService._();

  static PhotoService getInstance() {
    _instance ??= PhotoService._();
    return _instance!;
  }

  /// 写真アクセス権限をリクエストする
  ///
  /// 戻り値: 権限が付与されたかどうか
  @override
  Future<bool> requestPermission() async {
    try {
      debugPrint('=== PhotoService.requestPermission() 開始 ===');

      // まずはPhotoManagerで権限リクエスト（これがメイン）
      final pmState = await PhotoManager.requestPermissionExtend();
      debugPrint('PhotoManager権限状態: $pmState');

      if (pmState.isAuth) {
        debugPrint('PhotoManagerで権限が付与されました');
        return true;
      }

      // Limited access の場合も部分的に許可とみなす（iOS専用）
      if (pmState == PermissionState.limited) {
        debugPrint('PhotoManagerで制限つきアクセスが許可されました');
        return true;
      }

      // PhotoManagerで権限が拒否された場合、Androidでは追加でpermission_handlerを試す
      if (defaultTargetPlatform == TargetPlatform.android) {
        debugPrint('Android: permission_handlerで追加の権限チェックを実行');

        // Android 13以降は Permission.photos、それ以前は Permission.storage
        Permission permission = Permission.photos;

        var status = await permission.status;
        debugPrint('permission_handler権限状態: $status');

        // 権限が未決定または拒否の場合は明示的にリクエスト
        if (status.isDenied) {
          debugPrint('Android: 権限を明示的にリクエストします');
          status = await permission.request();
          debugPrint('Android: リクエスト後の権限状態: $status');

          if (status.isGranted) {
            debugPrint('Android: permission_handlerで権限が付与されました');
            // PhotoManagerで再度確認
            final pmStateAfter = await PhotoManager.requestPermissionExtend();
            debugPrint('Android: PhotoManager再確認結果: $pmStateAfter');
            return pmStateAfter.isAuth;
          }
        }

        // 永続的に拒否されている場合
        if (status.isPermanentlyDenied) {
          debugPrint('Android: 権限が永続的に拒否されています');
          return false;
        }
      }

      debugPrint('権限が拒否されています。pmState: $pmState');
      return false;
    } catch (e) {
      debugPrint('権限リクエストエラー: $e');
      return false;
    }
  }

  /// 権限が永続的に拒否されているかチェック
  @override
  Future<bool> isPermissionPermanentlyDenied() async {
    try {
      final currentStatus = await Permission.photos.status;
      return currentStatus.isPermanentlyDenied;
    } catch (e) {
      return false;
    }
  }

  /// 今日撮影された写真を取得する
  ///
  /// [limit]: 取得する写真の最大数
  /// 戻り値: 写真アセットのリスト
  @override
  Future<List<AssetEntity>> getTodayPhotos({int limit = 20}) async {
    // 権限チェック
    final bool hasPermission = await requestPermission();
    if (!hasPermission) {
      return [];
    }

    try {
      // 今日の日付の範囲を計算
      final DateTime now = DateTime.now();
      final DateTime startOfDay = DateTime(now.year, now.month, now.day);
      final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

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

  /// 指定された日付範囲の写真を取得する
  ///
  /// [startDate]: 開始日時
  /// [endDate]: 終了日時
  /// [limit]: 取得する写真の最大数
  /// 戻り値: 写真アセットのリスト
  @override
  Future<List<AssetEntity>> getPhotosInDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  }) async {
    // 権限チェック
    final bool hasPermission = await requestPermission();
    debugPrint('写真アクセス権限: $hasPermission');
    if (!hasPermission) {
      return [];
    }

    try {
      debugPrint('日付範囲: $startDate - $endDate');

      // 写真を取得
      final FilterOptionGroup filterOption = FilterOptionGroup(
        orders: [const OrderOption()],
        createTimeCond: DateTimeCond(min: startDate, max: endDate),
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

  /// 写真のバイナリデータを取得する
  ///
  /// [asset]: 写真アセット
  /// 戻り値: 写真のバイナリデータ
  @override
  Future<List<int>?> getPhotoData(AssetEntity asset) async {
    try {
      final Uint8List? data = await asset.originBytes;
      return data?.toList();
    } catch (e) {
      debugPrint('写真データ取得エラー: $e');
      return null;
    }
  }

  /// 写真のサムネイルデータを取得する
  ///
  /// [asset]: 写真アセット
  /// 戻り値: サムネイルのバイナリデータ
  @override
  Future<List<int>?> getThumbnailData(AssetEntity asset) async {
    try {
      final Uint8List? data = await asset.thumbnailDataWithSize(
        const ThumbnailSize(
          AppConstants.defaultThumbnailWidth,
          AppConstants.defaultThumbnailHeight,
        ),
      );
      return data?.toList();
    } catch (e) {
      debugPrint('サムネイルデータ取得エラー: $e');
      return null;
    }
  }

  /// 特定の日付の写真を取得する（後方互換性のため保持）
  ///
  /// [date]: 取得したい日付
  /// [limit]: 取得する写真の最大数
  /// 戻り値: 写真アセットのリスト
  Future<List<AssetEntity>> getPhotosByDate(
    DateTime date, {
    int limit = AppConstants.defaultPhotoLimit,
  }) async {
    final DateTime startOfDay = DateTime(date.year, date.month, date.day);
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    return await getPhotosInDateRange(
      startDate: startOfDay,
      endDate: endOfDay,
      limit: limit,
    );
  }

  /// Limited Photo Access時に写真選択画面を表示
  @override
  Future<bool> presentLimitedLibraryPicker() async {
    try {
      await PhotoManager.presentLimited();
      return true;
    } catch (e) {
      debugPrint('Limited Library Picker表示エラー: $e');
      return false;
    }
  }

  /// 現在の権限状態が Limited Access かチェック
  @override
  Future<bool> isLimitedAccess() async {
    try {
      final pmState = await PhotoManager.requestPermissionExtend();
      return pmState == PermissionState.limited;
    } catch (e) {
      debugPrint('権限状態チェックエラー: $e');
      return false;
    }
  }

  /// 写真のサムネイルを取得する（後方互換性のため保持）
  ///
  /// [asset]: 写真アセット
  /// [width]: サムネイルの幅
  /// [height]: サムネイルの高さ
  /// 戻り値: サムネイル画像
  @override
  Future<Uint8List?> getThumbnail(
    AssetEntity asset, {
    int width = AppConstants.defaultThumbnailWidth,
    int height = AppConstants.defaultThumbnailHeight,
  }) async {
    try {
      return await asset.thumbnailDataWithSize(ThumbnailSize(width, height));
    } catch (e) {
      debugPrint('サムネイル取得エラー: $e');
      return null;
    }
  }

  /// 写真の元画像を取得する（後方互換性のため保持）
  ///
  /// [asset]: 写真アセット
  /// 戻り値: 元の画像ファイル
  @override
  Future<Uint8List?> getOriginalFile(AssetEntity asset) async {
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
  Future<List<AssetEntity>> getAllPhotos({
    int limit = AppConstants.maxPhotoLimit,
  }) async {
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
