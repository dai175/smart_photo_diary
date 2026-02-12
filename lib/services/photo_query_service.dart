import 'package:photo_manager/photo_manager.dart';
import '../constants/app_constants.dart';
import 'interfaces/logging_service_interface.dart';
import '../core/errors/error_handler.dart';
import '../core/result/result.dart';
import '../core/result/result_extensions.dart';

/// 写真のクエリ・日付フィルタリング・ページネーションを担当する内部サービス
class PhotoQueryService {
  final ILoggingService _logger;
  final Future<bool> Function() _requestPermission;

  PhotoQueryService({
    required ILoggingService logger,
    required Future<bool> Function() requestPermission,
  }) : _logger = logger,
       _requestPermission = requestPermission;

  /// 今日撮影された写真を取得する
  Future<List<AssetEntity>> getTodayPhotos({int limit = 20}) async {
    final bool hasPermission = await _requestPermission();
    if (!hasPermission) {
      _logger.info('写真アクセス権限がありません', context: 'PhotoService.getTodayPhotos');
      return [];
    }

    try {
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

      final FilterOptionGroup filterOption = FilterOptionGroup(
        orders: const [
          OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
        createTimeCond: DateTimeCond(min: startOfDay, max: endOfDay),
      );

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: filterOption,
      );

      _logger.debug(
        '取得したアルバム数: ${albums.length}',
        context: 'PhotoService.getTodayPhotos',
      );

      if (albums.isEmpty) {
        _logger.debug(
          '今日のアルバムが見つかりません',
          context: 'PhotoService.getTodayPhotos',
        );
        return [];
      }

      final AssetPathEntity recentAlbum = albums.first;
      _logger.debug(
        'アルバム名: ${recentAlbum.name}',
        context: 'PhotoService.getTodayPhotos',
      );

      final List<AssetEntity> assets = await recentAlbum.getAssetListRange(
        start: 0,
        end: limit,
      );

      _logger.info(
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
      _logger.error(
        '写真取得エラー',
        context: 'PhotoService.getTodayPhotos',
        error: appError,
      );
      return [];
    }
  }

  /// 指定された日付範囲の写真を取得する
  Future<List<AssetEntity>> getPhotosInDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  }) async {
    final bool hasPermission = await _requestPermission();
    if (!hasPermission) {
      _logger.info(
        '写真アクセス権限がありません',
        context: 'PhotoService.getPhotosInDateRange',
      );
      return [];
    }

    try {
      final now = DateTime.now();
      if (startDate.isAfter(now)) {
        _logger.warning(
          '開始日が未来の日付です',
          context: 'PhotoService.getPhotosInDateRange',
          data: 'startDate: $startDate',
        );
        return [];
      }

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

      _logger.debug(
        '日付範囲: $localStartDate - $localEndDate (ローカルタイムゾーン)',
        context: 'PhotoService.getPhotosInDateRange',
      );

      final FilterOptionGroup filterOption = FilterOptionGroup(
        orders: const [
          OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
        createTimeCond: DateTimeCond(min: localStartDate, max: localEndDate),
      );

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: filterOption,
      );

      if (albums.isEmpty) {
        _logger.debug(
          '指定期間のアルバムが見つかりません',
          context: 'PhotoService.getPhotosInDateRange',
        );
        return [];
      }

      final AssetPathEntity album = albums.first;
      final List<AssetEntity> assets = await album.getAssetListRange(
        start: 0,
        end: limit,
      );

      final List<AssetEntity> validAssets = [];
      for (final asset in assets) {
        try {
          final createDate = asset.createDateTime;
          if (createDate.year < 1970 || createDate.isAfter(now)) {
            _logger.warning(
              '不正な作成日時の写真をスキップ',
              context: 'PhotoService.getPhotosInDateRange',
              data: 'createDate: $createDate, assetId: ${asset.id}',
            );
            continue;
          }

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
            _logger.debug(
              'タイムゾーン調整後、日付範囲外の写真をスキップ',
              context: 'PhotoService.getPhotosInDateRange',
              data:
                  'createDate: $localCreateDate, range: $localStartDate - $localEndDate',
            );
            continue;
          }

          final thumbnail = await asset.thumbnailDataWithSize(
            const ThumbnailSize(100, 100),
            quality: 50,
          );

          if (thumbnail == null || thumbnail.isEmpty) {
            _logger.warning(
              'サムネイルを取得できない写真をスキップ',
              context: 'PhotoService.getPhotosInDateRange',
              data: 'assetId: ${asset.id}',
            );
            continue;
          }

          validAssets.add(asset);
        } catch (e) {
          _logger.warning(
            '写真の検証中にエラーが発生',
            context: 'PhotoService.getPhotosInDateRange',
            data: 'assetId: ${asset.id}, error: $e',
          );
          continue;
        }
      }

      _logger.info(
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
      _logger.error(
        '写真取得エラー',
        context: 'PhotoService.getPhotosInDateRange',
        error: appError,
      );
      return [];
    }
  }

  /// 指定された日付の写真を取得する（ページネーション対応）
  Future<List<AssetEntity>> getPhotosForDate(
    DateTime date, {
    required int offset,
    required int limit,
  }) async {
    final bool hasPermission = await _requestPermission();
    if (!hasPermission) {
      _logger.info('写真アクセス権限がありません', context: 'PhotoService.getPhotosForDate');
      return [];
    }

    try {
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

      _logger.debug(
        '指定日の写真を検索',
        context: 'PhotoService.getPhotosForDate',
        data:
            '日付: $date, オフセット: $offset, 制限: $limit, 検索範囲: $startOfDay - $endOfDay (ローカルタイムゾーン)',
      );

      final FilterOptionGroup filterOption = FilterOptionGroup(
        orders: const [
          OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
        createTimeCond: DateTimeCond(min: startOfDay, max: endOfDay),
      );

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: filterOption,
      );

      _logger.debug(
        '取得したアルバム数: ${albums.length}',
        context: 'PhotoService.getPhotosForDate',
      );

      if (albums.isEmpty) {
        _logger.debug(
          '指定日のアルバムが見つかりません',
          context: 'PhotoService.getPhotosForDate',
        );
        return [];
      }

      final AssetPathEntity album = albums.first;
      final int totalCount = await album.assetCountAsync;
      _logger.debug(
        'アルバム情報',
        context: 'PhotoService.getPhotosForDate',
        data: 'アルバム名: ${album.name}, 総写真数: $totalCount',
      );

      if (offset >= totalCount) {
        _logger.debug(
          'オフセットが総数を超えています',
          context: 'PhotoService.getPhotosForDate',
          data: 'オフセット: $offset, 総数: $totalCount',
        );
        return [];
      }

      final int actualLimit = (offset + limit > totalCount)
          ? totalCount - offset
          : limit;

      final List<AssetEntity> assets = await album.getAssetListRange(
        start: offset,
        end: offset + actualLimit,
      );

      final List<AssetEntity> validAssets = [];
      for (final asset in assets) {
        try {
          final createDate = asset.createDateTime;
          final localCreateDate = DateTime(
            createDate.year,
            createDate.month,
            createDate.day,
          );

          if (localCreateDate.year == date.year &&
              localCreateDate.month == date.month &&
              localCreateDate.day == date.day) {
            validAssets.add(asset);
          } else {
            _logger.debug(
              'タイムゾーン調整後、異なる日付の写真をスキップ',
              context: 'PhotoService.getPhotosForDate',
              data:
                  'expected: ${date.toIso8601String()}, actual: ${localCreateDate.toIso8601String()}',
            );
          }
        } catch (e) {
          _logger.warning(
            '写真の日付確認中にエラー',
            context: 'PhotoService.getPhotosForDate',
            data: 'assetId: ${asset.id}, error: $e',
          );
          validAssets.add(asset);
        }
      }

      _logger.info(
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
      _logger.error(
        '写真取得エラー',
        context: 'PhotoService.getPhotosForDate',
        error: appError,
      );
      return [];
    }
  }

  /// 特定の日付の写真を取得する（後方互換性のため保持）
  Future<List<AssetEntity>> getPhotosByDate(
    DateTime date, {
    int limit = AppConstants.defaultPhotoLimit,
  }) async {
    return await getPhotosForDate(date, offset: 0, limit: limit);
  }

  /// すべての写真を取得する（日付フィルターなし）
  Future<List<AssetEntity>> getAllPhotos({
    int limit = AppConstants.maxPhotoLimit,
  }) async {
    final bool hasPermission = await _requestPermission();
    if (!hasPermission) {
      _logger.info('写真アクセス権限がありません', context: 'PhotoService.getAllPhotos');
      return [];
    }

    try {
      final FilterOptionGroup filterOption = FilterOptionGroup(
        orders: [const OrderOption()],
      );

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        filterOption: filterOption,
      );

      _logger.debug(
        '取得したアルバム数: ${albums.length}',
        context: 'PhotoService.getAllPhotos',
      );

      if (albums.isEmpty) {
        _logger.debug('アルバムが見つかりません', context: 'PhotoService.getAllPhotos');
        return [];
      }

      final AssetPathEntity album = albums.first;
      final List<AssetEntity> assets = await album.getAssetListRange(
        start: 0,
        end: limit,
      );

      _logger.info(
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
      _logger.error(
        '写真取得エラー',
        context: 'PhotoService.getAllPhotos',
        error: appError,
      );
      return [];
    }
  }

  /// 効率的な写真取得（ページネーション対応）
  Future<List<AssetEntity>> getPhotosEfficient({
    DateTime? startDate,
    DateTime? endDate,
    int offset = 0,
    int limit = 30,
  }) async {
    final bool hasPermission = await _requestPermission();
    if (!hasPermission) {
      _logger.info(
        '写真アクセス権限がありません',
        context: 'PhotoService.getPhotosEfficient',
      );
      return [];
    }

    try {
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

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: filterOption,
      );

      if (albums.isEmpty) {
        _logger.debug(
          'アルバムが見つかりません',
          context: 'PhotoService.getPhotosEfficient',
        );
        return [];
      }

      final AssetPathEntity album = albums.first;
      final int totalCount = await album.assetCountAsync;

      if (offset >= totalCount) {
        return [];
      }

      final int actualLimit = (offset + limit > totalCount)
          ? totalCount - offset
          : limit;

      final List<AssetEntity> assets = await album.getAssetListRange(
        start: offset,
        end: offset + actualLimit,
      );

      _logger.debug(
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
      _logger.error(
        '写真取得エラー',
        context: 'PhotoService.getPhotosEfficient',
        error: appError,
      );
      return [];
    }
  }

  /// 効率的な写真取得（Result版）
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
}
