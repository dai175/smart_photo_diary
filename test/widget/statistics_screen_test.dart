import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/screens/statistics_screen.dart';
import 'package:smart_photo_diary/screens/statistics/statistics_cards.dart';
import 'package:smart_photo_diary/screens/statistics/statistics_calendar.dart';
import 'package:smart_photo_diary/services/interfaces/diary_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';

import '../integration/mocks/mock_services.dart';
import '../test_helpers/mock_platform_channels.dart';
import '../test_helpers/widget_test_helpers.dart';

void main() {
  late MockILoggingService mockLogger;
  late MockIDiaryService mockDiary;

  setUpAll(() {
    registerMockFallbacks();
    MockPlatformChannels.setupMocks();
  });

  setUp(() {
    serviceLocator.clear();
    TestServiceSetup.clearAllMocks();

    mockLogger = TestServiceSetup.getLoggingService();
    mockDiary = TestServiceSetup.getDiaryService();

    // ILoggingService is required synchronously by the StatisticsController constructor
    serviceLocator.registerSingleton<ILoggingService>(mockLogger);
  });

  tearDown(() {
    serviceLocator.clear();
    TestServiceSetup.clearAllMocks();
  });

  tearDownAll(() {
    MockPlatformChannels.clearMocks();
  });

  Widget buildScreen() {
    return WidgetTestHelpers.wrapWithLocalizedApp(const StatisticsScreen());
  }

  /// Pump enough frames for async init without pumpAndSettle (which times out
  /// due to ongoing animations in child widgets).
  Future<void> pumpFrames(WidgetTester tester) async {
    await tester.pump(); // first frame
    await tester.pump(const Duration(milliseconds: 500)); // async init
    await tester.pump(const Duration(milliseconds: 500)); // animations
  }

  group('StatisticsScreen', () {
    group('AppBar display', () {
      testWidgets('shows AppBar with Statistics title', (
        WidgetTester tester,
      ) async {
        // Register diary service synchronously so the screen loads fully
        serviceLocator.registerSingleton<IDiaryService>(mockDiary);

        await tester.pumpWidget(buildScreen());
        await pumpFrames(tester);

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Statistics'), findsOneWidget);
      });
    });

    group('Loading state', () {
      testWidgets(
        'shows CircularProgressIndicator when diary service has not resolved',
        (WidgetTester tester) async {
          // Use a Completer that we never complete, keeping the controller
          // in its loading state
          final diaryCompleter = Completer<IDiaryService>();
          serviceLocator.registerAsyncFactory<IDiaryService>(
            () => diaryCompleter.future,
          );

          await tester.pumpWidget(buildScreen());
          await tester.pump(); // first frame

          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        },
      );

      testWidgets('shows loading title text while loading', (
        WidgetTester tester,
      ) async {
        final diaryCompleter = Completer<IDiaryService>();
        serviceLocator.registerAsyncFactory<IDiaryService>(
          () => diaryCompleter.future,
        );

        await tester.pumpWidget(buildScreen());
        await tester.pump();

        expect(find.text('Loading statistics...'), findsOneWidget);
      });

      testWidgets('shows loading subtitle text while loading', (
        WidgetTester tester,
      ) async {
        final diaryCompleter = Completer<IDiaryService>();
        serviceLocator.registerAsyncFactory<IDiaryService>(
          () => diaryCompleter.future,
        );

        await tester.pumpWidget(buildScreen());
        await tester.pump();

        expect(find.text('Analyzing your diary activity'), findsOneWidget);
      });
    });

    group('Content display', () {
      testWidgets('shows StatisticsCards when data finishes loading', (
        WidgetTester tester,
      ) async {
        final diaryCompleter = Completer<IDiaryService>();
        serviceLocator.registerAsyncFactory<IDiaryService>(
          () => diaryCompleter.future,
        );

        await tester.pumpWidget(buildScreen());
        await tester.pump();

        // Verify loading state first
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Complete the async diary service
        diaryCompleter.complete(mockDiary);
        await pumpFrames(tester);

        // StatisticsCards should now be visible
        expect(find.byType(StatisticsCards), findsOneWidget);
      });

      testWidgets('shows StatisticsCalendar when data finishes loading', (
        WidgetTester tester,
      ) async {
        final diaryCompleter = Completer<IDiaryService>();
        serviceLocator.registerAsyncFactory<IDiaryService>(
          () => diaryCompleter.future,
        );

        await tester.pumpWidget(buildScreen());
        await tester.pump();

        diaryCompleter.complete(mockDiary);
        await pumpFrames(tester);

        expect(find.byType(StatisticsCalendar), findsOneWidget);
      });

      testWidgets('hides CircularProgressIndicator after data loads', (
        WidgetTester tester,
      ) async {
        final diaryCompleter = Completer<IDiaryService>();
        serviceLocator.registerAsyncFactory<IDiaryService>(
          () => diaryCompleter.future,
        );

        await tester.pumpWidget(buildScreen());
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        diaryCompleter.complete(mockDiary);
        await pumpFrames(tester);

        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('Empty data', () {
      testWidgets('statistics cards show zeros with empty diary list', (
        WidgetTester tester,
      ) async {
        // Default mock returns Success([]) for getSortedDiaryEntries
        final diaryCompleter = Completer<IDiaryService>();
        serviceLocator.registerAsyncFactory<IDiaryService>(
          () => diaryCompleter.future,
        );

        await tester.pumpWidget(buildScreen());
        await tester.pump();

        diaryCompleter.complete(mockDiary);
        await pumpFrames(tester);

        // All stat values should be '0'
        // StatisticsCards displays totalEntries, currentStreak,
        // longestStreak, monthlyCount as text
        final zeroFinder = find.text('0');
        expect(zeroFinder, findsNWidgets(4));
      });

      testWidgets('statistics card labels are displayed with empty data', (
        WidgetTester tester,
      ) async {
        final diaryCompleter = Completer<IDiaryService>();
        serviceLocator.registerAsyncFactory<IDiaryService>(
          () => diaryCompleter.future,
        );

        await tester.pumpWidget(buildScreen());
        await tester.pump();

        diaryCompleter.complete(mockDiary);
        await pumpFrames(tester);

        expect(find.text('Total entries'), findsOneWidget);
        expect(find.text('Current streak'), findsOneWidget);
        expect(find.text('Longest streak'), findsOneWidget);
        expect(find.text('This month'), findsOneWidget);
      });
    });

    group('With diary entries', () {
      testWidgets('statistics cards reflect entry count', (
        WidgetTester tester,
      ) async {
        when(
          () => mockDiary.getSortedDiaryEntries(
            descending: any(named: 'descending'),
          ),
        ).thenAnswer(
          (_) async => Success(WidgetTestHelpers.createTestDiaryEntries(5)),
        );

        final diaryCompleter = Completer<IDiaryService>();
        serviceLocator.registerAsyncFactory<IDiaryService>(
          () => diaryCompleter.future,
        );

        await tester.pumpWidget(buildScreen());
        await tester.pump();

        diaryCompleter.complete(mockDiary);
        await pumpFrames(tester);

        // With 5 entries on consecutive days from today, StatisticsCards should
        // display non-zero values. Verify the StatisticsCards widget is present
        // and the '0' values from empty state are gone.
        expect(find.byType(StatisticsCards), findsOneWidget);
        // totalEntries = 5, and text '0' should not appear 4 times anymore
        expect(find.text('0'), findsNothing);
      });

      testWidgets('calls getSortedDiaryEntries on load', (
        WidgetTester tester,
      ) async {
        when(
          () => mockDiary.getSortedDiaryEntries(
            descending: any(named: 'descending'),
          ),
        ).thenAnswer(
          (_) async => Success(WidgetTestHelpers.createTestDiaryEntries(3)),
        );

        final diaryCompleter = Completer<IDiaryService>();
        serviceLocator.registerAsyncFactory<IDiaryService>(
          () => diaryCompleter.future,
        );

        await tester.pumpWidget(buildScreen());
        await tester.pump();

        diaryCompleter.complete(mockDiary);
        await pumpFrames(tester);

        verify(
          () => mockDiary.getSortedDiaryEntries(
            descending: any(named: 'descending'),
          ),
        ).called(greaterThan(0));
      });

      testWidgets('subscribes to diary changes stream', (
        WidgetTester tester,
      ) async {
        final diaryCompleter = Completer<IDiaryService>();
        serviceLocator.registerAsyncFactory<IDiaryService>(
          () => diaryCompleter.future,
        );

        await tester.pumpWidget(buildScreen());
        await tester.pump();

        diaryCompleter.complete(mockDiary);
        await pumpFrames(tester);

        verify(() => mockDiary.changes).called(greaterThan(0));
      });
    });
  });
}
