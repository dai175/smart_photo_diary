import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_constants.dart';
import 'interfaces/photo_service_interface.dart';
import 'photo_cache_service.dart';
import 'logging_service.dart';
import '../core/errors/error_handler.dart';
import '../core/result/result.dart';
import '../core/result/result_extensions.dart';
import '../core/errors/photo_error.dart';

/// 写真の取得と管理を担当するサービスクラス
class PhotoService implements IPhotoService {
  // シングルトンパターン
  static PhotoService? _instance;

  // image_picker インスタンス
  final ImagePicker _imagePicker = ImagePicker();

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
    final loggingService = await LoggingService.getInstance();

    try {
      loggingService.debug(
        '権限リクエスト開始',
        context: 'PhotoService.requestPermission',
      );

      // まずはPhotoManagerで権限リクエスト（これがメイン）
      final pmState = await PhotoManager.requestPermissionExtend();
      loggingService.debug(
        'PhotoManager権限状態: $pmState',
        context: 'PhotoService.requestPermission',
      );

      if (pmState.isAuth) {
        loggingService.info(
          '写真アクセス権限が付与されました',
          context: 'PhotoService.requestPermission',
        );
        return true;
      }

      // Limited access の場合も部分的に許可とみなす（iOS専用）
      if (pmState == PermissionState.limited) {
        loggingService.info(
          '制限つき写真アクセスが許可されました',
          context: 'PhotoService.requestPermission',
        );
        return true;
      }

      // PhotoManagerで権限が拒否された場合、Androidでは追加でpermission_handlerを試す
      if (defaultTargetPlatform == TargetPlatform.android) {
        loggingService.debug(
          'Android: permission_handlerで追加の権限チェックを実行',
          context: 'PhotoService.requestPermission',
        );

        // Android 13以降は Permission.photos、それ以前は Permission.storage
        Permission permission = Permission.photos;

        var status = await permission.status;
        loggingService.debug(
          'permission_handler権限状態: $status',
          context: 'PhotoService.requestPermission',
        );

        // 権限が未決定または拒否の場合は明示的にリクエスト
        if (status.isDenied) {
          loggingService.debug(
            'Android: 権限を明示的にリクエストします',
            context: 'PhotoService.requestPermission',
          );
          status = await permission.request();
          loggingService.debug(
            'Android: リクエスト後の権限状態: $status',
            context: 'PhotoService.requestPermission',
          );

          if (status.isGranted) {
            loggingService.info(
              'Android: 権限が付与されました',
              context: 'PhotoService.requestPermission',
            );
            // PhotoManagerで再度確認
            final pmStateAfter = await PhotoManager.requestPermissionExtend();
            loggingService.debug(
              'Android: PhotoManager再確認結果: $pmStateAfter',
              context: 'PhotoService.requestPermission',
            );
            return pmStateAfter.isAuth;
          }
        }

        // 永続的に拒否されている場合
        if (status.isPermanentlyDenied) {
          loggingService.warning(
            'Android: 権限が永続的に拒否されています',
            context: 'PhotoService.requestPermission',
          );
          return false;
        }
      }

      loggingService.warning(
        '写真アクセス権限が拒否されました',
        context: 'PhotoService.requestPermission',
        data: 'pmState: $pmState',
      );
      return false;
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoService.requestPermission',
      );
      loggingService.error(
        '権限リクエストエラー',
        context: 'PhotoService.requestPermission',
        error: appError,
      );
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
    final loggingService = await LoggingService.getInstance();

    // 権限チェック
    final bool hasPermission = await requestPermission();
    if (!hasPermission) {
      loggingService.info(
        '写真アクセス権限がありません',
        context: 'PhotoService.getTodayPhotos',
      );
      return [];
    }

    try {
      // タイムゾーン対応: 今日の日付の範囲を計算（ローカルタイムゾーン）
      final DateTime now = DateTime.now();
      final DateTime startOfDay = DateTime(now.year, now.month, now.day);
      final DateTime endOfDay = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
        999,
      );

