import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/screens/settings_screen.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/settings_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/storage_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';
import 'package:smart_photo_diary/services/storage_service.dart';

import '../integration/mocks/mock_services.dart';
import '../test_helpers/mock_platform_channels.dart';
import '../test_helpers/widget_test_helpers.dart';

void main() {
  late MockILoggingService mockLogger;
  late MockSettingsService mockSettings;
  late MockStorageService mockStorage;
  late MockSubscriptionServiceInterface mockSubscription;

  setUpAll(() {
    registerMockFallbacks();
    MockPlatformChannels.setupMocks();

    // Mock package_info_plus platform channel so PackageInfo.fromPlatform()
    // resolves instead of hanging indefinitely in the test environment.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/package_info'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'getAll') {
              return <String, dynamic>{
                'appName': 'Smart Photo Diary',
                'packageName': 'com.example.smart_photo_diary',
                'version': '1.0.0',
                'buildNumber': '1',
                'buildSignature': '',
                'installerStore': '',
              };
            }
            return null;
          },
        );
  });

  setUp(() {
    serviceLocator.clear();
    TestServiceSetup.clearAllMocks();

    mockLogger = TestServiceSetup.getLoggingService();
    mockSettings = MockSettingsService();
    mockStorage = TestServiceSetup.getStorageService();
    mockSubscription = TestServiceSetup.getSubscriptionService();

    // Stub SettingsService properties needed by SettingsController
    when(() => mockSettings.locale).thenReturn(null);
    when(() => mockSettings.themeMode).thenReturn(ThemeMode.system);
    when(() => mockSettings.localeNotifier).thenReturn(ValueNotifier(null));
    when(() => mockSettings.getSubscriptionInfoV2()).thenAnswer(
      (_) async => const Failure(ServiceException('Not available in test')),
    );

    // Stub StorageService
    when(() => mockStorage.getStorageInfoResult()).thenAnswer(
      (_) async => Success(StorageInfo(totalSize: 1024, diaryDataSize: 512)),
    );

    // Register synchronous logger service (always needed by constructor)
    serviceLocator.registerSingleton<ILoggingService>(mockLogger);
  });

  tearDown(() {
    serviceLocator.clear();
    TestServiceSetup.clearAllMocks();
  });

  tearDownAll(() {
    MockPlatformChannels.clearMocks();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/package_info'),
          null,
        );
  });

  Widget buildSettingsScreen() {
    return WidgetTestHelpers.wrapWithLocalizedApp(const SettingsScreen());
  }

  /// Pump enough frames for async init without pumpAndSettle (which times out
  /// due to ongoing animations in child screens).
  Future<void> pumpFrames(WidgetTester tester) async {
    await tester.pump(); // first frame
    await tester.pump(const Duration(milliseconds: 500)); // async init
    await tester.pump(const Duration(milliseconds: 500)); // animations
  }

  /// Register async ISettingsService via a Completer so that loadSettings()
  /// awaits it. Returns the completer so tests can complete it when ready.
  /// IStorageService is registered synchronously (accessed via get<>).
  Completer<ISettingsService> registerAsyncSettingsService() {
    final settingsCompleter = Completer<ISettingsService>();

    serviceLocator.registerAsyncFactory<ISettingsService>(
      () => settingsCompleter.future,
    );
    serviceLocator.registerSingleton<IStorageService>(mockStorage);
    serviceLocator.registerSingleton<ISubscriptionService>(mockSubscription);

    return settingsCompleter;
  }

  /// Register all services synchronously (already resolved) for tests that
  /// need the settings to be loaded immediately.
  void registerResolvedServices() {
    serviceLocator.registerSingleton<ISettingsService>(mockSettings);
    serviceLocator.registerSingleton<IStorageService>(mockStorage);
    serviceLocator.registerSingleton<ISubscriptionService>(mockSubscription);
  }

  group('SettingsScreen', () {
    group('AppBar display', () {
      testWidgets('shows AppBar with settings title', (
        WidgetTester tester,
      ) async {
        registerResolvedServices();

        await tester.pumpWidget(buildSettingsScreen());
        await pumpFrames(tester);

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
      });

      testWidgets('AppBar title is visible during loading state', (
        WidgetTester tester,
      ) async {
        final completer = registerAsyncSettingsService();

        await tester.pumpWidget(buildSettingsScreen());
        await pumpFrames(tester);

        // AppBar should still show title even during loading
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);

        // Clean up: complete to avoid pending futures
        completer.complete(mockSettings);
      });
    });

    group('Loading state', () {
      testWidgets('shows CircularProgressIndicator while loading', (
        WidgetTester tester,
      ) async {
        final completer = registerAsyncSettingsService();

        await tester.pumpWidget(buildSettingsScreen());
        await pumpFrames(tester);

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Clean up
        completer.complete(mockSettings);
      });

      testWidgets('shows loading title text while loading', (
        WidgetTester tester,
      ) async {
        final completer = registerAsyncSettingsService();

        await tester.pumpWidget(buildSettingsScreen());
        await pumpFrames(tester);

        expect(find.text('Loading settings...'), findsOneWidget);

        // Clean up
        completer.complete(mockSettings);
      });

      testWidgets('shows loading subtitle text while loading', (
        WidgetTester tester,
      ) async {
        final completer = registerAsyncSettingsService();

        await tester.pumpWidget(buildSettingsScreen());
        await pumpFrames(tester);

        expect(find.text('Fetching your app preferences'), findsOneWidget);

        // Clean up
        completer.complete(mockSettings);
      });
    });

    group('Settings loaded', () {
      testWidgets('shows settings content after services resolve', (
        WidgetTester tester,
      ) async {
        registerResolvedServices();

        await tester.pumpWidget(buildSettingsScreen());
        await pumpFrames(tester);

        // Loading indicator should be gone
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // Version info row should be visible
        expect(find.text('App version'), findsOneWidget);
      });

      testWidgets('shows license info after loading', (
        WidgetTester tester,
      ) async {
        registerResolvedServices();

        await tester.pumpWidget(buildSettingsScreen());
        await pumpFrames(tester);

        expect(find.text('Licenses'), findsOneWidget);
        expect(find.text('Open source licenses'), findsOneWidget);
      });

      testWidgets('shows version number when PackageInfo resolves', (
        WidgetTester tester,
      ) async {
        registerResolvedServices();

        await tester.pumpWidget(buildSettingsScreen());
        await pumpFrames(tester);

        // PackageInfo.fromPlatform() now resolves via mocked channel
        expect(find.text('1.0.0 (1)'), findsOneWidget);
      });

      testWidgets('does not show error state when settings load successfully', (
        WidgetTester tester,
      ) async {
        registerResolvedServices();

        await tester.pumpWidget(buildSettingsScreen());
        await pumpFrames(tester);

        // Error UI should not be shown
        expect(find.text('An error occurred'), findsNothing);
        expect(
          find.text('Failed to load settings. Pull down to retry.'),
          findsNothing,
        );
      });
    });

    group('Error state', () {
      testWidgets('shows error UI when settings service fails to load', (
        WidgetTester tester,
      ) async {
        // Register an async factory that throws an error
        serviceLocator.registerAsyncFactory<ISettingsService>(
          () => Future<ISettingsService>.error(
            Exception('Settings service failed'),
          ),
        );
        serviceLocator.registerSingleton<IStorageService>(mockStorage);
        serviceLocator.registerSingleton<ISubscriptionService>(
          mockSubscription,
        );

        await tester.pumpWidget(buildSettingsScreen());
        await pumpFrames(tester);

        // Error UI should be shown
        expect(find.text('An error occurred'), findsOneWidget);
        expect(
          find.text('Failed to load settings. Pull down to retry.'),
          findsOneWidget,
        );
      });

      testWidgets('shows error icon in error state', (
        WidgetTester tester,
      ) async {
        serviceLocator.registerAsyncFactory<ISettingsService>(
          () => Future<ISettingsService>.error(
            Exception('Settings service failed'),
          ),
        );
        serviceLocator.registerSingleton<IStorageService>(mockStorage);
        serviceLocator.registerSingleton<ISubscriptionService>(
          mockSubscription,
        );

        await tester.pumpWidget(buildSettingsScreen());
        await pumpFrames(tester);

        // Error icon should be present
        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      });

      testWidgets('does not show loading indicator in error state', (
        WidgetTester tester,
      ) async {
        serviceLocator.registerAsyncFactory<ISettingsService>(
          () => Future<ISettingsService>.error(
            Exception('Settings service failed'),
          ),
        );
        serviceLocator.registerSingleton<IStorageService>(mockStorage);
        serviceLocator.registerSingleton<ISubscriptionService>(
          mockSubscription,
        );

        await tester.pumpWidget(buildSettingsScreen());
        await pumpFrames(tester);

        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });
  });
}
