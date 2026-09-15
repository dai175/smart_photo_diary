import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/controllers/diary_preview_controller.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/models/diary_length.dart';
import 'package:smart_photo_diary/services/interfaces/ai_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/diary_crud_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/prompt_service_interface.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';

class MockLoggingService extends Mock implements ILoggingService {}

class MockAiService extends Mock implements IAiService {}

class MockPhotoService extends Mock implements IPhotoService {}

class MockDiaryCrudService extends Mock implements IDiaryCrudService {}

class MockPromptService extends Mock implements IPromptService {}

class MockAssetEntity extends Mock implements AssetEntity {}

void main() {
  late MockLoggingService mockLogger;
  late MockAiService mockAiService;
  late MockPhotoService mockPhotoService;
  late MockDiaryCrudService mockDiaryCrudService;
  late MockPromptService mockPromptService;

  setUp(() {
    mockLogger = MockLoggingService();
    mockAiService = MockAiService();
    mockPhotoService = MockPhotoService();
    mockDiaryCrudService = MockDiaryCrudService();
    mockPromptService = MockPromptService();
  });

  DiaryPreviewController createController() {
    return DiaryPreviewController(
      logger: mockLogger,
      photoService: mockPhotoService,
      aiService: mockAiService,
      diaryCrudService: mockDiaryCrudService,
      promptService: mockPromptService,
    );
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
        // getImageForAi で null を返してエラー終了させる
        final mockAsset = MockAssetEntity();
        when(() => mockAsset.createDateTime).thenReturn(DateTime(2025, 1, 15));
        when(() => mockPhotoService.getImageForAi(mockAsset)).thenAnswer(
          (_) async =>
              const Failure(PhotoAccessException('No AI image available')),
        );

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

    group('contextText の受け渡し', () {
      test('initializeAndGenerate に contextText を渡せる', () async {
        final controller = createController();
        addTearDown(controller.dispose);

        // 空アセットでエラー終了するが、contextText パラメータが受け付けられることを確認
        await controller.initializeAndGenerate(
          assets: [],
          contextText: '友達と花見',
          locale: const Locale('ja'),
        );

        expect(controller.isInitializing, isFalse);
        expect(controller.hasError, isTrue);
        expect(controller.errorType, DiaryPreviewErrorType.noPhotos);
      });
    });

    group('stale generation prevention', () {
      test('再生成が開始されたら古い生成結果は破棄される', () async {
        // First call: slow generation that fails with generationFailed
        final mockAsset1 = MockAssetEntity();
        when(() => mockAsset1.createDateTime).thenReturn(DateTime(2025, 1, 15));
        when(() => mockPhotoService.getImageForAi(mockAsset1)).thenAnswer((
          _,
        ) async {
          // Simulate slow AI processing
          await Future.delayed(const Duration(milliseconds: 100));
          return const Failure(PhotoAccessException('No AI image available'));
        });

        final controller = createController();
        addTearDown(controller.dispose);

        // Start first generation (slow, would result in generationFailed)
        final future1 = controller.initializeAndGenerate(
          assets: [mockAsset1],
          locale: const Locale('en'),
        );

        // Start second generation with empty assets (results in noPhotos)
        // This invalidates the first generation
        final future2 = controller.initializeAndGenerate(
          assets: [],
          locale: const Locale('en'),
        );

        await Future.wait([future1, future2]);

        // The error should reflect the second generation's result (noPhotos),
        // not the first (generationFailed)
        expect(controller.hasError, isTrue);
        expect(controller.errorType, DiaryPreviewErrorType.noPhotos);
      });
    });

    group('dispose', () {
      test('dispose で例外が発生しない', () {
        final controller = createController();
        expect(() => controller.dispose(), returnsNormally);
      });
    });

    group('cancel and usage recording', () {
      late MockAssetEntity mockAsset;

      DiaryEntry savedEntry() {
        final now = DateTime(2025, 1, 15);
        return DiaryEntry(
          id: 'saved-diary-id',
          date: now,
          title: 'Generated Title',
          content: 'Generated Content',
          photoIds: const ['photo-1'],
          createdAt: now,
          updatedAt: now,
        );
      }

      void stubLogger() {
        when(
          () => mockLogger.info(any(), context: any(named: 'context')),
        ).thenReturn(null);
        when(
          () => mockLogger.info(
            any(),
            context: any(named: 'context'),
            data: any(named: 'data'),
          ),
        ).thenReturn(null);
        when(
          () => mockLogger.warning(
            any(),
            context: any(named: 'context'),
            data: any(named: 'data'),
          ),
        ).thenReturn(null);
        when(
          () => mockLogger.error(
            any(),
            context: any(named: 'context'),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        ).thenReturn(null);
      }

      void stubSuccessfulGeneration() {
        when(() => mockAsset.createDateTime).thenReturn(DateTime(2025, 1, 15));
        when(
          () => mockPhotoService.getImageForAi(mockAsset),
        ).thenAnswer((_) async => Success(Uint8List.fromList([1, 2, 3])));
        when(
          () => mockAiService.generateDiaryFromImage(
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
          (_) async => Success(
            DiaryGenerationResult(
              title: 'Generated Title',
              content: 'Generated Content',
            ),
          ),
        );
        when(
          () => mockAiService.recordGenerationUsage(),
        ).thenAnswer((_) async => const Success(null));
        when(
          () => mockDiaryCrudService.saveDiaryEntryWithPhotos(
            date: any(named: 'date'),
            title: any(named: 'title'),
            content: any(named: 'content'),
            photos: any(named: 'photos'),
          ),
        ).thenAnswer((_) async => Success(savedEntry()));
      }

      setUp(() {
        mockAsset = MockAssetEntity();
        stubLogger();
        registerFallbackValue(Uint8List(0));
        registerFallbackValue(DateTime(2025, 1, 1));
        registerFallbackValue(const Locale('en'));
        registerFallbackValue(<AssetEntity>[]);
        registerFallbackValue(DiaryLength.standard);
      });

      test('dispose mid-flight does not auto-save or record usage', () async {
        final aiCompleter = Completer<Result<DiaryGenerationResult>>();
        var usageCount = 0;
        var saveCount = 0;
        when(() => mockAsset.createDateTime).thenReturn(DateTime(2025, 1, 15));
        when(
          () => mockPhotoService.getImageForAi(mockAsset),
        ).thenAnswer((_) async => Success(Uint8List.fromList([1, 2, 3])));
        when(
          () => mockAiService.generateDiaryFromImage(
            imageData: any(named: 'imageData'),
            date: any(named: 'date'),
            location: any(named: 'location'),
            photoTimes: any(named: 'photoTimes'),
            prompt: any(named: 'prompt'),
            contextText: any(named: 'contextText'),
            locale: any(named: 'locale'),
            diaryLength: any(named: 'diaryLength'),
          ),
        ).thenAnswer((_) => aiCompleter.future);
        when(() => mockAiService.recordGenerationUsage()).thenAnswer((_) async {
          usageCount++;
          return const Success(null);
        });
        when(
          () => mockDiaryCrudService.saveDiaryEntryWithPhotos(
            date: any(named: 'date'),
            title: any(named: 'title'),
            content: any(named: 'content'),
            photos: any(named: 'photos'),
          ),
        ).thenAnswer((_) async {
          saveCount++;
          return Success(savedEntry());
        });

        final controller = createController();

        final generateFuture = controller.initializeAndGenerate(
          assets: [mockAsset],
          locale: const Locale('en'),
        );

        await Future<void>.delayed(const Duration(milliseconds: 150));
        controller.dispose();

        aiCompleter.complete(
          Success(
            DiaryGenerationResult(
              title: 'Generated Title',
              content: 'Generated Content',
            ),
          ),
        );
        await generateFuture;

        expect(saveCount, 0);
        expect(usageCount, 0);
        expect(controller.savedDiaryId, isNull);
      });

      test('successful auto-save records usage once', () async {
        stubSuccessfulGeneration();
        var usageCount = 0;
        when(() => mockAiService.recordGenerationUsage()).thenAnswer((_) async {
          usageCount++;
          return const Success(null);
        });
        final controller = createController();
        addTearDown(controller.dispose);

        await controller.initializeAndGenerate(
          assets: [mockAsset],
          locale: const Locale('en'),
        );

        expect(controller.savedDiaryId, equals('saved-diary-id'));
        expect(controller.generatedTitle, equals('Generated Title'));
        expect(usageCount, 1);
      });

      test(
        'dispose after AI success before save still records usage',
        () async {
          final saveCompleter = Completer<Result<DiaryEntry>>();
          var usageCount = 0;
          var saveStarted = false;
          when(
            () => mockAsset.createDateTime,
          ).thenReturn(DateTime(2025, 1, 15));
          when(
            () => mockPhotoService.getImageForAi(mockAsset),
          ).thenAnswer((_) async => Success(Uint8List.fromList([1, 2, 3])));
          when(
            () => mockAiService.generateDiaryFromImage(
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
            (_) async => Success(
              DiaryGenerationResult(
                title: 'Generated Title',
                content: 'Generated Content',
              ),
            ),
          );
          when(() => mockAiService.recordGenerationUsage()).thenAnswer((
            _,
          ) async {
            usageCount++;
            return const Success(null);
          });
          when(
            () => mockDiaryCrudService.saveDiaryEntryWithPhotos(
              date: any(named: 'date'),
              title: any(named: 'title'),
              content: any(named: 'content'),
              photos: any(named: 'photos'),
            ),
          ).thenAnswer((_) {
            saveStarted = true;
            return saveCompleter.future;
          });

          final controller = createController();

          final generateFuture = controller.initializeAndGenerate(
            assets: [mockAsset],
            locale: const Locale('en'),
          );

          await Future<void>.delayed(const Duration(milliseconds: 150));
          expect(saveStarted, isTrue);

          controller.dispose();
          saveCompleter.complete(Success(savedEntry()));
          await generateFuture;

          expect(usageCount, 1);
          expect(controller.savedDiaryId, equals('saved-diary-id'));
        },
      );

      test(
        'dispose during post-save usage recording does not notify after dispose',
        () async {
          stubSuccessfulGeneration();
          final usageCompleter = Completer<Result<void>>();
          var usageStarted = false;
          var usageCount = 0;
          when(() => mockAiService.recordGenerationUsage()).thenAnswer((_) {
            usageStarted = true;
            usageCount++;
            return usageCompleter.future;
          });

          final controller = createController();
          final generateFuture = controller.initializeAndGenerate(
            assets: [mockAsset],
            locale: const Locale('en'),
          );

          await Future<void>.delayed(const Duration(milliseconds: 150));
          expect(usageStarted, isTrue);

          expect(() => controller.dispose(), returnsNormally);
          usageCompleter.complete(const Success(null));
          await generateFuture;

          expect(usageCount, 1);
          // Id is set without notifyListeners after dispose.
          expect(controller.savedDiaryId, equals('saved-diary-id'));
        },
      );
    });
  });
}
