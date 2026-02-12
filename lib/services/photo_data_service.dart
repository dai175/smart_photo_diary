import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';
import '../constants/app_constants.dart';
import 'interfaces/photo_cache_service_interface.dart';
import 'interfaces/logging_service_interface.dart';
import '../core/errors/error_handler.dart';
import '../core/service_locator.dart';

/// 写真のバイナリデータ取得・サムネイル管理を担当する内部サービス
class PhotoDataService {
  final ILoggingService _logger;

  PhotoDataService({required ILoggingService logger}) : _logger = logger;

  /// 写真のバイナリデータを取得する
  Future<List<int>?> getPhotoData(AssetEntity asset) async {
    try {
      final data = await asset.originBytes;
      return data?.toList();
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoDataService.getPhotoData',
      );
      _logger.error(
        '写真データ取得エラー',
        context: 'PhotoDataService.getPhotoData',
        error: appError,
      );
      return null;
    }
  }

  /// 写真のサムネイルデータを取得する
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
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoDataService.getThumbnailData',
      );
      _logger.error(
        'サムネイルデータ取得エラー',
        context: 'PhotoDataService.getThumbnailData',
        error: appError,
      );
      return null;
    }
  }

  /// 写真のサムネイルを取得する（キャッシュ付き）
  Future<Uint8List?> getThumbnail(
    AssetEntity asset, {
    int width = AppConstants.defaultThumbnailWidth,
    int height = AppConstants.defaultThumbnailHeight,
  }) async {
    try {
      final cacheService = serviceLocator.get<IPhotoCacheService>();
      return await cacheService.getThumbnail(
        asset,
        width: width,
        height: height,
        quality: 80,
      );
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoDataService.getThumbnail',
      );
      _logger.error(
        'サムネイル取得エラー',
        context: 'PhotoDataService.getThumbnail',
        error: appError,
      );
      return null;
    }
  }

  /// 写真の元画像を取得する
  Future<Uint8List?> getOriginalFile(AssetEntity asset) async {
    try {
      return await asset.originBytes;
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoDataService.getOriginalFile',
      );
      _logger.error(
        '元画像取得エラー',
        context: 'PhotoDataService.getOriginalFile',
        error: appError,
      );
      return null;
    }
  }
}
