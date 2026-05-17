import 'dart:io';

import 'package:photo_manager/photo_manager.dart';
import '../models/photo_type_filter.dart';
import 'interfaces/logging_service_interface.dart';

/// スクリーンショット判定とフォトタイプフィルタリングを担当する static ユーティリティ
final class PhotoFilterService {
  const PhotoFilterService._();

  /// iOSスクリーンショットスマートアルバムのアセットIDセットを取得
  ///
  /// iOSでは「スクリーンショット」スマートアルバムに属するアセットのIDを返す。
  /// Androidでは空セットを返す（relativePathベースで判定するため不要）。
  static Future<Set<String>> getScreenshotAssetIds([
    ILoggingService? logger,
  ]) async {
    if (!Platform.isIOS) return {};

    try {
      // PMDarwinPathFilterでスクリーンショットスマートアルバムを直接取得（ロケール非依存）
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: false,
        pathFilterOption: const PMPathFilter(
          darwin: PMDarwinPathFilter(
            type: [PMDarwinAssetCollectionType.smartAlbum],
            subType: [PMDarwinAssetCollectionSubtype.smartAlbumScreenshots],
          ),
        ),
      );

      final screenshotAlbum = albums.firstOrNull;
      if (screenshotAlbum == null) return {};

      final count = await screenshotAlbum.assetCountAsync;
      if (count == 0) return {};

      final assets = await screenshotAlbum.getAssetListRange(
        start: 0,
        end: count,
      );
      return assets.map((a) => a.id).toSet();
    } catch (e) {
      logger?.warning(
        'Failed to get screenshot asset IDs',
        context: 'PhotoFilterService.getScreenshotAssetIds',
        data: 'error: $e',
      );
      return {};
    }
  }

  /// スクリーンショット判定
  static bool _isScreenshot(AssetEntity asset, Set<String> screenshotAssetIds) {
    // スマートアルバムベース判定（iOS/Android共通）
    if (screenshotAssetIds.contains(asset.id)) {
      return true;
    }

    // iOS: スマートアルバム（screenshotAssetIds）のみで判定
    // subtype ビットマスクは実機で信頼できないため使用しない
    if (Platform.isIOS) {
      return false;
    }

    // Android: MediaStore.RELATIVE_PATH ベース
    final path = asset.relativePath ?? '';
    return path.toLowerCase().contains('screenshot');
  }

  /// 写真タイプフィルターを適用
  static List<AssetEntity> filterByPhotoType(
    List<AssetEntity> assets,
    PhotoTypeFilter filter,
    Set<String> screenshotAssetIds,
  ) {
    return switch (filter) {
      PhotoTypeFilter.all => assets,
      PhotoTypeFilter.photosOnly =>
        assets
            .where((asset) => !_isScreenshot(asset, screenshotAssetIds))
            .toList(),
    };
  }
}
