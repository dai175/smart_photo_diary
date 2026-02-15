import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/models/diary_length.dart';
import 'package:smart_photo_diary/widgets/settings/diary_settings_section.dart';

import '../../../integration/mocks/mock_services.dart';
import '../../../test_helpers/widget_test_helpers.dart';

void main() {
  late MockSettingsService mockSettings;
  late MockILoggingService mockLogger;
  var stateChangedCount = 0;

  setUpAll(() {
    registerMockFallbacks();
  });

  setUp(() {
    stateChangedCount = 0;
    mockSettings = MockSettingsService();
    mockLogger = TestServiceSetup.getLoggingService();

    when(() => mockSettings.diaryLength).thenReturn(DiaryLength.standard);
    when(
      () => mockSettings.setDiaryLength(any()),
    ).thenAnswer((_) async => const Success(null));
  });

  tearDown(() {
    TestServiceSetup.clearAllMocks();
  });

  Widget buildWidget() {
    return WidgetTestHelpers.wrapWithLocalizedApp(
      Scaffold(
        body: DiarySettingsSection(
          settingsService: mockSettings,
          logger: mockLogger,
          onStateChanged: () => stateChangedCount++,
        ),
      ),
    );
  }

  testWidgets('displays diary length title and current value', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pump();

    expect(find.text('Diary length'), findsOneWidget);
    expect(find.text('Standard'), findsOneWidget);
  });

  testWidgets('displays Short label when set to short', (tester) async {
    when(() => mockSettings.diaryLength).thenReturn(DiaryLength.short);

    await tester.pumpWidget(buildWidget());
    await tester.pump();

    expect(find.text('Short (for X posts)'), findsOneWidget);
  });

  testWidgets('tap opens dialog and selecting calls setDiaryLength', (
    tester,
  ) async {
    await tester.pumpWidget(buildWidget());
    await tester.pump();

    // Tap the row to open dialog
    await tester.tap(find.text('Diary length'));
    await tester.pumpAndSettle();

    // Dialog should show options
    expect(find.text('Default diary length'), findsOneWidget);
    expect(find.text('Short (for X posts)'), findsOneWidget);
    expect(find.text('Standard'), findsWidgets);

    // Select Short
    await tester.tap(find.text('Short (for X posts)'));
    await tester.pumpAndSettle();

    verify(() => mockSettings.setDiaryLength(DiaryLength.short)).called(1);
    expect(stateChangedCount, 1);
  });
}
