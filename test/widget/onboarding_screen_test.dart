import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/screens/onboarding/onboarding_screen.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/settings_service_interface.dart';

import '../integration/mocks/mock_services.dart';
import '../test_helpers/mock_platform_channels.dart';
import '../test_helpers/widget_test_helpers.dart';

void main() {
  late MockILoggingService mockLogger;
  late MockSettingsService mockSettings;
  late MockIPhotoService mockPhoto;

  setUpAll(() {
    registerMockFallbacks();
    MockPlatformChannels.setupMocks();
  });

  setUp(() {
    serviceLocator.clear();

    mockLogger = TestServiceSetup.getLoggingService();
    mockSettings = MockSettingsService();
    mockPhoto = TestServiceSetup.getPhotoService();

    serviceLocator.registerSingleton<ILoggingService>(mockLogger);
    serviceLocator.registerSingleton<ISettingsService>(mockSettings);
    serviceLocator.registerSingleton<IPhotoService>(mockPhoto);

    when(
      () => mockSettings.setFirstLaunchCompleted(),
    ).thenAnswer((_) async => const Success(null));
  });

  tearDown(() {
    serviceLocator.clear();
    TestServiceSetup.clearAllMocks();
  });

  tearDownAll(() {
    MockPlatformChannels.clearMocks();
  });

  Widget buildOnboardingScreen() {
    return WidgetTestHelpers.wrapWithLocalizedApp(const OnboardingScreen());
  }

  group('OnboardingScreen', () {
    group('Initial display', () {
      testWidgets('shows welcome page (first page) on launch', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildOnboardingScreen());
        await tester.pumpAndSettle();

        // Welcome page should be visible
        expect(find.text('Welcome to\nSmart Photo Diary'), findsOneWidget);
      });

      testWidgets('shows page indicator with 5 dots', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildOnboardingScreen());
        await tester.pumpAndSettle();

        // 5 AnimatedContainers for the page indicator dots
        expect(find.byType(AnimatedContainer), findsNWidgets(5));
      });
    });

    group('Page navigation', () {
      testWidgets('tapping Next navigates to page 2', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildOnboardingScreen());
        await tester.pumpAndSettle();

        // Tap Next button
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Page 2 shows the three-steps content
        expect(find.text('Create your diary in three steps'), findsOneWidget);
      });

      testWidgets('Back button appears from page 2 onwards', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildOnboardingScreen());
        await tester.pumpAndSettle();

        // Initially no Back button
        expect(find.text('Back'), findsNothing);

        // Navigate to page 2
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Back button should appear
        expect(find.text('Back'), findsOneWidget);
      });

      testWidgets('can navigate through all 5 pages with Next', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildOnboardingScreen());
        await tester.pumpAndSettle();

        // Page 1 -> 2
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Page 2 -> 3
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Page 3 -> 4
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Page 4 -> 5 (last page)
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Last page shows "Get started" instead of "Next"
        expect(find.text('Get started'), findsOneWidget);
        expect(find.text('Next'), findsNothing);
      });

      testWidgets('swipe gesture navigates between pages', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildOnboardingScreen());
        await tester.pumpAndSettle();

        // Swipe left to go to next page
        await tester.drag(find.byType(PageView), const Offset(-400, 0));
        await tester.pumpAndSettle();

        // Should now see page 2 content
        expect(find.text('Create your diary in three steps'), findsOneWidget);
      });
    });

    group('Skip button', () {
      testWidgets('is visible on pages 0-3 but not on page 4', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildOnboardingScreen());
        await tester.pumpAndSettle();

        // Skip visible on page 0
        expect(find.text('Skip'), findsOneWidget);

        // Navigate to page 4 (last page)
        for (int i = 0; i < 4; i++) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }

        // Skip should be hidden on last page
        expect(find.text('Skip'), findsNothing);
      });
    });

    group('Completion flow', () {
      testWidgets(
        'tapping Get started on last page calls completion services',
        (WidgetTester tester) async {
          // Block requestPermission so navigation to HomeScreen never happens
          // (avoids pending-timer issues from HomeScreen initialization).
          when(
            () => mockPhoto.requestPermission(),
          ).thenAnswer((_) => Completer<bool>().future);

          await tester.pumpWidget(buildOnboardingScreen());
          await tester.pumpAndSettle();

          // Navigate to last page
          for (int i = 0; i < 4; i++) {
            await tester.tap(find.text('Next'));
            await tester.pumpAndSettle();
          }

          // Tap Get started
          await tester.tap(find.text('Get started'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          // Settings service should be called
          verify(() => mockSettings.setFirstLaunchCompleted()).called(1);
        },
      );

      testWidgets('tapping Skip calls completion flow', (
        WidgetTester tester,
      ) async {
        // Block requestPermission so navigation to HomeScreen never happens
        when(
          () => mockPhoto.requestPermission(),
        ).thenAnswer((_) => Completer<bool>().future);

        await tester.pumpWidget(buildOnboardingScreen());
        await tester.pumpAndSettle();

        // Tap Skip
        await tester.tap(find.text('Skip'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Settings service should be called
        verify(() => mockSettings.setFirstLaunchCompleted()).called(1);
      });

      testWidgets('Back button navigates to previous page', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildOnboardingScreen());
        await tester.pumpAndSettle();

        // Navigate to page 2
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Tap Back
        await tester.tap(find.text('Back'));
        await tester.pumpAndSettle();

        // Should return to page 1
        expect(find.text('Welcome to\nSmart Photo Diary'), findsOneWidget);
      });
    });
  });
}
