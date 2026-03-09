import 'dart:ui';

import '../core/service_registration.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/interfaces/settings_service_interface.dart';

class LocalizationUtils {
  const LocalizationUtils._();

  static AppLocalizations resolveFor(Locale? locale) {
    final supported = AppLocalizations.supportedLocales;

    if (locale != null) {
      for (final candidate in supported) {
        if (candidate.languageCode == locale.languageCode &&
            candidate.countryCode == locale.countryCode) {
          return lookupAppLocalizations(candidate);
        }
      }

      for (final candidate in supported) {
        if (candidate.languageCode == locale.languageCode) {
          return lookupAppLocalizations(candidate);
        }
      }
    }

    return lookupAppLocalizations(supported.first);
  }

  static String appTitleFor(Locale? locale) => resolveFor(locale).appTitle;

  /// ISettingsService から現在のロケールを解決する。
  /// 取得できない場合はプラットフォームのロケールにフォールバックする。
  static Future<Locale> resolveCurrentLocale() async {
    try {
      final settingsService =
          await ServiceRegistration.getAsync<ISettingsService>();
      return settingsService.locale ?? PlatformDispatcher.instance.locale;
    } catch (_) {
      return PlatformDispatcher.instance.locale;
    }
  }
}
