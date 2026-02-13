import 'package:photo_manager/photo_manager.dart';
import '../constants/app_constants.dart';
import 'interfaces/logging_service_interface.dart';
import '../core/errors/app_exceptions.dart';
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
      _logger.info(
        'No photo access permission',
        context: 'PhotoQueryService.getTodayPhotos',
      );
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
        'Albums retrieved: ${albums.length}',
        context: 'PhotoQueryService.getTodayPhotos',
      );

      if (albums.isEmpty) {
        _logger.debug(
          'No albums found for today',
          context: 'PhotoQueryService.getTodayPhotos',
        );
        return [];
      }

      final AssetPathEntity recentAlbum = albums.first;
      _logger.debug(
        'Album name: ${recentAlbum.name}',
        context: 'PhotoQueryService.getTodayPhotos',
      );

      final List<AssetEntity> assets = await recentAlbum.getAssetListRange(
        start: 0,
        end: limit,
      );

      _logger.info(
        'Retrieved photos for today',
        context: 'PhotoQueryService.getTodayPhotos',
        data: 'Count: ${assets.length} photos',
      );
      return assets;
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoQueryService.getTodayPhotos',
      );
      _logger.error(
        'Photo retrieval error',
        context: 'PhotoQueryService.getTodayPhotos',
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
        'No photo access permission',
        context: 'PhotoQueryService.getPhotosInDateRange',
      );
      return [];
    }

    try {
      final now = DateTime.now();
      if (startDate.isAfter(now)) {
        _logger.warning(
          'Start date is in the future',
          context: 'PhotoQueryService.getPhotosInDateRange',
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
        'Date range: $localStartDate - $localEndDate (local timezone)',
        context: 'PhotoQueryService.getPhotosInDateRange',
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
          'No albums found for specified period',
          context: 'PhotoQueryService.getPhotosInDateRange',
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
              'Skipping photo with invalid creation date',
              context: 'PhotoQueryService.getPhotosInDateRange',
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
              'Skipping photo outside date range after timezone adjustment',
              context: 'PhotoQueryService.getPhotosInDateRange',
              data:
                  'createDate: $localCreateDate, range: $localStartDate - $localEndDate',
            );
            continue;
          }

          validAssets.add(asset);
        } catch (e) {
          _logger.warning(
            'Error during photo validation',
            context: 'PhotoQueryService.getPhotosInDateRange',
            data: 'assetId: ${asset.id}, error: $e',
          );
          continue;
        }
      }

      _logger.info(
        'Photos retrieved',
        context: 'PhotoQueryService.getPhotosInDateRange',
        data:
            '${validAssets.length} valid out of ${assets.length} total photos',
      );

      return validAssets;
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoQueryService.getPhotosInDateRange',
      );
      _logger.error(
        'Photo retrieval error',
        context: 'PhotoQueryService.getPhotosInDateRange',
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
      _logger.info(
        'No photo access permission',
        context: 'PhotoQueryService.getPhotosForDate',
      );
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
        'Searching photos for specified date',
        context: 'PhotoQueryService.getPhotosForDate',
        data:
            'Date: $date, offset: $offset, limit: $limit, range: $startOfDay - $endOfDay (local timezone)',
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
        'Albums retrieved: ${albums.length}',
        context: 'PhotoQueryService.getPhotosForDate',
      );

      if (albums.isEmpty) {
        _logger.debug(
          'No albums found for specified date',
          context: 'PhotoQueryService.getPhotosForDate',
        );
        return [];
      }

      final AssetPathEntity album = albums.first;
      final int totalCount = await album.assetCountAsync;
      _logger.debug(
        'Album info',
        context: 'PhotoQueryService.getPhotosForDate',
        data: 'Album name: ${album.name}, total photos: $totalCount',
      );

      if (offset >= totalCount) {
        _logger.debug(
          'Offset exceeds total count',
          context: 'PhotoQueryService.getPhotosForDate',
          data: 'Offset: $offset, total: $totalCount',
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
              'Skipping photo with different date after timezone adjustment',
              context: 'PhotoQueryService.getPhotosForDate',
              data:
                  'expected: ${date.toIso8601String()}, actual: ${localCreateDate.toIso8601String()}',
            );
          }
        } catch (e) {
          _logger.warning(
            'Error during photo date verification',
            context: 'PhotoQueryService.getPhotosForDate',
            data: 'assetId: ${asset.id}, error: $e',
          );
          validAssets.add(asset);
        }
      }

      _logger.info(
        'Retrieved photos for specified date',
        context: 'PhotoQueryService.getPhotosForDate',
        data:
            'Count: ${validAssets.length} photos (original: ${assets.length}), range: $offset - ${offset + actualLimit}',
      );

      return validAssets;
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoQueryService.getPhotosForDate',
      );
      _logger.error(
        'Photo retrieval error',
        context: 'PhotoQueryService.getPhotosForDate',
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
      _logger.info(
        'No photo access permission',
        context: 'PhotoQueryService.getAllPhotos',
      );
      return [];
    }

    try {
      final FilterOptionGroup filterOption = FilterOptionGroup(
        orders: [const OrderOption()],
      );

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: filterOption,
      );

      _logger.debug(
        'Albums retrieved: ${albums.length}',
        context: 'PhotoQueryService.getAllPhotos',
      );

      if (albums.isEmpty) {
        _logger.debug(
          'No albums found',
          context: 'PhotoQueryService.getAllPhotos',
        );
        return [];
      }

      final AssetPathEntity album = albums.first;
      final List<AssetEntity> assets = await album.getAssetListRange(
        start: 0,
        end: limit,
      );

      _logger.info(
        'All photos retrieved',
        context: 'PhotoQueryService.getAllPhotos',
        data: 'Album name: ${album.name}, count: ${assets.length} photos',
      );
      return assets;
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoQueryService.getAllPhotos',
      );
      _logger.error(
        'Photo retrieval error',
        context: 'PhotoQueryService.getAllPhotos',
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
        'No photo access permission',
        context: 'PhotoQueryService.getPhotosEfficient',
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
          'No albums found',
          context: 'PhotoQueryService.getPhotosEfficient',
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
        'Photos retrieved efficiently',
        context: 'PhotoQueryService.getPhotosEfficient',
        data: 'Count: ${assets.length}, offset: $offset, limit: $limit',
      );

      return assets;
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoQueryService.getPhotosEfficient',
      );
      _logger.error(
        'Photo retrieval error',
        context: 'PhotoQueryService.getPhotosEfficient',
        error: appError,
      );
      return [];
    }
  }

  /// 効率的な写真取得（Result版 — エラーを Failure として伝播）
  Future<Result<List<AssetEntity>>> getPhotosEfficientResult({
    DateTime? startDate,
    DateTime? endDate,
    int offset = 0,
    int limit = 30,
  }) async {
    return ResultHelper.tryExecuteAsync(() async {
      return await _getPhotosEfficientInternal(
        startDate: startDate,
        endDate: endDate,
        offset: offset,
        limit: limit,
      );
    }, context: 'PhotoQueryService.getPhotosEfficientResult');
  }

  /// 内部実装（例外を伝播 — Result版から呼ばれる）
  Future<List<AssetEntity>> _getPhotosEfficientInternal({
    DateTime? startDate,
    DateTime? endDate,
    int offset = 0,
    int limit = 30,
  }) async {
    final bool hasPermission = await _requestPermission();
    if (!hasPermission) {
      throw const PhotoAccessException(
        'No photo access permission',
        details: 'Permission denied',
      );
    }

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
        'No albums found',
        context: 'PhotoQueryService.getPhotosEfficient',
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
      'Photos retrieved efficiently',
      context: 'PhotoQueryService.getPhotosEfficient',
      data: 'Count: ${assets.length}, offset: $offset, limit: $limit',
    );

    return assets;
  }
}
