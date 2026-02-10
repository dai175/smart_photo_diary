import 'package:flutter/material.dart';
import '../../core/result/result.dart';
import '../../models/subscription_info_v2.dart';
import '../../models/plans/plan.dart';

/// 設定サービスのインターフェース
///
/// アプリケーション設定（テーマ、ロケール、サブスクリプション情報等）を
/// 管理するための抽象インターフェース。
abstract class ISettingsService {
  /// ロケール変更通知用のValueNotifier
  ValueNotifier<Locale?> get localeNotifier;

  /// 現在のテーマモード
  ThemeMode get themeMode;

  /// テーマモードを設定
  Future<Result<void>> setThemeMode(ThemeMode themeMode);

  /// 現在のロケール
  Locale? get locale;

  /// ロケールを設定
  Future<Result<void>> setLocale(Locale? locale);

  /// 初回起動かどうか
  bool get isFirstLaunch;

  /// 初回起動完了を記録
  Future<Result<void>> setFirstLaunchCompleted();

  /// 包括的なサブスクリプション情報を取得（V2版）
  Future<Result<SubscriptionInfoV2>> getSubscriptionInfoV2();

  /// 現在のプラン情報を取得（Planクラス版）
  Future<Result<Plan>> getCurrentPlanClass();

  /// プラン期限情報を取得（V2版）
  Future<Result<PlanPeriodInfoV2>> getPlanPeriodInfoV2();

  /// 自動更新状態情報を取得
  Future<Result<AutoRenewalInfoV2>> getAutoRenewalInfo();

  /// 使用統計情報を取得（Planクラス版）
  Future<Result<UsageStatisticsV2>> getUsageStatisticsWithPlanClass();

  /// 残り使用可能回数を取得
  Future<Result<int>> getRemainingGenerations();

  /// 次回リセット日を取得
  Future<Result<DateTime>> getNextResetDate();

  /// プラン変更可能かどうかを確認
  Future<Result<bool>> canChangePlan();

  /// プラン比較情報を取得（V2版）
  Future<Result<List<Plan>>> getAvailablePlansV2();
}
