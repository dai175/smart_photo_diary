import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/main.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/settings_service_interface.dart';

class _MockSettingsService extends Mock implements ISettingsService {}

class _MockLoggingService extends Mock implements ILoggingService {}

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

      serviceLocator.registerSingleton<ILoggingService>(loggingService);
      serviceLocator.registerSingleton<ISettingsService>(settingsService);

      addTearDown(localeNotifier.dispose);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('あなたの写真には、\nもう物語がある。'), findsOneWidget);

      localeNotifier.value = const Locale('en');
      await tester.pumpAndSettle();

      expect(find.text('Your photos\nalready hold the story.'), findsOneWidget);
    });
  });
}
