import 'package:photo_manager/photo_manager.dart';

/// タイムライン表示用の写真グルーピングタイプ
enum TimelineGroupType {
  /// 今日
  today,

  /// 昨日
  yesterday,

  /// 月単位
  monthly,
}

/// タイムライン表示用の写真グループ
class TimelinePhotoGroup {
  /// 表示名（"今日", "昨日", "2025年1月"）
  final String displayName;

  /// グループを代表する日付
  final DateTime groupDate;

  /// グルーピングタイプ
  final TimelineGroupType type;

  /// そのグループの写真リスト
  final List<AssetEntity> photos;

  const TimelinePhotoGroup({
    required this.displayName,
    required this.groupDate,
    required this.type,
    required this.photos,
  });

  /// 今日のグループかどうか
  bool get isToday => type == TimelineGroupType.today;

  /// 昨日のグループかどうか
  bool get isYesterday => type == TimelineGroupType.yesterday;

  /// 月単位のグループかどうか
  bool get isMonthly => type == TimelineGroupType.monthly;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimelinePhotoGroup &&
        other.displayName == displayName &&
        other.groupDate == groupDate &&
        other.type == type;
  }

  @override
  int get hashCode {
    return displayName.hashCode ^ groupDate.hashCode ^ type.hashCode;
  }

  @override
  String toString() {
    return 'TimelinePhotoGroup(displayName: $displayName, type: $type, photos: ${photos.length})';
  }
}
