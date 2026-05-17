import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/screens/diary_preview/diary_preview_generating.dart';
import 'package:smart_photo_diary/screens/diary_preview/diary_preview_screen.dart';
import 'package:smart_photo_diary/screens/diary_preview/diary_preview_body.dart';
import 'package:smart_photo_diary/models/diary_length.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_cache_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/ai_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/diary_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/diary_crud_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/settings_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';

import '../integration/mocks/mock_services.dart';
import '../test_helpers/mock_platform_channels.dart';
import '../test_helpers/widget_test_helpers.dart';

class MockIPhotoCacheService extends Mock implements IPhotoCacheService {}

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

    // IPhotoCacheService is used by DiaryPreviewGeneratingScreen._HeroPhoto
    final mockPhotoCache = MockIPhotoCacheService();
    when(
      () => mockPhotoCache.getThumbnail(
        any(),
        width: any(named: 'width'),
        height: any(named: 'height'),
        quality: any(named: 'quality'),
      ),
    ).thenAnswer(
      (_) async => const Failure<Uint8List>(PhotoAccessException('test')),
    );
    serviceLocator.registerSingleton<IPhotoCacheService>(mockPhotoCache);

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

  /// Build the screen at phone size and pump a few frames.
  ///
  /// Sets a 390×844 surface BEFORE pumpWidget so the 4:3 hero photo doesn't
  /// overflow the default 800×600 test canvas. Resets the size on teardown.
  Future<void> buildAndPump(WidgetTester tester, Widget widget) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(widget);
    await tester.pump(const Duration(milliseconds: 200)); // async init
    await tester.pump(const Duration(milliseconds: 200)); // animations
  }

  group('DiaryPreviewScreen', () {
    group('AppBar display', () {
      testWidgets('no AppBar shown during loading (skeleton screen)', (
        WidgetTester tester,
      ) async {
        await buildAndPump(tester, buildScreen());

        // During generation the skeleton screen is shown — no AppBar.
        expect(find.byType(AppBar), findsNothing);
      });
    });

    group('Initial loading state', () {
      testWidgets('shows DiaryPreviewGeneratingScreen during loading', (
        WidgetTester tester,
      ) async {
        await buildAndPump(tester, buildScreen());

        expect(find.byType(DiaryPreviewGeneratingScreen), findsOneWidget);
        expect(find.byType(DiaryPreviewBody), findsNothing);
      });

      testWidgets('shows generating status text during loading phase', (
        WidgetTester tester,
      ) async {
        await buildAndPump(tester, buildScreen());

        // The banner inside DiaryPreviewGeneratingScreen shows the status text.
        expect(find.text('Creating your diary...'), findsOneWidget);
      });
    });

    group('DiaryPreviewBody', () {
      testWidgets('DiaryPreviewBody is not shown during loading', (
        WidgetTester tester,
      ) async {
        await buildAndPump(tester, buildScreen());

        // Body is only shown after generation completes.
        expect(find.byType(DiaryPreviewBody), findsNothing);
      });
    });

    group('PopScope configuration', () {
      testWidgets('PopScope exists with canPop true during loading', (
        WidgetTester tester,
      ) async {
        await buildAndPump(tester, buildScreen());

        // During generation, back navigation is allowed freely (canPop: true).
        final popScopeFinder = find.byWidgetPredicate(
          (widget) => widget is PopScope && widget.canPop == true,
        );
        expect(popScopeFinder, findsAtLeastNWidgets(1));
      });
    });

    group('Save button visibility', () {
      testWidgets('save icon is not shown in AppBar during loading', (
        WidgetTester tester,
      ) async {
        await buildAndPump(tester, buildScreen());

        // save_rounded icon should not appear while initializing/loading
        expect(find.byIcon(Icons.save_rounded), findsNothing);
      });

      testWidgets('bottom bar is not shown during loading', (
        WidgetTester tester,
      ) async {
        await buildAndPump(tester, buildScreen());

        // The bottom bar with the "Save diary" button should not appear
        // while the controller is still loading or initializing.
        expect(find.text('Save diary'), findsNothing);
      });
    });

    group('Scaffold structure', () {
      testWidgets('renders Scaffold as the main widget', (
        WidgetTester tester,
      ) async {
        await buildAndPump(tester, buildScreen());

        expect(find.byType(Scaffold), findsOneWidget);
      });
    });
  });
}
