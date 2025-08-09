import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_constants.dart';
import 'interfaces/photo_service_interface.dart';
import 'photo_cache_service.dart';
import 'logging_service.dart';
import '../core/errors/error_handler.dart';
import '../core/result/result.dart';
import '../core/result/photo_result_helper.dart';

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

  /// 写真アクセス権限をリクエストする（Result版）
  ///
  /// 戻り値: 権限が付与されたかどうかのResult<bool>
  Future<Result<bool>> requestPermissionResult() async {
    final loggingService = await LoggingService.getInstance();

    try {
      loggingService.debug(
        '権限リクエスト開始 (Result版)',
        context: 'PhotoService.requestPermissionResult',
      );

      // まずはPhotoManagerで権限リクエスト（これがメイン）
      final pmState = await PhotoManager.requestPermissionExtend();
      loggingService.debug(
        'PhotoManager権限状態: $pmState',
        context: 'PhotoService.requestPermissionResult',
      );

      if (pmState.isAuth) {
        loggingService.info(
          '写真アクセス権限が付与されました',
          context: 'PhotoService.requestPermissionResult',
        );
        return PhotoResultHelper.photoPermissionResult(granted: true);
      }

      // Limited access の場合も部分的に許可とみなす（iOS専用）
      if (pmState == PermissionState.limited) {
        loggingService.info(
          '制限つき写真アクセスが許可されました',
          context: 'PhotoService.requestPermissionResult',
        );
        return PhotoResultHelper.photoPermissionResult(
          granted: false,
          isLimited: true,
        );
      }

      // PhotoManagerで権限が拒否された場合、Androidでは追加でpermission_handlerを試す
      if (defaultTargetPlatform == TargetPlatform.android) {
        loggingService.debug(
          'Android: permission_handlerで追加の権限チェックを実行',
          context: 'PhotoService.requestPermissionResult',
        );

        // Android 13以降は Permission.photos、それ以前は Permission.storage
        Permission permission = Permission.photos;

        var status = await permission.status;
        loggingService.debug(
          'permission_handler権限状態: $status',
          context: 'PhotoService.requestPermissionResult',
        );

        // 権限が未決定または拒否の場合は明示的にリクエスト
        if (status.isDenied) {
          loggingService.debug(
            'Android: 権限を明示的にリクエストします',
            context: 'PhotoService.requestPermissionResult',
          );
          status = await permission.request();
          loggingService.debug(
            'Android: リクエスト後の権限状態: $status',
            context: 'PhotoService.requestPermissionResult',
          );

          if (status.isGranted) {
            loggingService.info(
              'Android: 権限が付与されました',
              context: 'PhotoService.requestPermissionResult',
            );
            // PhotoManagerで再度確認
            final pmStateAfter = await PhotoManager.requestPermissionExtend();
            loggingService.debug(
              'Android: PhotoManager再確認結果: $pmStateAfter',
              context: 'PhotoService.requestPermissionResult',
            );
            return PhotoResultHelper.photoPermissionResult(
              granted: pmStateAfter.isAuth,
            );
          }
        }

        // 永続的に拒否されている場合
        if (status.isPermanentlyDenied) {
          loggingService.warning(
            'Android: 権限が永続的に拒否されています',
            context: 'PhotoService.requestPermissionResult',
          );
          return PhotoResultHelper.photoPermissionResult(
            granted: false,
            isPermanentlyDenied: true,
            errorMessage: 'Android: 写真アクセス権限が永続的に拒否されています。設定アプリから権限を有効にしてください。',
          );
        }
      }

      loggingService.warning(
        '写真アクセス権限が拒否されました',
        context: 'PhotoService.requestPermissionResult',
        data: 'pmState: $pmState',
      );

      // PhotoManagerの状態に基づいてエラーを分類
      return PhotoResultHelper.fromPermissionState(pmState);
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoService.requestPermissionResult',
      );
      loggingService.error(
        '権限リクエストエラー',
        context: 'PhotoService.requestPermissionResult',
        error: appError,
      );
      return PhotoResultHelper.fromError(
        e,
        context: 'PhotoService.requestPermissionResult',
        customMessage: '写真アクセス権限のリクエスト中にエラーが発生しました',
      );
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

  /// 権限が永続的に拒否されているかチェック（Result版）
  ///
  /// 戻り値: 永続的拒否かどうかのResult<bool>
  Future<Result<bool>> isPermissionPermanentlyDeniedResult() async {
    final loggingService = await LoggingService.getInstance();

    try {
      loggingService.debug(
        '永続的権限拒否チェック開始',
        context: 'PhotoService.isPermissionPermanentlyDeniedResult',
      );

      final currentStatus = await Permission.photos.status;
      loggingService.debug(
        'permission_handler権限状態: $currentStatus',
        context: 'PhotoService.isPermissionPermanentlyDeniedResult',
      );

      final isPermanentlyDenied = currentStatus.isPermanentlyDenied;

      if (isPermanentlyDenied) {
        loggingService.warning(
          '権限が永続的に拒否されています',
          context: 'PhotoService.isPermissionPermanentlyDeniedResult',
        );
      } else {
        loggingService.debug(
          '権限は永続的に拒否されていません',
          context: 'PhotoService.isPermissionPermanentlyDeniedResult',
        );
      }

      return Success(isPermanentlyDenied);
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoService.isPermissionPermanentlyDeniedResult',
      );
      loggingService.error(
        '永続的権限拒否チェックエラー',
        context: 'PhotoService.isPermissionPermanentlyDeniedResult',
        error: appError,
      );
      return PhotoResultHelper.fromError(
        e,
        context: 'PhotoService.isPermissionPermanentlyDeniedResult',
        customMessage: '永続的権限拒否状態のチェック中にエラーが発生しました',
      );
    }
  }

  /// 今日撮影された写真を取得する（Result<T>版）
  ///
  /// [limit]: 取得する写真の最大数
  /// 戻り値: 写真アセットのリストのResult型
  Future<Result<List<AssetEntity>>> getTodayPhotosResult({
    int limit = 20,
  }) async {
    final loggingService = await LoggingService.getInstance();

    // 権限チェック（Result<T>版を使用）
    final permissionResult = await requestPermissionResult();
    if (permissionResult.isFailure) {
      return Failure(permissionResult.error);
    }
    if (!permissionResult.value) {
      return PhotoResultHelper.photoAccessResult(
        null,
        hasPermission: false,
        errorMessage: '写真アクセス権限がありません',
      );
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

      loggingService.debug(
        '今日の写真を検索',
        context: 'PhotoService.getTodayPhotosResult',
        data: '検索範囲: $startOfDay - $endOfDay, 制限: $limit',
      );

      // 写真を取得
      final FilterOptionGroup filterOption = FilterOptionGroup(
        orders: [const OrderOption()],
        createTimeCond: DateTimeCond(min: startOfDay, max: endOfDay),
      );

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        filterOption: filterOption,
      );

      loggingService.debug(
        '取得したアルバム数: ${albums.length}',
        context: 'PhotoService.getTodayPhotosResult',
      );

      if (albums.isEmpty) {
        loggingService.debug(
          '今日のアルバムが見つかりません',
          context: 'PhotoService.getTodayPhotosResult',
        );
        return PhotoResultHelper.photoAccessResult(
          <AssetEntity>[],
          errorMessage: '今日の写真が見つかりませんでした',
        );
      }

      // 最近の写真アルバムから写真を取得
      final AssetPathEntity recentAlbum = albums.first;
      loggingService.debug(
        'アルバム名: ${recentAlbum.name}',
        context: 'PhotoService.getTodayPhotosResult',
      );

      final List<AssetEntity> assets = await recentAlbum.getAssetListRange(
        start: 0,
        end: limit,
      );

      if (assets.isEmpty) {
        loggingService.debug(
          '今日の写真がありません',
          context: 'PhotoService.getTodayPhotosResult',
        );
        return PhotoResultHelper.photoAccessResult(
          <AssetEntity>[],
          errorMessage: '今日撮影された写真がありません',
        );
      }

      loggingService.info(
        '今日の写真を取得しました',
        context: 'PhotoService.getTodayPhotosResult',
        data: '取得数: ${assets.length}枚',
      );

      return PhotoResultHelper.photoAccessResult(assets);
    } catch (e) {
      return PhotoResultHelper.fromError<List<AssetEntity>>(
        e,
        context: 'PhotoService.getTodayPhotosResult',
        customMessage: '今日の写真取得中にエラーが発生しました',
      );
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
        orders: [const OrderOption()],
        createTimeCond: DateTimeCond(min: startOfDay, max: endOfDay),
      );

      // アルバムを取得（最近の写真）
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
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

  /// 指定された日付範囲の写真を取得する（Result<T>版）
  ///
  /// [startDate]: 開始日時
  /// [endDate]: 終了日時
  /// [limit]: 取得する写真の最大数
  /// 戻り値: 写真アセットのリストのResult型
  Future<Result<List<AssetEntity>>> getPhotosInDateRangeResult({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  }) async {
    final loggingService = await LoggingService.getInstance();

    // 権限チェック（Result<T>版を使用）
    final permissionResult = await requestPermissionResult();
    if (permissionResult.isFailure) {
      return Failure(permissionResult.error);
    }
    if (!permissionResult.value) {
      return PhotoResultHelper.photoAccessResult(
        null,
        hasPermission: false,
        errorMessage: '写真アクセス権限がありません',
      );
    }

    try {
      // 日付の妥当性チェック
      final now = DateTime.now();
      if (startDate.isAfter(now)) {
        loggingService.warning(
          '開始日が未来の日付です',
          context: 'PhotoService.getPhotosInDateRangeResult',
          data: 'startDate: $startDate',
        );
        return PhotoResultHelper.photoAccessResult(
          <AssetEntity>[],
          errorMessage: '開始日が未来の日付のため、写真を取得できません',
        );
      }

      if (startDate.isAfter(endDate)) {
        return PhotoResultHelper.fromError<List<AssetEntity>>(
          ArgumentError('開始日が終了日より後です: $startDate > $endDate'),
          context: 'PhotoService.getPhotosInDateRangeResult',
          customMessage: '日付範囲が不正です',
        );
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
        '日付範囲の写真を検索',
        context: 'PhotoService.getPhotosInDateRangeResult',
        data: '範囲: $localStartDate - $localEndDate, 制限: $limit',
      );

      // 写真を取得
      final FilterOptionGroup filterOption = FilterOptionGroup(
        orders: [const OrderOption()],
        createTimeCond: DateTimeCond(min: localStartDate, max: localEndDate),
      );

      // アルバムを取得
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        filterOption: filterOption,
      );

      if (albums.isEmpty) {
        loggingService.debug(
          '指定期間のアルバムが見つかりません',
          context: 'PhotoService.getPhotosInDateRangeResult',
        );
        return PhotoResultHelper.photoAccessResult(
          <AssetEntity>[],
          errorMessage: '指定した期間の写真が見つかりませんでした',
        );
      }

      // アルバムから写真を取得
      final AssetPathEntity album = albums.first;

      final List<AssetEntity> assets = await album.getAssetListRange(
        start: 0,
        end: limit,
      );

      // エッジケース処理: 破損した写真やEXIF情報のない写真をフィルタリング
      final List<AssetEntity> validAssets = [];
      final List<String> corruptedPhotos = [];

      for (final asset in assets) {
        try {
          // 写真の作成日時を確認
          final createDate = asset.createDateTime;

          // 日付が不正な場合（例: 1970年以前、未来の日付）
          if (createDate.year < 1970 ||
              createDate.isAfter(now.add(const Duration(days: 1)))) {
            loggingService.debug(
              '無効な日付の写真をスキップ',
              context: 'PhotoService.getPhotosInDateRangeResult',
              data: 'createDate: $createDate, assetId: ${asset.id}',
            );
            continue;
          }

          // タイムゾーン変更対応: 日付範囲内に含まれるかを再確認
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
              context: 'PhotoService.getPhotosInDateRangeResult',
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
              context: 'PhotoService.getPhotosInDateRangeResult',
              data: 'assetId: ${asset.id}',
            );
            corruptedPhotos.add(asset.id);
            continue;
          }

          validAssets.add(asset);
        } catch (e) {
          loggingService.warning(
            '写真の検証中にエラーが発生',
            context: 'PhotoService.getPhotosInDateRangeResult',
            data: 'assetId: ${asset.id}, error: $e',
          );
          corruptedPhotos.add(asset.id);
          continue;
        }
      }

      // 破損写真が多数ある場合は警告
      if (corruptedPhotos.length > assets.length * 0.3) {
        loggingService.warning(
          '多数の破損写真が検出されました',
          context: 'PhotoService.getPhotosInDateRangeResult',
          data: '破損写真数: ${corruptedPhotos.length}/${assets.length}',
        );
      }

      loggingService.info(
        '日付範囲の写真を取得しました',
        context: 'PhotoService.getPhotosInDateRangeResult',
        data: '全${assets.length}枚中、有効${validAssets.length}枚',
      );

      return PhotoResultHelper.photoAccessResult(validAssets);
    } catch (e) {
      return PhotoResultHelper.fromError<List<AssetEntity>>(
        e,
        context: 'PhotoService.getPhotosInDateRangeResult',
        customMessage: '指定期間の写真取得中にエラーが発生しました',
      );
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
        orders: [const OrderOption()],
        createTimeCond: DateTimeCond(min: localStartDate, max: localEndDate),
      );

      // アルバムを取得
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
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

  /// 写真のバイナリデータを取得する（Result<T>版）
  ///
  /// [asset]: 写真アセット
  /// 戻り値: 写真データのList<int>のResult型
  Future<Result<List<int>>> getPhotoDataResult(AssetEntity asset) async {
    final loggingService = await LoggingService.getInstance();

    try {
      // アセットの妥当性チェック
      if (asset.id.isEmpty) {
        return PhotoResultHelper.fromError<List<int>>(
          ArgumentError('無効なアセットIDです'),
          context: 'PhotoService.getPhotoDataResult',
          customMessage: '写真アセットが不正です',
        );
      }

      loggingService.debug(
        '写真データを取得開始',
        context: 'PhotoService.getPhotoDataResult',
        data: 'assetId: ${asset.id}, type: ${asset.type}',
      );

      // メモリ使用量の事前確認（後でデータサイズで判定）
      // asset.sizeはファイルサイズではなくFlutterのSize型のため使用不可

      // 元画像データを取得
      final Uint8List? data = await asset.originBytes;

      // データ存在チェック
      if (data == null) {
        return PhotoResultHelper.fromError<List<int>>(
          StateError('写真データがnullです'),
          context: 'PhotoService.getPhotoDataResult',
          customMessage: '写真データの取得に失敗しました',
        );
      }

      // データサイズチェック
      if (data.isEmpty) {
        return PhotoResultHelper.fromError<List<int>>(
          StateError('写真データが空です'),
          context: 'PhotoService.getPhotoDataResult',
          customMessage: '写真データが破損している可能性があります',
        );
      }

      // 取得後のデータサイズ監視
      final sizeInMB = data.length / 1024 / 1024;
      if (sizeInMB > 100) {
        loggingService.warning(
          '非常に大容量の画像データ',
          context: 'PhotoService.getPhotoDataResult',
          data: 'データサイズ: ${sizeInMB.toStringAsFixed(2)}MB',
        );
      } else if (sizeInMB > 50) {
        loggingService.info(
          '大容量画像データを処理',
          context: 'PhotoService.getPhotoDataResult',
          data: 'データサイズ: ${sizeInMB.toStringAsFixed(2)}MB',
        );
      }

      // 基本的なデータ整合性チェック
      bool isValidImageData = _validateImageData(data);
      if (!isValidImageData) {
        loggingService.warning(
          '写真データ形式の検証で問題を検出',
          context: 'PhotoService.getPhotoDataResult',
          data: 'dataSize: ${data.length}バイト',
        );
        // 警告はするが処理は継続（未対応フォーマットの可能性もあるため）
      }

      // List<int>に変換
      final List<int> resultData = data.toList();

      loggingService.debug(
        '写真データ取得成功',
        context: 'PhotoService.getPhotoDataResult',
        data: 'dataSize: ${resultData.length}バイト, valid: $isValidImageData',
      );

      return Success(resultData);
    } catch (e) {
      return PhotoResultHelper.fromError<List<int>>(
        e,
        context: 'PhotoService.getPhotoDataResult',
        customMessage: '写真データの取得中にエラーが発生しました',
      );
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

  /// 写真のサムネイルデータを取得する（Result<T>版）
  ///
  /// [asset]: 写真アセット
  /// [width]: サムネイル幅（デフォルト: AppConstants.defaultThumbnailWidth）
  /// [height]: サムネイル高さ（デフォルト: AppConstants.defaultThumbnailHeight）
  /// 戻り値: サムネイルデータのList<int>のResult型
  Future<Result<List<int>>> getThumbnailDataResult(
    AssetEntity asset, {
    int width = AppConstants.defaultThumbnailWidth,
    int height = AppConstants.defaultThumbnailHeight,
  }) async {
    final loggingService = await LoggingService.getInstance();

    try {
      // アセットの妥当性チェック
      if (asset.id.isEmpty) {
        return PhotoResultHelper.fromError<List<int>>(
          ArgumentError('無効なアセットIDです'),
          context: 'PhotoService.getThumbnailDataResult',
          customMessage: '写真アセットが不正です',
        );
      }

      // サイズパラメータの妥当性チェック
      if (width <= 0 || height <= 0) {
        return PhotoResultHelper.fromError<List<int>>(
          ArgumentError('サムネイルサイズが不正です: ${width}x$height'),
          context: 'PhotoService.getThumbnailDataResult',
          customMessage: 'サムネイルサイズの設定が無効です',
        );
      }

      // 大きすぎるサムネイルサイズの警告
      if (width > 1000 || height > 1000) {
        loggingService.warning(
          '大きなサムネイルサイズが指定されました',
          context: 'PhotoService.getThumbnailDataResult',
          data: 'サイズ: ${width}x$height',
        );
      }

      loggingService.debug(
        'サムネイルデータを取得開始',
        context: 'PhotoService.getThumbnailDataResult',
        data: 'assetId: ${asset.id}, サイズ: ${width}x$height',
      );

      // サムネイルデータを取得
      final Uint8List? data = await asset.thumbnailDataWithSize(
        ThumbnailSize(width, height),
      );

      // データ存在チェック
      if (data == null) {
        return PhotoResultHelper.fromError<List<int>>(
          StateError('サムネイルデータがnullです'),
          context: 'PhotoService.getThumbnailDataResult',
          customMessage: 'サムネイルの生成に失敗しました',
        );
      }

      // データサイズチェック
      if (data.isEmpty) {
        return PhotoResultHelper.fromError<List<int>>(
          StateError('サムネイルデータが空です'),
          context: 'PhotoService.getThumbnailDataResult',
          customMessage: 'サムネイルデータが破損している可能性があります',
        );
      }

      // サムネイルサイズの妥当性チェック（最小サイズ）
      if (data.length < 100) {
        loggingService.warning(
          'サムネイルデータが異常に小さい',
          context: 'PhotoService.getThumbnailDataResult',
          data: 'dataSize: ${data.length}バイト',
        );
        return PhotoResultHelper.fromError<List<int>>(
          StateError('サムネイルデータが小さすぎます'),
          context: 'PhotoService.getThumbnailDataResult',
          customMessage: 'サムネイル生成が不完全です',
        );
      }

      // 基本的な画像データ整合性チェック
      bool isValidImageData = _validateImageData(data);
      if (!isValidImageData) {
        loggingService.warning(
          'サムネイル画像形式の検証で問題を検出',
          context: 'PhotoService.getThumbnailDataResult',
          data: 'dataSize: ${data.length}バイト, サイズ: ${width}x$height',
        );
        // サムネイルの場合は形式チェック失敗でも継続
      }

      // List<int>に変換
      final List<int> resultData = data.toList();

      loggingService.debug(
        'サムネイルデータ取得成功',
        context: 'PhotoService.getThumbnailDataResult',
        data:
            'dataSize: ${resultData.length}バイト, サイズ: ${width}x$height, valid: $isValidImageData',
      );

      return Success(resultData);
    } catch (e) {
      return PhotoResultHelper.fromError<List<int>>(
        e,
        context: 'PhotoService.getThumbnailDataResult',
        customMessage: 'サムネイルデータの取得中にエラーが発生しました',
      );
    }
  }

  /// 指定された日付の写真を取得する（Result<T>版）
  ///
  /// [date]: 取得したい日付
  /// [offset]: 取得開始位置（ページネーション用）
  /// [limit]: 取得する写真の最大数
  /// 戻り値: 写真アセットのリストのResult型
  Future<Result<List<AssetEntity>>> getPhotosForDateResult(
    DateTime date, {
    required int offset,
    required int limit,
  }) async {
    final loggingService = await LoggingService.getInstance();

    // 権限チェック（Result<T>版を使用）
    final permissionResult = await requestPermissionResult();
    if (permissionResult.isFailure) {
      return Failure(permissionResult.error);
    }
    if (!permissionResult.value) {
      return PhotoResultHelper.photoAccessResult(
        null,
        hasPermission: false,
        errorMessage: '写真アクセス権限がありません',
      );
    }

    try {
      // パラメータ妥当性チェック
      if (offset < 0) {
        return PhotoResultHelper.fromError<List<AssetEntity>>(
          ArgumentError('オフセットは0以上である必要があります: $offset'),
          context: 'PhotoService.getPhotosForDateResult',
          customMessage: 'ページネーション設定が不正です',
        );
      }

      if (limit <= 0) {
        return PhotoResultHelper.fromError<List<AssetEntity>>(
          ArgumentError('リミットは1以上である必要があります: $limit'),
          context: 'PhotoService.getPhotosForDateResult',
          customMessage: 'ページネーション設定が不正です',
        );
      }

      // 未来の日付チェック
      final now = DateTime.now();
      if (date.isAfter(now.add(const Duration(days: 1)))) {
        return PhotoResultHelper.photoAccessResult(
          <AssetEntity>[],
          errorMessage: '未来の日付の写真は取得できません',
        );
      }

      // タイムゾーン対応: 指定日の日付範囲を計算（その日の00:00:00から23:59:59まで）
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
        context: 'PhotoService.getPhotosForDateResult',
        data:
            '日付: $date, オフセット: $offset, 制限: $limit, 検索範囲: $startOfDay - $endOfDay',
      );

      // 写真を取得
      final FilterOptionGroup filterOption = FilterOptionGroup(
        orders: [const OrderOption()], // 作成日時の降順（新しい順）
        createTimeCond: DateTimeCond(min: startOfDay, max: endOfDay),
      );

      // アルバムを取得
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        filterOption: filterOption,
      );

      loggingService.debug(
        '取得したアルバム数: ${albums.length}',
        context: 'PhotoService.getPhotosForDateResult',
      );

      if (albums.isEmpty) {
        loggingService.debug(
          '指定日のアルバムが見つかりません',
          context: 'PhotoService.getPhotosForDateResult',
        );
        return PhotoResultHelper.photoAccessResult(
          <AssetEntity>[],
          errorMessage: '指定日の写真が見つかりませんでした',
        );
      }

      // 最近の写真アルバムから写真を取得（ページネーション対応）
      final AssetPathEntity album = albums.first;

      // アルバム内の総写真数を確認
      final int totalCount = await album.assetCountAsync;
      loggingService.debug(
        'アルバム情報',
        context: 'PhotoService.getPhotosForDateResult',
        data: 'アルバム名: ${album.name}, 総写真数: $totalCount',
      );

      // オフセットが総数を超えている場合
      if (offset >= totalCount) {
        loggingService.debug(
          'オフセットが総数を超えています',
          context: 'PhotoService.getPhotosForDateResult',
          data: 'オフセット: $offset, 総数: $totalCount',
        );
        return PhotoResultHelper.photoAccessResult(
          <AssetEntity>[],
          errorMessage: 'これ以上の写真はありません',
        );
      }

      // 実際に取得可能な数を計算
      final int actualLimit = (offset + limit > totalCount)
          ? totalCount - offset
          : limit;

      if (actualLimit <= 0) {
        return PhotoResultHelper.photoAccessResult(
          <AssetEntity>[],
          errorMessage: '取得可能な写真がありません',
        );
      }

      final List<AssetEntity> assets = await album.getAssetListRange(
        start: offset,
        end: offset + actualLimit,
      );

      // タイムゾーン変更対応: 取得した写真の日付を再確認
      final List<AssetEntity> validAssets = [];
      int skippedCount = 0;

      for (final asset in assets) {
        try {
          final createDate = asset.createDateTime;
          final localCreateDate = DateTime(
            createDate.year,
            createDate.month,
            createDate.day,
          );
          final targetDate = DateTime(date.year, date.month, date.day);

          // 日付が一致するかを確認（タイムゾーン対応）
          if (!localCreateDate.isAtSameMomentAs(targetDate)) {
            loggingService.debug(
              '日付不一致の写真をスキップ',
              context: 'PhotoService.getPhotosForDateResult',
              data:
                  'expected: ${targetDate.toIso8601String()}, actual: ${localCreateDate.toIso8601String()}',
            );
            skippedCount++;
            continue;
          }

          validAssets.add(asset);
        } catch (e) {
          loggingService.warning(
            '写真の日付確認中にエラー',
            context: 'PhotoService.getPhotosForDateResult',
            data: 'assetId: ${asset.id}, error: $e',
          );
          // エラーが発生した写真も含める（除外すると写真が表示されない可能性があるため）
          validAssets.add(asset);
        }
      }

      if (skippedCount > 0) {
        loggingService.debug(
          '日付不一致でスキップされた写真',
          context: 'PhotoService.getPhotosForDateResult',
          data: 'スキップ数: $skippedCount',
        );
      }

      loggingService.info(
        '指定日の写真を取得しました',
        context: 'PhotoService.getPhotosForDateResult',
        data:
            '取得数: ${validAssets.length}枚（元: ${assets.length}枚）, 取得範囲: $offset - ${offset + actualLimit}',
      );

      return PhotoResultHelper.photoAccessResult(validAssets);
    } catch (e) {
      return PhotoResultHelper.fromError<List<AssetEntity>>(
        e,
        context: 'PhotoService.getPhotosForDateResult',
        customMessage: '指定日の写真取得中にエラーが発生しました',
      );
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
        orders: [const OrderOption()], // 作成日時の降順（新しい順）
        createTimeCond: DateTimeCond(min: startOfDay, max: endOfDay),
      );

      // アルバムを取得
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
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

  /// Limited Photo Access時に写真選択画面を表示（Result版）
  ///
  /// 戻り値: 写真選択ダイアログの表示結果
  /// - Success(true): ユーザーが写真を選択/変更した
  /// - Success(false): ユーザーがキャンセルした
  /// - Failure: システムエラーが発生した
  Future<Result<bool>> presentLimitedLibraryPickerResult() async {
    final loggingService = await LoggingService.getInstance();

    try {
      loggingService.debug(
        'Limited Library Picker表示開始',
        context: 'PhotoService.presentLimitedLibraryPickerResult',
      );

      // プラットフォーム固有チェック（iOS専用機能）
      if (defaultTargetPlatform != TargetPlatform.iOS) {
        return PhotoResultHelper.fromError<bool>(
          PlatformException(
            code: 'PLATFORM_NOT_SUPPORTED',
            message: 'Limited Library Pickerはios専用の機能です',
          ),
          context: 'PhotoService.presentLimitedLibraryPickerResult',
          customMessage: 'この機能はiOSでのみ利用できます',
        );
      }

      // Limited Access状態の事前チェック
      final pmState = await PhotoManager.requestPermissionExtend();
      if (pmState != PermissionState.limited) {
        loggingService.warning(
          'Limited Access状態ではありません',
          context: 'PhotoService.presentLimitedLibraryPickerResult',
          data: '現在の権限状態: $pmState',
        );

        return PhotoResultHelper.fromError<bool>(
          StateError('Limited Access状態ではないため、写真選択ダイアログを表示できません'),
          context: 'PhotoService.presentLimitedLibraryPickerResult',
          customMessage: '写真の追加選択は制限付きアクセス時のみ利用できます',
        );
      }

      // システムダイアログ表示
      await PhotoManager.presentLimited();

      loggingService.info(
        'Limited Library Picker表示完了',
        context: 'PhotoService.presentLimitedLibraryPickerResult',
      );

      // 表示成功時はtrueを返す（PhotoManagerの仕様上、ユーザーの操作結果は区別できない）
      return const Success(true);
    } on PlatformException catch (e) {
      // システムUI表示失敗の詳細化
      if (e.code == 'PlatformException') {
        return PhotoResultHelper.fromError<bool>(
          e,
          context: 'PhotoService.presentLimitedLibraryPickerResult',
          customMessage: 'システムの写真選択ダイアログの表示に失敗しました',
        );
      }

      // その他のプラットフォーム例外
      return PhotoResultHelper.fromError<bool>(
        e,
        context: 'PhotoService.presentLimitedLibraryPickerResult',
        customMessage: 'プラットフォーム固有のエラーが発生しました',
      );
    } catch (e) {
      return PhotoResultHelper.fromError<bool>(
        e,
        context: 'PhotoService.presentLimitedLibraryPickerResult',
        customMessage: 'Limited Library Pickerの表示中にエラーが発生しました',
      );
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

  /// 現在の権限状態が Limited Access かチェック（Result版）
  ///
  /// 戻り値: Limited AccessかどうかのResult<bool>
  Future<Result<bool>> isLimitedAccessResult() async {
    final loggingService = await LoggingService.getInstance();

    try {
      loggingService.debug(
        'Limited Accessチェック開始',
        context: 'PhotoService.isLimitedAccessResult',
      );

      final pmState = await PhotoManager.requestPermissionExtend();
      loggingService.debug(
        'PhotoManager権限状態: $pmState',
        context: 'PhotoService.isLimitedAccessResult',
      );

      final isLimited = pmState == PermissionState.limited;

      if (isLimited) {
        loggingService.info(
          '現在Limited Accessモードです',
          context: 'PhotoService.isLimitedAccessResult',
        );
      } else {
        loggingService.debug(
          'Limited Accessではありません: $pmState',
          context: 'PhotoService.isLimitedAccessResult',
        );
      }

      return Success(isLimited);
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoService.isLimitedAccessResult',
      );
      loggingService.error(
        'Limited Accessチェックエラー',
        context: 'PhotoService.isLimitedAccessResult',
        error: appError,
      );
      return PhotoResultHelper.fromError(
        e,
        context: 'PhotoService.isLimitedAccessResult',
        customMessage: 'Limited Access状態のチェック中にエラーが発生しました',
      );
    }
  }

  /// Limited Photo Access時の統合的なハンドリング
  ///
  /// このメソッドは以下の処理を統合します:
  /// 1. Limited Access状態の検出
  /// 2. 条件に基づく写真選択UIの表示
  /// 3. ユーザーの選択結果の処理
  ///
  /// [checkPhotoCount]: 写真数をチェックするかどうか（デフォルト: true）
  /// [minimumPhotoThreshold]: 写真選択UIを表示する写真数の閾値（デフォルト: 1）
  ///
  /// 戻り値:
  /// - Success(true): Limited Access処理を実行し、ユーザーが写真を選択/変更
  /// - Success(false): Limited Accessではない、または条件に合致しない
  /// - Failure: システムエラーまたはプラットフォーム固有エラー
  Future<Result<bool>> handleLimitedPhotoAccess({
    bool checkPhotoCount = true,
    int minimumPhotoThreshold = 1,
  }) async {
    final loggingService = await LoggingService.getInstance();

    try {
      loggingService.debug(
        'Limited Photo Access統合処理開始',
        context: 'PhotoService.handleLimitedPhotoAccess',
        data:
            'checkPhotoCount: $checkPhotoCount, threshold: $minimumPhotoThreshold',
      );

      // Phase 1: Limited Access状態の検出
      final isLimitedResult = await isLimitedAccessResult();
      if (isLimitedResult.isFailure) {
        loggingService.error(
          'Limited Access状態チェックに失敗',
          context: 'PhotoService.handleLimitedPhotoAccess',
          error: isLimitedResult.error,
        );
        return Failure(isLimitedResult.error);
      }

      final isLimited = isLimitedResult.value;
      if (!isLimited) {
        loggingService.debug(
          'Limited Accessではないため処理をスキップ',
          context: 'PhotoService.handleLimitedPhotoAccess',
        );
        return const Success(false);
      }

      // Phase 2: 写真数チェック（オプション）
      if (checkPhotoCount) {
        try {
          final photos = await getTodayPhotos();
          if (photos.length >= minimumPhotoThreshold) {
            loggingService.debug(
              '写真数が閾値以上のためUI表示をスキップ',
              context: 'PhotoService.handleLimitedPhotoAccess',
              data: '写真数: ${photos.length}, 閾値: $minimumPhotoThreshold',
            );
            return const Success(false);
          }

          loggingService.info(
            'Limited Access + 写真不足のため選択UI表示',
            context: 'PhotoService.handleLimitedPhotoAccess',
            data: '写真数: ${photos.length}, 閾値: $minimumPhotoThreshold',
          );
        } catch (e) {
          loggingService.warning(
            '写真数チェック中にエラーが発生（処理継続）',
            context: 'PhotoService.handleLimitedPhotoAccess',
            data: 'エラー: $e',
          );
          // 写真数チェックエラーは致命的ではないので処理継続
        }
      }

      // Phase 3: 写真選択UIの表示
      final pickerResult = await presentLimitedLibraryPickerResult();
      if (pickerResult.isFailure) {
        loggingService.error(
          '写真選択UI表示に失敗',
          context: 'PhotoService.handleLimitedPhotoAccess',
          error: pickerResult.error,
        );
        return Failure(pickerResult.error);
      }

      final userSelected = pickerResult.value;
      loggingService.info(
        'Limited Photo Access統合処理完了',
        context: 'PhotoService.handleLimitedPhotoAccess',
        data: 'ユーザー選択結果: $userSelected',
      );

      return Success(userSelected);
    } catch (e) {
      return PhotoResultHelper.fromError<bool>(
        e,
        context: 'PhotoService.handleLimitedPhotoAccess',
        customMessage: 'Limited Photo Access処理中にエラーが発生しました',
      );
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

  /// 写真のサムネイルを取得する（Result<T>版）
  ///
  /// [asset]: 写真アセット
  /// [width]: サムネイル幅（デフォルト: AppConstants.defaultThumbnailWidth）
  /// [height]: サムネイル高さ（デフォルト: AppConstants.defaultThumbnailHeight）
  /// [quality]: 品質（デフォルト: 80）
  /// 戻り値: サムネイル画像のUint8ListのResult型
  Future<Result<Uint8List>> getThumbnailResult(
    AssetEntity asset, {
    int width = AppConstants.defaultThumbnailWidth,
    int height = AppConstants.defaultThumbnailHeight,
    int quality = 80,
  }) async {
    final loggingService = await LoggingService.getInstance();

    try {
      // アセットの妥当性チェック
      if (asset.id.isEmpty) {
        return PhotoResultHelper.fromError<Uint8List>(
          ArgumentError('無効なアセットIDです'),
          context: 'PhotoService.getThumbnailResult',
          customMessage: '写真アセットが不正です',
        );
      }

      // パラメータの妥当性チェック
      if (width <= 0 || height <= 0) {
        return PhotoResultHelper.fromError<Uint8List>(
          ArgumentError('サムネイルサイズが不正です: ${width}x$height'),
          context: 'PhotoService.getThumbnailResult',
          customMessage: 'サムネイルサイズの設定が無効です',
        );
      }

      if (quality < 1 || quality > 100) {
        return PhotoResultHelper.fromError<Uint8List>(
          ArgumentError('品質設定が不正です: $quality'),
          context: 'PhotoService.getThumbnailResult',
          customMessage: '品質設定は1-100の範囲で指定してください',
        );
      }

      loggingService.debug(
        'キャッシュ付きサムネイルを取得開始',
        context: 'PhotoService.getThumbnailResult',
        data: 'assetId: ${asset.id}, サイズ: ${width}x$height, 品質: $quality',
      );

      // PhotoCacheServiceを使用してキャッシュ付きでサムネイルを取得
      final cacheService = PhotoCacheService.getInstance();
      final Uint8List? data = await cacheService.getThumbnail(
        asset,
        width: width,
        height: height,
        quality: quality,
      );

      // データ存在チェック
      if (data == null) {
        return PhotoResultHelper.fromError<Uint8List>(
          StateError('キャッシュサービスからのサムネイルがnullです'),
          context: 'PhotoService.getThumbnailResult',
          customMessage: 'サムネイルの取得に失敗しました',
        );
      }

      // データサイズチェック
      if (data.isEmpty) {
        return PhotoResultHelper.fromError<Uint8List>(
          StateError('サムネイルデータが空です'),
          context: 'PhotoService.getThumbnailResult',
          customMessage: 'サムネイルデータが破損している可能性があります',
        );
      }

      // 最小サイズチェック（キャッシュサービス経由なので厳しくチェック）
      if (data.length < 50) {
        return PhotoResultHelper.fromError<Uint8List>(
          StateError('サムネイルデータが異常に小さい: ${data.length}バイト'),
          context: 'PhotoService.getThumbnailResult',
          customMessage: 'キャッシュからのサムネイル取得が不完全です',
        );
      }

      // 基本的な画像データ整合性チェック
      bool isValidImageData = _validateImageData(data);
      if (!isValidImageData) {
        loggingService.warning(
          'キャッシュサムネイルの画像形式検証で問題を検出',
          context: 'PhotoService.getThumbnailResult',
          data:
              'dataSize: ${data.length}バイト, サイズ: ${width}x$height, 品質: $quality',
        );
        // キャッシュサービス経由の場合も継続（形式チェックはベストエフォート）
      }

      loggingService.debug(
        'キャッシュ付きサムネイル取得成功',
        context: 'PhotoService.getThumbnailResult',
        data:
            'dataSize: ${data.length}バイト, サイズ: ${width}x$height, 品質: $quality, valid: $isValidImageData',
      );

      return Success(data);
    } catch (e) {
      return PhotoResultHelper.fromError<Uint8List>(
        e,
        context: 'PhotoService.getThumbnailResult',
        customMessage: 'キャッシュ付きサムネイル取得中にエラーが発生しました',
      );
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

  /// 写真の元画像を取得する（Result<T>版）
  ///
  /// [asset]: 写真アセット
  /// 戻り値: 元画像データのResult型
  Future<Result<Uint8List>> getOriginalFileResult(AssetEntity asset) async {
    final loggingService = await LoggingService.getInstance();

    try {
      // アセットの妥当性チェック
      if (asset.id.isEmpty) {
        return PhotoResultHelper.fromError<Uint8List>(
          ArgumentError('無効なアセットIDです'),
          context: 'PhotoService.getOriginalFileResult',
          customMessage: '写真アセットが不正です',
        );
      }

      loggingService.debug(
        '元画像データを取得開始',
        context: 'PhotoService.getOriginalFileResult',
        data:
            'assetId: ${asset.id}, type: ${asset.type}, duration: ${asset.duration}',
      );

      // ファイルサイズの事前チェック（後でデータサイズで判定）
      // asset.sizeはファイルサイズではなくFlutterのSize型のため使用不可

      // 元画像データを取得
      final Uint8List? data = await asset.originBytes;

      // データ存在チェック
      if (data == null) {
        return PhotoResultHelper.fromError<Uint8List>(
          StateError('元画像データがnullです'),
          context: 'PhotoService.getOriginalFileResult',
          customMessage: '元画像データの取得に失敗しました',
        );
      }

      // データサイズチェック
      if (data.isEmpty) {
        return PhotoResultHelper.fromError<Uint8List>(
          StateError('元画像データが空です'),
          context: 'PhotoService.getOriginalFileResult',
          customMessage: '元画像データが破損している可能性があります',
        );
      }

      // 取得後のデータサイズ監視
      final sizeInMB = data.length / 1024 / 1024;
      if (sizeInMB > 50) {
        // 50MB超過時は警告ログを出力
        loggingService.warning(
          '大容量画像ファイルを検出',
          context: 'PhotoService.getOriginalFileResult',
          data: 'データサイズ: ${sizeInMB.toStringAsFixed(2)}MB',
        );
      }

      // 基本的なデータ整合性チェック
      bool isValidImageData = _validateImageData(data);
      if (!isValidImageData) {
        loggingService.warning(
          '画像データの整合性に問題がある可能性があります',
          context: 'PhotoService.getOriginalFileResult',
          data: 'dataSize: ${data.length}バイト',
        );
      }

      loggingService.debug(
        '元画像データ取得成功',
        context: 'PhotoService.getOriginalFileResult',
        data: 'dataSize: ${data.length}バイト, valid: $isValidImageData',
      );

      return Success(data);
    } catch (e) {
      return PhotoResultHelper.fromError<Uint8List>(
        e,
        context: 'PhotoService.getOriginalFileResult',
        customMessage: '元画像データの取得中にエラーが発生しました',
      );
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
          orders: [const OrderOption()],
          createTimeCond: DateTimeCond(
            min: startDate ?? DateTime(1970),
            max: endDate ?? DateTime.now(),
          ),
        );
      } else {
        filterOption = FilterOptionGroup(orders: [const OrderOption()]);
      }

      // アルバムを取得
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
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

  /// 効率的な写真取得（Result<T>版・ページネーション対応）
  ///
  /// [startDate]: 開始日時（指定しない場合は全期間）
  /// [endDate]: 終了日時（指定しない場合は現在まで）
  /// [offset]: 取得開始位置（0以上）
  /// [limit]: 取得する写真の最大数（1-1000の範囲）
  /// 戻り値: Result<List<AssetEntity>>
  @override
  Future<Result<List<AssetEntity>>> getPhotosEfficientResult({
    DateTime? startDate,
    DateTime? endDate,
    int offset = 0,
    int limit = 30,
  }) async {
    final loggingService = await LoggingService.getInstance();

    try {
      // パラメータ検証
      if (offset < 0) {
        return PhotoResultHelper.fromError<List<AssetEntity>>(
          ArgumentError('オフセットは0以上である必要があります'),
          context: 'PhotoService.getPhotosEfficientResult',
          customMessage: '無効なオフセット値です',
        );
      }

      if (limit < 1 || limit > 1000) {
        return PhotoResultHelper.fromError<List<AssetEntity>>(
          ArgumentError('制限値は1-1000の範囲で指定してください'),
          context: 'PhotoService.getPhotosEfficientResult',
          customMessage: '無効な制限値です',
        );
      }

      // 日付範囲の妥当性チェック
      if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
        return PhotoResultHelper.fromError<List<AssetEntity>>(
          ArgumentError('開始日は終了日より前である必要があります'),
          context: 'PhotoService.getPhotosEfficientResult',
          customMessage: '無効な日付範囲です',
        );
      }

      // 大量データ取得の警告
      if (limit >= 1000) {
        loggingService.warning(
          '大量データ取得警告',
          context: 'PhotoService.getPhotosEfficientResult',
          data: '制限値: $limit (推奨最大1000)',
        );
      } else if (limit >= 500) {
        loggingService.info(
          '大量データ取得情報',
          context: 'PhotoService.getPhotosEfficientResult',
          data: '制限値: $limit',
        );
      }

      // 権限チェック
      final permissionResult = await requestPermissionResult();
      if (!permissionResult.isSuccess) {
        return Failure(permissionResult.error);
      }

      if (!permissionResult.value) {
        return PhotoResultHelper.photoAccessResult(
          null,
          hasPermission: false,
          errorMessage: '写真アクセス権限が拒否されました',
        );
      }

      loggingService.debug(
        '効率的な写真取得を開始',
        context: 'PhotoService.getPhotosEfficientResult',
        data: {
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
          'offset': offset,
          'limit': limit,
        }.toString(),
      );

      // フィルターオプションの作成
      final FilterOptionGroup filterOption;
      if (startDate != null || endDate != null) {
        filterOption = FilterOptionGroup(
          orders: [const OrderOption()],
          createTimeCond: DateTimeCond(
            min: startDate ?? DateTime(1970),
            max: endDate ?? DateTime.now(),
          ),
        );
      } else {
        filterOption = FilterOptionGroup(orders: [const OrderOption()]);
      }

      // アルバムを取得
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        filterOption: filterOption,
      );

      loggingService.debug(
        '取得したアルバム数: ${albums.length}',
        context: 'PhotoService.getPhotosEfficientResult',
      );

      if (albums.isEmpty) {
        loggingService.debug(
          'アルバムが見つかりません',
          context: 'PhotoService.getPhotosEfficientResult',
        );
        return PhotoResultHelper.photoAccessResult(
          <AssetEntity>[],
          errorMessage: '指定した条件に該当するアルバムが見つかりませんでした',
        );
      }

      // メインアルバムから写真を取得
      final AssetPathEntity album = albums.first;
      final int totalCount = await album.assetCountAsync;

      loggingService.debug(
        'アルバム情報',
        context: 'PhotoService.getPhotosEfficientResult',
        data: 'アルバム名: ${album.name}, 総写真数: $totalCount',
      );

      // オフセットが総数を超えている場合
      if (offset >= totalCount) {
        loggingService.debug(
          'オフセットが総数を超えています',
          context: 'PhotoService.getPhotosEfficientResult',
          data: 'オフセット: $offset, 総数: $totalCount',
        );
        return PhotoResultHelper.photoAccessResult(
          <AssetEntity>[],
          errorMessage: 'これ以上の写真はありません',
        );
      }

      // 実際に取得可能な数を計算
      final int actualLimit = (offset + limit > totalCount)
          ? totalCount - offset
          : limit;

      if (actualLimit <= 0) {
        return PhotoResultHelper.photoAccessResult(
          <AssetEntity>[],
          errorMessage: '取得可能な写真がありません',
        );
      }

      // ページネーション処理で写真を取得
      final List<AssetEntity> assets = await album.getAssetListRange(
        start: offset,
        end: offset + actualLimit,
      );

      loggingService.debug(
        '効率的な写真取得完了',
        context: 'PhotoService.getPhotosEfficientResult',
        data: '取得数: ${assets.length}, 実際の制限: $actualLimit, オフセット: $offset',
      );

      return PhotoResultHelper.photoAccessResult(assets);
    } on PlatformException catch (e) {
      return PhotoResultHelper.fromError<List<AssetEntity>>(
        e,
        context: 'PhotoService.getPhotosEfficientResult',
        customMessage: 'プラットフォーム固有のエラーが発生しました',
      );
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoService.getPhotosEfficientResult',
      );
      loggingService.error(
        '効率的な写真取得エラー',
        context: 'PhotoService.getPhotosEfficientResult',
        error: appError,
      );
      return PhotoResultHelper.fromError<List<AssetEntity>>(
        appError,
        context: 'PhotoService.getPhotosEfficientResult',
        customMessage: '写真の効率的な取得に失敗しました',
      );
    }
  }

  /// 画像データの基本的な整合性をチェック
  ///
  /// [data]: 画像データ
  /// 戻り値: データが有効かどうか
  bool _validateImageData(Uint8List data) {
    if (data.length < 10) {
      return false; // あまりにも小さなデータは無効
    }

    // 一般的な画像フォーマットのマジックナンバーをチェック
    // JPEG: FF D8 FF
    if (data.length >= 3 &&
        data[0] == 0xFF &&
        data[1] == 0xD8 &&
        data[2] == 0xFF) {
      return true;
    }

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (data.length >= 8 &&
        data[0] == 0x89 &&
        data[1] == 0x50 &&
        data[2] == 0x4E &&
        data[3] == 0x47 &&
        data[4] == 0x0D &&
        data[5] == 0x0A &&
        data[6] == 0x1A &&
        data[7] == 0x0A) {
      return true;
    }

    // GIF: 47 49 46 38 (GIF8)
    if (data.length >= 4 &&
        data[0] == 0x47 &&
        data[1] == 0x49 &&
        data[2] == 0x46 &&
        data[3] == 0x38) {
      return true;
    }

    // WebP: 57 45 42 50 (WEBP)（RIFF形式の場合は8バイト目から）
    if (data.length >= 12 &&
        data[8] == 0x57 &&
        data[9] == 0x45 &&
        data[10] == 0x42 &&
        data[11] == 0x50) {
      return true;
    }

    // BMP: 42 4D (BM)
    if (data.length >= 2 && data[0] == 0x42 && data[1] == 0x4D) {
      return true;
    }

    // HEIC: 通常はftypボックスで識別されるが簡易チェック
    // (複雑なため、ここでは基本的なサイズチェックのみ)
    if (data.length >= 100) {
      return true; // 十分なサイズがあれば有効と仮定
    }

    return false; // 認識できない形式
  }
}
