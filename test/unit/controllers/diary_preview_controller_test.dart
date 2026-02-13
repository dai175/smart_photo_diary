import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/controllers/diary_preview_controller.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/services/ai/ai_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';

class MockLoggingService extends Mock implements ILoggingService {}

class MockAiService extends Mock implements IAiService {}

class MockPhotoService extends Mock implements IPhotoService {}

class MockAssetEntity extends Mock implements AssetEntity {}

void main() {
  late MockLoggingService mockLogger;
  late MockAiService mockAiService;
  late MockPhotoService mockPhotoService;

  setUp(() {
    ServiceLocator().clear();
    mockLogger = MockLoggingService();
    mockAiService = MockAiService();
    mockPhotoService = MockPhotoService();

    ServiceLocator().registerSingleton<ILoggingService>(mockLogger);
    ServiceLocator().registerSingleton<IAiService>(mockAiService);
    ServiceLocator().registerSingleton<IPhotoService>(mockPhotoService);
  });

  tearDown(() {
    ServiceLocator().clear();
  });

  DiaryPreviewController createController() {
    return DiaryPreviewController();
  }

  group('DiaryPreviewController', () {
    group('初期状態', () {
      test('初期状態は正しくセットされている', () {
        final controller = createController();
        addTearDown(controller.dispose);

        expect(controller.isInitializing, isTrue);
        expect(controller.isLoading, isFalse);
        expect(controller.isSaving, isFalse);
        expect(controller.isAnalyzingPhotos, isFalse);
        expect(controller.currentPhotoIndex, 0);
        expect(controller.totalPhotos, 0);
        expect(controller.selectedPrompt, isNull);
        expect(controller.generatedTitle, isEmpty);
        expect(controller.generatedContent, isEmpty);
        expect(controller.hasError, isFalse);
        expect(controller.errorType, isNull);
        expect(controller.savedDiaryId, isNull);
        expect(controller.usageLimitReached, isFalse);
      });
    });

    group('initializeAndGenerate', () {
      test('空アセットリストで noPhotos エラーになる', () async {
        final controller = createController();
        addTearDown(controller.dispose);

        await controller.initializeAndGenerate(
          assets: [],
          locale: const Locale('en'),
        );

        expect(controller.isInitializing, isFalse);
        expect(controller.hasError, isTrue);
        expect(controller.errorType, DiaryPreviewErrorType.noPhotos);
      });

      test('初期化後に isInitializing が false になる', () async {
        // getOriginalFile で null を返してエラー終了させる
        final mockAsset = MockAssetEntity();
        when(() => mockAsset.createDateTime).thenReturn(DateTime(2025, 1, 15));
        when(
          () => mockPhotoService.getOriginalFile(mockAsset),
        ).thenAnswer((_) async => null);

        final controller = createController();
        addTearDown(controller.dispose);

        await controller.initializeAndGenerate(
          assets: [mockAsset],
          locale: const Locale('en'),
        );

        expect(controller.isInitializing, isFalse);
      });
    });

    group('clearPrompt', () {
      test('プロンプトがクリアされる', () {
        final controller = createController();
        addTearDown(controller.dispose);

        int notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.clearPrompt();

        expect(controller.selectedPrompt, isNull);
        expect(notifyCount, 1);
      });
    });

    group('状態の整合性', () {
      test('エラー状態ではローディングが false になる', () async {
        final controller = createController();
        addTearDown(controller.dispose);

        await controller.initializeAndGenerate(
          assets: [],
          locale: const Locale('en'),
        );

        expect(controller.hasError, isTrue);
        expect(controller.isLoading, isFalse);
        expect(controller.isSaving, isFalse);
      });

      test('notifyListeners が呼ばれる', () async {
        final controller = createController();
        addTearDown(controller.dispose);

        int notifyCount = 0;
        controller.addListener(() => notifyCount++);

        await controller.initializeAndGenerate(
          assets: [],
          locale: const Locale('en'),
        );

        // 初期化完了 + エラー設定 で少なくとも2回以上通知
        expect(notifyCount, greaterThanOrEqualTo(2));
      });
    });

    group('dispose', () {
      test('dispose で例外が発生しない', () {
        final controller = createController();
        expect(() => controller.dispose(), returnsNormally);
      });
    });
  });
}
