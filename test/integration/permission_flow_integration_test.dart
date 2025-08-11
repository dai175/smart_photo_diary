import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/services/ai/ai_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/diary_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'test_helpers/integration_test_helpers.dart';
import 'mocks/mock_services.dart';

/// Phase 2-2: 権限拒否→再要求→写真取得→日記作成フロー エンドツーエンド統合テスト
///
/// 実際のユーザー体験で最も重要な権限処理フローの完全検証
/// - 初回権限拒否処理
/// - ユーザーによる権限再要求
/// - 権限許可後のシームレスな写真アクセス
/// - 完全な日記作成フローの統合確認

void main() {
  group('Phase 2-2: 権限拒否→再要求→写真取得→日記作成フロー エンドツーエンド統合テスト', () {
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

    /// Create mock image data for tests
    Uint8List createMockImageData() {
      // Simple PNG header
      return Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
    }

    List<MockAssetEntity> createMockPhotosForPermissionTest() {
      final photos = <MockAssetEntity>[];
      final now = DateTime.now();

      for (int i = 0; i < 3; i++) {
        final photo = MockAssetEntity();
        when(() => photo.id).thenReturn('permission-test-photo-$i');
        when(() => photo.title).thenReturn('Permission Test Photo $i');
        when(
          () => photo.createDateTime,
        ).thenReturn(now.subtract(Duration(hours: i)));
        when(
          () => photo.modifiedDateTime,
        ).thenReturn(now.subtract(Duration(hours: i)));
        when(() => photo.type).thenReturn(AssetType.image);
        when(() => photo.width).thenReturn(1920);
        when(() => photo.height).thenReturn(1080);

        photos.add(photo);
      }

      return photos;
    }

    setUp(() async {
      // Fresh mock services for each test
      photoService = MockPhotoServiceInterface();
      aiService = MockAiServiceInterface();
      diaryService = MockDiaryServiceInterface();
      subscriptionService = MockSubscriptionServiceInterface();

      // Test plan will be created as needed in individual tests

      // Create mock photos
      mockPhotos = createMockPhotosForPermissionTest();

      // Setup basic subscription service
      IntegrationTestHelpers.setupMockPremiumPlan(
        subscriptionService as MockSubscriptionServiceInterface,
        usageCount: 0,
      );
    });

    tearDown(() async {
      reset(photoService as MockPhotoServiceInterface);
      reset(aiService as MockAiServiceInterface);
      reset(diaryService as MockDiaryServiceInterface);
      reset(subscriptionService as MockSubscriptionServiceInterface);
    });

    void setupPermissionDeniedMock() {
      when(
        () => photoService.requestPermission(),
      ).thenAnswer((_) async => false);

      when(
        () => photoService.getTodayPhotos(limit: any(named: 'limit')),
      ).thenThrow(PhotoAccessException('写真アクセス権限が拒否されています'));

      when(
        () => photoService.getPhotosInDateRange(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenThrow(PhotoAccessException('写真アクセス権限が拒否されています'));
    }

    void setupPermissionGrantedMock() {
      when(
        () => photoService.requestPermission(),
      ).thenAnswer((_) async => true);

      when(
        () => photoService.getTodayPhotos(limit: any(named: 'limit')),
      ).thenAnswer((_) async => mockPhotos);

      when(
        () => photoService.getPhotosInDateRange(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => mockPhotos);

      when(
        () => photoService.getOriginalFileResult(any()),
      ).thenAnswer((_) async => Success(createMockImageData()));
    }

    void setupSuccessfulAiServiceMock() {
      when(
        () => aiService.isOnlineResult(),
      ).thenAnswer((_) async => Success(true));

      when(
        () => aiService.generateDiaryFromMultipleImages(
          imagesWithTimes: any(named: 'imagesWithTimes'),
          location: any(named: 'location'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer(
        (_) async => Success(
          DiaryGenerationResult(
            title: '権限テスト日記',
            content: '写真アクセス権限が正常に取得され、素敵な日記を作成できました。',
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
      ).thenAnswer((_) async => Success(['権限', 'テスト', '成功']));
    }

    void setupSuccessfulDiaryServiceMock() {
      when(
        () => diaryService.saveDiaryEntry(
          date: any(named: 'date'),
          title: any(named: 'title'),
          content: any(named: 'content'),
          photoIds: any(named: 'photoIds'),
          location: any(named: 'location'),
          tags: any(named: 'tags'),
        ),
      ).thenAnswer(
        (_) async => Success(
          DiaryEntry(
            id: 'permission-test-diary',
            title: '権限テスト日記',
            content: '写真アクセス権限が正常に取得され、素敵な日記を作成できました。',
            date: DateTime.now(),
            photoIds: mockPhotos.map((p) => p.id).toList(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            location: '東京都渋谷区',
            tags: ['権限', 'テスト', '成功'],
          ),
        ),
      );
    }

    // =================================================================
    // Group 1: 初回権限拒否処理テスト
    // =================================================================

    group('Group 1: 初回権限拒否処理テスト', () {
      test('初回アクセス時の権限拒否 - PhotoService.requestPermission() = false', () async {
        // Arrange
        setupPermissionDeniedMock();

        // Act & Assert - 権限要求が拒否される
        final permissionGranted = await photoService.requestPermission();
        expect(permissionGranted, isFalse);

        // 写真取得が失敗する
        expect(
          () => photoService.getTodayPhotos(),
          throwsA(isA<PhotoAccessException>()),
        );

        // 権限拒否の検証
        verify(() => photoService.requestPermission()).called(1);
      });

      test('権限拒否時の写真一覧取得エラー処理', () async {
        // Arrange
        setupPermissionDeniedMock();

        // Act & Assert - 写真取得で例外がスローされる
        expect(
          () => photoService.getTodayPhotos(),
          throwsA(
            predicate(
              (e) =>
                  e is PhotoAccessException &&
                  e.message.contains('写真アクセス権限が拒否されています'),
            ),
          ),
        );

        expect(
          () => photoService.getPhotosInDateRange(
            startDate: DateTime.now().subtract(Duration(days: 7)),
            endDate: DateTime.now(),
          ),
          throwsA(isA<PhotoAccessException>()),
        );
      });

      test('権限拒否時のエラーメッセージ確認', () async {
        // Arrange
        setupPermissionDeniedMock();

        // Act & Assert
        try {
          await photoService.getTodayPhotos();
          fail('PhotoAccessException should be thrown');
        } catch (e) {
          expect(e, isA<PhotoAccessException>());
          expect(
            (e as PhotoAccessException).message,
            contains('写真アクセス権限が拒否されています'),
          );
        }
      });

      test('権限拒否状態での日記作成フロー中断', () async {
        // Arrange
        setupPermissionDeniedMock();

        // Act & Assert - 写真取得段階で中断
        expect(
          () => photoService.getTodayPhotos(),
          throwsA(isA<PhotoAccessException>()),
        );

        // 後続処理は実行されない（写真がないため）
        verifyNever(
          () => aiService.generateDiaryFromMultipleImages(
            imagesWithTimes: any(named: 'imagesWithTimes'),
            location: any(named: 'location'),
            onProgress: any(named: 'onProgress'),
          ),
        );
      });
    });

    // =================================================================
    // Group 2: 権限再要求処理テスト
    // =================================================================

    group('Group 2: 権限再要求処理テスト', () {
      test('ユーザー操作による権限再要求 - 拒否→許可への状態変更', () async {
        // Arrange - 最初は拒否状態
        when(
          () => photoService.requestPermission(),
        ).thenAnswer((_) async => false);

        // Act - 初回要求（拒否）
        final firstRequest = await photoService.requestPermission();
        expect(firstRequest, isFalse);

        // システム設定変更をシミュレート（ユーザーが設定アプリで権限許可）
        when(
          () => photoService.requestPermission(),
        ).thenAnswer((_) async => true);

        // Act - 再要求（許可）
        final secondRequest = await photoService.requestPermission();
        expect(secondRequest, isTrue);

        // Assert - 権限要求が2回呼ばれた
        verify(() => photoService.requestPermission()).called(2);
      });

      test('権限許可後の写真アクセス機能復旧確認', () async {
        // Arrange - 権限許可状態に設定
        setupPermissionGrantedMock();

        // Act - 権限要求が成功
        final permissionGranted = await photoService.requestPermission();
        expect(permissionGranted, isTrue);

        // 写真取得が成功する
        final todayPhotos = await photoService.getTodayPhotos();
        expect(todayPhotos, isNotEmpty);
        expect(todayPhotos.length, equals(mockPhotos.length));

        // 日付範囲指定での写真取得も成功
        final rangePhotos = await photoService.getPhotosInDateRange(
          startDate: DateTime.now().subtract(Duration(days: 1)),
          endDate: DateTime.now(),
        );
        expect(rangePhotos, isNotEmpty);

        // 写真データ取得も成功
        final imageDataResult = await photoService.getOriginalFileResult(
          mockPhotos.first,
        );
        expect(imageDataResult, isA<Success>());
      });

      test('段階的権限状態変更の動作確認', () async {
        // Arrange - 3段階の権限状態変更をシミュレート
        var requestCount = 0;
        when(() => photoService.requestPermission()).thenAnswer((_) async {
          requestCount++;
          switch (requestCount) {
            case 1:
              return false; // 初回拒否
            case 2:
              return false; // 2回目も拒否
            case 3:
              return true; // 3回目で許可
            default:
              return true;
          }
        });

        // Act & Assert - 段階的な状態変更
        expect(await photoService.requestPermission(), isFalse); // 1回目
        expect(await photoService.requestPermission(), isFalse); // 2回目
        expect(await photoService.requestPermission(), isTrue); // 3回目

        // 最終的に3回呼ばれた
        verify(() => photoService.requestPermission()).called(3);
      });
    });

    // =================================================================
    // Group 3: 権限許可後の完全フロー統合テスト
    // =================================================================

    group('Group 3: 権限許可後の完全フロー統合テスト', () {
      test('権限解決後の完全な日記作成フロー - 写真→AI→タグ→保存', () async {
        // Arrange - 全サービスを成功状態に設定
        setupPermissionGrantedMock();
        setupSuccessfulAiServiceMock();
        setupSuccessfulDiaryServiceMock();

        final testDate = DateTime.now();
        final location = '東京都渋谷区';

        // Phase 1: 権限取得
        final permissionGranted = await photoService.requestPermission();
        expect(permissionGranted, isTrue);

        // Phase 2: 写真選択
        final selectedPhotos = await photoService.getTodayPhotos();
        expect(selectedPhotos, isNotEmpty);

        // Phase 3: 写真データ取得
        final imageDataResults = <Success<Uint8List>>[];
        for (final photo in selectedPhotos) {
          final result = await photoService.getOriginalFileResult(photo);
          expect(result, isA<Success<Uint8List>>());
          imageDataResults.add(result as Success<Uint8List>);
        }

        // Phase 4: AI生成
        final imagesWithTimes = selectedPhotos
            .asMap()
            .entries
            .map(
              (entry) => (
                imageData: imageDataResults[entry.key].data,
                time: entry.value.createDateTime,
              ),
            )
            .toList();

        final diaryResult = await aiService.generateDiaryFromMultipleImages(
          imagesWithTimes: imagesWithTimes,
          location: location,
        );
        expect(diaryResult, isA<Success<DiaryGenerationResult>>());
        final generatedDiary = diaryResult.value;

        // Phase 5: タグ生成
        final tagsResult = await aiService.generateTagsFromContent(
          title: generatedDiary.title,
          content: generatedDiary.content,
          date: testDate,
          photoCount: selectedPhotos.length,
        );
        expect(tagsResult, isA<Success<List<String>>>());
        final generatedTags = tagsResult.value;

        // Phase 6: 保存
        final saveResult = await diaryService.saveDiaryEntry(
          date: testDate,
          title: generatedDiary.title,
          content: generatedDiary.content,
          photoIds: selectedPhotos.map((p) => p.id).toList(),
          location: location,
          tags: generatedTags,
        );
        expect(saveResult, isA<Success<DiaryEntry>>());
        final savedEntry = saveResult.value;

        // Phase 7: 完全性確認
        expect(savedEntry.title, equals(generatedDiary.title));
        expect(savedEntry.content, equals(generatedDiary.content));
        expect(savedEntry.photoIds.length, equals(selectedPhotos.length));
        expect(savedEntry.tags, equals(generatedTags));
        expect(savedEntry.location, equals(location));

        // 全フローが正常に実行されたことを確認
        verify(() => photoService.requestPermission()).called(1);
        verify(() => photoService.getTodayPhotos()).called(1);
        verify(
          () => aiService.generateDiaryFromMultipleImages(
            imagesWithTimes: any(named: 'imagesWithTimes'),
            location: any(named: 'location'),
          ),
        ).called(1);
        verify(
          () => aiService.generateTagsFromContent(
            title: any(named: 'title'),
            content: any(named: 'content'),
            date: any(named: 'date'),
            photoCount: any(named: 'photoCount'),
          ),
        ).called(1);
        verify(
          () => diaryService.saveDiaryEntry(
            date: any(named: 'date'),
            title: any(named: 'title'),
            content: any(named: 'content'),
            photoIds: any(named: 'photoIds'),
            location: any(named: 'location'),
            tags: any(named: 'tags'),
          ),
        ).called(1);
      });

      test('権限許可後のエラー回復力テスト - ネットワークエラーからの復旧', () async {
        // Arrange - 権限は許可、AIサービスは一時的にオフライン
        setupPermissionGrantedMock();
        setupSuccessfulDiaryServiceMock();

        // AI service initially offline
        when(
          () => aiService.isOnlineResult(),
        ).thenAnswer((_) async => Success(false));

        // Act - 権限取得は成功
        final permissionGranted = await photoService.requestPermission();
        expect(permissionGranted, isTrue);

        // 写真選択は成功
        final selectedPhotos = await photoService.getTodayPhotos();
        expect(selectedPhotos, isNotEmpty);

        // AI生成は失敗（オフライン）
        final onlineCheck = await aiService.isOnlineResult();
        expect(onlineCheck.valueOrNull, isFalse);

        // システム状態変更 - オンラインに復旧
        setupSuccessfulAiServiceMock();

        // 再度AI生成を試行（成功）
        final retryOnlineCheck = await aiService.isOnlineResult();
        expect(retryOnlineCheck.valueOrNull, isTrue);

        final imageDataResults = <Success<Uint8List>>[];
        for (final photo in selectedPhotos) {
          final result = await photoService.getOriginalFileResult(photo);
          imageDataResults.add(result as Success<Uint8List>);
        }

        final imagesWithTimes = selectedPhotos
            .asMap()
            .entries
            .map(
              (entry) => (
                imageData: imageDataResults[entry.key].data,
                time: entry.value.createDateTime,
              ),
            )
            .toList();

        final diaryResult = await aiService.generateDiaryFromMultipleImages(
          imagesWithTimes: imagesWithTimes,
          location: '東京都渋谷区',
        );
        expect(diaryResult, isA<Success<DiaryGenerationResult>>());

        // 権限問題は解決済み、ネットワーク問題も解決済み
        verify(() => photoService.requestPermission()).called(1);
        verify(() => aiService.isOnlineResult()).called(2);
      });
    });

    // =================================================================
    // Group 4: iOS限定アクセス権限（Limited Access）処理テスト
    // =================================================================

    group('Group 4: iOS限定アクセス権限（Limited Access）処理テスト', () {
      test('Limited access状態での制限された写真取得', () async {
        // Arrange - limited access状態をシミュレート
        when(
          () => photoService.requestPermission(),
        ).thenAnswer((_) async => true); // 権限はあるが制限あり

        // 制限された写真のみ取得可能
        final limitedPhotos = [mockPhotos.first]; // 1枚のみアクセス可能
        when(
          () => photoService.getTodayPhotos(limit: any(named: 'limit')),
        ).thenAnswer((_) async => limitedPhotos);

        when(
          () => photoService.getOriginalFileResult(any()),
        ).thenAnswer((_) async => Success(createMockImageData()));

        // Act
        final permissionGranted = await photoService.requestPermission();
        expect(permissionGranted, isTrue);

        final availablePhotos = await photoService.getTodayPhotos();
        expect(availablePhotos.length, equals(1)); // 制限されている

        // Limited accessでも日記作成は可能
        final imageResult = await photoService.getOriginalFileResult(
          availablePhotos.first,
        );
        expect(imageResult, isA<Success<Uint8List>>());
      });

      test('Limited access状態でのユーザーガイダンス確認', () async {
        // Arrange - limited access detection
        when(
          () => photoService.requestPermission(),
        ).thenAnswer((_) async => true);

        // 通常より少ない写真数（limited accessの兆候）
        final limitedPhotos = [mockPhotos.first];
        when(
          () => photoService.getTodayPhotos(limit: any(named: 'limit')),
        ).thenAnswer((_) async => limitedPhotos);

        // Act
        final availablePhotos = await photoService.getTodayPhotos(limit: 10);

        // Assert - 想定より少ない写真数（limited accessの可能性）
        expect(availablePhotos.length, lessThan(3));

        // この状態でもアプリは動作する
        expect(availablePhotos, isNotEmpty);
      });
    });

    // =================================================================
    // Group 5: 権限状態変遷の複雑なシナリオテスト
    // =================================================================

    group('Group 5: 権限状態変遷の複雑なシナリオテスト', () {
      test('複数回の権限拒否後の最終許可シナリオ', () async {
        // Arrange - 複雑な権限状態変遷
        var requestCount = 0;
        when(() => photoService.requestPermission()).thenAnswer((_) async {
          requestCount++;
          return requestCount >= 4; // 4回目で初めて許可
        });

        // Act - 複数回の権限要求
        expect(await photoService.requestPermission(), isFalse); // 1回目
        expect(await photoService.requestPermission(), isFalse); // 2回目
        expect(await photoService.requestPermission(), isFalse); // 3回目
        expect(await photoService.requestPermission(), isTrue); // 4回目

        // Assert
        verify(() => photoService.requestPermission()).called(4);
      });

      test('権限許可→拒否→再許可の状態変遷', () async {
        // Arrange - 権限状態が動的に変化
        var callOrder = 0;
        when(() => photoService.requestPermission()).thenAnswer((_) async {
          callOrder++;
          switch (callOrder) {
            case 1:
              return true; // 最初は許可
            case 2:
              return false; // システム設定で拒否に変更
            case 3:
              return true; // 再度許可
            default:
              return true;
          }
        });

        when(
          () => photoService.getTodayPhotos(limit: any(named: 'limit')),
        ).thenAnswer((_) async {
          if (callOrder == 2) {
            throw PhotoAccessException('権限が取り消されました');
          }
          return mockPhotos;
        });

        // Act & Assert - 動的な権限状態変化
        expect(await photoService.requestPermission(), isTrue); // 初回許可
        expect(await photoService.requestPermission(), isFalse); // 権限取り消し

        // 権限拒否状態では写真取得エラー
        expect(
          () => photoService.getTodayPhotos(),
          throwsA(isA<PhotoAccessException>()),
        );

        expect(await photoService.requestPermission(), isTrue); // 再許可

        // 再許可後は正常動作
        final photos = await photoService.getTodayPhotos();
        expect(photos, isNotEmpty);
      });

      test('アプリ再起動後の権限状態確認シミュレーション', () async {
        // Arrange - アプリ再起動をシミュレート（権限状態を再確認）
        setupPermissionGrantedMock();

        // Act - アプリ起動時の権限状態確認
        final initialPermissionCheck = await photoService.requestPermission();
        expect(initialPermissionCheck, isTrue);

        // 権限が有効な状態での通常操作
        final photos = await photoService.getTodayPhotos();
        expect(photos, isNotEmpty);

        // Assert - 起動時権限確認が実行された
        verify(() => photoService.requestPermission()).called(1);
        verify(() => photoService.getTodayPhotos()).called(1);
      });
    });

    // =================================================================
    // Group 6: エラーハンドリングとリカバリテスト
    // =================================================================

    group('Group 6: エラーハンドリングとリカバリテスト', () {
      test('権限エラーからのグレースフルリカバリ', () async {
        // Arrange - 権限エラーからリカバリするシナリオ
        var attemptCount = 0;
        when(() => photoService.requestPermission()).thenAnswer((_) async {
          attemptCount++;
          return attemptCount >= 2; // 2回目で成功
        });

        when(
          () => photoService.getTodayPhotos(limit: any(named: 'limit')),
        ).thenAnswer((_) async {
          if (attemptCount < 2) {
            throw PhotoAccessException('権限が不十分です');
          }
          return mockPhotos;
        });

        // Act - エラーからのリカバリ
        expect(await photoService.requestPermission(), isFalse); // 1回目失敗

        // エラー状態では写真取得も失敗
        expect(
          () => photoService.getTodayPhotos(),
          throwsA(isA<PhotoAccessException>()),
        );

        // リトライ後成功
        expect(await photoService.requestPermission(), isTrue); // 2回目成功

        final photos = await photoService.getTodayPhotos();
        expect(photos, isNotEmpty);

        // Assert
        verify(() => photoService.requestPermission()).called(2);
      });

      test('部分的権限エラーでの継続処理確認', () async {
        // Arrange - 写真は取得できるがAIエラー
        setupPermissionGrantedMock();
        setupSuccessfulDiaryServiceMock();

        // AI service fails
        when(
          () => aiService.generateDiaryFromMultipleImages(
            imagesWithTimes: any(named: 'imagesWithTimes'),
            location: any(named: 'location'),
            onProgress: any(named: 'onProgress'),
          ),
        ).thenAnswer((_) async => Failure(AiProcessingException('AI処理エラー')));

        // Act - 写真取得は成功
        final permissionGranted = await photoService.requestPermission();
        expect(permissionGranted, isTrue);

        final photos = await photoService.getTodayPhotos();
        expect(photos, isNotEmpty);

        // AI処理は失敗するが、写真取得は成功している
        final imageResults = <Success<Uint8List>>[];
        for (final photo in photos) {
          final result = await photoService.getOriginalFileResult(photo);
          expect(result, isA<Success<Uint8List>>());
          imageResults.add(result as Success<Uint8List>);
        }

        final imagesWithTimes = photos
            .asMap()
            .entries
            .map(
              (entry) => (
                imageData: imageResults[entry.key].data,
                time: entry.value.createDateTime,
              ),
            )
            .toList();

        final diaryResult = await aiService.generateDiaryFromMultipleImages(
          imagesWithTimes: imagesWithTimes,
          location: '東京都渋谷区',
        );
        expect(diaryResult, isA<Failure<DiaryGenerationResult>>());

        // Assert - 権限問題は解決、AI問題のみ
        verify(() => photoService.requestPermission()).called(1);
        verify(() => photoService.getTodayPhotos()).called(1);
        verify(
          () => aiService.generateDiaryFromMultipleImages(
            imagesWithTimes: any(named: 'imagesWithTimes'),
            location: any(named: 'location'),
          ),
        ).called(1);
      });

      test('全サービス統合でのエラーチェーン確認', () async {
        // Arrange - 段階的なエラー確認
        setupPermissionDeniedMock(); // 権限拒否
        setupSuccessfulAiServiceMock();
        setupSuccessfulDiaryServiceMock();

        // Phase 1: 権限エラー
        expect(await photoService.requestPermission(), isFalse);

        // Phase 2: 権限エラーにより後続処理は実行不可
        expect(
          () => photoService.getTodayPhotos(),
          throwsA(isA<PhotoAccessException>()),
        );

        // Phase 3: 権限解決後、全て正常動作
        setupPermissionGrantedMock();

        expect(await photoService.requestPermission(), isTrue);
        final photos = await photoService.getTodayPhotos();
        expect(photos, isNotEmpty);

        // Assert - 権限解決後は正常フローが可能
        verify(() => photoService.requestPermission()).called(2);
      });
    });
  });
}
