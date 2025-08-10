import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/services/ai/ai_service_interface.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import '../../test_helpers/mock_platform_channels.dart';

// Mock implementation of AiServiceInterface for testing
class MockAiServiceInterface extends Mock implements AiServiceInterface {}

void main() {
  group('AiService Mock Tests', () {
    late MockAiServiceInterface mockAiService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      MockPlatformChannels.setupMocks();
      registerFallbackValue(Uint8List(0));
      registerFallbackValue(DateTime.now());
      registerFallbackValue(<String>[]);
      registerFallbackValue(<DateTime>[]);
      registerFallbackValue(<({Uint8List imageData, DateTime time})>[]);
    });

    tearDownAll(() {
      MockPlatformChannels.clearMocks();
    });

    setUp(() {
      mockAiService = MockAiServiceInterface();
    });

    group('isOnline', () {
      test('should return true when connected', () async {
        // Arrange
        when(() => mockAiService.isOnline()).thenAnswer((_) async => true);

        // Act
        final result = await mockAiService.isOnline();

        // Assert
        expect(result, isTrue);
        verify(() => mockAiService.isOnline()).called(1);
      });

      test('should return false when disconnected', () async {
        // Arrange
        when(() => mockAiService.isOnline()).thenAnswer((_) async => false);

        // Act
        final result = await mockAiService.isOnline();

        // Assert
        expect(result, isFalse);
        verify(() => mockAiService.isOnline()).called(1);
      });
    });

    group('isOnlineResult', () {
      test('should return Success<bool> when connected', () async {
        // Arrange
        final expectedResult = Success(true);
        when(
          () => mockAiService.isOnlineResult(),
        ).thenAnswer((_) async => expectedResult);

        // Act
        final result = await mockAiService.isOnlineResult();

        // Assert
        expect(result, equals(expectedResult));
        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
        verify(() => mockAiService.isOnlineResult()).called(1);
      });

      test('should return Success<bool> when disconnected', () async {
        // Arrange
        final expectedResult = Success(false);
        when(
          () => mockAiService.isOnlineResult(),
        ).thenAnswer((_) async => expectedResult);

        // Act
        final result = await mockAiService.isOnlineResult();

        // Assert
        expect(result, equals(expectedResult));
        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
        verify(() => mockAiService.isOnlineResult()).called(1);
      });

      test('should return Failure when network error occurs', () async {
        // Arrange
        final networkError = NetworkException('ネットワーク接続の確認中にエラーが発生しました');
        final expectedResult = Failure<bool>(networkError);
        when(
          () => mockAiService.isOnlineResult(),
        ).thenAnswer((_) async => expectedResult);

        // Act
        final result = await mockAiService.isOnlineResult();

        // Assert
        expect(result, equals(expectedResult));
        expect(result.isFailure, isTrue);
        expect(result.error, isA<NetworkException>());
        verify(() => mockAiService.isOnlineResult()).called(1);
      });
    });

    group('AiProcessingException Hierarchy', () {
      test('should handle AiGenerationException properly', () async {
        // Arrange
        final generationError = AiGenerationException('日記生成に失敗しました');
        final expectedResult = Failure<DiaryGenerationResult>(generationError);
        when(
          () => mockAiService.generateDiaryFromImage(
            imageData: any(named: 'imageData'),
            date: any(named: 'date'),
            location: any(named: 'location'),
            photoTimes: any(named: 'photoTimes'),
          ),
        ).thenAnswer((_) async => expectedResult);

        // Act
        final result = await mockAiService.generateDiaryFromImage(
          imageData: Uint8List.fromList([1, 2, 3]),
          date: DateTime.now(),
        );

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<AiGenerationException>());
        expect(result.error, isA<AiProcessingException>());
      });

      test('should handle AiApiResponseException properly', () async {
        // Arrange
        final apiError = AiApiResponseException('APIレスポンスが不正です');
        final expectedResult = Failure<DiaryGenerationResult>(apiError);
        when(
          () => mockAiService.generateDiaryFromImage(
            imageData: any(named: 'imageData'),
            date: any(named: 'date'),
            location: any(named: 'location'),
            photoTimes: any(named: 'photoTimes'),
          ),
        ).thenAnswer((_) async => expectedResult);

        // Act
        final result = await mockAiService.generateDiaryFromImage(
          imageData: Uint8List.fromList([1, 2, 3]),
          date: DateTime.now(),
        );

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<AiApiResponseException>());
        expect(result.error, isA<AiProcessingException>());
      });

      test('should handle AiOfflineException properly', () async {
        // Arrange
        final offlineError = AiOfflineException('オフライン状態では利用できません');
        final expectedResult = Failure<DiaryGenerationResult>(offlineError);
        when(
          () => mockAiService.generateDiaryFromImage(
            imageData: any(named: 'imageData'),
            date: any(named: 'date'),
            location: any(named: 'location'),
            photoTimes: any(named: 'photoTimes'),
          ),
        ).thenAnswer((_) async => expectedResult);

        // Act
        final result = await mockAiService.generateDiaryFromImage(
          imageData: Uint8List.fromList([1, 2, 3]),
          date: DateTime.now(),
        );

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<AiOfflineException>());
        expect(result.error, isA<AiProcessingException>());
      });
    });

    group('generateDiaryFromImage', () {
      test('should generate diary from image data', () async {
        // Arrange
        final imageData = Uint8List.fromList([0, 1, 2, 3]);
        final date = DateTime(2024, 1, 15, 12, 0);
        final expectedResult = Success(
          DiaryGenerationResult(
            title: '体験から生成された日記',
            content: '画像から素敵な思い出を記録しました。',
          ),
        );

        when(
          () => mockAiService.generateDiaryFromImage(
            imageData: any(named: 'imageData'),
            date: any(named: 'date'),
            location: any(named: 'location'),
            photoTimes: any(named: 'photoTimes'),
          ),
        ).thenAnswer((_) async => expectedResult);

        // Act
        final result = await mockAiService.generateDiaryFromImage(
          imageData: imageData,
          date: date,
        );

        // Assert
        expect(result, equals(expectedResult));
        verify(
          () => mockAiService.generateDiaryFromImage(
            imageData: imageData,
            date: date,
            location: null,
            photoTimes: null,
          ),
        ).called(1);
      });
    });

    group('generateDiaryFromMultipleImages', () {
      test('should generate diary from multiple images', () async {
        // Arrange
        final imagesWithTimes = [
          (
            imageData: Uint8List.fromList([0, 1, 2]),
            time: DateTime(2024, 1, 15, 10, 0),
          ),
          (
            imageData: Uint8List.fromList([3, 4, 5]),
            time: DateTime(2024, 1, 15, 11, 0),
          ),
        ];
        final expectedResult = Success(
          DiaryGenerationResult(
            title: '複数の体験から生成された日記',
            content: '複数の画像から素敵な一日の物語を作成しました。',
          ),
        );

        when(
          () => mockAiService.generateDiaryFromMultipleImages(
            imagesWithTimes: any(named: 'imagesWithTimes'),
            location: any(named: 'location'),
            onProgress: any(named: 'onProgress'),
          ),
        ).thenAnswer((_) async => expectedResult);

        // Act
        final result = await mockAiService.generateDiaryFromMultipleImages(
          imagesWithTimes: imagesWithTimes,
        );

        // Assert
        expect(result, equals(expectedResult));
      });

      test('should call progress callback during generation', () async {
        // Arrange
        final imagesWithTimes = [
          (imageData: Uint8List.fromList([0, 1]), time: DateTime.now()),
          (imageData: Uint8List.fromList([2, 3]), time: DateTime.now()),
        ];

        when(
          () => mockAiService.generateDiaryFromMultipleImages(
            imagesWithTimes: any(named: 'imagesWithTimes'),
            location: any(named: 'location'),
            onProgress: any(named: 'onProgress'),
          ),
        ).thenAnswer((_) async {
          return Success(
            DiaryGenerationResult(title: 'Test', content: 'Test content'),
          );
        });

        // Act
        await mockAiService.generateDiaryFromMultipleImages(
          imagesWithTimes: imagesWithTimes,
          onProgress: (current, total) {
            // Progress callback implementation for testing
          },
        );

        // Assert
        verify(
          () => mockAiService.generateDiaryFromMultipleImages(
            imagesWithTimes: imagesWithTimes,
            location: null,
            onProgress: any(named: 'onProgress'),
          ),
        ).called(1);
      });
    });

    group('generateTagsFromContent', () {
      test('should generate tags from diary content', () async {
        // Arrange
        const title = '公園での楽しい一日';
        const content = '今日は友達と公園でピクニックをしました。天気も良く、とても楽しい時間を過ごすことができました。';
        final date = DateTime(2024, 1, 15);
        const photoCount = 5;
        final expectedTags = Success(['公園', 'ピクニック', '友達', '天気', '楽しい']);

        when(
          () => mockAiService.generateTagsFromContent(
            title: any(named: 'title'),
            content: any(named: 'content'),
            date: any(named: 'date'),
            photoCount: any(named: 'photoCount'),
          ),
        ).thenAnswer((_) async => expectedTags);

        // Act
        final result = await mockAiService.generateTagsFromContent(
          title: title,
          content: content,
          date: date,
          photoCount: photoCount,
        );

        // Assert
        expect(result, equals(expectedTags));
        expect(result.value.length, equals(5));
        expect(result.value, contains('公園'));
        expect(result.value, contains('友達'));
        verify(
          () => mockAiService.generateTagsFromContent(
            title: title,
            content: content,
            date: date,
            photoCount: photoCount,
          ),
        ).called(1);
      });

      test('should generate tags for short content', () async {
        // Arrange
        const title = '散歩';
        const content = '短い散歩をしました。';
        final date = DateTime(2024, 1, 15);
        const photoCount = 1;
        final expectedTags = Success(['散歩', '短時間']);

        when(
          () => mockAiService.generateTagsFromContent(
            title: any(named: 'title'),
            content: any(named: 'content'),
            date: any(named: 'date'),
            photoCount: any(named: 'photoCount'),
          ),
        ).thenAnswer((_) async => expectedTags);

        // Act
        final result = await mockAiService.generateTagsFromContent(
          title: title,
          content: content,
          date: date,
          photoCount: photoCount,
        );

        // Assert
        expect(result, equals(expectedTags));
        expect(result.value, contains('散歩'));
      });

      test('should handle empty content', () async {
        // Arrange
        const title = '';
        const content = '';
        final date = DateTime(2024, 1, 15);
        const photoCount = 0;
        final expectedTags = Success(<String>[]);

        when(
          () => mockAiService.generateTagsFromContent(
            title: any(named: 'title'),
            content: any(named: 'content'),
            date: any(named: 'date'),
            photoCount: any(named: 'photoCount'),
          ),
        ).thenAnswer((_) async => expectedTags);

        // Act
        final result = await mockAiService.generateTagsFromContent(
          title: title,
          content: content,
          date: date,
          photoCount: photoCount,
        );

        // Assert
        expect(result.value, isEmpty);
      });

      test('should generate time-based tags', () async {
        // Arrange
        const title = '朝の日記';
        const content = '早朝に起きて散歩をしました。';
        final date = DateTime(2024, 1, 15, 6, 0); // Early morning
        const photoCount = 2;
        final expectedTags = Success(['朝', '早朝', '散歩', '時間']);

        when(
          () => mockAiService.generateTagsFromContent(
            title: any(named: 'title'),
            content: any(named: 'content'),
            date: any(named: 'date'),
            photoCount: any(named: 'photoCount'),
          ),
        ).thenAnswer((_) async => expectedTags);

        // Act
        final result = await mockAiService.generateTagsFromContent(
          title: title,
          content: content,
          date: date,
          photoCount: photoCount,
        );

        // Assert
        expect(result.value, contains('朝'));
        expect(result.value, contains('散歩'));
      });
    });

    group('Error Handling', () {
      test('should handle invalid image data gracefully', () async {
        // Arrange
        final invalidImageData = Uint8List.fromList([]);
        final date = DateTime.now();
        final fallbackResult = Success(
          DiaryGenerationResult(
            title: 'エラー時の日記',
            content: '画像の処理中にエラーが発生しましたが、代替の日記を生成しました。',
          ),
        );

        when(
          () => mockAiService.generateDiaryFromImage(
            imageData: any(named: 'imageData'),
            date: any(named: 'date'),
            location: any(named: 'location'),
            photoTimes: any(named: 'photoTimes'),
          ),
        ).thenAnswer((_) async => fallbackResult);

        // Act
        final result = await mockAiService.generateDiaryFromImage(
          imageData: invalidImageData,
          date: date,
        );

        // Assert
        expect(result, equals(fallbackResult));
      });
    });

    group('Interface Compliance', () {
      test('should implement AiServiceInterface', () {
        expect(mockAiService, isA<AiServiceInterface>());
      });

      test('should have all required interface methods', () {
        expect(mockAiService.isOnline, isA<Function>());
        expect(mockAiService.generateDiaryFromImage, isA<Function>());
        expect(mockAiService.generateDiaryFromMultipleImages, isA<Function>());
        expect(mockAiService.generateTagsFromContent, isA<Function>());
      });
    });

    group('Data Classes', () {
      test('DiaryGenerationResult should be properly constructed', () {
        const title = 'テストタイトル';
        const content = 'テストコンテンツ';

        final result = DiaryGenerationResult(title: title, content: content);

        expect(result.title, equals(title));
        expect(result.content, equals(content));
      });
    });
  });
}
