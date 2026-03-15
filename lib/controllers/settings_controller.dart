import 'dart:ui';

import 'package:package_info_plus/package_info_plus.dart';

import '../core/service_registration.dart';
import '../models/subscription_info_v2.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../services/interfaces/settings_service_interface.dart';
import 'base_error_controller.dart';

/// SettingsScreen の状態管理・ビジネスロジック
class SettingsController extends BaseErrorController {
  late final ILoggingService _logger;
  ISettingsService? _settingsService;

  /// ログサービス（UIウィジェットに渡す用）
  ILoggingService get logger => _logger;

  int _requestVersion = 0;
  PackageInfo? _packageInfo;
  SubscriptionInfoV2? _subscriptionInfo;
  Locale? _selectedLocale;

  /// パッケージ情報
  PackageInfo? get packageInfo => _packageInfo;

  /// サブスクリプション情報
  SubscriptionInfoV2? get subscriptionInfo => _subscriptionInfo;

  /// 選択中のロケール
  Locale? get selectedLocale => _selectedLocale;

  /// 設定サービス（UI側で直接アクセスが必要な場合用）
  ISettingsService? get settingsService => _settingsService;

  /// 設定データの読み込みが完了しているか
  bool get hasSettingsLoaded => _settingsService != null;

  SettingsController({required ILoggingService logger}) {
    _logger = logger;
  }

  /// 設定データを読み込む
  Future<void> loadSettings() async {
    final localVersion = ++_requestVersion;
    setLoading(true);

    try {
      // settingsService と packageInfo を並列取得
      final settingsFuture = ServiceRegistration.getAsync<ISettingsService>();
      final packageFuture = PackageInfo.fromPlatform()
          .then<PackageInfo?>((v) => v)
          .catchError((_) => null);
      final (settings, packageInfo) = await (
        settingsFuture,
        packageFuture,
      ).wait;
      if (localVersion != _requestVersion) return;

      _settingsService = settings;
      _packageInfo = packageInfo;
      _selectedLocale = _settingsService!.locale;

      // subscriptionInfo を取得
      final subscriptionResult = await _settingsService!
          .getSubscriptionInfoV2();
      if (localVersion != _requestVersion) return;

      if (subscriptionResult.isSuccess) {
        _subscriptionInfo = subscriptionResult.value;
      } else {
        _logger.error(
          'Failed to fetch subscription info',
          error: subscriptionResult.error,
          context: 'SettingsController',
        );
      }
    } catch (e) {
      if (localVersion != _requestVersion) return;
      _logger.error(
        'Failed to load settings',
        error: e,
        context: 'SettingsController',
      );
    }

    setLoading(false);
  }

  /// ロケール変更
  void onLocaleChanged(Locale? locale) {
    _selectedLocale = locale;
    notifyListeners();
  }

  /// 外部からUI再構築をトリガーするための公開メソッド
  void notifyStateChanged() {
    notifyListeners();
  }
}
