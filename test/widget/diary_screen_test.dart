import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/screens/diary_screen.dart';
import 'package:smart_photo_diary/services/interfaces/diary_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/diary_query_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/diary_tag_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_cache_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/ui/components/loading_shimmer.dart';
import 'package:smart_photo_diary/widgets/diary_card_widget.dart';

import '../integration/mocks/mock_services.dart';
import '../test_helpers/mock_platform_channels.dart';
import '../test_helpers/widget_test_helpers.dart';

/// Mock for IPhotoCacheService (not in shared mocks)
class MockIPhotoCacheService extends Mock implements IPhotoCacheService {}

void main() {
  late MockILoggingService mockLogger;
  late MockIDiaryService mockDiary;
  late MockIPhotoCacheService mockPhotoCache;

  setUpAll(() {
    registerMockFallbacks();
    MockPlatformChannels.setupMocks();
  });

  setUp(() {
    serviceLocator.clear();
    TestServiceSetup.clearAllMocks();

    mockLogger = TestServiceSetup.getLoggingService();
    mockDiary = TestServiceSetup.getDiaryService();
    mockPhotoCache = MockIPhotoCacheService();

    // Stub IPhotoCacheService methods
    when(
      () => mockPhotoCache.preloadThumbnails(
        any(),
        width: any(named: 'width'),
        height: any(named: 'height'),
        quality: any(named: 'quality'),
      ),
    ).thenAnswer((_) async {});

    serviceLocator.registerSingleton<ILoggingService>(mockLogger);
    serviceLocator.registerSingleton<IPhotoCacheService>(mockPhotoCache);

    final mockPhotoService = TestServiceSetup.getPhotoService();
    serviceLocator.registerSingleton<IPhotoService>(mockPhotoService);
  });

  tearDown(() {
    serviceLocator.clear();
    TestServiceSetup.clearAllMocks();
  });

  tearDownAll(() {
    MockPlatformChannels.clearMocks();
  });

  Widget buildScreen() {
    return WidgetTestHelpers.wrapWithLocalizedApp(const DiaryScreen());
  }

  /// Pump enough frames for async init without pumpAndSettle (which times out
  /// due to ongoing animations in child screens).
  Future<void> pumpFrames(WidgetTester tester) async {
    await tester.pump(); // first frame
    await tester.pump(const Duration(milliseconds: 500)); // async init
    await tester.pump(const Duration(milliseconds: 500)); // animations
  }

  /// Helper to register IDiaryService as an immediately-resolved async factory.
  void registerDiaryServiceAsync() {
    serviceLocator.registerAsyncFactory<IDiaryService>(() async => mockDiary);
    serviceLocator.registerSingleton<IDiaryQueryService>(mockDiary);
    serviceLocator.registerSingleton<IDiaryTagService>(MockIDiaryTagService());
  }

  group('DiaryScreen', () {
    group('AppBar display', () {
      testWidgets('shows AppBar with diary list title', (
        WidgetTester tester,
      ) async {
        registerDiaryServiceAsync();

        await tester.pumpWidget(buildScreen());
        await pumpFrames(tester);

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Diaries'), findsOneWidget);
      });

      testWidgets('shows search icon in AppBar actions', (
        WidgetTester tester,
      ) async {
        registerDiaryServiceAsync();

        await tester.pumpWidget(buildScreen());
        await pumpFrames(tester);

        // Search icon (Icons.search_rounded) should be present
        expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      });

      testWidgets('shows filter icon in AppBar actions', (
        WidgetTester tester,
      ) async {
        registerDiaryServiceAsync();

        await tester.pumpWidget(buildScreen());
        await pumpFrames(tester);

        // Filter icon (Icons.filter_list_rounded) should be present
        expect(find.byIcon(Icons.filter_list_rounded), findsOneWidget);
      });
    });

    group('Loading state', () {
      testWidgets('shows DiaryCardShimmer widgets when loading', (
        WidgetTester tester,
      ) async {
        // Register diary service with a completer that is never completed
        // so the controller stays in loading state.
        final diaryCompleter = Completer<IDiaryService>();
        serviceLocator.registerAsyncFactory<IDiaryService>(
          () => diaryCompleter.future,
        );
        final queryCompleter = Completer<IDiaryQueryService>();
        serviceLocator.registerAsyncFactory<IDiaryQueryService>(
          () => queryCompleter.future,
        );

        await tester.pumpWidget(buildScreen());
        await tester.pump(); // first frame

        // Shimmer widgets should be displayed while loading
        expect(find.byType(DiaryCardShimmer), findsWidgets);
      });
    });

    group('Empty state', () {
      testWidgets(
        'shows empty state with book_outlined icon and message when no entries',
        (WidgetTester tester) async {
          registerDiaryServiceAsync();

          await tester.pumpWidget(buildScreen());
          await pumpFrames(tester);

          // Empty state icon
          expect(find.byIcon(Icons.book_outlined), findsOneWidget);

          // Empty state message
          expect(find.text('No saved diaries'), findsOneWidget);
        },
      );
    });

    group('With diary entries', () {
      testWidgets('shows DiaryCardWidget items when entries exist', (
        WidgetTester tester,
      ) async {
        final testEntries = WidgetTestHelpers.createTestDiaryEntries(3);

        // Override the default mock to return test entries
        when(
          () => mockDiary.getFilteredDiaryEntriesPage(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Success(testEntries));

        registerDiaryServiceAsync();

        await tester.pumpWidget(buildScreen());
        await pumpFrames(tester);

        // Should show 3 DiaryCardWidget items
        expect(find.byType(DiaryCardWidget), findsNWidgets(3));
      });
    });

    group('Search functionality', () {
      testWidgets('tapping search icon switches AppBar to search mode', (
        WidgetTester tester,
      ) async {
        registerDiaryServiceAsync();

        await tester.pumpWidget(buildScreen());
        await pumpFrames(tester);

        // Tap the search icon
        await tester.tap(find.byIcon(Icons.search_rounded));
        await tester.pump();

        // Search mode should show a TextField in AppBar
        expect(find.byType(TextField), findsOneWidget);
      });
    });

    group('Filter icon display', () {
      testWidgets('filter icon is present in AppBar actions', (
        WidgetTester tester,
      ) async {
        registerDiaryServiceAsync();

        await tester.pumpWidget(buildScreen());
        await pumpFrames(tester);

        // filter_list_rounded is the default (inactive) filter icon
        expect(find.byIcon(Icons.filter_list_rounded), findsOneWidget);
      });
    });
  });
}
