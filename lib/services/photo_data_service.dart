import 'dart:io';
import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';
import '../constants/ai_constants.dart';
import '../constants/app_constants.dart';
import '../core/errors/app_exceptions.dart';
import '../core/result/result.dart';
import 'interfaces/photo_cache_service_interface.dart';
import 'interfaces/logging_service_interface.dart';
import '../core/errors/error_handler.dart';

/// 写真のバイナリデータ取得・サムネイル管理を担当する内部サービス
class PhotoDataService {
  final ILoggingService _logger;
  final IPhotoCacheService _cacheService;

  PhotoDataService({
    required ILoggingService logger,
    required IPhotoCacheService cacheService,
  }) : _logger = logger,
       _cacheService = cacheService;

  /// 写真IDリストからAssetEntityを取得する
  Future<Result<List<AssetEntity>>> getAssetsByIds(
    List<String> photoIds,
  ) async {
    try {
      final results = await Future.wait(
        photoIds.map((photoId) async {
          try {
            return await AssetEntity.fromId(photoId);
          } catch (e) {
            _logger.error(
              'Photo retrieval error: photoId: $photoId',
              context: 'PhotoDataService.getAssetsByIds',
              error: e,
            );
            return null;
          }
        }),
      );
      return Success(results.whereType<AssetEntity>().toList());
    } catch (e) {
      return Failure(
        PhotoAccessException('Failed to load photo assets', originalError: e),
      );
    }
  }

  /// 写真のバイナリデータを取得する
  Future<Result<List<int>>> getPhotoData(AssetEntity asset) async {
    try {
      final data = await asset.originBytes;
      if (data == null) {
        return const Failure(
          PhotoAccessException('Failed to retrieve photo data: data is null'),
        );
      }
      return Success(data.toList());
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoDataService.getPhotoData',
      );
      _logger.error(
        'Photo data retrieval error',
        context: 'PhotoDataService.getPhotoData',
        error: appError,
      );
      return Failure(
        PhotoAccessException('Failed to retrieve photo data', originalError: e),
      );
    }
  }

  /// 写真のサムネイルデータを取得する
  Future<Result<List<int>>> getThumbnailData(AssetEntity asset) async {
    try {
      final data = await asset.thumbnailDataWithSize(
        const ThumbnailSize(
          AppConstants.defaultThumbnailWidth,
          AppConstants.defaultThumbnailHeight,
        ),
      );
      if (data == null) {
        return const Failure(
          PhotoAccessException(
            'Failed to retrieve thumbnail data: data is null',
          ),
        );
      }
      return Success(data.toList());
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoDataService.getThumbnailData',
      );
      _logger.error(
        'Thumbnail data retrieval error',
        context: 'PhotoDataService.getThumbnailData',
        error: appError,
      );
      return Failure(
        PhotoAccessException(
          'Failed to retrieve thumbnail data',
          originalError: e,
        ),
      );
    }
  }

  /// 写真のサムネイルを取得する（キャッシュ付き）
  Future<Result<Uint8List>> getThumbnail(
    AssetEntity asset, {
    int width = AppConstants.defaultThumbnailWidth,
    int height = AppConstants.defaultThumbnailHeight,
  }) async {
    try {
      return await _cacheService.getThumbnail(
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
        'Thumbnail retrieval error',
        context: 'PhotoDataService.getThumbnail',
        error: appError,
      );
      return Failure(
        PhotoAccessException('Failed to retrieve thumbnail', originalError: e),
      );
    }
  }

  /// AI送信用にリサイズした画像を取得する
  ///
  /// 元画像をプラットフォームネイティブのパイプラインで最大 [AiConstants.aiImageMaxSize] px に
  /// リサイズし、JPEG として返す。モバイル通信でのアップロードサイズを大幅に削減する。
  Future<Result<Uint8List>> getImageForAi(AssetEntity asset) async {
    try {
      const size = ThumbnailSize.square(AiConstants.aiImageMaxSize);
      final option = Platform.isIOS || Platform.isMacOS
          ? ThumbnailOption.ios(
              size: size,
              format: ThumbnailFormat.jpeg,
              quality: AiConstants.aiImageQuality,
              resizeContentMode: ResizeContentMode.fit,
            )
          // Android: Glide のデフォルトが FitCenter のため明示指定不要
          : const ThumbnailOption(
              size: size,
              format: ThumbnailFormat.jpeg,
              quality: AiConstants.aiImageQuality,
            );
      final data = await asset.thumbnailDataWithOption(option);
      if (data == null) {
        return const Failure(
          PhotoAccessException('Failed to retrieve AI image: data is null'),
        );
      }
      return Success(data);
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoDataService.getImageForAi',
      );
      _logger.error(
        'AI image retrieval error',
        context: 'PhotoDataService.getImageForAi',
        error: appError,
      );
      return Failure(
        PhotoAccessException('Failed to retrieve AI image', originalError: e),
      );
    }
  }

  /// 写真の元画像を取得する
  Future<Result<Uint8List>> getOriginalFile(AssetEntity asset) async {
    try {
      final data = await asset.originBytes;
      if (data == null) {
        return const Failure(
          PhotoAccessException(
            'Failed to retrieve original file: data is null',
          ),
        );
      }
      return Success(data);
    } catch (e) {
      final appError = ErrorHandler.handleError(
        e,
        context: 'PhotoDataService.getOriginalFile',
      );
      _logger.error(
        'Original image retrieval error',
        context: 'PhotoDataService.getOriginalFile',
        error: appError,
      );
      return Failure(
        PhotoAccessException(
          'Failed to retrieve original file',
          originalError: e,
        ),
      );
    }
  }
}
