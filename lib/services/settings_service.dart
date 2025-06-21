import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/errors/error_handler.dart';
import '../core/result/result.dart';
import '../core/result/result_extensions.dart';
import '../models/subscription_info.dart';
import '../models/subscription_plan.dart';
import 'interfaces/subscription_service_interface.dart';
import '../core/service_locator.dart';

/// 日記生成方式の列挙型
enum DiaryGenerationMode {
  /// 画像直接解析方式（画像 → Gemini Vision API）
  vision,
}

class SettingsService {
  static SettingsService? _instance;
  static SharedPreferences? _preferences;

  // Phase 1.8.1.1: SubscriptionService依存注入
  ISubscriptionService? _subscriptionService;

  SettingsService._();

  /// 非同期ファクトリメソッドでサービスインスタンスを取得
  static Future<SettingsService> getInstance() async {
    try {
      _instance ??= SettingsService._();
      _preferences ??= await SharedPreferences.getInstance();

      // Phase 1.8.1.1: SubscriptionService依存注入
      if (_instance!._subscriptionService == null) {
        _instance!._subscriptionService = await ServiceLocator()
            .getAsync<ISubscriptionService>();
      }

      return _instance!;
    } catch (error) {
      throw ErrorHandler.handleError(
        error,
        context: 'SettingsService.getInstance',
      );
    }
  }

  /// 同期的なサービスインスタンス取得（事前に初期化済みの場合のみ）
  static SettingsService get instance {
    if (_instance == null) {
      throw StateError(
        'SettingsService has not been initialized. Call getInstance() first.',
      );
    }
    return _instance!;
  }

  // テーマ設定のキー
  static const String _themeKey = 'theme_mode';

  // テーマモード
  ThemeMode get themeMode {
    return ErrorHandler.safeExecuteSync(
          () {
            final themeModeIndex = _preferences?.getInt(_themeKey) ?? 0;
            if (themeModeIndex < 0 ||
                themeModeIndex >= ThemeMode.values.length) {
              return ThemeMode.system;
            }
            return ThemeMode.values[themeModeIndex];
          },
          context: 'SettingsService.themeMode',
          fallbackValue: ThemeMode.system,
        ) ??
        ThemeMode.system;
  }

  Future<Result<void>> setThemeMode(ThemeMode themeMode) async {
    return ResultHelper.tryExecuteAsync(() async {
      await _preferences?.setInt(_themeKey, themeMode.index);
    }, context: 'SettingsService.setThemeMode');
  }

  // 日記生成モード（常にvision固定）
  static const DiaryGenerationMode generationMode = DiaryGenerationMode.vision;

  // ========================================
  // Phase 1.8.1: サブスクリプション状態管理API
  // ========================================

  /// Phase 1.8.1.1: 包括的なサブスクリプション情報を取得
  /// 設定画面表示で使用する統合されたサブスクリプション情報を返します
  Future<Result<SubscriptionInfo>> getSubscriptionInfo() async {
    return ResultHelper.tryExecuteAsync(() async {
      if (_subscriptionService == null) {
        throw StateError('SubscriptionService is not initialized');
      }

      // SubscriptionServiceから現在の状態を取得
      final statusResult = await _subscriptionService!.getCurrentStatus();
      if (statusResult.isFailure) {
        throw statusResult.error;
      }

      // SubscriptionInfoに変換して返す
      return SubscriptionInfo.fromStatus(statusResult.value);
    }, context: 'SettingsService.getSubscriptionInfo');
  }

  /// Phase 1.8.1.2: 現在のプラン情報を取得
  Future<Result<SubscriptionPlan>> getCurrentPlan() async {
    return ResultHelper.tryExecuteAsync(() async {
      if (_subscriptionService == null) {
        throw StateError('SubscriptionService is not initialized');
      }

      final planResult = await _subscriptionService!.getCurrentPlan();
      if (planResult.isFailure) {
        throw planResult.error;
      }

      return planResult.value;
    }, context: 'SettingsService.getCurrentPlan');
  }

