import '../../models/plans/plan.dart';

/// 写真アクセス制御サービスのインターフェース
///
/// プランに基づいた写真へのアクセス可否を判定する責任を持つ
abstract class IPhotoAccessControlService {
  /// 指定されたプランでアクセス可能な最古の日付を取得
  ///
  /// [plan]: 対象のプラン
  /// 戻り値: アクセス可能な最古の日付（日付のみ、時刻は00:00:00）
  DateTime getAccessibleDateForPlan(Plan plan);

  /// 指定された写真の撮影日時がプランでアクセス可能かどうかを判定
  ///
  /// [photoDate]: 写真の撮影日時
  /// [plan]: 対象のプラン
  /// 戻り値: アクセス可能な場合はtrue
  bool isPhotoAccessible(DateTime photoDate, Plan plan);

  /// 現在のプランでアクセス可能な日付範囲の説明を取得
  ///
  /// [plan]: 対象のプラン
  /// [formatter]: 日数を受け取りローカライズ済み説明文を返すコールバック
  /// 戻り値: ユーザー向けの説明文
  String getAccessRangeDescription(
    Plan plan, {
    required String Function(int days) formatter,
  });
}
