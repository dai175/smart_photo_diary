import 'package:flutter/material.dart';
import '../../core/result/result.dart';
import '../../models/subscription_info_v2.dart';
import '../../models/plans/plan.dart';

/// 設定サービスのインターフェース
///
/// アプリケーション設定（テーマ、ロケール、サブスクリプション情報等）を
/// 管理するための抽象インターフェース。
/// サブスクリプション関連メソッドは内部的にISubscriptionServiceに委譲する。
abstract class ISettingsService {
  /// ロケール変更通知用のValueNotifier
  ValueNotifier<Locale?> get localeNotifier;

  /// 現在のテーマモード
  ThemeMode get themeMode;

  /// テーマモードを設定
  ///
  /// Returns:
  /// - Success: void（設定完了）
  /// - Failure: [ServiceException] SharedPreferences書き込み失敗時
  Future<Result<void>> setThemeMode(ThemeMode themeMode);

  /// 現在のロケール
  Locale? get locale;

  /// ロケールを設定
  ///
  /// [locale] null を指定するとシステムデフォルトに戻す
  ///
  /// Returns:
  /// - Success: void（設定完了）
  /// - Failure: [ServiceException] SharedPreferences書き込み失敗時
  Future<Result<void>> setLocale(Locale? locale);

  /// 初回起動かどうか
  bool get isFirstLaunch;

  /// 初回起動完了を記録
  ///
  /// Returns:
  /// - Success: void（記録完了）
  /// - Failure: [ServiceException] SharedPreferences書き込み失敗時
  Future<Result<void>> setFirstLaunchCompleted();

  /// 包括的なサブスクリプション情報を取得（V2版）
  ///
  /// Returns:
  /// - Success: [SubscriptionInfoV2]（プラン名、ステータス、使用量等）
  /// - Failure: [ServiceException] SubscriptionServiceが未初期化の場合
  Future<Result<SubscriptionInfoV2>> getSubscriptionInfoV2();

  /// 現在のプラン情報を取得（Planクラス版）
  ///
  /// Returns:
  /// - Success: 現在の [Plan] オブジェクト
  /// - Failure: [ServiceException] SubscriptionServiceが未初期化の場合
  Future<Result<Plan>> getCurrentPlanClass();

  /// プラン期限情報を取得（V2版）
  ///
  /// Returns:
  /// - Success: [PlanPeriodInfoV2]（開始日、終了日、残り日数等）
  /// - Failure: [ServiceException] SubscriptionServiceが未初期化の場合
  Future<Result<PlanPeriodInfoV2>> getPlanPeriodInfoV2();

  /// 自動更新状態情報を取得
  ///
  /// Returns:
  /// - Success: [AutoRenewalInfoV2]（自動更新の有無、次回更新日等）
  /// - Failure: [ServiceException] SubscriptionServiceが未初期化の場合
  Future<Result<AutoRenewalInfoV2>> getAutoRenewalInfo();

  /// 使用統計情報を取得（Planクラス版）
  ///
  /// Returns:
  /// - Success: [UsageStatisticsV2]（AI使用量、残回数等）
  /// - Failure: [ServiceException] SubscriptionServiceが未初期化の場合
  Future<Result<UsageStatisticsV2>> getUsageStatisticsWithPlanClass();

  /// 残り使用可能回数を取得
  ///
  /// Returns:
  /// - Success: 今月の残りAI生成可能回数
  /// - Failure: [ServiceException] SubscriptionServiceが未初期化の場合
  Future<Result<int>> getRemainingGenerations();

  /// 次回リセット日を取得
  ///
  /// Returns:
  /// - Success: 次の月次リセット日時
  /// - Failure: [ServiceException] SubscriptionServiceが未初期化の場合
  Future<Result<DateTime>> getNextResetDate();

  /// プラン変更可能かどうかを確認
  ///
  /// Returns:
  /// - Success: 変更可能な場合 true
  /// - Failure: [ServiceException] SubscriptionServiceが未初期化の場合
  Future<Result<bool>> canChangePlan();

  /// プラン比較情報を取得（V2版）
  ///
  /// Returns:
  /// - Success: 利用可能な [Plan] リスト
  /// - Failure: [ServiceException] SubscriptionServiceが未初期化の場合
  Future<Result<List<Plan>>> getAvailablePlansV2();
}
