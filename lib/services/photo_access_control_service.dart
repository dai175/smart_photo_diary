import '../models/plans/plan.dart';
import 'interfaces/photo_access_control_service_interface.dart';
import 'interfaces/logging_service_interface.dart';

/// 写真アクセス制御サービスの実装
///
/// プランに基づいた写真へのアクセス可否を判定する
class PhotoAccessControlService implements IPhotoAccessControlService {
  final ILoggingService? _logger;

  PhotoAccessControlService({ILoggingService? logger}) : _logger = logger;

  /// 指定されたプランでアクセス可能な最古の日付を取得
  @override
  DateTime getAccessibleDateForPlan(Plan plan) {
    final now = DateTime.now();
    // タイムゾーン対応: 今日の0時0分0秒を基準にする（ローカルタイムゾーン）
    final today = DateTime(now.year, now.month, now.day);

    // プランのアクセス可能日数分だけ過去に遡る
    final accessibleDate = today.subtract(
      Duration(days: plan.pastPhotoAccessDays),
    );

    _logger?.info(
      'Accessible range calculated: plan=${plan.displayName}, '
      'pastDays=${plan.pastPhotoAccessDays}, '
      'oldestAccessibleDate=$accessibleDate (local timezone)',
      context: 'PhotoAccessControlService.getAccessibleDateForPlan',
    );

    return accessibleDate;
  }

  /// 指定された写真の撮影日時がプランでアクセス可能かどうかを判定
  @override
  bool isPhotoAccessible(DateTime photoDate, Plan plan) {
    // タイムゾーン対応: 日付のみで比較（時刻は考慮しない）、ローカルタイムゾーンで正規化
    final photoDateOnly = DateTime(
      photoDate.year,
      photoDate.month,
      photoDate.day,
    );
    final accessibleDate = getAccessibleDateForPlan(plan);

    // 写真の日付がアクセス可能日以降であればアクセス可能
    final isAccessible =
        photoDateOnly.isAfter(accessibleDate) ||
        photoDateOnly.isAtSameMomentAs(accessibleDate);

    _logger?.info(
      'Photo access check: '
      'plan=${plan.displayName}, '
      'photoDate=$photoDateOnly (local), '
      'oldestAccessibleDate=$accessibleDate (local), '
      'result=$isAccessible',
      context: 'PhotoAccessControlService.isPhotoAccessible',
    );

    return isAccessible;
  }

  /// 現在のプランでアクセス可能な日付範囲の説明を取得
  /// [formatter] はUI層からローカライズ済みの文字列を生成するコールバック
  @override
  String getAccessRangeDescription(
    Plan plan, {
    required String Function(int days) formatter,
  }) {
    return formatter(plan.pastPhotoAccessDays);
  }
}
