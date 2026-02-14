import 'package:photo_manager/photo_manager.dart';
import '../constants/app_constants.dart';
import 'interfaces/logging_service_interface.dart';
import '../core/errors/app_exceptions.dart';
import '../core/result/result.dart';

/// 写真のクエリ・日付フィルタリング・ページネーションを担当する内部サービス
class PhotoQueryService {
  final ILoggingService _logger;
  final Future<bool> Function() _requestPermission;

  PhotoQueryService({
    required ILoggingService logger,
    required Future<bool> Function() requestPermission,
  }) : _logger = logger,
       _requestPermission = requestPermission;

  // =================================================================
  // 共通ヘルパー
  // =================================================================

  /// 権限チェック。権限がない場合は null を返す。
  Future<bool> _ensurePermission(String caller) async {
    final hasPermission = await _requestPermission();
    if (!hasPermission) {
      _logger.info(
        'No photo access permission',
        context: 'PhotoQueryService.$caller',
      );
    }
    return hasPermission;
  }

  /// 日付範囲用の FilterOptionGroup を構築
  FilterOptionGroup _buildDateFilter({DateTime? startDate, DateTime? endDate}) {
    if (startDate != null || endDate != null) {
      return FilterOptionGroup(
        orders: const [
          OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
        createTimeCond: DateTimeCond(
          min: startDate ?? DateTime(1970),
          max: endDate ?? DateTime.now(),
        ),
      );
    }
    return FilterOptionGroup(
      orders: const [OrderOption(type: OrderOptionType.createDate, asc: false)],
    );
  }

  /// アルバムの先頭から写真を取得する共通処理
  Future<List<AssetEntity>> _fetchFromAlbum(
    FilterOptionGroup filterOption, {
    required int offset,
    required int limit,
    required String caller,
  }) async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: filterOption,
    );

    _logger.debug(
      'Albums retrieved: ${albums.length}',
      context: 'PhotoQueryService.$caller',
    );

    if (albums.isEmpty) {
      _logger.debug('No albums found', context: 'PhotoQueryService.$caller');
      return [];
    }

    final album = albums.first;
    final totalCount = await album.assetCountAsync;

    if (offset >= totalCount) {
      return [];
    }

    final actualLimit = (offset + limit > totalCount)
        ? totalCount - offset
        : limit;

