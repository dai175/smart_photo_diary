import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/controllers/settings_controller.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/models/photo_type_filter.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/settings_service_interface.dart';

import '../mocks/mock_services.dart';
import '../test_helpers/integration_test_helpers.dart';

void main() {
  group('スモークテスト: 設定変更フロー', () {
    setUpAll(() {
      registerMockFallbacks();
    });

    setUp(() async {
      await IntegrationTestHelpers.setUpIntegrationEnvironment();
    });

    tearDown(() async {
      await IntegrationTestHelpers.tearDownIntegrationEnvironment();
    });

    SettingsController createController() {
      final logger = serviceLocator.get<ILoggingService>();
      return SettingsController(logger: logger);
    }

    test('SettingsController が設定を正常にロードする', () async {
      final controller = createController();
      addTearDown(controller.dispose);

      await controller.loadSettings();

      expect(controller.hasSettingsLoaded, isTrue);
      expect(controller.hasError, isFalse);
    });

    test('loadSettings 後に settingsService から themeMode が取得できる', () async {
      final controller = createController();
      addTearDown(controller.dispose);

      await controller.loadSettings();

      expect(controller.settingsService?.themeMode, equals(ThemeMode.system));
    });

    test('loadSettings 後に localeNotifier が日本語を示す', () async {
      final controller = createController();
      addTearDown(controller.dispose);

      await controller.loadSettings();

      expect(controller.settingsService?.localeNotifier, isNotNull);
      expect(
        controller.settingsService?.localeNotifier.value,
        equals(const Locale('ja')),
      );
    });

    test('setPhotoTypeFilter が SettingsService に委譲される', () async {
      final mockSettingsService =
          serviceLocator.get<ISettingsService>() as MockSettingsService;
      when(
        () => mockSettingsService.setPhotoTypeFilter(any()),
      ).thenAnswer((_) async => const Success(null));

      final controller = createController();
      addTearDown(controller.dispose);
      await controller.loadSettings();

      await controller.settingsService?.setPhotoTypeFilter(
        PhotoTypeFilter.photosOnly,
      );

      verify(
        () =>
            mockSettingsService.setPhotoTypeFilter(PhotoTypeFilter.photosOnly),
      ).called(1);
    });
  });
}
