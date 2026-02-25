import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/errors/app_exceptions.dart';
import '../core/errors/error_handler.dart';
import '../core/result/result.dart';
import '../core/result/result_extensions.dart';
import '../models/diary_length.dart';
import '../models/photo_type_filter.dart';
import '../models/subscription_info_v2.dart';
import '../models/plans/plan.dart';
import '../models/plans/plan_factory.dart';
import 'interfaces/settings_service_interface.dart';
import 'interfaces/subscription_service_interface.dart';
import '../core/service_locator.dart';

/// 日記生成方式の列挙型
enum DiaryGenerationMode {
  /// 画像直接解析方式（画像 → Gemini Vision API）
  vision,
}

class SettingsService implements ISettingsService {
  SharedPreferences? _preferences;

  // Phase 1.8.1.1: SubscriptionService依存注入
  ISubscriptionService? _subscriptionService;

  static const String _localeKey = 'app_locale';
  static const String _photoTypeFilterKey = 'photo_type_filter';
  final ValueNotifier<Locale?> _localeNotifier = ValueNotifier<Locale?>(null);
  final ValueNotifier<PhotoTypeFilter> _photoTypeFilterNotifier =
      ValueNotifier<PhotoTypeFilter>(PhotoTypeFilter.all);

  /// DI用の公開コンストラクタ
  SettingsService();

  /// DI用の非同期初期化
  Future<void> initialize() async {
    _preferences ??= await SharedPreferences.getInstance();
    _localeNotifier.value = _loadStoredLocale();
    _photoTypeFilterNotifier.value = _loadStoredPhotoTypeFilter();
    _subscriptionService ??= await serviceLocator
        .getAsync<ISubscriptionService>();
  }

  // 日記の長さ設定のキー
  static const String _diaryLengthKey = 'diary_length';

  // テーマ設定のキー
  static const String _themeKey = 'theme_mode';

  // 初回起動フラグのキー
  static const String _firstLaunchKey = 'is_first_launch';

  @override
  ValueNotifier<Locale?> get localeNotifier => _localeNotifier;

  @override
  ValueNotifier<PhotoTypeFilter> get photoTypeFilterNotifier =>
      _photoTypeFilterNotifier;

  // 写真タイプフィルター
  @override
  PhotoTypeFilter get photoTypeFilter {
    return ErrorHandler.safeExecuteSync(
          () {
            final index = _preferences?.getInt(_photoTypeFilterKey);
            if (index == null ||
                index < 0 ||
                index >= PhotoTypeFilter.values.length) {
              return PhotoTypeFilter.all;
            }
            return PhotoTypeFilter.values[index];
          },
          context: 'SettingsService.photoTypeFilter',
          fallbackValue: PhotoTypeFilter.all,
        ) ??
        PhotoTypeFilter.all;
  }

  @override
  Future<Result<void>> setPhotoTypeFilter(PhotoTypeFilter filter) async {
    return ResultHelper.tryExecuteAsync(() async {
      final prefs = _preferences;
      if (prefs == null) {
        throw const SettingsException('SettingsService is not initialized');
      }
      final saved = await prefs.setInt(_photoTypeFilterKey, filter.index);
      if (!saved) {
        throw const SettingsException('Failed to persist photo type filter');
      }
      _photoTypeFilterNotifier.value = filter;
    }, context: 'SettingsService.setPhotoTypeFilter');
  }

  // 日記の長さ
  @override
  DiaryLength get diaryLength {
    return ErrorHandler.safeExecuteSync(
          () {
            final index = _preferences?.getInt(_diaryLengthKey);
            if (index == null ||
                index < 0 ||
                index >= DiaryLength.values.length) {
              return DiaryLength.standard;
            }
            return DiaryLength.values[index];
          },
          context: 'SettingsService.diaryLength',
          fallbackValue: DiaryLength.standard,
        ) ??
        DiaryLength.standard;
  }

  @override
  Future<Result<void>> setDiaryLength(DiaryLength length) async {
    return ResultHelper.tryExecuteAsync(() async {
      final prefs = _preferences;
      if (prefs == null) {
        throw const SettingsException('SettingsService is not initialized');
      }
      await prefs.setInt(_diaryLengthKey, length.index);
    }, context: 'SettingsService.setDiaryLength');
  }

  // テーマモード
  @override
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

  @override
  Future<Result<void>> setThemeMode(ThemeMode themeMode) async {
    return ResultHelper.tryExecuteAsync(() async {
      final prefs = _preferences;
      if (prefs == null) {
        throw const SettingsException('SettingsService is not initialized');
      }
      await prefs.setInt(_themeKey, themeMode.index);
    }, context: 'SettingsService.setThemeMode');
  }

  @override
  Locale? get locale {
    return ErrorHandler.safeExecuteSync<Locale?>(() {
      final rawValue = _preferences?.getString(_localeKey);
      return _parseLocale(rawValue);
    }, context: 'SettingsService.locale');
  }

  @override
  Future<Result<void>> setLocale(Locale? locale) async {
    return ResultHelper.tryExecuteAsync(() async {
      final prefs = _preferences;
      if (prefs == null) {
        throw const SettingsException('SettingsService is not initialized');
      }
      if (locale == null) {
        await prefs.remove(_localeKey);
      } else {
        await prefs.setString(_localeKey, _serializeLocale(locale));
      }
      _localeNotifier.value = locale;
    }, context: 'SettingsService.setLocale');
  }

  // 初回起動判定
  @override
  bool get isFirstLaunch {
    return ErrorHandler.safeExecuteSync(
          () {
            return _preferences?.getBool(_firstLaunchKey) ?? true;
          },
          context: 'SettingsService.isFirstLaunch',
          fallbackValue: true,
        ) ??
        true;
  }