    return album.getAssetListRange(start: offset, end: offset + actualLimit);
  }

  /// 写真の日付を検証し、範囲内のもののみ返す
  List<AssetEntity> _filterByDateRange(
    List<AssetEntity> assets, {
    required DateTime startDate,
    required DateTime endDate,
    required String caller,
  }) {
    final now = DateTime.now();
    final validAssets = <AssetEntity>[];
    for (final asset in assets) {
      try {
        final createDate = asset.createDateTime;
        if (createDate.year < 1970 || createDate.isAfter(now)) {
          _logger.warning(
            'Skipping photo with invalid creation date',
            context: 'PhotoQueryService.$caller',
            data: 'createDate: $createDate, assetId: ${asset.id}',
          );
          continue;
        }

        final localDate = DateTime(
          createDate.year,
          createDate.month,
          createDate.day,
          createDate.hour,
          createDate.minute,
          createDate.second,
        );

        if (localDate.isBefore(startDate) || localDate.isAfter(endDate)) {
          _logger.debug(
            'Skipping photo outside date range after timezone adjustment',
            context: 'PhotoQueryService.$caller',
            data: 'createDate: $localDate, range: $startDate - $endDate',
          );
          continue;
        }

        validAssets.add(asset);
      } catch (e) {
        _logger.warning(
          'Error during photo validation',
          context: 'PhotoQueryService.$caller',
          data: 'assetId: ${asset.id}, error: $e',
        );
        continue;
      }
    }
    return validAssets;
  }

  // =================================================================
  // 公開メソッド
  // =================================================================

  /// 今日撮影された写真を取得する
  Future<Result<List<AssetEntity>>> getTodayPhotos({int limit = 20}) async {
    if (!await _ensurePermission('getTodayPhotos')) {
      return const Failure(PhotoAccessException('No photo access permission'));
    }

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

      final filterOption = _buildDateFilter(
        startDate: startOfDay,
        endDate: endOfDay,
      );
      final assets = await _fetchFromAlbum(
        filterOption,
        offset: 0,
        limit: limit,
        caller: 'getTodayPhotos',
      );

      final validAssets = _filterByDateRange(
        assets,
        startDate: startOfDay,
        endDate: endOfDay,
        caller: 'getTodayPhotos',
      );

      _logger.info(
        'Retrieved photos for today',
        context: 'PhotoQueryService.getTodayPhotos',
        data:
            'Count: ${validAssets.length} photos (original: ${assets.length})',
      );
      return Success(validAssets);
    } catch (e) {
      return Failure(
        e is AppException
            ? e
            : PhotoAccessException(
                'Failed to get today photos',
                originalError: e,
              ),
      );
    }
  }

  /// 指定された日付範囲の写真を取得する
  Future<Result<List<AssetEntity>>> getPhotosInDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  }) async {
    if (!await _ensurePermission('getPhotosInDateRange')) {
      return const Failure(PhotoAccessException('No photo access permission'));
    }

    try {
      final now = DateTime.now();
      if (startDate.isAfter(now)) {
        _logger.warning(
          'Start date is in the future',
          context: 'PhotoQueryService.getPhotosInDateRange',
          data: 'startDate: $startDate',
        );
        return const Success([]);
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

      final filterOption = _buildDateFilter(
        startDate: localStartDate,
        endDate: localEndDate,
      );
      final assets = await _fetchFromAlbum(
        filterOption,
        offset: 0,
        limit: limit,
        caller: 'getPhotosInDateRange',
      );

      final validAssets = _filterByDateRange(
        assets,
        startDate: localStartDate,
        endDate: localEndDate,
        caller: 'getPhotosInDateRange',
      );

      _logger.info(
        'Photos retrieved',
        context: 'PhotoQueryService.getPhotosInDateRange',
        data:
            '${validAssets.length} valid out of ${assets.length} total photos',
      );

      return Success(validAssets);
    } catch (e) {
      return Failure(
        e is AppException
            ? e
            : PhotoAccessException(
                'Failed to get photos in date range',
                originalError: e,
              ),
      );
    }
  }

  /// 指定された日付の写真を取得する（ページネーション対応）
  Future<Result<List<AssetEntity>>> getPhotosForDate(
    DateTime date, {
    required int offset,
    required int limit,
  }) async {
    if (!await _ensurePermission('getPhotosForDate')) {
      return const Failure(PhotoAccessException('No photo access permission'));
    }

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(
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

      final filterOption = _buildDateFilter(
        startDate: startOfDay,
        endDate: endOfDay,
      );
      final assets = await _fetchFromAlbum(
        filterOption,
        offset: offset,
        limit: limit,
        caller: 'getPhotosForDate',
      );

      final validAssets = _filterByDateRange(
        assets,
        startDate: startOfDay,
        endDate: endOfDay,
        caller: 'getPhotosForDate',
      );

      _logger.info(
        'Retrieved photos for specified date',
        context: 'PhotoQueryService.getPhotosForDate',
        data:
            'Count: ${validAssets.length} photos (original: ${assets.length}), range: $offset - ${offset + limit}',
      );

      return Success(validAssets);
    } catch (e) {
      return Failure(
        e is AppException
            ? e
            : PhotoAccessException(
                'Failed to get photos for date',
                originalError: e,
              ),
      );
    }
  }

  /// 特定の日付の写真を取得する（後方互換性のため保持）
  Future<Result<List<AssetEntity>>> getPhotosByDate(
    DateTime date, {
    int limit = AppConstants.defaultPhotoLimit,
  }) async {
    return await getPhotosForDate(date, offset: 0, limit: limit);
  }

  /// すべての写真を取得する（日付フィルターなし）
  Future<Result<List<AssetEntity>>> getAllPhotos({
    int limit = AppConstants.maxPhotoLimit,
  }) async {
    if (!await _ensurePermission('getAllPhotos')) {
      return const Failure(PhotoAccessException('No photo access permission'));
    }

    try {
      final filterOption = _buildDateFilter();
      final assets = await _fetchFromAlbum(
        filterOption,
        offset: 0,
        limit: limit,
        caller: 'getAllPhotos',
      );

      _logger.info(
        'All photos retrieved',
        context: 'PhotoQueryService.getAllPhotos',
        data: 'Count: ${assets.length} photos',
      );
      return Success(assets);
    } catch (e) {
      return Failure(
        e is AppException
            ? e
            : PhotoAccessException(
                'Failed to get all photos',
                originalError: e,
              ),
      );
    }
  }

  /// 効率的な写真取得（ページネーション対応）
  Future<Result<List<AssetEntity>>> getPhotosEfficient({
    DateTime? startDate,
    DateTime? endDate,
    int offset = 0,
    int limit = 30,
  }) async {
    if (!await _ensurePermission('getPhotosEfficient')) {
      return const Failure(PhotoAccessException('No photo access permission'));
    }

    try {
      final assets = await _getPhotosEfficientInternal(
        startDate: startDate,
        endDate: endDate,
        offset: offset,
        limit: limit,
      );
      return Success(assets);
    } catch (e) {
      return Failure(
        e is AppException
            ? e
            : PhotoAccessException(
                'Failed to get photos efficiently',
                originalError: e,
              ),
      );
    }
  }

  /// 内部実装（例外を伝播 — getPhotosEfficient / Result版 共通）
  Future<List<AssetEntity>> _getPhotosEfficientInternal({
    DateTime? startDate,
    DateTime? endDate,
    int offset = 0,
    int limit = 30,
  }) async {
    final filterOption = _buildDateFilter(
      startDate: startDate,
      endDate: endDate,
    );
    final assets = await _fetchFromAlbum(
      filterOption,
      offset: offset,
      limit: limit,
      caller: 'getPhotosEfficient',
    );

    if (startDate != null && endDate != null) {
      final validAssets = _filterByDateRange(
        assets,
        startDate: startDate,
        endDate: endDate,
        caller: 'getPhotosEfficient',
      );

      _logger.debug(
        'Photos retrieved efficiently',
        context: 'PhotoQueryService.getPhotosEfficient',
        data:
            'Count: ${validAssets.length} (original: ${assets.length}), offset: $offset, limit: $limit',
      );

      return validAssets;
    }

    _logger.debug(
      'Photos retrieved efficiently',
      context: 'PhotoQueryService.getPhotosEfficient',
      data: 'Count: ${assets.length}, offset: $offset, limit: $limit',
    );

    return assets;
  }
}
