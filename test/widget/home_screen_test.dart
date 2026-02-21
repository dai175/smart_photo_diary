import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/screens/home_screen.dart';
import 'package:smart_photo_diary/services/interfaces/diary_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_cache_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/settings_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/storage_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';

import '../integration/mocks/mock_services.dart';
import '../test_helpers/mock_platform_channels.dart';
import '../test_helpers/widget_test_helpers.dart';

/// Mock for IPhotoCacheService (not in shared mocks)
class MockIPhotoCacheService extends Mock implements IPhotoCacheService {}

void main() {
  late MockILoggingService mockLogger;
  late MockIPhotoService mockPhoto;
  late MockIDiaryService mockDiary;
  late MockSubscriptionServiceInterface mockSubscription;
  late MockSettingsService mockSettings;
  late MockStorageService mockStorage;
  late MockIPhotoCacheService mockPhotoCache;

  setUpAll(() {
    registerMockFallbacks();
    MockPlatformChannels.setupMocks();
  });

  setUp(() {
    serviceLocator.clear();
    TestServiceSetup.clearAllMocks();

    mockLogger = TestServiceSetup.getLoggingService();
    mockPhoto = TestServiceSetup.getPhotoService();
    mockDiary = TestServiceSetup.getDiaryService();
    mockSubscription = TestServiceSetup.getSubscriptionService();
    mockSettings = MockSettingsService();
    mockStorage = TestServiceSetup.getStorageService();
    mockPhotoCache = MockIPhotoCacheService();

    // Stub SettingsService properties needed by SettingsScreen
    when(() => mockSettings.locale).thenReturn(null);
    when(() => mockSettings.themeMode).thenReturn(ThemeMode.system);
    when(() => mockSettings.localeNotifier).thenReturn(ValueNotifier(null));

    serviceLocator.registerSingleton<ILoggingService>(mockLogger);
    serviceLocator.registerSingleton<IPhotoService>(mockPhoto);
    serviceLocator.registerSingleton<IDiaryService>(mockDiary);
    serviceLocator.registerSingleton<ISubscriptionService>(mockSubscription);
    serviceLocator.registerSingleton<ISettingsService>(mockSettings);
    serviceLocator.registerSingleton<IStorageService>(mockStorage);
    serviceLocator.registerSingleton<IPhotoCacheService>(mockPhotoCache);
  });

  tearDown(() {
    serviceLocator.clear();
    TestServiceSetup.clearAllMocks();
  });

  tearDownAll(() {
    MockPlatformChannels.clearMocks();
  });

  Widget buildHomeScreen() {
    return WidgetTestHelpers.wrapWithLocalizedApp(const HomeScreen());
  }

  /// Pump enough frames for async init without pumpAndSettle (which times out
  /// due to ongoing animations in child screens).
  Future<void> pumpFrames(WidgetTester tester) async {
    await tester.pump(); // first frame
    await tester.pump(const Duration(milliseconds: 500)); // async init
    await tester.pump(const Duration(milliseconds: 500)); // animations
  }

  group('HomeScreen', () {
    group('Tab bar display', () {
      testWidgets('shows BottomNavigationBar with 4 tabs', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildHomeScreen());
        await pumpFrames(tester);

        expect(find.byType(BottomNavigationBar), findsOneWidget);

        // 4 tab labels
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Diary'), findsOneWidget);
        expect(find.text('Statistics'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
      });

      testWidgets('Home tab is selected initially', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildHomeScreen());
        await pumpFrames(tester);

        final navBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(navBar.currentIndex, 0);
      });

      testWidgets('IndexedStack exists for tab management', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildHomeScreen());
        await pumpFrames(tester);

        expect(find.byType(IndexedStack), findsOneWidget);
      });
    });

    group('Tab switching', () {
      testWidgets('tapping Diary tab switches to index 1', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildHomeScreen());
        await pumpFrames(tester);

        await tester.tap(find.text('Diary'));
        await tester.pump();

        final navBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(navBar.currentIndex, 1);
      });

      testWidgets('tapping Statistics tab switches to index 2', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildHomeScreen());
        await pumpFrames(tester);

        await tester.tap(find.text('Statistics'));
        await tester.pump();

        final navBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(navBar.currentIndex, 2);
      });

      testWidgets('tapping Settings tab switches to index 3', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildHomeScreen());
        await pumpFrames(tester);

        await tester.tap(find.text('Settings'));
        await tester.pump();

        final navBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(navBar.currentIndex, 3);
      });
    });

    group('Initial data loading', () {
      testWidgets('requests photo permission on init', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildHomeScreen());
        await pumpFrames(tester);

        verify(() => mockPhoto.requestPermission()).called(greaterThan(0));
      });

      testWidgets('loads diary entries on init', (WidgetTester tester) async {
        await tester.pumpWidget(buildHomeScreen());
        await pumpFrames(tester);

        verify(
          () => mockDiary.getSortedDiaryEntries(
            descending: any(named: 'descending'),
          ),
        ).called(greaterThan(0));
      });

      testWidgets('subscribes to diary changes stream on init', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildHomeScreen());
        await pumpFrames(tester);

        verify(() => mockDiary.changes).called(greaterThan(0));
      });
    });
  });
}
