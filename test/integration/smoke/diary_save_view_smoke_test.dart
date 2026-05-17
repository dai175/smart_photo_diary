import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/controllers/diary_preview_controller.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/services/interfaces/ai_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';

import '../mocks/mock_services.dart';
import '../test_helpers/integration_test_helpers.dart';

void main() {
  group('スモークテスト: 日記保存・表示フロー', () {
    late MockIDiaryCrudService mockDiaryService;

    setUpAll(() {
      registerMockFallbacks();
    });

    setUp(() async {
      await IntegrationTestHelpers.setUpIntegrationEnvironment();
      when(
        () => IntegrationTestHelpers.mockPhotoService.getImageForAi(any()),
      ).thenAnswer((_) async => Success(IntegrationTestHelpers.mockPngBytes));

      mockDiaryService = MockIDiaryCrudService();
    });

    tearDown(() async {
      await IntegrationTestHelpers.tearDownIntegrationEnvironment();
    });

    DiaryPreviewController createController({MockIAiService? aiMock}) {
      final logger = serviceLocator.get<ILoggingService>();
      final effectiveAiMock = aiMock ?? IntegrationTestHelpers.mockAiService;
      return DiaryPreviewController(
        logger: logger,
        photoService: IntegrationTestHelpers.mockPhotoService,
        getAiService: () async => effectiveAiMock,
        getDiaryService: () async => mockDiaryService,
      );
    }

    test('AI 生成されたタイトル・内容が DiaryService に渡される', () async {
      when(
        () => mockDiaryService.saveDiaryEntryWithPhotos(
          date: any(named: 'date'),
          title: any(named: 'title'),
          content: any(named: 'content'),
          photos: any(named: 'photos'),
        ),
      ).thenAnswer(
        (_) async => Success(
          IntegrationTestHelpers.createTestDiaryEntry(id: 'saved-id'),
        ),
      );

      final assets = IntegrationTestHelpers.createMockAssets(1);
      final controller = createController();
      addTearDown(controller.dispose);

      await controller.initializeAndGenerate(
        assets: assets,
        locale: const Locale('ja'),
      );

      expect(controller.hasError, isFalse);
      verify(
        () => mockDiaryService.saveDiaryEntryWithPhotos(
          date: any(named: 'date'),
          title: 'テスト日記のタイトル',
          content: 'これはテスト用に生成された日記の内容です。写真から素敵な思い出を記録しました。',
          photos: any(named: 'photos'),
        ),
      ).called(1);
    });

    test('保存成功時に savedDiaryId がコントローラーに記録される', () async {
      const expectedId = 'unique-diary-123';
      when(
        () => mockDiaryService.saveDiaryEntryWithPhotos(
          date: any(named: 'date'),
          title: any(named: 'title'),
          content: any(named: 'content'),
          photos: any(named: 'photos'),
        ),
      ).thenAnswer(
        (_) async => Success(
          IntegrationTestHelpers.createTestDiaryEntry(id: expectedId),
        ),
      );

      final assets = IntegrationTestHelpers.createMockAssets(1);
      final controller = createController();
      addTearDown(controller.dispose);

      await controller.initializeAndGenerate(
        assets: assets,
        locale: const Locale('ja'),
      );

      expect(controller.savedDiaryId, equals(expectedId));
    });

    test('保存失敗時に saveFailed エラー状態になる', () async {
      final aiMock = MockIAiService();
      when(
        () => aiMock.generateDiaryFromImage(
          imageData: any(named: 'imageData'),
          date: any(named: 'date'),
          location: any(named: 'location'),
          photoTimes: any(named: 'photoTimes'),
          prompt: any(named: 'prompt'),
          contextText: any(named: 'contextText'),
          locale: any(named: 'locale'),
          diaryLength: any(named: 'diaryLength'),
        ),
      ).thenAnswer(
        (_) async =>
            Success(DiaryGenerationResult(title: '生成タイトル', content: '生成内容')),
      );

      when(
        () => mockDiaryService.saveDiaryEntryWithPhotos(
          date: any(named: 'date'),
          title: any(named: 'title'),
          content: any(named: 'content'),
          photos: any(named: 'photos'),
        ),
      ).thenAnswer(
        (_) async => const Failure(ServiceException('Database write failed')),
      );

      final assets = IntegrationTestHelpers.createMockAssets(1);
      final controller = createController(aiMock: aiMock);
      addTearDown(controller.dispose);

      await controller.initializeAndGenerate(
        assets: assets,
        locale: const Locale('ja'),
      );

      expect(controller.hasError, isTrue);
      expect(controller.errorType, DiaryPreviewErrorType.saveFailed);
      expect(controller.savedDiaryId, isNull);
    });
  });
}