  /// Phase 1.8.1.2: プラン期限情報を取得
  Future<Result<PlanPeriodInfo>> getPlanPeriodInfo() async {
    return ResultHelper.tryExecuteAsync(() async {
      if (_subscriptionService == null) {
        throw StateError('SubscriptionService is not initialized');
      }

      final statusResult = await _subscriptionService!.getCurrentStatus();
      if (statusResult.isFailure) {
        throw statusResult.error;
      }

      final planResult = await _subscriptionService!.getCurrentPlan();
      if (planResult.isFailure) {
        throw planResult.error;
      }

      return PlanPeriodInfo.fromStatus(statusResult.value, planResult.value);
    }, context: 'SettingsService.getPlanPeriodInfo');
  }

  /// Phase 1.8.1.3: 自動更新状態情報を取得
  Future<Result<AutoRenewalInfo>> getAutoRenewalInfo() async {
    return ResultHelper.tryExecuteAsync(() async {
      if (_subscriptionService == null) {
        throw StateError('SubscriptionService is not initialized');
      }

      final statusResult = await _subscriptionService!.getCurrentStatus();
      if (statusResult.isFailure) {
        throw statusResult.error;
      }

      return AutoRenewalInfo.fromStatus(statusResult.value);
    }, context: 'SettingsService.getAutoRenewalInfo');
  }

  /// Phase 1.8.1.4: 使用量統計情報を取得
  Future<Result<UsageStatistics>> getUsageStatistics() async {
    return ResultHelper.tryExecuteAsync(() async {
      if (_subscriptionService == null) {
        throw StateError('SubscriptionService is not initialized');
      }

      final statusResult = await _subscriptionService!.getCurrentStatus();
      if (statusResult.isFailure) {
        throw statusResult.error;
      }

      final planResult = await _subscriptionService!.getCurrentPlan();
      if (planResult.isFailure) {
        throw planResult.error;
      }

      return UsageStatistics.fromStatus(statusResult.value, planResult.value);
    }, context: 'SettingsService.getUsageStatistics');
  }

  /// Phase 1.8.1.4: 残り使用可能回数を取得（既存のSubscriptionServiceメソッドのラッパー）
  Future<Result<int>> getRemainingGenerations() async {
    return ResultHelper.tryExecuteAsync(() async {
      if (_subscriptionService == null) {
        throw StateError('SubscriptionService is not initialized');
      }

      final result = await _subscriptionService!.getRemainingGenerations();
      if (result.isFailure) {
        throw result.error;
      }

      return result.value;
    }, context: 'SettingsService.getRemainingGenerations');
  }

  /// Phase 1.8.1.4: 次回リセット日を取得（既存のSubscriptionServiceメソッドのラッパー）
  Future<Result<DateTime>> getNextResetDate() async {
    return ResultHelper.tryExecuteAsync(() async {
      if (_subscriptionService == null) {
        throw StateError('SubscriptionService is not initialized');
      }

      final result = await _subscriptionService!.getNextResetDate();
      if (result.isFailure) {
        throw result.error;
      }

      return result.value;
    }, context: 'SettingsService.getNextResetDate');
  }

  /// Phase 1.8.1.4: プラン変更可能かどうかを確認
  Future<Result<bool>> canChangePlan() async {
    return ResultHelper.tryExecuteAsync(() async {
      if (_subscriptionService == null) {
        throw StateError('SubscriptionService is not initialized');
      }

      // 現在の状態を確認して、プラン変更が可能かどうかを判定
      final statusResult = await _subscriptionService!.getCurrentStatus();
      if (statusResult.isFailure) {
        throw statusResult.error;
      }

      // サブスクリプションが初期化されていればプラン変更可能
      return _subscriptionService!.isInitialized;
    }, context: 'SettingsService.canChangePlan');
  }

  /// Phase 1.8.1.4: プラン比較情報を取得
  Future<Result<List<SubscriptionPlan>>> getAvailablePlans() async {
    return ResultHelper.tryExecuteAsync(() async {
      if (_subscriptionService == null) {
        throw StateError('SubscriptionService is not initialized');
      }

      final result = _subscriptionService!.getAvailablePlans();
      if (result.isFailure) {
        throw result.error;
      }

      return result.value;
    }, context: 'SettingsService.getAvailablePlans');
  }
}
