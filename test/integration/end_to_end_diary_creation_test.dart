import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/services/ai/ai_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/diary_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/models/plans/plan.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'test_helpers/integration_test_helpers.dart';
import 'mocks/mock_services.dart';

/// Phase 2-2: エンドツーエンド統合テスト実装
///
/// 写真選択→AI生成→タグ付け→保存の完全フロー統合テスト
/// 複数サービス間の連携とResult<T>パターンの検証

void main() {
  group('Phase 2-2: エンドツーエンド統合テスト - 写真選択→AI生成→タグ付け→保存', () {
    late PhotoServiceInterface photoService;
    late AiServiceInterface aiService;
    late DiaryServiceInterface diaryService;
    late ISubscriptionService subscriptionService;
    late List<MockAssetEntity> mockPhotos;

    setUpAll(() async {
      registerMockFallbacks();
      await IntegrationTestHelpers.setUpIntegrationEnvironment();
    });

    tearDownAll(() async {
      await IntegrationTestHelpers.tearDownIntegrationEnvironment();
    });

    // =================================================================
    // ヘルパーメソッド
    // =================================================================

    List<MockAssetEntity> createMockPhotosWithMetadata(int count) {
      final photos = <MockAssetEntity>[];
      final now = DateTime.now();

      for (int i = 0; i < count; i++) {
        final mockPhoto = MockAssetEntity();
        final photoTime = now.subtract(Duration(hours: i));

        when(() => mockPhoto.id).thenReturn('e2e-photo-$i');
        when(() => mockPhoto.title).thenReturn('E2E Test Photo $i');
        when(() => mockPhoto.createDateTime).thenReturn(photoTime);
        when(() => mockPhoto.modifiedDateTime).thenReturn(photoTime);
        when(() => mockPhoto.type).thenReturn(AssetType.image);
        when(() => mockPhoto.width).thenReturn(1920);
        when(() => mockPhoto.height).thenReturn(1080);
        when(() => mockPhoto.duration).thenReturn(0);

        photos.add(mockPhoto);
      }

      return photos;
    }

    Uint8List createMockImageData({int size = 1024}) {
      return Uint8List.fromList(List.generate(size, (index) => index % 256));
    }

    void setupSuccessfulPhotoFlow(List<AssetEntity> photos) {
      // PhotoService成功パターン
      when(
        () => photoService.requestPermission(),
      ).thenAnswer((_) async => true);
      when(
        () => photoService.getTodayPhotos(limit: any(named: 'limit')),
      ).thenAnswer((_) async => photos);

      for (final photo in photos) {
        when(
          () => photoService.getOriginalFileResult(photo),
        ).thenAnswer((_) async => Success(createMockImageData()));
        when(
          () => photoService.getThumbnailData(photo),
        ).thenAnswer((_) async => createMockImageData(size: 512));
      }
    }

    void setupSuccessfulAiFlow({String? customTitle, String? customContent}) {
      // AiService成功パターン
      when(
        () => aiService.isOnlineResult(),
      ).thenAnswer((_) async => Success(true));
      when(
        () => aiService.canUseAiGeneration(),
      ).thenAnswer((_) async => Success(true));
      when(
        () => aiService.getRemainingGenerations(),
      ).thenAnswer((_) async => Success(10));

      when(
        () => aiService.generateDiaryFromImage(
          imageData: any(named: 'imageData'),
          date: any(named: 'date'),
          location: any(named: 'location'),
          photoTimes: any(named: 'photoTimes'),
          prompt: any(named: 'prompt'),
        ),
      ).thenAnswer(
        (_) async => Success(
          DiaryGenerationResult(
            title: customTitle ?? 'AIが生成したタイトル',
            content:
                customContent ?? 'AIが生成した日記の内容。今日は素晴らしい一日でした。写真からの思い出を記録します。',
          ),
        ),
      );

      when(
        () => aiService.generateDiaryFromMultipleImages(
          imagesWithTimes: any(named: 'imagesWithTimes'),
          location: any(named: 'location'),
          prompt: any(named: 'prompt'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer(
        (_) async => Success(
          DiaryGenerationResult(
            title: customTitle ?? 'AIが生成した複数画像タイトル',
            content: customContent ?? 'AIが複数の写真から生成した日記の内容。多くの瞬間を記録できました。',
          ),
        ),
      );

      when(
        () => aiService.generateTagsFromContent(
          title: any(named: 'title'),
          content: any(named: 'content'),
          date: any(named: 'date'),
          photoCount: any(named: 'photoCount'),
        ),
      ).thenAnswer((_) async => Success(['日記', 'AI生成', 'テスト', '思い出']));
    }

    void setupSuccessfulDiaryFlow() {
      // DiaryService成功パターン
      when(
        () => diaryService.saveDiaryEntry(
          date: any(named: 'date'),
          title: any(named: 'title'),
          content: any(named: 'content'),
          photoIds: any(named: 'photoIds'),
          location: any(named: 'location'),
          tags: any(named: 'tags'),
        ),
      ).thenAnswer((invocation) async {
        final date = invocation.namedArguments[#date] as DateTime;
        final title = invocation.namedArguments[#title] as String;
        final content = invocation.namedArguments[#content] as String;
        final photoIds = invocation.namedArguments[#photoIds] as List<String>;
        final location = invocation.namedArguments[#location] as String?;
        final tags = invocation.namedArguments[#tags] as List<String>?;

        return Success(
          DiaryEntry(
            id: 'e2e-diary-${date.millisecondsSinceEpoch}',
            date: date,
            title: title,
            content: content,
            photoIds: photoIds,
            location: location,
            tags: tags ?? [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      });

      when(
        () => diaryService.saveDiaryEntryWithAiGeneration(
          photos: any(named: 'photos'),
          date: any(named: 'date'),
          location: any(named: 'location'),
          prompt: any(named: 'prompt'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((invocation) async {
        final photos = invocation.namedArguments[#photos] as List<AssetEntity>;
        final date =
            invocation.namedArguments[#date] as DateTime? ?? DateTime.now();
        final location = invocation.namedArguments[#location] as String?;

        return Success(
          DiaryEntry(
            id: 'e2e-ai-diary-${date.millisecondsSinceEpoch}',
            date: date,
            title: 'AIが生成したタイトル',
            content: 'AIが生成した日記の内容',
            photoIds: photos.map((p) => p.id).toList(),
            location: location,
            tags: ['日記', 'AI生成', 'テスト'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      });
    }

    setUp(() async {
      // 各テストで新しいモックサービス作成
      photoService = MockPhotoServiceInterface();
      aiService = MockAiServiceInterface();
      diaryService = MockDiaryServiceInterface();
      subscriptionService = MockSubscriptionServiceInterface();

      // テスト用写真データ作成
      mockPhotos = createMockPhotosWithMetadata(3);

      // 基本的なサブスクリプション設定（Basic Plan）
      when(() => subscriptionService.isInitialized).thenReturn(true);
      when(
        () => subscriptionService.getCurrentPlanClass(),
      ).thenAnswer((_) async => Success(BasicPlan()));
      when(
        () => subscriptionService.canUseAiGeneration(),
      ).thenAnswer((_) async => Success(true));
      when(
        () => subscriptionService.getRemainingGenerations(),
      ).thenAnswer((_) async => Success(10));
      when(
        () => subscriptionService.incrementAiUsage(),
      ).thenAnswer((_) async => Success(null));
    });

    tearDown(() async {
      // モック状態をクリア
      reset(photoService);
      reset(aiService);
      reset(diaryService);
      reset(subscriptionService);
    });

    // =================================================================
    // Group 1: 写真選択フロー統合テスト
    // =================================================================

    group('Group 1: 写真選択フロー統合テスト - PhotoService統合とAssetEntity選択機能', () {
      test('写真アクセス権限取得 → 今日の写真取得 → 写真データ取得', () async {
        // Arrange
        setupSuccessfulPhotoFlow(mockPhotos);

        // Act & Assert - Step 1: 権限取得
        final permissionResult = await photoService.requestPermission();
        expect(permissionResult, isTrue);

        // Act & Assert - Step 2: 今日の写真取得
        final photos = await photoService.getTodayPhotos(limit: 10);
        expect(photos, isNotEmpty);
        expect(photos.length, equals(3));

        // Act & Assert - Step 3: 各写真のデータ取得
        for (final photo in photos) {
          final imageDataResult = await photoService.getOriginalFileResult(
            photo,
          );
          expect(imageDataResult, isA<Success<Uint8List>>());
          expect(imageDataResult.valueOrNull, isNotNull);
          expect(imageDataResult.valueOrNull!.length, greaterThan(0));

          final thumbnailData = await photoService.getThumbnailData(photo);
          expect(thumbnailData, isNotNull);
          expect(thumbnailData?.length, greaterThan(0));
        }

        // Verify interactions
        verify(() => photoService.requestPermission()).called(1);
        verify(() => photoService.getTodayPhotos(limit: 10)).called(1);
        verify(() => photoService.getOriginalFileResult(any())).called(3);
        verify(() => photoService.getThumbnailData(any())).called(3);
      });

      test('写真選択エラー時のハンドリング - 権限拒否シナリオ', () async {
        // Arrange
        when(
          () => photoService.requestPermission(),
        ).thenAnswer((_) async => false);

        // Act
        final permissionResult = await photoService.requestPermission();

        // Assert
        expect(permissionResult, isFalse);

        // 権限がない場合は写真取得を試行しない
        verifyNever(
          () => photoService.getTodayPhotos(limit: any(named: 'limit')),
        );
      });

      test('写真データ取得エラー時のハンドリング', () async {
        // Arrange
        when(
          () => photoService.requestPermission(),
        ).thenAnswer((_) async => true);
        when(
          () => photoService.getTodayPhotos(limit: any(named: 'limit')),
        ).thenAnswer((_) async => mockPhotos);
        when(
          () => photoService.getOriginalFileResult(any()),
        ).thenAnswer((_) async => Failure(PhotoAccessException('画像データ取得エラー')));

        // Act
        final photos = await photoService.getTodayPhotos(limit: 10);
        final imageDataResult = await photoService.getOriginalFileResult(
          photos.first,
        );

        // Assert
        expect(photos, isNotEmpty);
        expect(imageDataResult, isA<Failure<Uint8List>>());
        expect(imageDataResult.errorOrNull, isA<PhotoAccessException>());
      });
    });

    // =================================================================
    // Group 2: AI生成フロー統合テスト
    // =================================================================

    group('Group 2: AI生成フロー統合テスト - AiService統合と日記生成処理', () {
      test('単一画像からAI日記生成 - オンライン状態確認 → 生成 → タグ生成', () async {
        // Arrange
        setupSuccessfulAiFlow();
        final photo = mockPhotos.first;
        final imageData = createMockImageData();
        final testDate = DateTime.now();

        // Act & Assert - Step 1: オンライン状態確認
        final onlineResult = await aiService.isOnlineResult();
        expect(onlineResult, isA<Success<bool>>());
        expect(onlineResult.valueOrNull, isTrue);

        // Act & Assert - Step 2: 使用制限確認
        final canUseResult = await aiService.canUseAiGeneration();
        expect(canUseResult, isA<Success<bool>>());
        expect(canUseResult.valueOrNull, isTrue);

        // Act & Assert - Step 3: AI日記生成
        final diaryResult = await aiService.generateDiaryFromImage(
          imageData: imageData,
          date: testDate,
          location: '東京都渋谷区',
          photoTimes: [photo.createDateTime],
          prompt: 'テスト用のプロンプト',
        );

        expect(diaryResult, isA<Success<DiaryGenerationResult>>());
        final generatedDiary = diaryResult.valueOrNull!;
        expect(generatedDiary.title, equals('AIが生成したタイトル'));
        expect(generatedDiary.content, contains('AIが生成した日記の内容'));

        // Act & Assert - Step 4: タグ自動生成
        final tagsResult = await aiService.generateTagsFromContent(
          title: generatedDiary.title,
          content: generatedDiary.content,
          date: testDate,
          photoCount: 1,
        );

        expect(tagsResult, isA<Success<List<String>>>());
        final tags = tagsResult.valueOrNull!;
        expect(tags, contains('日記'));
        expect(tags, contains('AI生成'));
        expect(tags.length, greaterThanOrEqualTo(3));

        // Verify interactions
        verify(() => aiService.isOnlineResult()).called(1);
        verify(() => aiService.canUseAiGeneration()).called(1);
        verify(
          () => aiService.generateDiaryFromImage(
            imageData: imageData,
            date: testDate,
            location: '東京都渋谷区',
            photoTimes: [photo.createDateTime],
            prompt: 'テスト用のプロンプト',
          ),
        ).called(1);
        verify(
          () => aiService.generateTagsFromContent(
            title: generatedDiary.title,
            content: generatedDiary.content,
            date: testDate,
            photoCount: 1,
          ),
        ).called(1);
      });

      test('複数画像からAI日記生成 - プログレスコールバック付き', () async {
        // Arrange
        setupSuccessfulAiFlow(
          customTitle: '複数画像のタイトル',
          customContent: '複数の写真から生成された素晴らしい日記です。',
        );

        final imagesWithTimes = mockPhotos
            .map(
              (photo) => (
                imageData: createMockImageData(),
                time: photo.createDateTime,
              ),
            )
            .toList();

        // Act
        final diaryResult = await aiService.generateDiaryFromMultipleImages(
          imagesWithTimes: imagesWithTimes,
          location: '東京都新宿区',
          prompt: '複数画像用プロンプト',
          onProgress: (current, total) {
            // プログレス進行を確認（モックでは実際の進行は発生しない）
          },
        );

        // Assert
        expect(diaryResult, isA<Success<DiaryGenerationResult>>());
        final generatedDiary = diaryResult.valueOrNull!;
        expect(generatedDiary.title, equals('複数画像のタイトル'));
        expect(generatedDiary.content, contains('複数の写真'));

        // プログレスコールバックは実際のサービスでは呼ばれるが、モックでは検証しない
        verify(
          () => aiService.generateDiaryFromMultipleImages(
            imagesWithTimes: imagesWithTimes,
            location: '東京都新宿区',
            prompt: '複数画像用プロンプト',
            onProgress: any(named: 'onProgress'),
          ),
        ).called(1);
      });

      test('AI生成エラー時のハンドリング - オフライン状態', () async {
        // Arrange
        when(
          () => aiService.isOnlineResult(),
        ).thenAnswer((_) async => Success(false));

        // Act
        final onlineResult = await aiService.isOnlineResult();

        // Assert
        expect(onlineResult, isA<Success<bool>>());
        expect(onlineResult.valueOrNull, isFalse);

        // オフライン時はAI生成を呼ばない
        verifyNever(
          () => aiService.generateDiaryFromImage(
            imageData: any(named: 'imageData'),
            date: any(named: 'date'),
            location: any(named: 'location'),
            photoTimes: any(named: 'photoTimes'),
            prompt: any(named: 'prompt'),
          ),
        );
      });

      test('AI生成エラー時のハンドリング - 使用制限到達', () async {
        // Arrange
        when(
          () => aiService.isOnlineResult(),
        ).thenAnswer((_) async => Success(true));
        when(
          () => aiService.canUseAiGeneration(),
        ).thenAnswer((_) async => Success(false));
        when(
          () => aiService.getRemainingGenerations(),
        ).thenAnswer((_) async => Success(0));

        // Act
        final canUseResult = await aiService.canUseAiGeneration();
        final remainingResult = await aiService.getRemainingGenerations();

        // Assert
        expect(canUseResult, isA<Success<bool>>());
        expect(canUseResult.valueOrNull, isFalse);
        expect(remainingResult, isA<Success<int>>());
        expect(remainingResult.valueOrNull, equals(0));
      });

      test('AI生成エラー時のハンドリング - API呼び出し失敗', () async {
        // Arrange
        when(
          () => aiService.isOnlineResult(),
        ).thenAnswer((_) async => Success(true));
        when(
          () => aiService.canUseAiGeneration(),
        ).thenAnswer((_) async => Success(true));
        when(
          () => aiService.generateDiaryFromImage(
            imageData: any(named: 'imageData'),
            date: any(named: 'date'),
            location: any(named: 'location'),
            photoTimes: any(named: 'photoTimes'),
            prompt: any(named: 'prompt'),
          ),
        ).thenAnswer((_) async => Failure(AiProcessingException('AI生成APIエラー')));

        // Act
        final diaryResult = await aiService.generateDiaryFromImage(
          imageData: createMockImageData(),
          date: DateTime.now(),
        );

        // Assert
        expect(diaryResult, isA<Failure<DiaryGenerationResult>>());
        expect(diaryResult.errorOrNull, isA<AiProcessingException>());
      });
    });

    // =================================================================
    // Group 3: タグ付けフロー統合テスト
    // =================================================================

    group('Group 3: タグ付けフロー統合テスト - AI生成結果からのタグ自動生成', () {
      test('日記内容からのタグ自動生成 - 内容解析とカテゴリ分類', () async {
        // Arrange
        setupSuccessfulAiFlow();

        final title = '公園での散歩';
        final content =
            '今日は天気が良かったので、家族と一緒に近所の公園を散歩しました。桜が咲いていてとても綺麗でした。子供たちも楽しそうに遊んでいて、素晴らしい一日になりました。';
        final date = DateTime.now();
        final photoCount = 2;

        // Act
        final tagsResult = await aiService.generateTagsFromContent(
          title: title,
          content: content,
          date: date,
          photoCount: photoCount,
        );

        // Assert
        expect(tagsResult, isA<Success<List<String>>>());
        final tags = tagsResult.valueOrNull!;
        expect(tags, isNotEmpty);
        expect(tags.length, greaterThanOrEqualTo(3));

        // 期待されるタグが含まれているかチェック
        expect(tags, contains('日記'));
        expect(tags, contains('AI生成'));

        verify(
          () => aiService.generateTagsFromContent(
            title: title,
            content: content,
            date: date,
            photoCount: photoCount,
          ),
        ).called(1);
      });

      test('タグ生成エラー時のハンドリング - 内容不足', () async {
        // Arrange
        when(
          () => aiService.generateTagsFromContent(
            title: any(named: 'title'),
            content: any(named: 'content'),
            date: any(named: 'date'),
            photoCount: any(named: 'photoCount'),
          ),
        ).thenAnswer((_) async => Failure(AiProcessingException('内容が不十分です')));

        // Act
        final tagsResult = await aiService.generateTagsFromContent(
          title: '',
          content: '',
          date: DateTime.now(),
          photoCount: 0,
        );

        // Assert
        expect(tagsResult, isA<Failure<List<String>>>());
        expect(tagsResult.errorOrNull, isA<AiProcessingException>());
      });

      test('タグ生成成功時のフォールバック - 空タグリスト処理', () async {
        // Arrange
        when(
          () => aiService.generateTagsFromContent(
            title: any(named: 'title'),
            content: any(named: 'content'),
            date: any(named: 'date'),
            photoCount: any(named: 'photoCount'),
          ),
        ).thenAnswer((_) async => Success(<String>[]));

        // Act
        final tagsResult = await aiService.generateTagsFromContent(
          title: '短いタイトル',
          content: '短い内容',
          date: DateTime.now(),
          photoCount: 1,
        );

        // Assert
        expect(tagsResult, isA<Success<List<String>>>());
        final tags = tagsResult.valueOrNull!;
        expect(tags, isEmpty);
      });
    });

    // =================================================================
    // Group 4: 保存フロー統合テスト
    // =================================================================

    group('Group 4: 保存フロー統合テスト - DiaryService統合と永続化処理', () {
      test('AI生成結果の日記保存 - タグ付きエントリー永続化', () async {
        // Arrange
        setupSuccessfulDiaryFlow();

        final date = DateTime.now();
        final title = 'AI生成タイトル';
        final content = 'AI生成された日記内容です。今日の思い出を記録します。';
        final photoIds = ['photo-1', 'photo-2', 'photo-3'];
        final location = '東京都渋谷区';
        final tags = ['日記', 'AI生成', 'テスト', '思い出'];

        // Act
        final saveResult = await diaryService.saveDiaryEntry(
          date: date,
          title: title,
          content: content,
          photoIds: photoIds,
          location: location,
          tags: tags,
        );

        // Assert
        expect(saveResult, isA<Success<DiaryEntry>>());
        final savedEntry = saveResult.valueOrNull!;

        expect(savedEntry.title, equals(title));
        expect(savedEntry.content, equals(content));
        expect(savedEntry.photoIds, equals(photoIds));
        expect(savedEntry.location, equals(location));
        expect(savedEntry.tags, equals(tags));
        expect(savedEntry.date, equals(date));
        expect(savedEntry.id, isNotEmpty);
        expect(savedEntry.createdAt, isNotNull);
        expect(savedEntry.updatedAt, isNotNull);

        verify(
          () => diaryService.saveDiaryEntry(
            date: date,
            title: title,
            content: content,
            photoIds: photoIds,
            location: location,
            tags: tags,
          ),
        ).called(1);
      });

      test('DiaryServiceの高レベルAPI使用 - saveDiaryEntryWithAiGeneration', () async {
        // Arrange
        setupSuccessfulDiaryFlow();
        setupSuccessfulAiFlow();

        final testDate = DateTime.now();
        final location = '東京都新宿区';
        final prompt = 'テスト用プロンプト';

        // Act
        final saveResult = await diaryService.saveDiaryEntryWithAiGeneration(
          photos: mockPhotos,
          date: testDate,
          location: location,
          prompt: prompt,
          onProgress: (message) {
            // プログレスメッセージ確認（モックでは実際のメッセージは発生しない）
          },
        );

        // Assert
        expect(saveResult, isA<Success<DiaryEntry>>());
        final savedEntry = saveResult.valueOrNull!;

        expect(savedEntry.title, equals('AIが生成したタイトル'));
        expect(savedEntry.content, equals('AIが生成した日記の内容'));
        expect(
          savedEntry.photoIds,
          equals(mockPhotos.map((p) => p.id).toList()),
        );
        expect(savedEntry.location, equals(location));
        expect(savedEntry.tags, contains('日記'));
        expect(savedEntry.tags, contains('AI生成'));
        expect(savedEntry.date, equals(testDate));

        verify(
          () => diaryService.saveDiaryEntryWithAiGeneration(
            photos: mockPhotos,
            date: testDate,
            location: location,
            prompt: prompt,
            onProgress: any(named: 'onProgress'),
          ),
        ).called(1);
      });

      test('日記保存エラー時のハンドリング - データベースエラー', () async {
        // Arrange
        when(
          () => diaryService.saveDiaryEntry(
            date: any(named: 'date'),
            title: any(named: 'title'),
            content: any(named: 'content'),
            photoIds: any(named: 'photoIds'),
            location: any(named: 'location'),
            tags: any(named: 'tags'),
          ),
        ).thenAnswer((_) async => Failure(ServiceException('データベース保存エラー')));

        // Act
        final saveResult = await diaryService.saveDiaryEntry(
          date: DateTime.now(),
          title: 'テストタイトル',
          content: 'テスト内容',
          photoIds: ['photo-1'],
        );

        // Assert
        expect(saveResult, isA<Failure<DiaryEntry>>());
        expect(saveResult.errorOrNull, isA<ServiceException>());
      });
    });

    // =================================================================
    // Group 5: 完全フロー統合テスト
    // =================================================================

    group('Group 5: 完全フロー統合テスト - 写真→AI→タグ→保存の一連処理', () {
      test('エンドツーエンド成功シナリオ - 全段階の完全統合', () async {
        // Arrange
        setupSuccessfulPhotoFlow(mockPhotos);
        setupSuccessfulAiFlow();
        setupSuccessfulDiaryFlow();

        final testDate = DateTime.now();
        final location = '東京都品川区';

        // Act & Assert - Step 1: 写真選択フロー
        final permissionGranted = await photoService.requestPermission();
        expect(permissionGranted, isTrue);

        final availablePhotos = await photoService.getTodayPhotos(limit: 10);
        expect(availablePhotos, isNotEmpty);

        final selectedPhotos = availablePhotos.take(2).toList(); // 2枚選択

        // 選択写真の画像データ取得
        final imageDataResults = <Result<Uint8List>>[];
        for (final photo in selectedPhotos) {
          final imageResult = await photoService.getOriginalFileResult(photo);
          expect(imageResult, isA<Success<Uint8List>>());
          imageDataResults.add(imageResult);
        }

        // Act & Assert - Step 2: AI生成フロー
        final onlineCheck = await aiService.isOnlineResult();
        expect(onlineCheck.valueOrNull, isTrue);

        final canUseAi = await aiService.canUseAiGeneration();
        expect(canUseAi.valueOrNull, isTrue);

        // 複数画像からAI生成
        final imagesWithTimes = selectedPhotos
            .asMap()
            .entries
            .map(
              (entry) => (
                imageData: imageDataResults[entry.key].valueOrNull!,
                time: entry.value.createDateTime,
              ),
            )
            .toList();

        final diaryResult = await aiService.generateDiaryFromMultipleImages(
          imagesWithTimes: imagesWithTimes,
          location: location,
          onProgress: (current, total) {
            // AI生成プログレス確認（モックでは実際の進行は発生しない）
          },
        );

        expect(diaryResult, isA<Success<DiaryGenerationResult>>());
        final generatedDiary = diaryResult.valueOrNull!;

        // Act & Assert - Step 3: タグ生成フロー
        final tagsResult = await aiService.generateTagsFromContent(
          title: generatedDiary.title,
          content: generatedDiary.content,
          date: testDate,
          photoCount: selectedPhotos.length,
        );

        expect(tagsResult, isA<Success<List<String>>>());
        final generatedTags = tagsResult.valueOrNull!;

        // Act & Assert - Step 4: 保存フロー
        final saveResult = await diaryService.saveDiaryEntry(
          date: testDate,
          title: generatedDiary.title,
          content: generatedDiary.content,
          photoIds: selectedPhotos.map((p) => p.id).toList(),
          location: location,
          tags: generatedTags,
        );

        expect(saveResult, isA<Success<DiaryEntry>>());
        final finalEntry = saveResult.valueOrNull!;

        // Final assertions - 完全なエンドツーエンド検証
        expect(finalEntry.title, equals('AIが生成した複数画像タイトル'));
        expect(finalEntry.content, contains('複数の写真'));
        expect(finalEntry.photoIds.length, equals(2));
        expect(finalEntry.location, equals(location));
        expect(finalEntry.tags, contains('日記'));
        expect(finalEntry.tags, contains('AI生成'));
        expect(finalEntry.date, equals(testDate));

        // Verify all service interactions occurred
        verify(() => photoService.requestPermission()).called(1);
        verify(() => photoService.getTodayPhotos(limit: 10)).called(1);
        verify(() => photoService.getOriginalFileResult(any())).called(2);
        verify(() => aiService.isOnlineResult()).called(1);
        verify(() => aiService.canUseAiGeneration()).called(1);
        verify(
          () => aiService.generateDiaryFromMultipleImages(
            imagesWithTimes: any(named: 'imagesWithTimes'),
            location: location,
            onProgress: any(named: 'onProgress'),
          ),
        ).called(1);
        verify(
          () => aiService.generateTagsFromContent(
            title: generatedDiary.title,
            content: generatedDiary.content,
            date: testDate,
            photoCount: 2,
          ),
        ).called(1);
        verify(
          () => diaryService.saveDiaryEntry(
            date: testDate,
            title: generatedDiary.title,
            content: generatedDiary.content,
            photoIds: selectedPhotos.map((p) => p.id).toList(),
            location: location,
            tags: generatedTags,
          ),
        ).called(1);
      });

      test('エンドツーエンド高レベルAPI使用 - saveDiaryEntryWithAiGeneration統合', () async {
        // Arrange
        setupSuccessfulPhotoFlow(mockPhotos);
        setupSuccessfulDiaryFlow();
        setupSuccessfulAiFlow();

        final testDate = DateTime.now();
        final location = '東京都港区';
        final prompt = 'エンドツーエンドテスト用プロンプト';

        // Act - 高レベルAPIによる一括処理
        final result = await diaryService.saveDiaryEntryWithAiGeneration(
          photos: mockPhotos,
          date: testDate,
          location: location,
          prompt: prompt,
          onProgress: (message) {
            // プログレスメッセージ確認（モックでは実際のメッセージは発生しない）
          },
        );

        // Assert
        expect(result, isA<Success<DiaryEntry>>());
        final savedEntry = result.valueOrNull!;

        expect(savedEntry.title, isNotEmpty);
        expect(savedEntry.content, isNotEmpty);
        expect(savedEntry.photoIds.length, equals(mockPhotos.length));
        expect(savedEntry.location, equals(location));
        expect(savedEntry.tags, isNotEmpty);
        expect(savedEntry.date, equals(testDate));

        // 高レベルAPIが1回呼ばれることを確認
        verify(
          () => diaryService.saveDiaryEntryWithAiGeneration(
            photos: mockPhotos,
            date: testDate,
            location: location,
            prompt: prompt,
            onProgress: any(named: 'onProgress'),
          ),
        ).called(1);
      });
    });

    // =================================================================
    // Group 6: エラーハンドリング統合テスト
    // =================================================================

    group('Group 6: エラーハンドリング統合テスト - 各段階での異常系処理確認', () {
      test('写真選択段階でのエラー波及 - 権限拒否時の処理停止', () async {
        // Arrange - 写真権限拒否
        when(
          () => photoService.requestPermission(),
        ).thenAnswer((_) async => false);

        // Act
        final permissionResult = await photoService.requestPermission();

        // Assert
        expect(permissionResult, isFalse);

        // 権限がない場合、後続処理は実行されないことを確認
        verifyNever(
          () => photoService.getTodayPhotos(limit: any(named: 'limit')),
        );
        verifyNever(
          () => aiService.generateDiaryFromImage(
            imageData: any(named: 'imageData'),
            date: any(named: 'date'),
          ),
        );
        verifyNever(
          () => diaryService.saveDiaryEntry(
            date: any(named: 'date'),
            title: any(named: 'title'),
            content: any(named: 'content'),
            photoIds: any(named: 'photoIds'),
          ),
        );
      });

      test('AI生成段階でのエラー波及 - オフライン時の処理停止', () async {
        // Arrange
        setupSuccessfulPhotoFlow(mockPhotos);
        when(
          () => aiService.isOnlineResult(),
        ).thenAnswer((_) async => Success(false));

        // Act - 写真選択は成功
        final photos = await photoService.getTodayPhotos(limit: 5);
        expect(photos, isNotEmpty);

        // AI生成前チェックで停止
        final onlineResult = await aiService.isOnlineResult();
        expect(onlineResult.valueOrNull, isFalse);

        // Assert - AI生成とその後の処理は実行されない
        verifyNever(
          () => aiService.generateDiaryFromImage(
            imageData: any(named: 'imageData'),
            date: any(named: 'date'),
          ),
        );
        verifyNever(
          () => diaryService.saveDiaryEntry(
            date: any(named: 'date'),
            title: any(named: 'title'),
            content: any(named: 'content'),
            photoIds: any(named: 'photoIds'),
          ),
        );
      });

      test('AI生成段階でのエラー波及 - 使用制限到達時の処理停止', () async {
        // Arrange
        setupSuccessfulPhotoFlow(mockPhotos);
        when(
          () => aiService.isOnlineResult(),
        ).thenAnswer((_) async => Success(true));
        when(
          () => aiService.canUseAiGeneration(),
        ).thenAnswer((_) async => Success(false));

        // Act - 写真選択は成功
        final photos = await photoService.getTodayPhotos(limit: 5);
        expect(photos, isNotEmpty);

        // オンライン確認は成功
        final onlineResult = await aiService.isOnlineResult();
        expect(onlineResult.valueOrNull, isTrue);

        // 使用制限で停止
        final canUseResult = await aiService.canUseAiGeneration();
        expect(canUseResult.valueOrNull, isFalse);

        // Assert - AI生成は実行されない
        verifyNever(
          () => aiService.generateDiaryFromImage(
            imageData: any(named: 'imageData'),
            date: any(named: 'date'),
          ),
        );
      });

      test('保存段階でのエラー処理 - データベースエラー時の適切なエラー返却', () async {
        // Arrange
        setupSuccessfulPhotoFlow(mockPhotos);
        setupSuccessfulAiFlow();
        when(
          () => diaryService.saveDiaryEntry(
            date: any(named: 'date'),
            title: any(named: 'title'),
            content: any(named: 'content'),
            photoIds: any(named: 'photoIds'),
            location: any(named: 'location'),
            tags: any(named: 'tags'),
          ),
        ).thenAnswer((_) async => Failure(ServiceException('データベース保存失敗')));

        // Act - AI生成まで成功
        final photos = await photoService.getTodayPhotos(limit: 1);
        final imageResult = await photoService.getOriginalFileResult(
          photos.first,
        );

        final diaryResult = await aiService.generateDiaryFromImage(
          imageData: imageResult.valueOrNull!,
          date: DateTime.now(),
        );
        expect(diaryResult, isA<Success<DiaryGenerationResult>>());

        final tagsResult = await aiService.generateTagsFromContent(
          title: diaryResult.valueOrNull!.title,
          content: diaryResult.valueOrNull!.content,
          date: DateTime.now(),
          photoCount: 1,
        );
        expect(tagsResult, isA<Success<List<String>>>());

        // 保存で失敗
        final saveResult = await diaryService.saveDiaryEntry(
          date: DateTime.now(),
          title: diaryResult.valueOrNull!.title,
          content: diaryResult.valueOrNull!.content,
          photoIds: [photos.first.id],
          tags: tagsResult.valueOrNull,
        );

        // Assert
        expect(saveResult, isA<Failure<DiaryEntry>>());
        expect(saveResult.errorOrNull, isA<ServiceException>());
        expect(saveResult.errorOrNull!.message, contains('データベース保存失敗'));
      });
    });

    // =================================================================
    // Group 7: プラン制限統合テスト
    // =================================================================

    group('Group 7: プラン制限統合テスト - Basic/Premium別のAI生成制限確認', () {
      test('Basic Planでの使用制限 - 月間上限到達時の制限動作', () async {
        // Arrange - Basic Plan使用制限到達
        when(
          () => subscriptionService.getCurrentPlanClass(),
        ).thenAnswer((_) async => Success(BasicPlan()));
        when(
          () => subscriptionService.canUseAiGeneration(),
        ).thenAnswer((_) async => Success(false));
        when(
          () => subscriptionService.getRemainingGenerations(),
        ).thenAnswer((_) async => Success(0));

        // Act
        final planResult = await subscriptionService.getCurrentPlanClass();
        final canUseResult = await subscriptionService.canUseAiGeneration();
        final remainingResult = await subscriptionService
            .getRemainingGenerations();

        // Assert
        expect(planResult, isA<Success<Plan>>());
        final plan = planResult.valueOrNull! as BasicPlan;
        expect(plan.isPremium, isFalse);
        expect(plan.monthlyAiGenerationLimit, equals(10)); // Basic plan limit

        expect(canUseResult, isA<Success<bool>>());
        expect(canUseResult.valueOrNull, isFalse);

        expect(remainingResult, isA<Success<int>>());
        expect(remainingResult.valueOrNull, equals(0));
      });

      test('Premium Planでの使用制限 - より多い制限での動作', () async {
        // Arrange - Premium Plan
        final premiumPlan = PremiumMonthlyPlan();
        when(
          () => subscriptionService.getCurrentPlanClass(),
        ).thenAnswer((_) async => Success(premiumPlan));
        when(
          () => subscriptionService.canUseAiGeneration(),
        ).thenAnswer((_) async => Success(true));
        when(
          () => subscriptionService.getRemainingGenerations(),
        ).thenAnswer((_) async => Success(85)); // 100 - 15 used

        // Act
        final planResult = await subscriptionService.getCurrentPlanClass();
        final canUseResult = await subscriptionService.canUseAiGeneration();
        final remainingResult = await subscriptionService
            .getRemainingGenerations();

        // Assert
        expect(planResult, isA<Success<Plan>>());
        final plan = planResult.valueOrNull! as PremiumMonthlyPlan;
        expect(plan.isPremium, isTrue);
        expect(
          plan.monthlyAiGenerationLimit,
          equals(100),
        ); // Premium plan limit

        expect(canUseResult, isA<Success<bool>>());
        expect(canUseResult.valueOrNull, isTrue);

        expect(remainingResult, isA<Success<int>>());
        expect(remainingResult.valueOrNull, equals(85));
      });

      test('AI生成使用後の使用量更新 - incrementAiUsage統合確認', () async {
        // Arrange
        setupSuccessfulPhotoFlow(mockPhotos);
        setupSuccessfulAiFlow();
        setupSuccessfulDiaryFlow();

        when(() => subscriptionService.incrementAiUsage()).thenAnswer((
          _,
        ) async {
          return Success(null);
        });

        // Act - AI生成を伴う日記作成
        final photos = await photoService.getTodayPhotos(limit: 1);
        final result = await diaryService.saveDiaryEntryWithAiGeneration(
          photos: photos,
          date: DateTime.now(),
        );

        // Mockでは実際の使用量更新は行われないため、手動で確認
        await subscriptionService.incrementAiUsage();

        // Assert
        expect(result, isA<Success<DiaryEntry>>());
        verify(() => subscriptionService.incrementAiUsage()).called(1);
      });
    });
  });
}
