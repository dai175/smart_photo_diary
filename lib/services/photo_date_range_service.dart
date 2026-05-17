import 'package:photo_manager/photo_manager.dart';
import 'interfaces/logging_service_interface.dart';

/// 日付範囲の構築とアセット日付バリデーションを担当する static ユーティリティ
final class PhotoDateRangeService {
  const PhotoDateRangeService._();

  static const _defaultOrders = [
    OrderOption(type: OrderOptionType.createDate, asc: false),
  ];

  /// 日付範囲用の FilterOptionGroup を構築
  static FilterOptionGroup buildDateFilter({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (startDate != null || endDate != null) {
      return FilterOptionGroup(
        orders: _defaultOrders,
        createTimeCond: DateTimeCond(
          min: startDate ?? DateTime(1970),
          max: endDate ?? DateTime.now(),
        ),
      );
    }
    return FilterOptionGroup(orders: _defaultOrders);
  }

  /// 写真の日付を検証し、範囲内のもののみ返す
  static List<AssetEntity> filterByDateRange(
    List<AssetEntity> assets, {
    required DateTime startDate,
    required DateTime endDate,
    required ILoggingService logger,
    required String logContext,
  }) {
    final now = DateTime.now();
    final validAssets = <AssetEntity>[];
    for (final asset in assets) {
      try {
        final createDate = asset.createDateTime;
        if (createDate.year < 1970 || createDate.isAfter(now)) {
          logger.warning(
            'Skipping photo with invalid creation date',
            context: logContext,
            data: 'createDate: $createDate, assetId: ${asset.id}',
          );
          continue;
        }

        // photo_manager の createDateTime はローカル時刻に UTC オフセットが残る場合があるため
        // フィールドを直接組み立てて tzinfo を除去する
        final localDate = DateTime(
          createDate.year,
          createDate.month,
          createDate.day,
          createDate.hour,
          createDate.minute,
          createDate.second,
        );

        if (localDate.isBefore(startDate) || localDate.isAfter(endDate)) {
          logger.debug(
            'Skipping photo outside date range after timezone adjustment',
            context: logContext,
            data: 'createDate: $localDate, range: $startDate - $endDate',
          );
          continue;
        }

        validAssets.add(asset);
      } catch (e) {
        logger.warning(
          'Error during photo validation',
          context: logContext,
          data: 'assetId: ${asset.id}, error: $e',
        );
        continue;
      }
    }
    return validAssets;
  }
}
