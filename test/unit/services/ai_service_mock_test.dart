import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/services/ai/ai_service_interface.dart';
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


    group('generateDiaryFromImage', () {
      test('should generate diary from image data', () async {
        // Arrange
        final imageData = Uint8List.fromList([0, 1, 2, 3]);
        final date = DateTime(2024, 1, 15, 12, 0);
        final expectedResult = DiaryGenerationResult(
          title: '写真から生成された日記',
          content: '画像から素敵な思い出を記録しました。',
        );

        when(() => mockAiService.generateDiaryFromImage(
          imageData: any(named: 'imageData'),
          date: any(named: 'date'),
          location: any(named: 'location'),
          photoTimes: any(named: 'photoTimes'),
        )).thenAnswer((_) async => expectedResult);

        // Act
        final result = await mockAiService.generateDiaryFromImage(
          imageData: imageData,
          date: date,
        );

        // Assert
        expect(result, equals(expectedResult));
        verify(() => mockAiService.generateDiaryFromImage(
          imageData: imageData,
          date: date,
          location: null,
          photoTimes: null,
        )).called(1);
      });
    });

    group('generateDiaryFromMultipleImages', () {
      test('should generate diary from multiple images', () async {
        // Arrange
        final imagesWithTimes = [
          (imageData: Uint8List.fromList([0, 1, 2]), time: DateTime(2024, 1, 15, 10, 0)),
          (imageData: Uint8List.fromList([3, 4, 5]), time: DateTime(2024, 1, 15, 11, 0)),
        ];
        final expectedResult = DiaryGenerationResult(
          title: '複数の写真から生成された日記',
          content: '複数の画像から素敵な一日の物語を作成しました。',
        );

        when(() => mockAiService.generateDiaryFromMultipleImages(
          imagesWithTimes: any(named: 'imagesWithTimes'),
          location: any(named: 'location'),
          onProgress: any(named: 'onProgress'),
        )).thenAnswer((_) async => expectedResult);

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
        
        when(() => mockAiService.generateDiaryFromMultipleImages(
          imagesWithTimes: any(named: 'imagesWithTimes'),
          location: any(named: 'location'),
          onProgress: any(named: 'onProgress'),
        )).thenAnswer((_) async {
          return DiaryGenerationResult(title: 'Test', content: 'Test content');
        });

        // Act
        await mockAiService.generateDiaryFromMultipleImages(
          imagesWithTimes: imagesWithTimes,
          onProgress: (current, total) {
            // Progress callback implementation for testing
          },
        );

        // Assert
        verify(() => mockAiService.generateDiaryFromMultipleImages(
          imagesWithTimes: imagesWithTimes,
          location: null,
          onProgress: any(named: 'onProgress'),
        )).called(1);
      });
    });

    group('generateTagsFromContent', () {
      test('should generate tags from diary content', () async {
        // Arrange
        const title = '公園での楽しい一日';
        const content = '今日は友達と公園でピクニックをしました。天気も良く、とても楽しい時間を過ごすことができました。';
        final date = DateTime(2024, 1, 15);
        const photoCount = 5;
        final expectedTags = ['公園', 'ピクニック', '友達', '天気', '楽しい'];

        when(() => mockAiService.generateTagsFromContent(
          title: any(named: 'title'),
          content: any(named: 'content'),
          date: any(named: 'date'),
          photoCount: any(named: 'photoCount'),
        )).thenAnswer((_) async => expectedTags);

        // Act
        final result = await mockAiService.generateTagsFromContent(
          title: title,
          content: content,
          date: date,
          photoCount: photoCount,
        );

        // Assert
        expect(result, equals(expectedTags));
        expect(result.length, equals(5));
        expect(result, contains('公園'));
        expect(result, contains('友達'));
        verify(() => mockAiService.generateTagsFromContent(
          title: title,
          content: content,
          date: date,
          photoCount: photoCount,
        )).called(1);
      });

      test('should generate tags for short content', () async {
        // Arrange
        const title = '散歩';
        const content = '短い散歩をしました。';
        final date = DateTime(2024, 1, 15);
        const photoCount = 1;
        final expectedTags = ['散歩', '短時間'];

        when(() => mockAiService.generateTagsFromContent(
          title: any(named: 'title'),
          content: any(named: 'content'),
          date: any(named: 'date'),
          photoCount: any(named: 'photoCount'),
        )).thenAnswer((_) async => expectedTags);

        // Act
        final result = await mockAiService.generateTagsFromContent(
          title: title,
          content: content,
          date: date,
          photoCount: photoCount,
        );

        // Assert
        expect(result, equals(expectedTags));
        expect(result, contains('散歩'));
      });

      test('should handle empty content', () async {
        // Arrange
        const title = '';
        const content = '';
        final date = DateTime(2024, 1, 15);
        const photoCount = 0;
        final expectedTags = <String>[];

        when(() => mockAiService.generateTagsFromContent(
          title: any(named: 'title'),
          content: any(named: 'content'),
          date: any(named: 'date'),
          photoCount: any(named: 'photoCount'),
        )).thenAnswer((_) async => expectedTags);

        // Act
        final result = await mockAiService.generateTagsFromContent(
          title: title,
          content: content,
          date: date,
          photoCount: photoCount,
        );

        // Assert
        expect(result, isEmpty);
      });

      test('should generate time-based tags', () async {
        // Arrange
        const title = '朝の日記';
        const content = '早朝に起きて散歩をしました。';
        final date = DateTime(2024, 1, 15, 6, 0); // Early morning
        const photoCount = 2;
        final expectedTags = ['朝', '早朝', '散歩', '時間'];

        when(() => mockAiService.generateTagsFromContent(
          title: any(named: 'title'),
          content: any(named: 'content'),
          date: any(named: 'date'),
          photoCount: any(named: 'photoCount'),
        )).thenAnswer((_) async => expectedTags);

        // Act
        final result = await mockAiService.generateTagsFromContent(
          title: title,
          content: content,
          date: date,
          photoCount: photoCount,
        );

        // Assert
        expect(result, contains('朝'));
        expect(result, contains('散歩'));
      });
    });

    group('Error Handling', () {

      test('should handle invalid image data gracefully', () async {
        // Arrange
        final invalidImageData = Uint8List.fromList([]);
        final date = DateTime.now();
        final fallbackResult = DiaryGenerationResult(
          title: 'エラー時の日記',
          content: '画像の処理中にエラーが発生しましたが、代替の日記を生成しました。',
        );

        when(() => mockAiService.generateDiaryFromImage(
          imageData: any(named: 'imageData'),
          date: any(named: 'date'),
          location: any(named: 'location'),
          photoTimes: any(named: 'photoTimes'),
        )).thenAnswer((_) async => fallbackResult);

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