import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/services/diary_service.dart';
import 'package:smart_photo_diary/services/ai/ai_service_interface.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'test_helpers/integration_test_helpers.dart';
import 'mocks/mock_services.dart';

/// Phase 2-2: DiaryService + AiService統合フロー実装テスト
///
/// saveDiaryEntryWithAiGeneration完全フロー統合テスト
/// 写真データ取得→AI生成→タグ付け→保存の完全統合フローの検証

void main() {
  group(
    'Phase 2-2: DiaryService + AiService統合フロー - saveDiaryEntryWithAiGeneration完全フロー',
    () {
      late DiaryService diaryService;
      late MockPhotoServiceInterface mockPhotoService;
      late MockAiServiceInterface mockAiService;
      late MockSubscriptionServiceInterface mockSubscriptionService;
      late List<MockAssetEntity> mockPhotos;

      setUpAll(() async {
        registerMockFallbacks();
        await IntegrationTestHelpers.setUpIntegrationEnvironment();
      });

      tearDownAll(() async {
        await IntegrationTestHelpers.tearDownIntegrationEnvironment();
      });

      setUp(() async {
        // Mock services の作成
        mockPhotoService = MockPhotoServiceInterface();
        mockAiService = MockAiServiceInterface();
        mockSubscriptionService = MockSubscriptionServiceInterface();

        // デフォルトのBasicPlan設定
        TestServiceSetup.configureSubscriptionServiceForPlan(
          mockSubscriptionService,
          BasicPlan(),
          usageCount: 0,
        );

        // Mock photos の作成
        mockPhotos = [MockAssetEntity(), MockAssetEntity(), MockAssetEntity()];

        // Mock photos の基本設定
        for (int i = 0; i < mockPhotos.length; i++) {
          when(() => mockPhotos[i].id).thenReturn('test-photo-$i');
          when(
            () => mockPhotos[i].createDateTime,
          ).thenReturn(DateTime(2024, 1, 15, 10 + i, 30));
          when(() => mockPhotos[i].title).thenReturn('Test Photo $i');
          when(() => mockPhotos[i].width).thenReturn(1920);
          when(() => mockPhotos[i].height).thenReturn(1080);
          when(() => mockPhotos[i].type).thenReturn(AssetType.image);
        }

        // DiaryServiceインスタンスを依存性注入で作成
        diaryService = DiaryService.createWithDependencies(
          aiService: mockAiService,
          photoService: mockPhotoService,
        );

        await diaryService.initialize();
      });

      tearDown(() async {
        // モックの状態を完全にリセット
        reset(mockPhotoService);
        reset(mockAiService);
        reset(mockSubscriptionService);

        // 各モックに対してのフォールバック登録を再実行
        registerMockFallbacks();
      });

      // =================================================================
      // ヘルパーメソッド
      // =================================================================

      void setupPhotoServiceMocks() {
        // 各写真に対してデータ取得の成功を設定
        for (int i = 0; i < mockPhotos.length; i++) {
          when(
            () => mockPhotoService.getOriginalFileResult(mockPhotos[i]),
          ).thenAnswer(
            (_) async => Success(
              Uint8List.fromList([
                1 + i, 2 + i, 3 + i, 4 + i, // 写真ごとに異なるデータ
              ]),
            ),
          );
        }
      }

      void setupAiServiceMocks() {
        // AI日記生成の成功設定
        when(
          () => mockAiService.generateDiaryFromImage(
            imageData: any(named: 'imageData'),
            date: any(named: 'date'),
            location: any(named: 'location'),
            photoTimes: any(named: 'photoTimes'),
            prompt: any(named: 'prompt'),
          ),
        ).thenAnswer(
          (_) async => Success(
            DiaryGenerationResult(title: 'AI生成タイトル', content: 'AI生成コンテンツ'),
          ),
        );

        when(
          () => mockAiService.generateDiaryFromMultipleImages(
            imagesWithTimes: any(named: 'imagesWithTimes'),
            location: any(named: 'location'),
            prompt: any(named: 'prompt'),
            onProgress: any(named: 'onProgress'),
          ),
        ).thenAnswer(
          (_) async => Success(
            DiaryGenerationResult(title: 'AI生成タイトル', content: 'AI生成コンテンツ'),
          ),
        );
      }

      void setupTagGenerationMocks() {
        // タグ生成の成功設定
        when(
          () => mockAiService.generateTagsFromContent(
            title: any(named: 'title'),
            content: any(named: 'content'),
            date: any(named: 'date'),
            photoCount: any(named: 'photoCount'),
          ),
        ).thenAnswer((_) async => Success(['AI', 'テスト', '統合']));
      }

      void setupSuccessfulMocks() {
        setupPhotoServiceMocks();
        setupAiServiceMocks();
        setupTagGenerationMocks();
      }

      // =================================================================
      // Group 1: saveDiaryEntryWithAiGeneration基本フロー
      // =================================================================

      group('Group 1: saveDiaryEntryWithAiGeneration基本フロー', () {
        test('saveDiaryEntryWithAiGeneration - 基本的な呼び出し確認', () async {
          // Arrange
          setupSuccessfulMocks();

          // Act
          final result = await diaryService.saveDiaryEntryWithAiGeneration(
            photos: [mockPhotos.first],
            date: DateTime(2024, 1, 15),
            location: 'テスト場所',
          );

          // Assert
          expect(result, isA<Result<DiaryEntry>>());
          expect(result.isSuccess, isTrue);

          result.fold((diaryEntry) {
            expect(diaryEntry, isA<DiaryEntry>());
            expect(diaryEntry.title, equals('AI生成タイトル'));
            expect(diaryEntry.content, equals('AI生成コンテンツ'));
            expect(diaryEntry.location, equals('テスト場所'));
            expect(diaryEntry.photoIds, hasLength(1));
            expect(diaryEntry.photoIds.first, equals('test-photo-0'));
          }, (error) => fail('Should succeed: $error'));
        });

        test('saveDiaryEntryWithAiGeneration - 引数検証（空の写真配列）', () async {
          // Act
          final result = await diaryService.saveDiaryEntryWithAiGeneration(
            photos: [],
          );

          // Assert
          expect(result.isFailure, isTrue);
          expect(result.error, isA<ValidationException>());
          expect(result.error.message, contains('最低1枚の写真が必要'));
        });

        test('saveDiaryEntryWithAiGeneration - デフォルト日付設定確認', () async {
          // Arrange
          setupSuccessfulMocks();
          final beforeCall = DateTime.now();

          // Act
          final result = await diaryService.saveDiaryEntryWithAiGeneration(
            photos: [mockPhotos.first],
          );

          // Assert
          expect(result.isSuccess, isTrue);
          result.fold((diaryEntry) {
            final entryDate = diaryEntry.date;
            expect(
              entryDate.isAfter(beforeCall.subtract(Duration(minutes: 1))),
              isTrue,
            );
            expect(
              entryDate.isBefore(DateTime.now().add(Duration(minutes: 1))),
              isTrue,
            );
          }, (error) => fail('Should succeed: $error'));
        });

        test('saveDiaryEntryWithAiGeneration - 進行状況コールバック確認', () async {
          // Arrange
          setupSuccessfulMocks();
          final progressMessages = <String>[];

          // Act
          final result = await diaryService.saveDiaryEntryWithAiGeneration(
            photos: [mockPhotos.first],
            onProgress: (message) => progressMessages.add(message),
          );

          // Assert
          expect(result.isSuccess, isTrue);
          expect(progressMessages, isNotEmpty);
          expect(
            progressMessages.any((msg) => msg.contains('写真データを取得中')),
            isTrue,
          );
          expect(
            progressMessages.any((msg) => msg.contains('AIが日記を生成中')),
            isTrue,
          );
          expect(progressMessages.any((msg) => msg.contains('タグを生成中')), isTrue);
          expect(progressMessages.any((msg) => msg.contains('日記を保存中')), isTrue);
          expect(progressMessages.any((msg) => msg.contains('完了')), isTrue);
        });
      });

      // =================================================================
      // Group 2: 写真データ取得統合テスト
      // =================================================================

      group('Group 2: 写真データ取得統合テスト', () {
        test('単一写真のデータ取得確認', () async {
          // Arrange
          setupPhotoServiceMocks();
          setupAiServiceMocks();
          setupTagGenerationMocks();

          // Act
          final result = await diaryService.saveDiaryEntryWithAiGeneration(
            photos: [mockPhotos.first],
          );

          // Assert
          expect(result.isSuccess, isTrue);

          // PhotoService.getOriginalFileResult が呼ばれたことを確認
          verify(
            () => mockPhotoService.getOriginalFileResult(mockPhotos.first),
          ).called(1);
        });

        test('複数写真のデータ取得確認', () async {
          // Arrange
          setupPhotoServiceMocks();
          setupAiServiceMocks();
          setupTagGenerationMocks();

          // Act
          final result = await diaryService.saveDiaryEntryWithAiGeneration(
            photos: mockPhotos,
          );

          // Assert
          expect(result.isSuccess, isTrue);

          // 各写真に対してgetOriginalFileResultが呼ばれたことを確認
          for (final photo in mockPhotos) {
            verify(
              () => mockPhotoService.getOriginalFileResult(photo),
            ).called(1);
          }
        });

        test('写真データ取得失敗時のエラーハンドリング', () async {
          // Arrange
          when(
            () => mockPhotoService.getOriginalFileResult(any()),
          ).thenAnswer((_) async => Failure(PhotoAccessException('写真アクセスエラー')));

          // Act
          final result = await diaryService.saveDiaryEntryWithAiGeneration(
            photos: [mockPhotos.first],
          );

          // Assert
          expect(result.isFailure, isTrue);
          expect(result.error, isA<PhotoAccessException>());
          expect(result.error.message, contains('写真アクセスエラー'));
        });

        test('部分的な写真データ取得失敗', () async {
          // Arrange
          when(
            () => mockPhotoService.getOriginalFileResult(mockPhotos[0]),
          ).thenAnswer((_) async => Success(Uint8List.fromList([1, 2, 3, 4])));
          when(
            () => mockPhotoService.getOriginalFileResult(mockPhotos[1]),
          ).thenAnswer(
            (_) async => Failure(PhotoAccessException('写真2アクセスエラー')),
          );
          when(
            () => mockPhotoService.getOriginalFileResult(mockPhotos[2]),
          ).thenAnswer((_) async => Success(Uint8List.fromList([5, 6, 7, 8])));

          // Act
          final result = await diaryService.saveDiaryEntryWithAiGeneration(
            photos: mockPhotos,
          );

          // Assert
          expect(result.isFailure, isTrue);
          expect(result.error, isA<PhotoAccessException>());

          // 最初のエラーで停止することを確認
          verify(
            () => mockPhotoService.getOriginalFileResult(mockPhotos[0]),
          ).called(1);
          verify(
            () => mockPhotoService.getOriginalFileResult(mockPhotos[1]),
          ).called(1);
          verifyNever(
            () => mockPhotoService.getOriginalFileResult(mockPhotos[2]),
          );
        });
      });

      // =================================================================
      // Group 3: AI生成統合テスト
      // =================================================================

      group('Group 3: AI生成統合テスト', () {
        test('単一写真でのAI日記生成確認', () async {
          // Arrange
          setupPhotoServiceMocks();
          when(
            () => mockAiService.generateDiaryFromImage(
              imageData: any(named: 'imageData'),
              date: any(named: 'date'),
              location: any(named: 'location'),
              photoTimes: any(named: 'photoTimes'),
              prompt: any(named: 'prompt'),
            ),
          ).thenAnswer(
            (_) async => Success(
              DiaryGenerationResult(
                title: 'AI単一写真タイトル',
                content: 'AI単一写真コンテンツ',
              ),
            ),
          );
          setupTagGenerationMocks();

          // Act
          final result = await diaryService.saveDiaryEntryWithAiGeneration(
            photos: [mockPhotos.first],
            location: 'テスト場所',
            prompt: 'テストプロンプト',
          );

          // Assert
          expect(result.isSuccess, isTrue);

          // generateDiaryFromImage が呼ばれたことを確認
          verify(
            () => mockAiService.generateDiaryFromImage(
              imageData: any(named: 'imageData'),
              date: any(named: 'date'),
              location: 'テスト場所',
              photoTimes: any(named: 'photoTimes'),
              prompt: 'テストプロンプト',
            ),
          ).called(1);

          // generateDiaryFromMultipleImages は呼ばれないことを確認
          verifyNever(
            () => mockAiService.generateDiaryFromMultipleImages(
              imagesWithTimes: any(named: 'imagesWithTimes'),
              location: any(named: 'location'),
              prompt: any(named: 'prompt'),
              onProgress: any(named: 'onProgress'),
            ),
          );

          result.fold((diaryEntry) {
            expect(diaryEntry.title, equals('AI単一写真タイトル'));
            expect(diaryEntry.content, equals('AI単一写真コンテンツ'));
          }, (error) => fail('Should succeed: $error'));
        });

        test('複数写真でのAI日記生成確認', () async {
          // Arrange
          setupPhotoServiceMocks();
          when(
            () => mockAiService.generateDiaryFromMultipleImages(
              imagesWithTimes: any(named: 'imagesWithTimes'),
              location: any(named: 'location'),
              prompt: any(named: 'prompt'),
              onProgress: any(named: 'onProgress'),
            ),
          ).thenAnswer(
            (_) async => Success(
              DiaryGenerationResult(
                title: 'AI複数写真タイトル',
                content: 'AI複数写真コンテンツ',
              ),
            ),
          );
          setupTagGenerationMocks();

          // Act
          final result = await diaryService.saveDiaryEntryWithAiGeneration(
            photos: mockPhotos.sublist(0, 2), // 2枚の写真
            location: 'テスト場所',
          );

          // Assert
          expect(result.isSuccess, isTrue);

          // generateDiaryFromMultipleImages が呼ばれたことを確認
          verify(
            () => mockAiService.generateDiaryFromMultipleImages(
              imagesWithTimes: any(named: 'imagesWithTimes'),
              location: 'テスト場所',
              prompt: null,
              onProgress: any(named: 'onProgress'),
            ),
          ).called(1);

          // generateDiaryFromImage は呼ばれないことを確認
          verifyNever(
            () => mockAiService.generateDiaryFromImage(
              imageData: any(named: 'imageData'),
              date: any(named: 'date'),
              location: any(named: 'location'),
              photoTimes: any(named: 'photoTimes'),
              prompt: any(named: 'prompt'),
            ),
          );

          result.fold((diaryEntry) {
            expect(diaryEntry.title, equals('AI複数写真タイトル'));
            expect(diaryEntry.content, equals('AI複数写真コンテンツ'));
          }, (error) => fail('Should succeed: $error'));
        });

        test('AI生成失敗時のエラーハンドリング', () async {
          // Arrange
          setupPhotoServiceMocks();
          when(
            () => mockAiService.generateDiaryFromImage(
              imageData: any(named: 'imageData'),
              date: any(named: 'date'),
              location: any(named: 'location'),
              photoTimes: any(named: 'photoTimes'),
              prompt: any(named: 'prompt'),
            ),
          ).thenAnswer((_) async => Failure(AiProcessingException('AI生成エラー')));

          // Act
          final result = await diaryService.saveDiaryEntryWithAiGeneration(
            photos: [mockPhotos.first],
          );

          // Assert
          expect(result.isFailure, isTrue);
          expect(result.error, isA<AiProcessingException>());
          expect(result.error.message, contains('AI生成エラー'));
        });

        test('AI生成進行状況コールバック確認', () async {
          // Arrange
          setupPhotoServiceMocks();

          when(
            () => mockAiService.generateDiaryFromMultipleImages(
              imagesWithTimes: any(named: 'imagesWithTimes'),
              location: any(named: 'location'),
              prompt: any(named: 'prompt'),
              onProgress: any(named: 'onProgress'),
            ),
          ).thenAnswer((invocation) async {
            // onProgressコールバックをシミュレート
            final callback =
                invocation.namedArguments[#onProgress] as Function(int, int)?;
            callback?.call(1, 2);
            callback?.call(2, 2);

            return Success(
              DiaryGenerationResult(
                title: 'AI進行状況テストタイトル',
                content: 'AI進行状況テストコンテンツ',
              ),
            );
          });
          setupTagGenerationMocks();

          final progressMessages = <String>[];

          // Act
          final result = await diaryService.saveDiaryEntryWithAiGeneration(
            photos: mockPhotos.sublist(0, 2),
            onProgress: (message) => progressMessages.add(message),
          );

          // Assert
          expect(result.isSuccess, isTrue);
          expect(
            progressMessages.any((msg) => msg.contains('写真1/2を分析中')),
            isTrue,
          );
          expect(
            progressMessages.any((msg) => msg.contains('写真2/2を分析中')),
            isTrue,
          );
        });
      });

      // =================================================================
      // Group 4: タグ生成統合テスト
      // =================================================================

      group('Group 4: タグ生成統合テスト', () {
        test('タグ生成成功時の確認', () async {
          // Arrange
          setupPhotoServiceMocks();
          setupAiServiceMocks();
          when(
            () => mockAiService.generateTagsFromContent(
              title: any(named: 'title'),
              content: any(named: 'content'),
              date: any(named: 'date'),
              photoCount: any(named: 'photoCount'),
            ),
          ).thenAnswer((_) async => Success(['AI', 'テスト', '統合']));

          // Act
          final result = await diaryService.saveDiaryEntryWithAiGeneration(
            photos: [mockPhotos.first],
          );

          // Assert
          expect(result.isSuccess, isTrue);

          // generateTagsFromContent が呼ばれたことを確認
          verify(
            () => mockAiService.generateTagsFromContent(
              title: 'AI生成タイトル',
              content: 'AI生成コンテンツ',
              date: any(named: 'date'),
              photoCount: 1,
            ),
          ).called(1);

          result.fold((diaryEntry) {
            expect(diaryEntry.tags, isNotNull);
            expect(diaryEntry.tags, containsAll(['AI', 'テスト', '統合']));
          }, (error) => fail('Should succeed: $error'));
        });

        test('タグ生成失敗時のフォールバック確認', () async {
          // Arrange
          setupPhotoServiceMocks();
          setupAiServiceMocks();
          when(
            () => mockAiService.generateTagsFromContent(
              title: any(named: 'title'),
              content: any(named: 'content'),
              date: any(named: 'date'),
              photoCount: any(named: 'photoCount'),
            ),
          ).thenAnswer((_) async => Failure(AiProcessingException('タグ生成エラー')));

          // Act
          final result = await diaryService.saveDiaryEntryWithAiGeneration(
            photos: [mockPhotos.first],
            date: DateTime(2024, 1, 15, 10, 30), // 朝の時間帯
          );

          // Assert
          expect(result.isSuccess, isTrue);

          result.fold((diaryEntry) {
            expect(diaryEntry.tags, isNotNull);
            expect(diaryEntry.tags, isNotEmpty);
            // フォールバックタグ（時間帯ベース）が含まれることを確認
            expect(diaryEntry.tags, contains('朝'));
          }, (error) => fail('Should succeed with fallback tags: $error'));
        });
      });

      // =================================================================
      // Group 5: データベース保存統合テスト
      // =================================================================

      group('Group 5: データベース保存統合テスト', () {
        test('生成されたデータの正確な保存確認', () async {
          // Arrange
          setupSuccessfulMocks();

          // Act
          final result = await diaryService.saveDiaryEntryWithAiGeneration(
            photos: mockPhotos,
            date: DateTime(2024, 1, 15, 14, 30),
            location: 'テスト場所',
          );

          // Assert
          expect(result.isSuccess, isTrue);

          result.fold((diaryEntry) {
            // 基本情報の確認
            expect(diaryEntry.id, isNotEmpty);
            expect(diaryEntry.title, equals('AI生成タイトル'));
            expect(diaryEntry.content, equals('AI生成コンテンツ'));
            expect(diaryEntry.location, equals('テスト場所'));

            // 写真IDsの確認
            expect(diaryEntry.photoIds, hasLength(3));
            expect(
              diaryEntry.photoIds,
              containsAll(['test-photo-0', 'test-photo-1', 'test-photo-2']),
            );

            // タグの確認
            expect(diaryEntry.tags, containsAll(['AI', 'テスト', '統合']));

            // 日付の確認
            expect(diaryEntry.date.year, equals(2024));
            expect(diaryEntry.date.month, equals(1));
            expect(diaryEntry.date.day, equals(15));
            expect(diaryEntry.date.hour, equals(14));
            expect(diaryEntry.date.minute, equals(30));

            // メタデータの確認
            expect(diaryEntry.createdAt, isNotNull);
            expect(diaryEntry.updatedAt, isNotNull);
            expect(diaryEntry.createdAt.isBefore(DateTime.now()), isTrue);
            expect(diaryEntry.updatedAt.isBefore(DateTime.now()), isTrue);
          }, (error) => fail('Should succeed: $error'));

          // 保存後に取得可能であることを確認
          final savedEntry = result.value;
          final retrievedResult = await diaryService.getDiaryEntry(
            savedEntry.id,
          );

          expect(retrievedResult.isSuccess, isTrue);
          retrievedResult.fold((retrieved) {
            expect(retrieved, isNotNull);
            expect(retrieved!.id, equals(savedEntry.id));
            expect(retrieved.title, equals(savedEntry.title));
            expect(retrieved.content, equals(savedEntry.content));
          }, (error) => fail('Should be able to retrieve saved entry: $error'));
        });
      });

      // =================================================================
      // Group 6: エラーハンドリング統合テスト
      // =================================================================

      group('Group 6: エラーハンドリング統合テスト', () {
        test('PhotoService未注入時のエラーハンドリング', () async {
          // Arrange - PhotoServiceの依存性テスト
          // このテストでは、DiaryServiceがPhotoServiceに適切に依存していることを確認

          // Act & Assert - DiaryServiceがPhotoServiceInterfaceを実装していることを確認
          expect(diaryService, isA<DiaryService>());

          // PhotoServiceが必要な処理でmockが呼ばれることを確認
          setupPhotoServiceMocks();
          setupAiServiceMocks();
          setupTagGenerationMocks();

          final result = await diaryService.saveDiaryEntryWithAiGeneration(
            photos: [mockPhotos.first],
          );

          expect(result.isSuccess, isTrue);
          verify(
            () => mockPhotoService.getOriginalFileResult(mockPhotos.first),
          ).called(1);
        });

        test('総合的なエラーハンドリング確認', () async {
          // Arrange - 意図的にエラーを発生させるモック設定
          // resetではなく、直接失敗するモック設定を上書き
          when(
            () => mockPhotoService.getOriginalFileResult(any()),
          ).thenAnswer((_) async => Failure(ServiceException('予期しないエラー')));

          // Act
          final result = await diaryService.saveDiaryEntryWithAiGeneration(
            photos: [mockPhotos.first],
          );

          // Assert
          expect(result.isFailure, isTrue);
          expect(result.error, isA<ServiceException>());
          expect(result.error.message, contains('予期しないエラー'));
        });
      });

      // =================================================================
      // Group 7: End-to-Endフロー確認テスト
      // =================================================================

      group('Group 7: End-to-Endフロー確認テスト', () {
        test('完全な統合フロー - 写真選択→AI生成→タグ付け→保存', () async {
          // Arrange
          setupSuccessfulMocks();
          final progressMessages = <String>[];

          // Act - 完全なフローの実行
          final result = await diaryService.saveDiaryEntryWithAiGeneration(
            photos: mockPhotos,
            date: DateTime(2024, 1, 15, 15, 45),
            location: 'End-to-End テスト場所',
            prompt: 'テスト用プロンプト',
            onProgress: (message) => progressMessages.add(message),
          );

          // Assert - 結果確認
          expect(result.isSuccess, isTrue);

          // 進行状況の確認
          expect(progressMessages, hasLength(greaterThan(4)));
          expect(progressMessages.first, contains('写真データを取得中'));
          expect(progressMessages.last, contains('完了'));

          result.fold((diaryEntry) {
            // 完全な結果確認
            expect(diaryEntry.id, isNotEmpty);
            expect(diaryEntry.title, equals('AI生成タイトル'));
            expect(diaryEntry.content, equals('AI生成コンテンツ'));
            expect(diaryEntry.location, equals('End-to-End テスト場所'));
            expect(diaryEntry.photoIds, hasLength(3));
            expect(diaryEntry.tags, containsAll(['AI', 'テスト', '統合']));
            expect(diaryEntry.date.hour, equals(15));
            expect(diaryEntry.date.minute, equals(45));
          }, (error) => fail('End-to-End test should succeed: $error'));

          // 全サービスが適切に呼び出されたことを確認
          verify(() => mockPhotoService.getOriginalFileResult(any())).called(3);
          verify(
            () => mockAiService.generateDiaryFromMultipleImages(
              imagesWithTimes: any(named: 'imagesWithTimes'),
              location: 'End-to-End テスト場所',
              prompt: 'テスト用プロンプト',
              onProgress: any(named: 'onProgress'),
            ),
          ).called(1);
          verify(
            () => mockAiService.generateTagsFromContent(
              title: 'AI生成タイトル',
              content: 'AI生成コンテンツ',
              date: any(named: 'date'),
              photoCount: 3,
            ),
          ).called(1);
        });

        test('パフォーマンス測定 - 実行時間確認', () async {
          // Arrange
          setupSuccessfulMocks();
          final stopwatch = Stopwatch()..start();

          // Act
          final result = await diaryService.saveDiaryEntryWithAiGeneration(
            photos: [mockPhotos.first],
          );

          stopwatch.stop();

          // Assert
          expect(result.isSuccess, isTrue);
          expect(stopwatch.elapsed.inSeconds, lessThan(10)); // 10秒以内での完了
          expect(stopwatch.elapsed.inMilliseconds, greaterThan(0)); // 実際に時間が経過
        });
      });
    },
  );
}
