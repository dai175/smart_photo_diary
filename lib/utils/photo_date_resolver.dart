import 'package:photo_manager/photo_manager.dart';

/// 写真アセットの日時解決ユーティリティ
class PhotoDateResolver {
  PhotoDateResolver._();

  static final _epoch = DateTime(1970);

  /// アセットから有効な日時を取得する。
  ///
  /// [AssetEntity.createDateTime] がエポック（1970年以前）の場合は
  /// [AssetEntity.modifiedDateTime] をフォールバックとして使用する。
  static DateTime resolveAssetDateTime(AssetEntity asset) {
    final createDate = asset.createDateTime;
    return createDate.isAfter(_epoch) ? createDate : asset.modifiedDateTime;
  }

  /// 写真リストの代表日時を算出（中央値）
  static DateTime resolveMedianDateTime(List<AssetEntity> assets) {
    final photoTimes =
        assets
            .map(resolveAssetDateTime)
            .where((dt) => dt.isAfter(_epoch))
            .toList()
          ..sort();

    if (photoTimes.isEmpty) return DateTime.now();

    return photoTimes.length == 1
        ? photoTimes.first
        : photoTimes[photoTimes.length ~/ 2];
  }
}