  // 初回起動完了を記録
  @override
  Future<Result<void>> setFirstLaunchCompleted() async {
    return ResultHelper.tryExecuteAsync(() async {
      final prefs = _preferences;
      if (prefs == null) {
        throw const SettingsException('SettingsService is not initialized');
      }
      await prefs.setBool(_firstLaunchKey, false);
    }, context: 'SettingsService.setFirstLaunchCompleted');
  }

  // 日記生成モード（常にvision固定）
  static const DiaryGenerationMode generationMode = DiaryGenerationMode.vision;

  Locale? _loadStoredLocale() => locale;

  PhotoTypeFilter _loadStoredPhotoTypeFilter() => photoTypeFilter;

  static Locale? _parseLocale(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final separator = value.contains('-') ? '-' : '_';
    final segments = value.split(separator);
    if (segments.isEmpty) {
      return null;
    }
    if (segments.length == 1) {
      return Locale(segments.first);
    }
    final languageCode = segments[0];
    final countryCode = segments[1];
    if (countryCode.isEmpty) {
      return Locale(languageCode);
    }
    return Locale(languageCode, countryCode);
  }

  static String _serializeLocale(Locale locale) {
    if (locale.countryCode == null || locale.countryCode!.isEmpty) {
      return locale.languageCode;
    }
    return '${locale.languageCode}_${locale.countryCode}';
  }

  // ========================================
  // Phase 1.8.1: サブスクリプション状態管理API
  // ========================================

  /// 包括的なサブスクリプション情報を取得（メイン実装 - V2版）
  /// 設定画面表示で使用する統合されたサブスクリプション情報を返します
  @override
  Future<Result<SubscriptionInfoV2>> getSubscriptionInfoV2() async {
    return ResultHelper.tryExecuteAsync(() async {
      if (_subscriptionService == null) {
        throw StateError('SubscriptionService is not initialized');
      }

      // SubscriptionServiceから現在の状態を取得
      final statusResult = await _subscriptionService!.getCurrentStatus();
      if (statusResult.isFailure) {
        throw statusResult.error;
      }

      // SubscriptionInfoV2に変換して返す
      return SubscriptionInfoV2.fromStatus(statusResult.value);
    }, context: 'SettingsService.getSubscriptionInfoV2');
  }

  /// 現在のプラン情報を取得（メイン実装 - Planクラス版）
  @override
  Future<Result<Plan>> getCurrentPlanClass() async {
    return ResultHelper.tryExecuteAsync(() async {
      if (_subscriptionService == null) {
        throw StateError('SubscriptionService is not initialized');
      }

      final planResult = await _subscriptionService!.getCurrentPlanClass();
      if (planResult.isFailure) {
        throw planResult.error;
      }

      return planResult.value;
    }, context: 'SettingsService.getCurrentPlanClass');
  }

  /// プラン期限情報を取得（メイン実装 - V2版）
  @override
  Future<Result<PlanPeriodInfoV2>> getPlanPeriodInfoV2() async {
    return ResultHelper.tryExecuteAsync(() async {
      if (_subscriptionService == null) {
        throw StateError('SubscriptionService is not initialized');
      }

      final statusResult = await _subscriptionService!.getCurrentStatus();
      if (statusResult.isFailure) {
        throw statusResult.error;
      }

      final planResult = await _subscriptionService!.getCurrentPlanClass();
      if (planResult.isFailure) {
        throw planResult.error;
      }

      return PlanPeriodInfoV2.fromStatusAndPlan(
        statusResult.value,
        planResult.value,
      );
    }, context: 'SettingsService.getPlanPeriodInfoV2');
  }

  /// Phase 1.8.1.3: 自動更新状態情報を取得
  @override
  Future<Result<AutoRenewalInfoV2>> getAutoRenewalInfo() async {
    return ResultHelper.tryExecuteAsync(() async {
      if (_subscriptionService == null) {
        throw StateError('SubscriptionService is not initialized');
      }

      final statusResult = await _subscriptionService!.getCurrentStatus();
      if (statusResult.isFailure) {
        throw statusResult.error;
      }

      return AutoRenewalInfoV2.fromStatus(statusResult.value);
    }, context: 'SettingsService.getAutoRenewalInfo');
  }

  /// 使用統計情報を取得（メイン実装 - Planクラス版）
  @override
  Future<Result<UsageStatisticsV2>> getUsageStatisticsWithPlanClass() async {
    return ResultHelper.tryExecuteAsync(() async {
      if (_subscriptionService == null) {
        throw StateError('SubscriptionService is not initialized');
      }

      final statusResult = await _subscriptionService!.getCurrentStatus();
      if (statusResult.isFailure) {
        throw statusResult.error;
      }

      final planResult = await _subscriptionService!.getCurrentPlanClass();
      if (planResult.isFailure) {
        throw planResult.error;
      }

      return UsageStatisticsV2.fromStatusAndPlan(
        statusResult.value,
        planResult.value,
      );
    }, context: 'SettingsService.getUsageStatisticsWithPlanClass');
  }

  /// Phase 1.8.1.4: 残り使用可能回数を取得（既存のSubscriptionServiceメソッドのラッパー）
  @override
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
  @override
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
  @override
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

  /// プラン比較情報を取得（メイン実装 - V2版）
  @override
  Future<Result<List<Plan>>> getAvailablePlansV2() async {
    return ResultHelper.tryExecuteAsync(() async {
      if (_subscriptionService == null) {
        throw StateError('SubscriptionService is not initialized');
      }

      // 新しいPlanFactoryを使用
      final plans = PlanFactory.getAllPlans();
      return plans;
    }, context: 'SettingsService.getAvailablePlansV2');
  }
}
