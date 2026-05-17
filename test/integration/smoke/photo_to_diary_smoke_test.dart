import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/controllers/diary_preview_controller.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';

import '../mocks/mock_services.dart';
import '../test_helpers/integration_test_helpers.dart';

void main() {
  group('スモークテスト: 写真 → 日記生成フロー', () {
    late MockIDiaryCrudService mockDiaryService;

    setUpAll(() {
      registerMockFallbacks();
    });

    setUp(() async {
      await IntegrationTestHelpers.setUpIntegrationEnvironment();

      mockDiaryService = MockIDiaryCrudService();
      when(
        () => mockDiaryService.saveDiaryEntryWithPhotos(
          date: any(named: 'date'),
          title: any(named: 'title'),
          content: any(named: 'content'),
          photos: any(named: 'photos'),
        ),
      ).thenAnswer(
        (_) async => Success(
          IntegrationTestHelpers.createTestDiaryEntry(id: 'smoke-diary-id'),
        ),
      );
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

    test('単一写真から日記が生成・自動保存される', () async {
      final assets = IntegrationTestHelpers.createMockAssets(1);
      when(
        () => IntegrationTestHelpers.mockPhotoService.getImageForAi(any()),
      ).thenAnswer((_) async => Success(IntegrationTestHelpers.mockPngBytes));

      final controller = createController();
      addTearDown(controller.dispose);

      await controller.initializeAndGenerate(
        assets: assets,
        locale: const Locale('ja'),
      );

      expect(controller.hasError, isFalse);
      expect(controller.generatedTitle, isNotEmpty);
      expect(controller.generatedContent, isNotEmpty);
      expect(controller.savedDiaryId, equals('smoke-diary-id'));
      verify(
        () => IntegrationTestHelpers.mockAiService.generateDiaryFromImage(
          imageData: any(named: 'imageData'),
          date: any(named: 'date'),
          location: any(named: 'location'),
          photoTimes: any(named: 'photoTimes'),
          prompt: any(named: 'prompt'),
          contextText: any(named: 'contextText'),
          locale: any(named: 'locale'),
          diaryLength: any(named: 'diaryLength'),
        ),
      ).called(1);
    });

    test('写真画像取得失敗時に generationFailed エラーになる', () async {
      // getImageForAi のデフォルトが Failure を返すことを利用
      final assets = IntegrationTestHelpers.createMockAssets(1);
      final controller = createController();
      addTearDown(controller.dispose);

      await controller.initializeAndGenerate(
        assets: assets,
        locale: const Locale('ja'),
      );

      expect(controller.hasError, isTrue);
      expect(controller.errorType, DiaryPreviewErrorType.generationFailed);
    });

    test('AI ネットワークエラー時に generationFailed エラーになる', () async {
      final assets = IntegrationTestHelpers.createMockAssets(1);
      when(
        () => IntegrationTestHelpers.mockPhotoService.getImageForAi(any()),
      ).thenAnswer((_) async => Success(IntegrationTestHelpers.mockPngBytes));

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
        (_) async => const Failure(AiProcessingException('Network error')),
      );

      final controller = createController(aiMock: aiMock);
      addTearDown(controller.dispose);

      await controller.initializeAndGenerate(
        assets: assets,
        locale: const Locale('ja'),
      );

      expect(controller.hasError, isTrue);
      expect(controller.errorType, DiaryPreviewErrorType.generationFailed);
    });

    test('使用量上限エラー時に usageLimitReached が true になる', () async {
      final assets = IntegrationTestHelpers.createMockAssets(1);
      when(
        () => IntegrationTestHelpers.mockPhotoService.getImageForAi(any()),
      ).thenAnswer((_) async => Success(IntegrationTestHelpers.mockPngBytes));

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
        (_) async => const Failure(
          AiProcessingException(
            'Usage limit exceeded',
            isUsageLimitError: true,
          ),
        ),
      );

      final controller = createController(aiMock: aiMock);
      addTearDown(controller.dispose);

      await controller.initializeAndGenerate(
        assets: assets,
        locale: const Locale('ja'),
      );

      expect(controller.usageLimitReached, isTrue);
      expect(controller.hasError, isFalse);
    });

    test('写真なしで initializeAndGenerate を呼ぶと noPhotos エラーになる', () async {
      final controller = createController();
      addTearDown(controller.dispose);

      await controller.initializeAndGenerate(
        assets: [],
        locale: const Locale('ja'),
      );

      expect(controller.hasError, isTrue);
      expect(controller.errorType, DiaryPreviewErrorType.noPhotos);
    });
  });
}
