import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/controllers/settings_controller.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/settings_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/storage_service_interface.dart';
import 'package:smart_photo_diary/services/storage_service.dart';

class MockLoggingService extends Mock implements ILoggingService {}

class MockSettingsService extends Mock implements ISettingsService {}

class MockStorageService extends Mock implements IStorageService {}

void main() {
  late MockLoggingService mockLogger;
  late MockSettingsService mockSettings;
  late MockStorageService mockStorage;

  setUp(() {
    ServiceLocator().clear();
    mockLogger = MockLoggingService();
    mockSettings = MockSettingsService();
    mockStorage = MockStorageService();

    ServiceLocator().registerSingleton<ILoggingService>(mockLogger);
    ServiceLocator().registerSingleton<ISettingsService>(mockSettings);
    ServiceLocator().registerSingleton<IStorageService>(mockStorage);

    // Default stubs
    when(() => mockSettings.locale).thenReturn(null);
    when(() => mockSettings.getSubscriptionInfoV2()).thenAnswer(
      (_) async => const Failure(ServiceException('Not available in test')),
    );
    when(() => mockStorage.getStorageInfoResult()).thenAnswer(
      (_) async => Success(StorageInfo(totalSize: 1024, diaryDataSize: 512)),
    );
  });

  tearDown(() {
    ServiceLocator().clear();
  });

  SettingsController createController() {
    return SettingsController();
  }

  group('SettingsController', () {
    group('初期状態', () {
      test('初期状態は正しくセットされている', () {
        final controller = createController();
        addTearDown(controller.dispose);

        expect(controller.packageInfo, isNull);
        expect(controller.storageInfo, isNull);
        expect(controller.subscriptionInfo, isNull);
        expect(controller.selectedLocale, isNull);
        expect(controller.isLoading, isFalse);
      });
    });

    group('loadSettings', () {
      test('ロード完了後に isLoading が false になる', () async {
        // PackageInfo.fromPlatform() はテスト環境で例外を投げるが、
        // loadSettings 内のtry-catchで処理されロードは完了する
        final controller = createController();
        addTearDown(controller.dispose);

        await controller.loadSettings();

        expect(controller.isLoading, isFalse);
        // settingsService は PackageInfo 例外前に設定される
        expect(controller.settingsService, isNotNull);
      });

      test('ロード中は isLoading が true になる', () async {
        final controller = createController();
        addTearDown(controller.dispose);

        bool wasLoadingTrue = false;
        controller.addListener(() {
          if (controller.isLoading) {
            wasLoadingTrue = true;
          }
        });

        await controller.loadSettings();
        expect(wasLoadingTrue, isTrue);
      });

      test('ストレージ情報取得エラー時もロードが完了する', () async {
        when(() => mockStorage.getStorageInfoResult()).thenAnswer(
          (_) async => const Failure(ServiceException('Storage error')),
        );

        final controller = createController();
        addTearDown(controller.dispose);

        await controller.loadSettings();

        expect(controller.isLoading, isFalse);
        expect(controller.storageInfo, isNull);
        verify(
          () => mockLogger.error(
            any(),
            error: any(named: 'error'),
            context: any(named: 'context'),
          ),
        ).called(greaterThan(0));
      });
    });

    group('onLocaleChanged', () {
      test('ロケールが変更される', () {
        final controller = createController();
        addTearDown(controller.dispose);

        int notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.onLocaleChanged(const Locale('ja'));

        expect(controller.selectedLocale, const Locale('ja'));
        expect(notifyCount, 1);
      });

      test('null に変更できる', () {
        final controller = createController();
        addTearDown(controller.dispose);

        controller.onLocaleChanged(const Locale('ja'));
        controller.onLocaleChanged(null);

        expect(controller.selectedLocale, isNull);
      });
    });

    group('logger', () {
      test('logger getter がアクセス可能', () {
        final controller = createController();
        addTearDown(controller.dispose);

        expect(controller.logger, isNotNull);
      });
    });
  });
}
