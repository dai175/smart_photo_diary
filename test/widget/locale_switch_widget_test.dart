import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/main.dart';
import 'package:smart_photo_diary/services/logging_service.dart';
import 'package:smart_photo_diary/services/settings_service.dart';

class _MockSettingsService extends Mock implements SettingsService {}

class _MockLoggingService extends Mock implements LoggingService {}

void main() {
  setUp(() {
    serviceLocator.clear();
  });

  tearDown(() {
    serviceLocator.clear();
  });

  group('MyAppのロケール切替', () {
    testWidgets('SettingsServiceの通知でオンボーディング文言が切り替わる', (tester) async {
      final localeNotifier = ValueNotifier<Locale?>(const Locale('ja'));
      final settingsService = _MockSettingsService();
      final loggingService = _MockLoggingService();

      when(() => settingsService.localeNotifier).thenReturn(localeNotifier);
      when(() => settingsService.themeMode).thenReturn(ThemeMode.system);
      when(() => settingsService.isFirstLaunch).thenReturn(true);
      when(
        () => settingsService.locale,
      ).thenAnswer((invocation) => localeNotifier.value);

      serviceLocator.registerSingleton<LoggingService>(loggingService);
      serviceLocator.registerSingleton<SettingsService>(settingsService);

      addTearDown(localeNotifier.dispose);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('Smart Photo Diary\nへようこそ'), findsOneWidget);

      localeNotifier.value = const Locale('en');
      await tester.pumpAndSettle();

      expect(find.text('Welcome to\nSmart Photo Diary'), findsOneWidget);
    });
  });
}
