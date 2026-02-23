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
      testWidgets('shows philosophy page (first page) on launch', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildOnboardingScreen());
        await tester.pumpAndSettle();

        // Philosophy page should be visible
        expect(
          find.text('Your photos\nalready hold the story.'),
          findsOneWidget,
        );
      });

      testWidgets('shows page indicator with 4 dots', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildOnboardingScreen());
        await tester.pumpAndSettle();

        // 4 AnimatedContainers for the page indicator dots
        expect(find.byType(AnimatedContainer), findsNWidgets(4));
      });
    });

    group('Page navigation', () {
      testWidgets('tapping Begin navigates to experience page', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildOnboardingScreen());
        await tester.pumpAndSettle();

        // Tap Begin button
        await tester.tap(find.text('Begin'));
        await tester.pumpAndSettle();

        // Experience page should be visible
        expect(find.text('Relive your day in seconds.'), findsOneWidget);
      });

      testWidgets('can navigate through all 4 pages', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildOnboardingScreen());
        await tester.pumpAndSettle();

        // Page 1: Philosophy -> tap Begin
        await tester.tap(find.text('Begin'));
        await tester.pumpAndSettle();

        // Page 2: Experience -> tap Next
        expect(find.text('Relive your day in seconds.'), findsOneWidget);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Page 3: Trust -> tap Continue
        expect(find.text('Private by design.'), findsOneWidget);
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Page 4: Permission (last page)
        expect(find.text('Start with today.'), findsOneWidget);
        expect(find.text('Create my first diary'), findsOneWidget);
      });

      testWidgets('swipe gesture navigates between pages', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildOnboardingScreen());
        await tester.pumpAndSettle();

        // Swipe left to go to next page
        await tester.drag(find.byType(PageView), const Offset(-400, 0));
        await tester.pumpAndSettle();

        // Should now see experience page content
        expect(find.text('Relive your day in seconds.'), findsOneWidget);
      });
    });

    group('Skip button', () {
      testWidgets('is visible on pages 0-2 but not on page 3', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildOnboardingScreen());
        await tester.pumpAndSettle();

        // Skip visible on page 0
        expect(find.text('Skip'), findsOneWidget);

        // Navigate to page 3 (last page)
        final ctaTexts = ['Begin', 'Next', 'Continue'];
        for (int i = 0; i < 3; i++) {
          await tester.tap(find.text(ctaTexts[i]));
          await tester.pumpAndSettle();
        }

        // Skip should be visually hidden on last page (Visibility with maintainSize)
        final visibilityWidget = tester.widget<Visibility>(
          find.ancestor(
            of: find.text('Skip'),
            matching: find.byType(Visibility),
          ),
        );
        expect(visibilityWidget.visible, isFalse);
      });
    });

    group('Completion flow', () {
      testWidgets(
        'tapping Create my first diary on last page calls completion services',
        (WidgetTester tester) async {
          // Block requestPermission so navigation to HomeScreen never happens
          // (avoids pending-timer issues from HomeScreen initialization).
          when(
            () => mockPhoto.requestPermission(),
          ).thenAnswer((_) => Completer<Result<bool>>().future);

          await tester.pumpWidget(buildOnboardingScreen());
          await tester.pumpAndSettle();

          // Navigate to last page
          final ctaTexts = ['Begin', 'Next', 'Continue'];
          for (int i = 0; i < 3; i++) {
            await tester.tap(find.text(ctaTexts[i]));
            await tester.pumpAndSettle();
          }

          // Tap Create my first diary
          await tester.tap(find.text('Create my first diary'));
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
        ).thenAnswer((_) => Completer<Result<bool>>().future);

        await tester.pumpWidget(buildOnboardingScreen());
        await tester.pumpAndSettle();

        // Tap Skip
        await tester.tap(find.text('Skip'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Settings service should be called
        verify(() => mockSettings.setFirstLaunchCompleted()).called(1);
      });
    });
  });
}
