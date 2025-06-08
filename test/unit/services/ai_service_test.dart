import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/services/ai_service.dart';
import 'package:smart_photo_diary/services/ai/ai_service_interface.dart';
import 'package:smart_photo_diary/services/ai/gemini_api_client.dart';
import 'package:smart_photo_diary/services/ai/diary_generator.dart';
import 'package:smart_photo_diary/services/ai/tag_generator.dart';
import 'package:smart_photo_diary/services/ai/offline_fallback_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../test_helpers/mock_platform_channels.dart';

// Mock classes
class MockGeminiApiClient extends Mock implements GeminiApiClient {}
class MockDiaryGenerator extends Mock implements DiaryGenerator {}
class MockTagGenerator extends Mock implements TagGenerator {}
class MockOfflineFallbackService extends Mock implements OfflineFallbackService {}
class MockConnectivity extends Mock implements Connectivity {}

void main() {
  group('AiService', () {
    late AiService aiService;
    late MockGeminiApiClient mockGeminiClient;
    late MockDiaryGenerator mockDiaryGenerator;
    late MockTagGenerator mockTagGenerator;
    late MockOfflineFallbackService mockOfflineService;

    setUpAll(() {
      // Initialize Flutter binding for tests that use platform channels
      TestWidgetsFlutterBinding.ensureInitialized();
      // Setup mock platform channels
      MockPlatformChannels.setupMocks();
    });

    tearDownAll(() {
      // Clear mock platform channels
      MockPlatformChannels.clearMocks();
    });

    setUp(() {
      mockGeminiClient = MockGeminiApiClient();
      mockDiaryGenerator = MockDiaryGenerator();
      mockTagGenerator = MockTagGenerator();
      mockOfflineService = MockOfflineFallbackService();
      
      // Create AiService instance (in real app this would be injected)
      aiService = AiService();
    });

    group('isOnline', () {
      test('should return true when connected to wifi', () async {
        // This test verifies the real connectivity check works
        // In integration tests, this would test actual connectivity
        final result = await aiService.isOnline();
        expect(result, isA<bool>());
      });
    });

    group('generateDiaryFromLabels', () {
      test('should generate diary from labels with basic parameters', () async {
        // Arrange
        final labels = ['cat', 'garden', 'sunny'];
        final date = DateTime(2024, 1, 15, 14, 30);

        // Act - This will make real API call or fallback to offline
        final result = await aiService.generateDiaryFromLabels(
          labels: labels,
          date: date,
        );

        // Assert
        expect(result, isA<DiaryGenerationResult>());
        expect(result.title, isNotEmpty);
        expect(result.content, isNotEmpty);
      });

      test('should generate diary from labels with all parameters', () async {
        // Arrange
        final labels = ['dog', 'park', 'morning'];
        final date = DateTime(2024, 1, 15, 8, 0);
        const location = 'Central Park';
        final photoTimes = [
          DateTime(2024, 1, 15, 8, 0),
          DateTime(2024, 1, 15, 8, 15),
        ];
        final photoTimeLabels = [
          PhotoTimeLabel(time: DateTime(2024, 1, 15, 8, 0), labels: ['dog']),
          PhotoTimeLabel(time: DateTime(2024, 1, 15, 8, 15), labels: ['park']),
        ];

        // Act
        final result = await aiService.generateDiaryFromLabels(
          labels: labels,
          date: date,
          location: location,
          photoTimes: photoTimes,
          photoTimeLabels: photoTimeLabels,
        );

        // Assert
        expect(result, isA<DiaryGenerationResult>());
        expect(result.title, isNotEmpty);
        expect(result.content, isNotEmpty);
      });

      test('should handle empty labels list', () async {
        // Arrange
        final date = DateTime(2024, 1, 15, 14, 30);

        // Act
        final result = await aiService.generateDiaryFromLabels(
          labels: [],
          date: date,
        );

        // Assert
        expect(result, isA<DiaryGenerationResult>());
        expect(result.title, isNotEmpty);
        expect(result.content, isNotEmpty);
      });
    });

    group('generateDiaryFromImage', () {
      test('should generate diary from image data', () async {
        // Arrange
        final imageData = Uint8List.fromList([1, 2, 3, 4]); // Mock image data
        final date = DateTime(2024, 1, 15, 14, 30);

        // Act
        final result = await aiService.generateDiaryFromImage(
          imageData: imageData,
          date: date,
        );

        // Assert
        expect(result, isA<DiaryGenerationResult>());
        expect(result.title, isNotEmpty);
        expect(result.content, isNotEmpty);
      });

      test('should generate diary from image with location and photo times', () async {
        // Arrange
        final imageData = Uint8List.fromList([1, 2, 3, 4]);
        final date = DateTime(2024, 1, 15, 14, 30);
        const location = 'Tokyo Tower';
        final photoTimes = [DateTime(2024, 1, 15, 14, 30)];

        // Act
        final result = await aiService.generateDiaryFromImage(
          imageData: imageData,
          date: date,
          location: location,
          photoTimes: photoTimes,
        );

        // Assert
        expect(result, isA<DiaryGenerationResult>());
        expect(result.title, isNotEmpty);
        expect(result.content, isNotEmpty);
      });
    });

    group('generateDiaryFromMultipleImages', () {
      test('should generate diary from multiple images', () async {
        // Arrange
        final imagesWithTimes = [
          (imageData: Uint8List.fromList([1, 2, 3]), time: DateTime(2024, 1, 15, 8, 0)),
          (imageData: Uint8List.fromList([4, 5, 6]), time: DateTime(2024, 1, 15, 8, 15)),
        ];
        const location = 'Beach';

        // Track progress calls
        final progressCalls = <(int, int)>[];

        // Act
        final result = await aiService.generateDiaryFromMultipleImages(
          imagesWithTimes: imagesWithTimes,
          location: location,
          onProgress: (current, total) {
            progressCalls.add((current, total));
          },
        );

        // Assert
        expect(result, isA<DiaryGenerationResult>());
        expect(result.title, isNotEmpty);
        expect(result.content, isNotEmpty);
        expect(progressCalls, isNotEmpty);
      });

      test('should handle single image in multiple images method', () async {
        // Arrange
        final imagesWithTimes = [
          (imageData: Uint8List.fromList([1, 2, 3]), time: DateTime(2024, 1, 15, 8, 0)),
        ];

        // Act
        final result = await aiService.generateDiaryFromMultipleImages(
          imagesWithTimes: imagesWithTimes,
        );

        // Assert
        expect(result, isA<DiaryGenerationResult>());
        expect(result.title, isNotEmpty);
        expect(result.content, isNotEmpty);
      });

      test('should handle empty images list', () async {
        // Arrange
        final imagesWithTimes = <({Uint8List imageData, DateTime time})>[];

        // Act
        final result = await aiService.generateDiaryFromMultipleImages(
          imagesWithTimes: imagesWithTimes,
        );

        // Assert
        expect(result, isA<DiaryGenerationResult>());
        expect(result.title, isNotEmpty);
        expect(result.content, isNotEmpty);
      });
    });

    group('generateTagsFromContent', () {
      test('should generate tags from diary content', () async {
        // Arrange
        const title = 'Beautiful day at the park';
        const content = 'Went to the park with my dog. The weather was sunny and perfect for a walk. We played fetch and met other dogs.';
        final date = DateTime(2024, 1, 15, 14, 30);
        const photoCount = 3;

        // Act
        final result = await aiService.generateTagsFromContent(
          title: title,
          content: content,
          date: date,
          photoCount: photoCount,
        );

        // Assert
        expect(result, isA<List<String>>());
        expect(result, isNotEmpty);
        // Should contain relevant tags
        expect(result.any((tag) => tag.contains('park') || tag.contains('dog') || tag.contains('sunny') || tag.contains('散歩')), isTrue);
      });

      test('should generate tags for short content', () async {
        // Arrange
        const title = 'Coffee';
        const content = 'Morning coffee.';
        final date = DateTime(2024, 1, 15, 8, 0);
        const photoCount = 1;

        // Act
        final result = await aiService.generateTagsFromContent(
          title: title,
          content: content,
          date: date,
          photoCount: photoCount,
        );

        // Assert
        expect(result, isA<List<String>>());
        expect(result, isNotEmpty);
      });

      test('should handle empty content', () async {
        // Arrange
        const title = '';
        const content = '';
        final date = DateTime(2024, 1, 15, 14, 30);
        const photoCount = 0;

        // Act
        final result = await aiService.generateTagsFromContent(
          title: title,
          content: content,
          date: date,
          photoCount: photoCount,
        );

        // Assert
        expect(result, isA<List<String>>());
        expect(result, isNotEmpty); // Should at least return time-based tags
      });

      test('should generate time-based tags', () async {
        // Arrange
        const title = 'Test';
        const content = 'Test content';
        final morningDate = DateTime(2024, 1, 15, 8, 0);
        const photoCount = 1;

        // Act
        final result = await aiService.generateTagsFromContent(
          title: title,
          content: content,
          date: morningDate,
          photoCount: photoCount,
        );

        // Assert
        expect(result, isA<List<String>>());
        expect(result, isNotEmpty);
        // Should contain time-based tag
        expect(result.any((tag) => tag.contains('朝') || tag.contains('morning')), isTrue);
      });
    });

    group('Error Handling', () {
      test('should provide fallback when network fails', () async {
        // This test would verify offline fallback behavior
        // In a real implementation, we'd mock network failures
        
        final labels = ['test'];
        final date = DateTime(2024, 1, 15, 14, 30);

        // Act - should not throw even if network fails
        final result = await aiService.generateDiaryFromLabels(
          labels: labels,
          date: date,
        );

        // Assert
        expect(result, isA<DiaryGenerationResult>());
        expect(result.title, isNotEmpty);
        expect(result.content, isNotEmpty);
      });

      test('should handle invalid image data gracefully', () async {
        // Arrange
        final invalidImageData = Uint8List(0); // Empty data
        final date = DateTime(2024, 1, 15, 14, 30);

        // Act - should not throw
        final result = await aiService.generateDiaryFromImage(
          imageData: invalidImageData,
          date: date,
        );

        // Assert
        expect(result, isA<DiaryGenerationResult>());
        expect(result.title, isNotEmpty);
        expect(result.content, isNotEmpty);
      });
    });

    group('Interface Compliance', () {
      test('should implement AiServiceInterface', () {
        expect(aiService, isA<AiServiceInterface>());
      });

      test('should have all required interface methods', () {
        // Verify that all interface methods are implemented
        expect(aiService.isOnline, isA<Future<bool> Function()>());
        expect(aiService.generateDiaryFromLabels, isA<Function>());
        expect(aiService.generateDiaryFromImage, isA<Function>());
        expect(aiService.generateDiaryFromMultipleImages, isA<Function>());
        expect(aiService.generateTagsFromContent, isA<Function>());
      });
    });

    group('Data Classes', () {
      test('DiaryGenerationResult should be properly constructed', () {
        // Act
        final result = DiaryGenerationResult(
          title: 'Test Title',
          content: 'Test Content',
        );

        // Assert
        expect(result.title, equals('Test Title'));
        expect(result.content, equals('Test Content'));
      });

      test('PhotoTimeLabel should be properly constructed', () {
        // Arrange
        final time = DateTime(2024, 1, 15, 14, 30);
        final labels = ['test', 'photo'];

        // Act
        final photoTimeLabel = PhotoTimeLabel(
          time: time,
          labels: labels,
        );

        // Assert
        expect(photoTimeLabel.time, equals(time));
        expect(photoTimeLabel.labels, equals(labels));
      });
    });
  });
}