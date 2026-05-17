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

        expect(
          find.text('Your photos already hold the story.'),
          findsOneWidget,
        );
      });

      testWidgets('shows progress header with 4 segments', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildOnboardingScreen());
        await tester.pumpAndSettle();

        // 4 AnimatedContainers for the progress segment track
        expect(find.byType(AnimatedContainer), findsNWidgets(4));
      });
    });

    group('Page navigation', () {
      testWidgets('tapping Begin navigates to how-it-works page', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildOnboardingScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Begin'));
        await tester.pumpAndSettle();

        expect(find.text('Pick a photo. We do the writing.'), findsOneWidget);
      });

      testWidgets('can navigate through all 4 pages', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildOnboardingScreen());
        await tester.pumpAndSettle();

        // Page 1: Welcome -> tap Begin
        await tester.tap(find.text('Begin'));
        await tester.pumpAndSettle();

        // Page 2: How It Works -> tap Next
        expect(find.text('Pick a photo. We do the writing.'), findsOneWidget);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Page 3: Privacy -> tap Continue
        expect(find.text('Your diary stays here.'), findsOneWidget);
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Page 4: Ready (last page)
        expect(find.text('Start with today.'), findsOneWidget);
        expect(find.text('Create my first diary'), findsOneWidget);
      });

      testWidgets('swipe gesture navigates between pages', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildOnboardingScreen());
        await tester.pumpAndSettle();

        // fling with velocity to ensure PageView wins the gesture arena
        // over the vertical SingleChildScrollView inside each page
        await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
        await tester.pumpAndSettle();

        expect(find.text('Pick a photo. We do the writing.'), findsOneWidget);
      });
    });

    group('Skip button', () {
      testWidgets('is visible on pages 0-2 but absent on page 3', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildOnboardingScreen());
        await tester.pumpAndSettle();

        // Skip visible on page 0
        expect(find.text('Skip'), findsOneWidget);

        // Navigate to page 3 (last page)
        final ctaTexts = ['Begin', 'Next', 'Continue'];
        for (final label in ctaTexts) {
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
        }

        // Skip is not rendered on the last page
        expect(find.text('Skip'), findsNothing);
      });
    });

    group('Completion flow', () {
      testWidgets(
        'tapping Create my first diary on last page calls completion services',
        (WidgetTester tester) async {
          when(
            () => mockPhoto.requestPermission(),
          ).thenAnswer((_) => Completer<Result<bool>>().future);

          await tester.pumpWidget(buildOnboardingScreen());
          await tester.pumpAndSettle();

          final ctaTexts = ['Begin', 'Next', 'Continue'];
          for (final label in ctaTexts) {
            await tester.tap(find.text(label));
            await tester.pumpAndSettle();
          }

          await tester.tap(find.text('Create my first diary'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          verify(() => mockSettings.setFirstLaunchCompleted()).called(1);
        },
      );

      testWidgets('tapping Skip calls completion flow', (
        WidgetTester tester,
      ) async {
        when(
          () => mockPhoto.requestPermission(),
        ).thenAnswer((_) => Completer<Result<bool>>().future);

        await tester.pumpWidget(buildOnboardingScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Skip'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        verify(() => mockSettings.setFirstLaunchCompleted()).called(1);
      });
    });
  });
}
