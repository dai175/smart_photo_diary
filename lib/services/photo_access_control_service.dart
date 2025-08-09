import 'package:flutter/foundation.dart';
import '../models/plans/plan.dart';
import 'interfaces/photo_access_control_service_interface.dart';
import 'logging_service.dart';

/// 写真アクセス制御サービスの実装
///
/// プランに基づいた写真へのアクセス可否を判定する
class PhotoAccessControlService implements PhotoAccessControlServiceInterface {
  // シングルトンパターン
  static PhotoAccessControlService? _instance;

  PhotoAccessControlService._();

  static PhotoAccessControlService getInstance() {
    _instance ??= PhotoAccessControlService._();
    return _instance!;
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

    if (kDebugMode) {
      _logAsync(
        'アクセス可能範囲計算',
        context: 'PhotoAccessControlService.getAccessibleDateForPlan',
        data: {
          'planName': plan.displayName,
          'pastDays': plan.pastPhotoAccessDays,
          'accessibleDate': accessibleDate.toIso8601String(),
        },
      );
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

    if (kDebugMode) {
      _logAsync(
        '写真アクセス判定',
        context: 'PhotoAccessControlService.isPhotoAccessible',
        data: {
          'planName': plan.displayName,
          'photoDate': photoDateOnly.toIso8601String(),
          'accessibleDate': accessibleDate.toIso8601String(),
          'result': isAccessible,
        },
      );
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

  /// 非同期でログ出力を行う（テスト環境での初期化問題を回避）
  void _logAsync(
    String message, {
    required String context,
    Map<String, dynamic>? data,
  }) {
    // 非同期でログを出力し、エラーが発生してもメイン処理に影響させない
    Future.microtask(() async {
      try {
        final loggingService = await LoggingService.getInstance();
        loggingService.debug(message, context: context, data: data);
      } catch (e) {
        // ログ出力に失敗した場合は debugPrint にフォールバック
        debugPrint('[$context] $message - $data');
      }
    });
  }
}
