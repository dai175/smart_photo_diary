import '../models/plans/plan.dart';
import 'interfaces/photo_access_control_service_interface.dart';
import 'interfaces/logging_service_interface.dart';
import '../core/service_locator.dart';

/// 写真アクセス制御サービスの実装
///
/// プランに基づいた写真へのアクセス可否を判定する
class PhotoAccessControlService implements IPhotoAccessControlService {
  // シングルトンパターン
  static PhotoAccessControlService? _instance;
  ILoggingService? _logger;

  PhotoAccessControlService._();

  @Deprecated('Use ServiceLocator.get<IPhotoAccessControlService>() instead')
  static PhotoAccessControlService getInstance() {
    _instance ??= PhotoAccessControlService._();
    return _instance!;
  }

  /// LoggingServiceを取得（遅延初期化）
  ILoggingService _getLogger() {
    _logger ??= serviceLocator.get<ILoggingService>();
    return _logger!;
  }

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

    try {
      final logger = _getLogger();
      logger.info(
        'アクセス可能範囲計算: プラン=${plan.displayName}, '
        '過去${plan.pastPhotoAccessDays}日前まで, '
        '最古アクセス可能日=$accessibleDate (ローカルタイムゾーン)',
        context: 'PhotoAccessControlService.getAccessibleDateForPlan',
      );
    } catch (e) {
      // LoggingServiceが初期化されていない場合は無視
    }

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

    try {
      final logger = _getLogger();
      logger.info(
        '写真アクセス判定: '
        'プラン=${plan.displayName}, '
        '撮影日=$photoDateOnly (ローカル), '
        '最古アクセス可能日=$accessibleDate (ローカル), '
        '結果=$isAccessible',
        context: 'PhotoAccessControlService.isPhotoAccessible',
      );
    } catch (e) {
      // LoggingServiceが初期化されていない場合は無視
    }

    return isAccessible;
  }

  /// 現在のプランでアクセス可能な日付範囲の説明を取得
  @override
  String getAccessRangeDescription(Plan plan) {
    final days = plan.pastPhotoAccessDays;

    if (days == 1) {
      return 'Premiumで過去1年分';
    } else if (days == 7) {
      return '1週間前までの写真';
    } else if (days == 30) {
      return '1ヶ月前までの写真';
    } else if (days == 365) {
      return '1年前までの写真';
    } else {
      return '$days日前までの写真';
    }
  }
}
