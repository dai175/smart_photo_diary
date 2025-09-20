import 'dart:ui';

import '../l10n/generated/app_localizations.dart';

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
}
