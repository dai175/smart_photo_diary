import 'dart:async';
import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import '../constants/app_constants.dart';
import 'interfaces/photo_service_interface.dart';
import 'interfaces/photo_permission_service_interface.dart';
import 'interfaces/camera_service_interface.dart';
import 'interfaces/photo_cache_service_interface.dart';
import 'interfaces/logging_service_interface.dart';
import '../core/errors/error_handler.dart';
import '../core/result/result.dart';
import '../core/result/result_extensions.dart';
import '../core/service_locator.dart';

/// 写真の取得と管理を担当するサービスクラス（Facade）
///
/// 権限管理はIPhotoPermissionServiceに、カメラ撮影はICameraServiceに委譲。
/// クエリ・データ取得メソッドは本クラスに保持。
class PhotoService implements IPhotoService {
  final ILoggingService _logger;
  final IPhotoPermissionService _permissionService;

  PhotoService({
    required ILoggingService logger,
    required IPhotoPermissionService permissionService,
  }) : _logger = logger,
       _permissionService = permissionService;

  /// カメラサービス（遅延解決 - 循環依存回避）
  ICameraService get _cameraService => serviceLocator.get<ICameraService>();

  // =================================================================
  // 権限管理メソッド（IPhotoPermissionServiceへの委譲）
  // =================================================================

  @override
  Future<bool> requestPermission() => _permissionService.requestPermission();

  @override
  Future<bool> isPermissionPermanentlyDenied() =>
      _permissionService.isPermissionPermanentlyDenied();

  @override
  Future<bool> presentLimitedLibraryPicker() =>
      _permissionService.presentLimitedLibraryPicker();

  @override
  Future<bool> isLimitedAccess() => _permissionService.isLimitedAccess();

  // =================================================================
  // カメラ撮影メソッド（ICameraServiceへの委譲）
  // =================================================================

  @override
  Future<Result<AssetEntity?>> capturePhoto() => _cameraService.capturePhoto();

  @override
  Future<Result<bool>> requestCameraPermission() =>
      _cameraService.requestCameraPermission();

  @override
  Future<Result<bool>> isCameraPermissionDenied() =>
      _cameraService.isCameraPermissionDenied();

  // =================================================================
  // クエリメソッド（本クラスに保持）
  // =================================================================

  /// 今日撮影された写真を取得する
  ///
  /// [limit]: 取得する写真の最大数
  /// 戻り値: 写真アセットのリスト
  @override
  Future<List<AssetEntity>> getTodayPhotos({int limit = 20}) async {
    final loggingService = _logger;

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
    final loggingService = _logger;

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
    final loggingService = _logger;

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

  /// すべての写真を取得する（日付フィルターなし）
  ///
  /// [limit]: 取得する写真の最大数
  /// 戻り値: 写真アセットのリスト
  Future<List<AssetEntity>> getAllPhotos({
    int limit = AppConstants.maxPhotoLimit,
  }) async {
    final loggingService = _logger;

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
    final loggingService = _logger;

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

  // =================================================================
  // データ取得メソッド（本クラスに保持）
  // =================================================================

  /// 写真のバイナリデータを取得する
  ///
  /// [asset]: 写真アセット
  /// 戻り値: 写真のバイナリデータ
  @override
  Future<List<int>?> getPhotoData(AssetEntity asset) async {
    try {
      final data = await asset.originBytes;
      return data?.toList();
    } catch (e) {
      final loggingService = _logger;
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
      final data = await asset.thumbnailDataWithSize(
        const ThumbnailSize(
          AppConstants.defaultThumbnailWidth,
          AppConstants.defaultThumbnailHeight,
        ),
      );
      return data?.toList();
    } catch (e) {
      final loggingService = _logger;
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
    final cacheService = serviceLocator.get<IPhotoCacheService>();
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
      final loggingService = _logger;
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
}
