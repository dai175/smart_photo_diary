import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/widgets/settings/appearance_settings_section.dart';

import '../../../integration/mocks/mock_services.dart';
import '../../../test_helpers/widget_test_helpers.dart';

void main() {
  late MockSettingsService mockSettings;
  late MockILoggingService mockLogger;
  var stateChangedCount = 0;
  Locale? lastLocale;

  setUpAll(() {
    registerMockFallbacks();
    registerFallbackValue(ThemeMode.system);
  });

  setUp(() {
    stateChangedCount = 0;
    lastLocale = const Locale('en');
    mockSettings = MockSettingsService();
    mockLogger = TestServiceSetup.getLoggingService();

    when(() => mockSettings.themeMode).thenReturn(ThemeMode.system);
    when(() => mockSettings.locale).thenReturn(null);
    when(
      () => mockSettings.setThemeMode(any()),
    ).thenAnswer((_) async => const Success(null));
    when(
      () => mockSettings.setLocale(any()),
    ).thenAnswer((_) async => const Success(null));
  });

  tearDown(() {
    TestServiceSetup.clearAllMocks();
  });

  Widget buildWidget({Locale? selectedLocale}) {
    return WidgetTestHelpers.wrapWithLocalizedApp(
      Scaffold(
        body: AppearanceSettingsSection(
          settingsService: mockSettings,
          logger: mockLogger,
          selectedLocale: selectedLocale,
          onThemeChanged: (_) {},
          onLocaleChanged: (locale) => lastLocale = locale,
          onStateChanged: () => stateChangedCount++,
        ),
      ),
    );
  }

  group('AppearanceSettingsSection', () {
    group('theme row', () {
      testWidgets('displays theme title and current system value', (
        tester,
      ) async {
        await tester.pumpWidget(buildWidget());
        await tester.pump();

        expect(find.text('Theme'), findsOneWidget);
        expect(find.text('Follow system'), findsWidgets);
      });

      testWidgets('shows Light label when themeMode is light', (tester) async {
        when(() => mockSettings.themeMode).thenReturn(ThemeMode.light);

        await tester.pumpWidget(buildWidget());
        await tester.pump();

        expect(find.text('Light'), findsOneWidget);
      });

      testWidgets('shows Dark label when themeMode is dark', (tester) async {
        when(() => mockSettings.themeMode).thenReturn(ThemeMode.dark);

        await tester.pumpWidget(buildWidget());
        await tester.pump();

        expect(find.text('Dark'), findsOneWidget);
      });

      testWidgets('tap opens theme dialog with all options', (tester) async {
        await tester.pumpWidget(buildWidget());
        await tester.pump();

        await tester.tap(find.text('Theme'));
        await tester.pumpAndSettle();

        expect(find.text('Choose theme'), findsOneWidget);
        expect(find.text('Follow system'), findsWidgets);
        expect(find.text('Light'), findsOneWidget);
        expect(find.text('Dark'), findsOneWidget);
      });

      testWidgets('selecting theme calls setThemeMode and onStateChanged', (
        tester,
      ) async {
        await tester.pumpWidget(buildWidget());
        await tester.pump();

        await tester.tap(find.text('Theme'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Light'));
        await tester.pumpAndSettle();

        verify(() => mockSettings.setThemeMode(ThemeMode.light)).called(1);
        expect(stateChangedCount, 1);
      });
    });

    group('language row', () {
      testWidgets('displays language title and system default', (tester) async {
        await tester.pumpWidget(buildWidget(selectedLocale: null));
        await tester.pump();

        expect(find.text('Language'), findsOneWidget);
        expect(find.text('Follow system'), findsWidgets);
      });

      testWidgets('shows English when selectedLocale is en_US', (tester) async {
        await tester.pumpWidget(
          buildWidget(selectedLocale: const Locale('en', 'US')),
        );
        await tester.pump();

        expect(find.text('English'), findsOneWidget);
      });

      testWidgets('shows Japanese when selectedLocale is ja_JP', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildWidget(selectedLocale: const Locale('ja', 'JP')),
        );
        await tester.pump();

        expect(find.text('日本語'), findsOneWidget);
      });

      testWidgets('tap opens language dialog with all options', (tester) async {
        await tester.pumpWidget(buildWidget());
        await tester.pump();

        await tester.tap(find.text('Language'));
        await tester.pumpAndSettle();

        expect(find.text('Choose language'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);
        expect(find.text('日本語'), findsOneWidget);
      });

      testWidgets('selecting language calls setLocale and onLocaleChanged', (
        tester,
      ) async {
        await tester.pumpWidget(buildWidget(selectedLocale: null));
        await tester.pump();

        await tester.tap(find.text('Language'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('English'));
        await tester.pumpAndSettle();

        verify(
          () => mockSettings.setLocale(const Locale('en', 'US')),
        ).called(1);
        expect(lastLocale, const Locale('en', 'US'));
      });
    });
  });
}
