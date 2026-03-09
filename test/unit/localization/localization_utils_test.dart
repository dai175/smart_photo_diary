import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/localization/localization_utils.dart';
import 'package:smart_photo_diary/services/interfaces/settings_service_interface.dart';

class MockSettingsService extends Mock implements ISettingsService {}

void main() {
  late MockSettingsService mockSettings;

  setUp(() {
    ServiceLocator().clear();
    mockSettings = MockSettingsService();
    ServiceLocator().registerSingleton<ISettingsService>(mockSettings);
  });

  tearDown(() {
    ServiceLocator().clear();
  });

  group('resolveCurrentLocale', () {
    test('settingsService のロケールがあればそれを返す', () async {
      when(() => mockSettings.locale).thenReturn(const Locale('ja'));

      final locale = await LocalizationUtils.resolveCurrentLocale();

      expect(locale, const Locale('ja'));
    });

    test('settingsService のロケールが null ならプラットフォームロケールを返す', () async {
      when(() => mockSettings.locale).thenReturn(null);

      final locale = await LocalizationUtils.resolveCurrentLocale();

      expect(locale, PlatformDispatcher.instance.locale);
    });

    test('settingsService 取得失敗時はプラットフォームロケールを返す', () async {
      ServiceLocator().clear();

      final locale = await LocalizationUtils.resolveCurrentLocale();

      expect(locale, PlatformDispatcher.instance.locale);
    });
  });
}
