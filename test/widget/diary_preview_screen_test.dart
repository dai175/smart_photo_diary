import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/screens/diary_preview/diary_preview_screen.dart';
import 'package:smart_photo_diary/screens/diary_preview/diary_preview_body.dart';
import 'package:smart_photo_diary/models/diary_length.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/ai_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/diary_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/diary_crud_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/settings_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';

import '../integration/mocks/mock_services.dart';
import '../test_helpers/mock_platform_channels.dart';
import '../test_helpers/widget_test_helpers.dart';

void main() {
  late MockILoggingService mockLogger;
  late MockIPhotoService mockPhoto;

  setUpAll(() {
    registerMockFallbacks();
    registerFallbackValue(const ThumbnailSize(120, 120));
    registerFallbackValue(ThumbnailFormat.jpeg);
    MockPlatformChannels.setupMocks();
  });

  setUp(() {
    serviceLocator.clear();
    TestServiceSetup.clearAllMocks();

    mockLogger = TestServiceSetup.getLoggingService();
    mockPhoto = TestServiceSetup.getPhotoService();

    // Synchronous services required by DiaryPreviewController constructor
    serviceLocator.registerSingleton<ILoggingService>(mockLogger);
    serviceLocator.registerSingleton<IPhotoService>(mockPhoto);

    // ISettingsService is resolved asynchronously in DiaryPreviewScreen
    final mockSettings = MockSettingsService();
    when(() => mockSettings.diaryLength).thenReturn(DiaryLength.standard);
    serviceLocator.registerSingleton<ISettingsService>(mockSettings);

    // Async services — register factories that never complete so the screen
    // stays in loading/initializing state by default.
    final aiCompleter = Completer<IAiService>();
    serviceLocator.registerAsyncFactory<IAiService>(() => aiCompleter.future);

    final diaryCompleter = Completer<IDiaryService>();
    serviceLocator.registerAsyncFactory<IDiaryService>(
      () => diaryCompleter.future,
    );
    final diaryCrudCompleter = Completer<IDiaryCrudService>();
    serviceLocator.registerAsyncFactory<IDiaryCrudService>(
      () => diaryCrudCompleter.future,
    );

    final subscriptionCompleter = Completer<ISubscriptionService>();
    serviceLocator.registerAsyncFactory<ISubscriptionService>(
      () => subscriptionCompleter.future,
    );
  });

  tearDown(() {
    serviceLocator.clear();
    TestServiceSetup.clearAllMocks();
  });

  tearDownAll(() {
    MockPlatformChannels.clearMocks();
  });

  /// Create a mock [AssetEntity] with default stubs.
  MockAssetEntity createMockAsset({String id = 'test-asset-1'}) {
    final mockAsset = MockAssetEntity();
    when(() => mockAsset.id).thenReturn(id);
    when(() => mockAsset.createDateTime).thenReturn(DateTime(2025, 6, 15));
    when(() => mockAsset.type).thenReturn(AssetType.image);
    when(() => mockAsset.width).thenReturn(1080);
    when(() => mockAsset.height).thenReturn(1920);
    when(
      () => mockAsset.thumbnailDataWithSize(
        any(),
        quality: any(named: 'quality'),
        format: any(named: 'format'),
      ),
    ).thenAnswer((_) async => null);
    return mockAsset;
  }

  Widget buildScreen({List<AssetEntity>? assets, bool multipleAssets = false}) {
    final mockAssets =
        assets ??
        (multipleAssets
            ? [
                createMockAsset(id: 'test-asset-1'),
                createMockAsset(id: 'test-asset-2'),
              ]
            : [createMockAsset()]);

    return WidgetTestHelpers.wrapWithLocalizedApp(
      DiaryPreviewScreen(selectedAssets: mockAssets),
    );
  }

  /// Pump a few frames to trigger initState / postFrameCallback without
  /// waiting for pumpAndSettle (which would time out due to ongoing animations
  /// and never-completing async services).
  Future<void> pumpFrames(WidgetTester tester) async {
    await tester.pump(); // first frame
    await tester.pump(const Duration(milliseconds: 200)); // async init
    await tester.pump(const Duration(milliseconds: 200)); // animations
  }

  group('DiaryPreviewScreen', () {
    group('AppBar display', () {
      testWidgets('shows AppBar with preview title', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildScreen());
        await pumpFrames(tester);

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Diary preview'), findsOneWidget);
      });

      testWidgets('AppBar uses theme default background color', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildScreen());
        await pumpFrames(tester);

        // AppBar now uses theme default (no explicit backgroundColor)
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.backgroundColor, isNull);
      });
    });

    group('Initial loading state', () {
      testWidgets('shows CircularProgressIndicator during initialization', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildScreen());
        // Pump enough to fire the postFrameCallback and its internal
        // Future.delayed(100ms), but async services never complete so
        // the controller stays in loading state.
        await pumpFrames(tester);

        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      });

      testWidgets('shows generating text after initialization phase', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildScreen());
        await pumpFrames(tester);

        // After the 100ms delay, isInitializing becomes false and isLoading
        // becomes true. The loading states widget shows "Creating your diary..."
        expect(find.text('Creating your diary...'), findsOneWidget);
      });
    });

    group('DiaryPreviewBody', () {
      testWidgets('DiaryPreviewBody widget is rendered', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildScreen());
        await pumpFrames(tester);

        expect(find.byType(DiaryPreviewBody), findsOneWidget);
      });
    });

    group('PopScope configuration', () {
      testWidgets('PopScope widget exists with canPop false', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildScreen());
        await pumpFrames(tester);

        // Find PopScope via predicate since multiple PopScopes may exist
        // in the widget tree (from MaterialApp scaffolding, routes, etc.).
        final popScopeFinder = find.byWidgetPredicate(
          (widget) => widget is PopScope && widget.canPop == false,
        );
        expect(popScopeFinder, findsOneWidget);
      });
    });

    group('Save button visibility', () {
      testWidgets('save icon is not shown in AppBar during loading', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildScreen());
        await pumpFrames(tester);

        // save_rounded icon should not appear while initializing/loading
        expect(find.byIcon(Icons.save_rounded), findsNothing);
      });

      testWidgets('bottom bar is not shown during loading', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildScreen());
        await pumpFrames(tester);

        // The bottom bar with the "Save diary" button should not appear
        // while the controller is still loading or initializing.
        expect(find.text('Save diary'), findsNothing);
      });
    });

    group('Scaffold structure', () {
      testWidgets('renders Scaffold as the main widget', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildScreen());
        await pumpFrames(tester);

        expect(find.byType(Scaffold), findsOneWidget);
      });
    });
  });
}
