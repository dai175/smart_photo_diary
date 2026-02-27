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
import 'interfaces/settings_service_interface.dart';
import 'interfaces/subscription_service_interface.dart';
import '../core/service_locator.dart';
import 'settings_subscription_delegate.dart';

/// 日記生成方式の列挙型
enum DiaryGenerationMode {
  /// 画像直接解析方式（画像 → Gemini Vision API）
  vision,
}

class SettingsService implements ISettingsService {
  SharedPreferences? _preferences;

  ISubscriptionService? _subscriptionService;
  SettingsSubscriptionDelegate? _subscriptionDelegate;

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
    _subscriptionDelegate ??= SettingsSubscriptionDelegate(
      subscriptionService: _subscriptionService!,
    );
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

  // サブスクリプション状態管理API（SettingsSubscriptionDelegate に委譲）

  /// delegate が初期化済みであることを保証してから返す
  SettingsSubscriptionDelegate _requireDelegate() {
    final delegate = _subscriptionDelegate;
    if (delegate == null) {
      throw StateError('SubscriptionService is not initialized');
    }
    return delegate;
  }

  @override
  Future<Result<SubscriptionInfoV2>> getSubscriptionInfoV2() =>
      _delegateOr(() => _requireDelegate().getSubscriptionInfoV2());

  @override
  Future<Result<Plan>> getCurrentPlanClass() =>
      _delegateOr(() => _requireDelegate().getCurrentPlanClass());

  @override
  Future<Result<PlanPeriodInfoV2>> getPlanPeriodInfoV2() =>
      _delegateOr(() => _requireDelegate().getPlanPeriodInfoV2());

  @override
  Future<Result<AutoRenewalInfoV2>> getAutoRenewalInfo() =>
      _delegateOr(() => _requireDelegate().getAutoRenewalInfo());

  @override
  Future<Result<UsageStatisticsV2>> getUsageStatisticsWithPlanClass() =>
      _delegateOr(() => _requireDelegate().getUsageStatisticsWithPlanClass());

  @override
  Future<Result<int>> getRemainingGenerations() =>
      _delegateOr(() => _requireDelegate().getRemainingGenerations());

  @override
  Future<Result<DateTime>> getNextResetDate() =>
      _delegateOr(() => _requireDelegate().getNextResetDate());

  @override
  Future<Result<bool>> canChangePlan() =>
      _delegateOr(() => _requireDelegate().canChangePlan());

  @override
  Future<Result<List<Plan>>> getAvailablePlansV2() =>
      _delegateOr(() => _requireDelegate().getAvailablePlansV2());

  /// delegate 未初期化時は Failure を返すラッパー
  Future<Result<T>> _delegateOr<T>(Future<Result<T>> Function() fn) async {
    try {
      return await fn();
    } on StateError catch (e) {
      return Failure(ServiceException(e.message));
    }
  }
}
