import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/models/photo_type_filter.dart';
import 'package:smart_photo_diary/widgets/settings/photo_filter_settings_section.dart';

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

    when(() => mockSettings.photoTypeFilter).thenReturn(PhotoTypeFilter.all);
    when(
      () => mockSettings.setPhotoTypeFilter(any()),
    ).thenAnswer((_) async => const Success(null));
  });

  tearDown(() {
    TestServiceSetup.clearAllMocks();
  });

  Widget buildWidget() {
    return WidgetTestHelpers.wrapWithLocalizedApp(
      Scaffold(
        body: PhotoFilterSettingsSection(
          settingsService: mockSettings,
          logger: mockLogger,
          onStateChanged: () => stateChangedCount++,
        ),
      ),
    );
  }

  testWidgets('displays photo type filter title and current value', (
    tester,
  ) async {
    await tester.pumpWidget(buildWidget());
    await tester.pump();

    expect(find.text('Image type'), findsOneWidget);
    expect(find.text('All images'), findsOneWidget);
  });

  testWidgets('displays Photos only label when set to photosOnly', (
    tester,
  ) async {
    when(
      () => mockSettings.photoTypeFilter,
    ).thenReturn(PhotoTypeFilter.photosOnly);

    await tester.pumpWidget(buildWidget());
    await tester.pump();

    expect(find.text('Photos only'), findsOneWidget);
  });

  testWidgets('tap opens dialog and selecting calls setPhotoTypeFilter', (
    tester,
  ) async {
    await tester.pumpWidget(buildWidget());
    await tester.pump();

    // Tap the row to open dialog
    await tester.tap(find.text('Image type'));
    await tester.pumpAndSettle();

    // Dialog should show options
    expect(find.text('Select image type'), findsOneWidget);
    expect(find.text('All images'), findsWidgets);
    expect(find.text('Photos only'), findsOneWidget);

    // Select Photos only
    await tester.tap(find.text('Photos only'));
    await tester.pumpAndSettle();

    verify(
      () => mockSettings.setPhotoTypeFilter(PhotoTypeFilter.photosOnly),
    ).called(1);
    expect(stateChangedCount, 1);
  });

  testWidgets('does not call setter when same value selected', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pump();

    // Tap the row to open dialog
    await tester.tap(find.text('Image type'));
    await tester.pumpAndSettle();

    // Select the currently active option (All images)
    await tester.tap(find.text('All images').last);
    await tester.pumpAndSettle();

    verifyNever(() => mockSettings.setPhotoTypeFilter(any()));
    expect(stateChangedCount, 0);
  });
}