      // 写真を取得
      final FilterOptionGroup filterOption = FilterOptionGroup(
        orders: const [
          OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
        createTimeCond: DateTimeCond(min: startOfDay, max: endOfDay),
      );

      // アルバムを取得（最近の写真）
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: filterOption,
      );

      loggingService.debug(
        '取得したアルバム数: ${albums.length}',
        context: 'PhotoService.getTodayPhotos',
      );

      if (albums.isEmpty) {
        loggingService.debug(
          '今日のアルバムが見つかりません',
          context: 'PhotoService.getTodayPhotos',
        );
        return [];
      }

      // 最近の写真アルバムから写真を取得
      final AssetPathEntity recentAlbum = albums.first;
      loggingService.debug(
        'アルバム名: ${recentAlbum.name}',
        context: 'PhotoService.getTodayPhotos',
      );

      final List<AssetEntity> assets = await recentAlbum.getAssetListRange(
        start: 0,
        end: limit,
      );

      loggingService.info(
        '今日の写真を取得しました',
        context: 'PhotoService.getTodayPhotos',
        data: '取得数: ${assets.length}枚',
      );
      return assets;
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoService.getTodayPhotos',
      );
      loggingService.error(
        '写真取得エラー',
        context: 'PhotoService.getTodayPhotos',
        error: appError,
      );
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
    final loggingService = await LoggingService.getInstance();

    // 権限チェック
    final bool hasPermission = await requestPermission();
    if (!hasPermission) {
      loggingService.info(
        '写真アクセス権限がありません',
        context: 'PhotoService.getPhotosInDateRange',
      );
      return [];
    }

    try {
      // 日付の妥当性チェック
      final now = DateTime.now();
      if (startDate.isAfter(now)) {
        loggingService.warning(
          '開始日が未来の日付です',
          context: 'PhotoService.getPhotosInDateRange',
          data: 'startDate: $startDate',
        );
        return [];
      }

      // タイムゾーン対応: デバイスのローカルタイムゾーンで日付を正規化
      final localStartDate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        startDate.hour,
        startDate.minute,
        startDate.second,
      );
      final localEndDate = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        endDate.hour,
        endDate.minute,
        endDate.second,
      );

      loggingService.debug(
        '日付範囲: $localStartDate - $localEndDate (ローカルタイムゾーン)',
        context: 'PhotoService.getPhotosInDateRange',
      );

      // 写真を取得
      final FilterOptionGroup filterOption = FilterOptionGroup(
        orders: const [
          OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
        createTimeCond: DateTimeCond(min: localStartDate, max: localEndDate),
      );

      // アルバムを取得
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: filterOption,
      );

      if (albums.isEmpty) {
        loggingService.debug(
          '指定期間のアルバムが見つかりません',
          context: 'PhotoService.getPhotosInDateRange',
        );
        return [];
      }

      // アルバムから写真を取得
      final AssetPathEntity album = albums.first;

      final List<AssetEntity> assets = await album.getAssetListRange(
        start: 0,
        end: limit,
      );

      // エッジケース処理: 破損した写真やEXIF情報のない写真をフィルタリング
      final List<AssetEntity> validAssets = [];
      for (final asset in assets) {
        try {
          // 写真の作成日時を確認
          final createDate = asset.createDateTime;

          // 日付が不正な場合（例: 1970年以前、未来の日付）
          if (createDate.year < 1970 || createDate.isAfter(now)) {
            loggingService.warning(
              '不正な作成日時の写真をスキップ',
              context: 'PhotoService.getPhotosInDateRange',
              data: 'createDate: $createDate, assetId: ${asset.id}',
            );
            continue;
          }

          // タイムゾーン変更対応: 日付範囲内に含まれるかを再確認
          // デバイスのタイムゾーンが変わっても、正しく日付範囲でフィルタリング
          final localCreateDate = DateTime(
            createDate.year,
            createDate.month,
            createDate.day,
            createDate.hour,
            createDate.minute,
            createDate.second,
          );

          if (localCreateDate.isBefore(localStartDate) ||
              localCreateDate.isAfter(localEndDate)) {
            loggingService.debug(
              'タイムゾーン調整後、日付範囲外の写真をスキップ',
              context: 'PhotoService.getPhotosInDateRange',
              data:
                  'createDate: $localCreateDate, range: $localStartDate - $localEndDate',
            );
            continue;
          }

          // サムネイルを取得してファイルの有効性を確認
          final thumbnail = await asset.thumbnailDataWithSize(
            const ThumbnailSize(100, 100),
            quality: 50,
          );

          if (thumbnail == null || thumbnail.isEmpty) {
            loggingService.warning(
              'サムネイルを取得できない写真をスキップ',
              context: 'PhotoService.getPhotosInDateRange',
              data: 'assetId: ${asset.id}',
            );
            continue;
          }

          validAssets.add(asset);
        } catch (e) {
          loggingService.warning(
            '写真の検証中にエラーが発生',
            context: 'PhotoService.getPhotosInDateRange',
            data: 'assetId: ${asset.id}, error: $e',
          );
          // エラーが発生した写真はスキップ
          continue;
        }
      }

      loggingService.info(
        '写真を取得しました',
        context: 'PhotoService.getPhotosInDateRange',
        data: '全${assets.length}枚中、有効${validAssets.length}枚',
      );

      return validAssets;
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoService.getPhotosInDateRange',
      );
      loggingService.error(
        '写真取得エラー',
        context: 'PhotoService.getPhotosInDateRange',
        error: appError,
      );
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
      final loggingService = await LoggingService.getInstance();
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoService.getPhotoData',
      );
      loggingService.error(
        '写真データ取得エラー',
        context: 'PhotoService.getPhotoData',
        error: appError,
      );
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
      final loggingService = await LoggingService.getInstance();
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoService.getThumbnailData',
      );
      loggingService.error(
        'サムネイルデータ取得エラー',
        context: 'PhotoService.getThumbnailData',
        error: appError,
      );
      return null;
    }
  }

  /// 指定された日付の写真を取得する
  ///
  /// [date]: 取得したい日付
  /// [offset]: 取得開始位置（ページネーション用）
  /// [limit]: 取得する写真の最大数
  /// 戻り値: 写真アセットのリスト
  @override
  Future<List<AssetEntity>> getPhotosForDate(
    DateTime date, {
    required int offset,
    required int limit,
  }) async {
    final loggingService = await LoggingService.getInstance();

    // 権限チェック
    final bool hasPermission = await requestPermission();
    if (!hasPermission) {
      loggingService.info(
        '写真アクセス権限がありません',
        context: 'PhotoService.getPhotosForDate',
      );
      return [];
    }

    try {
      // タイムゾーン対応: 指定日の日付範囲を計算（その日の00:00:00から23:59:59まで）
      // ローカルタイムゾーンで正規化
      final DateTime startOfDay = DateTime(date.year, date.month, date.day);
      final DateTime endOfDay = DateTime(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
        999,
      );

      loggingService.debug(
        '指定日の写真を検索',
        context: 'PhotoService.getPhotosForDate',
        data:
            '日付: $date, オフセット: $offset, 制限: $limit, 検索範囲: $startOfDay - $endOfDay (ローカルタイムゾーン)',
      );

      // 写真を取得
      final FilterOptionGroup filterOption = FilterOptionGroup(
        orders: const [
          OrderOption(type: OrderOptionType.createDate, asc: false), // 新しい順
        ],
        createTimeCond: DateTimeCond(min: startOfDay, max: endOfDay),
      );

      // アルバムを取得
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: filterOption,
      );

      loggingService.debug(
        '取得したアルバム数: ${albums.length}',
        context: 'PhotoService.getPhotosForDate',
      );

      if (albums.isEmpty) {
        loggingService.debug(
          '指定日のアルバムが見つかりません',
          context: 'PhotoService.getPhotosForDate',
        );
        return [];
      }

      // 最近の写真アルバムから写真を取得（ページネーション対応）
      final AssetPathEntity album = albums.first;

      // アルバム内の総写真数を確認
      final int totalCount = await album.assetCountAsync;
      loggingService.debug(
        'アルバム情報',
        context: 'PhotoService.getPhotosForDate',
        data: 'アルバム名: ${album.name}, 総写真数: $totalCount',
      );

      // オフセットが総数を超えている場合は空のリストを返す
      if (offset >= totalCount) {
        loggingService.debug(
          'オフセットが総数を超えています',
          context: 'PhotoService.getPhotosForDate',
          data: 'オフセット: $offset, 総数: $totalCount',
        );
        return [];
      }

      // 実際に取得可能な数を計算
      final int actualLimit = (offset + limit > totalCount)
          ? totalCount - offset
          : limit;

      final List<AssetEntity> assets = await album.getAssetListRange(
        start: offset,
        end: offset + actualLimit,
      );

      // タイムゾーン変更対応: 取得した写真の日付を再確認
      final List<AssetEntity> validAssets = [];
      for (final asset in assets) {
        try {
          final createDate = asset.createDateTime;
          final localCreateDate = DateTime(
            createDate.year,
            createDate.month,
            createDate.day,
          );

          // 指定日と同じ日付の写真のみを含める
          if (localCreateDate.year == date.year &&
              localCreateDate.month == date.month &&
              localCreateDate.day == date.day) {
            validAssets.add(asset);
          } else {
            loggingService.debug(
              'タイムゾーン調整後、異なる日付の写真をスキップ',
              context: 'PhotoService.getPhotosForDate',
              data:
                  'expected: ${date.toIso8601String()}, actual: ${localCreateDate.toIso8601String()}',
            );
          }
        } catch (e) {
          loggingService.warning(
            '写真の日付確認中にエラー',
            context: 'PhotoService.getPhotosForDate',
            data: 'assetId: ${asset.id}, error: $e',
          );
          // エラーが発生した写真も含める（除外すると写真が表示されない可能性があるため）
          validAssets.add(asset);
        }
      }

      loggingService.info(
        '指定日の写真を取得しました',
        context: 'PhotoService.getPhotosForDate',
        data:
            '取得数: ${validAssets.length}枚（元: ${assets.length}枚）, 取得範囲: $offset - ${offset + actualLimit}',
      );

      return validAssets;
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoService.getPhotosForDate',
      );
      loggingService.error(
        '写真取得エラー',
        context: 'PhotoService.getPhotosForDate',
        error: appError,
      );
      return [];
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
    return await getPhotosForDate(date, offset: 0, limit: limit);
  }

  /// Limited Photo Access時に写真選択画面を表示
  @override
  Future<bool> presentLimitedLibraryPicker() async {
    try {
      await PhotoManager.presentLimited();
      return true;
    } catch (e) {
      final loggingService = await LoggingService.getInstance();
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoService.presentLimitedLibraryPicker',
      );
      loggingService.error(
        'Limited Library Picker表示エラー',
        context: 'PhotoService.presentLimitedLibraryPicker',
        error: appError,
      );
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
      final loggingService = await LoggingService.getInstance();
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoService.isLimitedAccess',
      );
      loggingService.error(
        '権限状態チェックエラー',
        context: 'PhotoService.isLimitedAccess',
        error: appError,
      );
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
    // PhotoCacheServiceを使用してキャッシュ付きでサムネイルを取得
    final cacheService = PhotoCacheService.getInstance();
    return await cacheService.getThumbnail(
      asset,
      width: width,
      height: height,
      quality: 80,
    );
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
      final loggingService = await LoggingService.getInstance();
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoService.getOriginalFile',
      );
      loggingService.error(
        '元画像取得エラー',
        context: 'PhotoService.getOriginalFile',
        error: appError,
      );
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
    final loggingService = await LoggingService.getInstance();

    // 権限チェック
    final bool hasPermission = await requestPermission();
    if (!hasPermission) {
      loggingService.info(
        '写真アクセス権限がありません',
        context: 'PhotoService.getAllPhotos',
      );
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

      loggingService.debug(
        '取得したアルバム数: ${albums.length}',
        context: 'PhotoService.getAllPhotos',
      );

      if (albums.isEmpty) {
        loggingService.debug(
          'アルバムが見つかりません',
          context: 'PhotoService.getAllPhotos',
        );
        return [];
      }

      // アルバムから写真を取得
      final AssetPathEntity album = albums.first;

      final List<AssetEntity> assets = await album.getAssetListRange(
        start: 0,
        end: limit,
      );

      loggingService.info(
        'すべての写真を取得しました',
        context: 'PhotoService.getAllPhotos',
        data: 'アルバム名: ${album.name}, 取得数: ${assets.length}枚',
      );
      return assets;
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoService.getAllPhotos',
      );
      loggingService.error(
        '写真取得エラー',
        context: 'PhotoService.getAllPhotos',
        error: appError,
      );
      return [];
    }
  }

  /// 効率的な写真取得（ページネーション対応）
  ///
  /// [startDate]: 開始日時（指定しない場合は全期間）
  /// [endDate]: 終了日時（指定しない場合は現在まで）
  /// [offset]: 取得開始位置
  /// [limit]: 取得する写真の最大数
  /// 戻り値: 写真アセットのリスト
  @override
  Future<List<AssetEntity>> getPhotosEfficient({
    DateTime? startDate,
    DateTime? endDate,
    int offset = 0,
    int limit = 30,
  }) async {
    final loggingService = await LoggingService.getInstance();

    // 権限チェック
    final bool hasPermission = await requestPermission();
    if (!hasPermission) {
      loggingService.info(
        '写真アクセス権限がありません',
        context: 'PhotoService.getPhotosEfficient',
      );
      return [];
    }

    try {
      // フィルターオプションの作成
      final FilterOptionGroup filterOption;
      if (startDate != null || endDate != null) {
        filterOption = FilterOptionGroup(
          orders: const [
            OrderOption(type: OrderOptionType.createDate, asc: false),
          ],
          createTimeCond: DateTimeCond(
            min: startDate ?? DateTime(1970),
            max: endDate ?? DateTime.now(),
          ),
        );
      } else {
        filterOption = FilterOptionGroup(
          orders: const [
            OrderOption(type: OrderOptionType.createDate, asc: false),
          ],
        );
      }

      // アルバムを取得
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: filterOption,
      );

      if (albums.isEmpty) {
        loggingService.debug(
          'アルバムが見つかりません',
          context: 'PhotoService.getPhotosEfficient',
        );
        return [];
      }

      // メインアルバムから写真を取得
      final AssetPathEntity album = albums.first;
      final int totalCount = await album.assetCountAsync;

      // オフセットが総数を超えている場合は空のリストを返す
      if (offset >= totalCount) {
        return [];
      }

      // 実際に取得可能な数を計算
      final int actualLimit = (offset + limit > totalCount)
          ? totalCount - offset
          : limit;

      final List<AssetEntity> assets = await album.getAssetListRange(
        start: offset,
        end: offset + actualLimit,
      );

      loggingService.debug(
        '写真を効率的に取得しました',
        context: 'PhotoService.getPhotosEfficient',
        data: '取得数: ${assets.length}, オフセット: $offset, 制限: $limit',
      );

      return assets;
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoService.getPhotosEfficient',
      );
      loggingService.error(
        '写真取得エラー',
        context: 'PhotoService.getPhotosEfficient',
        error: appError,
      );
      return [];
    }
  }

  // ========================================
  // Result<T>パターン版のメソッド実装
  // ========================================

  /// 写真アクセス権限をリクエストする（Result版）
  @override
  Future<Result<bool>> requestPermissionResult() async {
    return ResultHelper.tryExecuteAsync(() async {
      return await requestPermission();
    }, context: 'PhotoService.requestPermissionResult');
  }

  /// 権限が永続的に拒否されているかチェック（Result版）
  @override
  Future<Result<bool>> isPermissionPermanentlyDeniedResult() async {
    return ResultHelper.tryExecuteAsync(() async {
      return await isPermissionPermanentlyDenied();
    }, context: 'PhotoService.isPermissionPermanentlyDeniedResult');
  }

  /// 今日撮影された写真を取得する（Result版）
  @override
  Future<Result<List<AssetEntity>>> getTodayPhotosResult({
    int limit = 20,
  }) async {
    return ResultHelper.tryExecuteAsync(() async {
      return await getTodayPhotos(limit: limit);
    }, context: 'PhotoService.getTodayPhotosResult');
  }

  /// 指定された日付範囲の写真を取得する（Result版）
  @override
  Future<Result<List<AssetEntity>>> getPhotosInDateRangeResult({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  }) async {
    return ResultHelper.tryExecuteAsync(() async {
      return await getPhotosInDateRange(
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
    }, context: 'PhotoService.getPhotosInDateRangeResult');
  }

  /// 指定された日付の写真を取得する（Result版）
  @override
  Future<Result<List<AssetEntity>>> getPhotosForDateResult(
    DateTime date, {
    required int offset,
    required int limit,
  }) async {
    return ResultHelper.tryExecuteAsync(() async {
      return await getPhotosForDate(date, offset: offset, limit: limit);
    }, context: 'PhotoService.getPhotosForDateResult');
  }

  /// 写真のバイナリデータを取得する（Result版）
  @override
  Future<Result<List<int>?>> getPhotoDataResult(AssetEntity asset) async {
    return ResultHelper.tryExecuteAsync(() async {
      return await getPhotoData(asset);
    }, context: 'PhotoService.getPhotoDataResult');
  }

  /// 写真のサムネイルデータを取得する（Result版）
  @override
  Future<Result<List<int>?>> getThumbnailDataResult(AssetEntity asset) async {
    return ResultHelper.tryExecuteAsync(() async {
      return await getThumbnailData(asset);
    }, context: 'PhotoService.getThumbnailDataResult');
  }

  /// 写真の元画像を取得する（Result版）
  @override
  Future<Result<dynamic>> getOriginalFileResult(AssetEntity asset) async {
    return ResultHelper.tryExecuteAsync(() async {
      return await getOriginalFile(asset);
    }, context: 'PhotoService.getOriginalFileResult');
  }

  /// 写真のサムネイルを取得する（Result版）
  @override
  Future<Result<dynamic>> getThumbnailResult(
    AssetEntity asset, {
    int width = 200,
    int height = 200,
  }) async {
    return ResultHelper.tryExecuteAsync(() async {
      return await getThumbnail(asset, width: width, height: height);
    }, context: 'PhotoService.getThumbnailResult');
  }

  /// Limited Photo Access時に写真選択画面を表示（Result版）
  @override
  Future<Result<bool>> presentLimitedLibraryPickerResult() async {
    return ResultHelper.tryExecuteAsync(() async {
      return await presentLimitedLibraryPicker();
    }, context: 'PhotoService.presentLimitedLibraryPickerResult');
  }

  /// 現在の権限状態が Limited Access かチェック（Result版）
  @override
  Future<Result<bool>> isLimitedAccessResult() async {
    return ResultHelper.tryExecuteAsync(() async {
      return await isLimitedAccess();
    }, context: 'PhotoService.isLimitedAccessResult');
  }

  /// 効率的な写真取得（Result版）
  @override
  Future<Result<List<AssetEntity>>> getPhotosEfficientResult({
    DateTime? startDate,
    DateTime? endDate,
    int offset = 0,
    int limit = 30,
  }) async {
    return ResultHelper.tryExecuteAsync(() async {
      return await getPhotosEfficient(
        startDate: startDate,
        endDate: endDate,
        offset: offset,
        limit: limit,
      );
    }, context: 'PhotoService.getPhotosEfficientResult');
  }

  // ========================================
  // カメラ撮影機能の実装
  // ========================================

  /// カメラから写真を撮影する
  @override
  Future<Result<AssetEntity?>> capturePhoto() async {
    final loggingService = await LoggingService.getInstance();

    try {
      loggingService.debug('カメラ撮影を開始', context: 'PhotoService.capturePhoto');

      // 権限状態の詳細チェック
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // 少し待機してiOSの権限状態が更新されるのを待つ
      final cameraStatus = await Permission.camera.status;
      loggingService.debug(
        'カメラ権限状態をチェック: $cameraStatus (isGranted: ${cameraStatus.isGranted}, isDenied: ${cameraStatus.isDenied}, isPermanentlyDenied: ${cameraStatus.isPermanentlyDenied})',
        context: 'PhotoService.capturePhoto',
      );

      // 永続的に拒否されている場合のみ事前にブロック
      if (cameraStatus.isPermanentlyDenied) {
        loggingService.warning(
          'カメラ権限が永続的に拒否されています',
          context: 'PhotoService.capturePhoto',
          data: 'status: $cameraStatus',
        );
        return Failure(PhotoError.cameraPermissionDenied());
      }

      // denied状態でも初回は image_picker を実行して権限ダイアログを表示させる
      loggingService.debug(
        'image_pickerでカメラアクセスを実行（権限ダイアログ表示含む）',
        context: 'PhotoService.capturePhoto',
        data: '現在の権限状態: $cameraStatus',
      );

      // image_pickerでカメラアクセス
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85, // 品質を85%に設定（ファイルサイズとのバランス）
      );

      if (photo == null) {
        // ユーザーがキャンセルした場合
        loggingService.info(
          'カメラ撮影がキャンセルされました',
          context: 'PhotoService.capturePhoto',
        );
        return Success(null);
      }

      loggingService.debug(
        'カメラ撮影完了',
        context: 'PhotoService.capturePhoto',
        data: 'ファイルパス: ${photo.path}',
      );

      // 撮影した写真をフォトライブラリに手動保存
      loggingService.debug(
        '撮影した写真をフォトライブラリに保存中',
        context: 'PhotoService.capturePhoto',
      );

      try {
        // XFileをUint8Listに変換してフォトライブラリに保存
        final bytes = await photo.readAsBytes();
        final savedAsset = await PhotoManager.editor.saveImage(
          bytes,
          filename:
              'Smart_Photo_Diary_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        loggingService.info(
          'カメラ撮影が完了し、フォトライブラリに保存されました',
          context: 'PhotoService.capturePhoto',
          data: 'AssetID: ${savedAsset.id}',
        );
        return Success(savedAsset);
      } catch (e) {
        loggingService.error(
          '撮影した写真の保存処理でエラー: $e',
          context: 'PhotoService.capturePhoto',
        );

        // フォールバック: 従来の方法で検索
        loggingService.debug(
          'フォールバック: 従来の方法でAssetEntity検索',
          context: 'PhotoService.capturePhoto',
        );

        // photo_managerに新しい写真が追加されるまで少し待つ
        await Future.delayed(const Duration(milliseconds: 1500)); // 待機時間を増加

        // 写真ライブラリを更新
        await PhotoManager.clearFileCache();

        // より広い範囲で最新の写真を取得
        final latestPhotos = await getTodayPhotos(limit: 10);

        // 撮影時刻に最も近い写真を探す
        final captureTime = DateTime.now();
        AssetEntity? capturedAsset;

        for (final asset in latestPhotos) {
          final timeDiff = captureTime.difference(asset.createDateTime).abs();
          if (timeDiff.inMinutes < 5) {
            // 検索範囲を5分に拡大
            capturedAsset = asset;
            break;
          }
        }

        if (capturedAsset != null) {
          loggingService.info(
            'フォールバック検索でAssetEntityを取得しました',
            context: 'PhotoService.capturePhoto',
            data: 'AssetID: ${capturedAsset.id}',
          );
          return Success(capturedAsset);
        } else {
          loggingService.warning(
            'フォールバック検索でもAssetEntityの取得に失敗しました',
            context: 'PhotoService.capturePhoto',
          );
          return Failure(PhotoError.cameraAssetNotFound());
        }
      }
    } catch (e) {
      // image_pickerでの権限拒否エラーを特別処理
      if (e.toString().contains('camera_access_denied') ||
          e.toString().contains('Permission denied') ||
          e.toString().contains('User denied')) {
        loggingService.warning(
          'カメラ権限がユーザーによって拒否されました',
          context: 'PhotoService.capturePhoto',
          data: 'error: $e',
        );

        // 権限状態を再チェックして正確な状態を把握
        final statusAfterDenied = await Permission.camera.status;
        loggingService.debug(
          '権限拒否後の状態: $statusAfterDenied',
          context: 'PhotoService.capturePhoto',
        );

        return Failure(PhotoError.cameraPermissionDenied());
      }

      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoService.capturePhoto',
      );
      loggingService.error(
        'カメラ撮影エラー',
        context: 'PhotoService.capturePhoto',
        error: appError,
      );
      return Failure(appError);
    }
  }

  /// カメラ権限をリクエストする
  @override
  Future<Result<bool>> requestCameraPermission() async {
    final loggingService = await LoggingService.getInstance();

    try {
      loggingService.debug(
        'カメラ権限リクエスト開始',
        context: 'PhotoService.requestCameraPermission',
      );

      var status = await Permission.camera.status;
      loggingService.info(
        'カメラ権限の現在の状態: $status (isGranted: ${status.isGranted}, isDenied: ${status.isDenied}, isPermanentlyDenied: ${status.isPermanentlyDenied})',
        context: 'PhotoService.requestCameraPermission',
      );

      // 権限が未許可の場合はリクエスト
      if (!status.isGranted) {
        // 永続的に拒否されている場合は設定画面への誘導が必要
        if (status.isPermanentlyDenied) {
          loggingService.warning(
            'カメラ権限が永続的に拒否されています。設定アプリでの許可が必要です。',
            context: 'PhotoService.requestCameraPermission',
          );
          return Success(false); // 権限なしだが、設定誘導のためSuccess(false)を返す
        }

        loggingService.debug(
          'カメラ権限をリクエスト（現在の状態: $status）',
          context: 'PhotoService.requestCameraPermission',
        );
        status = await Permission.camera.request();
        loggingService.info(
          'リクエスト後のカメラ権限状態: $status (isGranted: ${status.isGranted}, isDenied: ${status.isDenied}, isPermanentlyDenied: ${status.isPermanentlyDenied})',
          context: 'PhotoService.requestCameraPermission',
        );
      }

      final granted = status.isGranted;
      loggingService.info(
        granted ? 'カメラ権限が付与されました' : 'カメラ権限が拒否されました',
        context: 'PhotoService.requestCameraPermission',
        data: 'status: $status',
      );

      return Success(granted);
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoService.requestCameraPermission',
      );
      loggingService.error(
        'カメラ権限リクエストエラー',
        context: 'PhotoService.requestCameraPermission',
        error: appError,
      );
      return Failure(appError);
    }
  }

  /// カメラ権限が拒否されているかチェック
  @override
  Future<Result<bool>> isCameraPermissionDenied() async {
    final loggingService = await LoggingService.getInstance();

    try {
      final status = await Permission.camera.status;
      final isDenied = status.isDenied || status.isPermanentlyDenied;

      loggingService.debug(
        'カメラ権限拒否状態をチェック',
        context: 'PhotoService.isCameraPermissionDenied',
        data: 'status: $status, isDenied: $isDenied',
      );

      return Success(isDenied);
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoService.isCameraPermissionDenied',
      );
      loggingService.error(
        'カメラ権限状態チェックエラー',
        context: 'PhotoService.isCameraPermissionDenied',
        error: appError,
      );
      return Failure(appError);
    }
  }
}
