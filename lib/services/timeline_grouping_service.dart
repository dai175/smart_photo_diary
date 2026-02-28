import 'package:photo_manager/photo_manager.dart';
import '../models/timeline_photo_group.dart';

/// タイムライン用の写真グルーピングサービス
///
/// ホーム画面タブ統合で実装されたコアサービス。
/// 写真を日付別にグルーピングし、タイムライン表示用のデータ構造を提供。
/// - 今日/昨日/月単位の階層グルーピング
/// - シングルトンパターンでパフォーマンス最適化
class TimelineGroupingService {
  static const TimelineGroupingService _instance =
      TimelineGroupingService._internal();

  factory TimelineGroupingService() => _instance;

  const TimelineGroupingService._internal();

  /// 写真をタイムライン用にグルーピング（多言語化対応）
  List<TimelinePhotoGroup> groupPhotosForTimelineLocalized(
    List<AssetEntity> photos, {
    required String todayLabel,
    required String yesterdayLabel,
    required String Function(int year, int month) monthYearFormatter,
  }) {
    if (photos.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<AssetEntity>> groupMap = {};

    // 写真を日付別にグルーピング
    for (final photo in photos) {
      final photoDate = photo.createDateTime;
      final photoDay = DateTime(photoDate.year, photoDate.month, photoDate.day);

      String groupKey;
      if (_isSameDate(photoDay, today)) {
        groupKey = 'today';
      } else if (_isSameDate(photoDay, yesterday)) {
        groupKey = 'yesterday';
      } else {
        // 月単位でグルーピング
        groupKey =
            '${photoDate.year}-${photoDate.month.toString().padLeft(2, '0')}';
      }

      groupMap.putIfAbsent(groupKey, () => []).add(photo);
    }

    // TimelinePhotoGroupに変換
    final List<TimelinePhotoGroup> groups = [];

    // 今日のグループ
    if (groupMap.containsKey('today')) {
      groups.add(
        TimelinePhotoGroup(
          displayName: todayLabel,
          groupDate: today,
          type: TimelineGroupType.today,
          photos: groupMap['today']!,
        ),
      );
    }

    // 昨日のグループ
    if (groupMap.containsKey('yesterday')) {
      groups.add(
        TimelinePhotoGroup(
          displayName: yesterdayLabel,
          groupDate: yesterday,
          type: TimelineGroupType.yesterday,
          photos: groupMap['yesterday']!,
        ),
      );
    }

    // 月単位のグループ（新しい順にソート）
    final monthlyKeys =
        groupMap.keys
            .where((key) => key != 'today' && key != 'yesterday')
            .toList()
          ..sort((a, b) => b.compareTo(a)); // 降順（新しい月が上）

    for (final key in monthlyKeys) {
      final parts = key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);

      groups.add(
        TimelinePhotoGroup(
          displayName: monthYearFormatter(year, month),
          groupDate: DateTime(year, month),
          type: TimelineGroupType.monthly,
          photos: groupMap[key]!,
        ),
      );
    }

    return groups;
  }

  /// グループヘッダーテキストを生成（多言語化対応）
  String getTimelineHeaderLocalized(
    DateTime date,
    TimelineGroupType type, {
    required String todayLabel,
    required String yesterdayLabel,
    required String Function(int year, int month) monthYearFormatter,
  }) {
    switch (type) {
      case TimelineGroupType.today:
        return todayLabel;
      case TimelineGroupType.yesterday:
        return yesterdayLabel;
      case TimelineGroupType.monthly:
        return monthYearFormatter(date.year, date.month);
    }
  }

  /// 選択制限の視覚的フィードバック用
  /// 指定された写真が薄い表示になるべきかどうかを判定
  bool shouldShowDimmed(AssetEntity photo, DateTime? selectedDate) {
    if (selectedDate == null) return false;

    final photoDate = photo.createDateTime;
    return !_isSameDate(photoDate, selectedDate);
  }

  /// 同じ日付かどうかをチェック
  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 写真リストから選択されている日付を取得
  DateTime? getSelectedDate(List<AssetEntity> selectedPhotos) {
    if (selectedPhotos.isEmpty) return null;
    return selectedPhotos.first.createDateTime;
  }
}
