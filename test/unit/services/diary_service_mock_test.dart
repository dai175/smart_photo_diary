import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/services/diary_service.dart';
import 'package:smart_photo_diary/services/ai/ai_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import '../../test_helpers/mock_platform_channels.dart';

// Mock classes
class MockAiServiceInterface extends Mock implements AiServiceInterface {}
class MockPhotoServiceInterface extends Mock implements PhotoServiceInterface {}
class MockAssetEntity extends Mock implements AssetEntity {}

void main() {
  group('DiaryService Mock Tests', () {
    late MockAiServiceInterface mockAiService;
    late MockPhotoServiceInterface mockPhotoService;
    late DiaryService diaryService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      MockPlatformChannels.setupMocks();
      registerFallbackValue(MockAssetEntity());
    });

    tearDownAll(() {
      MockPlatformChannels.clearMocks();
    });

    setUp(() {
      mockAiService = MockAiServiceInterface();
      mockPhotoService = MockPhotoServiceInterface();
      
      diaryService = DiaryService.createWithDependencies(
        aiService: mockAiService,
        photoService: mockPhotoService,
      );
    });

    group('DiaryEntry Creation Logic', () {
      test('should create diary entry with required fields', () async {
        // Arrange
        final testDate = DateTime(2024, 1, 15, 14, 30);
        const title = 'Test Title';
        const content = 'Test Content';
        const photoIds = ['photo1', 'photo2'];

        // Act
        final result = await diaryService.saveDiaryEntry(
          date: testDate,
          title: title,
          content: content,
          photoIds: photoIds,
        );

        // Assert
        expect(result.date, equals(testDate));
        expect(result.title, equals(title));
        expect(result.content, equals(content));
        expect(result.photoIds, equals(photoIds));
        expect(result.id, isNotEmpty);
        expect(result.createdAt, isNotNull);
        expect(result.updatedAt, isNotNull);
      });

      test('should create diary entry with optional fields', () async {
        // Arrange
        final testDate = DateTime(2024, 1, 15, 14, 30);
        const title = 'Test Title';
        const content = 'Test Content';
        const photoIds = ['photo1'];
        const location = 'Test Location';
        const tags = ['tag1', 'tag2'];

        // Act
        final result = await diaryService.saveDiaryEntry(
          date: testDate,
          title: title,
          content: content,
          photoIds: photoIds,
          location: location,
          tags: tags,
        );

        // Assert
        expect(result.location, equals(location));
        expect(result.tags, equals(tags));
      });

      test('should handle empty photo IDs', () async {
        // Arrange
        final testDate = DateTime(2024, 1, 15, 14, 30);

        // Act
        final result = await diaryService.saveDiaryEntry(
          date: testDate,
          title: 'Test Title',
          content: 'Test Content',
          photoIds: [],
        );

        // Assert
        expect(result.photoIds, isEmpty);
      });
    });

    group('AssetEntity to PhotoIds Conversion', () {
      test('should convert AssetEntity list to photo IDs', () async {
        // Arrange
        final mockAsset1 = MockAssetEntity();
        final mockAsset2 = MockAssetEntity();
        when(() => mockAsset1.id).thenReturn('asset1');
        when(() => mockAsset2.id).thenReturn('asset2');
        
        final testDate = DateTime(2024, 1, 15, 14, 30);
        final assets = [mockAsset1, mockAsset2];

        // Act
        final result = await diaryService.saveDiaryEntryWithPhotos(
          date: testDate,
          title: 'Test Title',
          content: 'Test Content',
          photos: assets,
        );

        // Assert
        expect(result.photoIds, equals(['asset1', 'asset2']));
      });

      test('should handle empty AssetEntity list', () async {
        // Arrange
        final testDate = DateTime(2024, 1, 15, 14, 30);

        // Act
        final result = await diaryService.saveDiaryEntryWithPhotos(
          date: testDate,
          title: 'Test Title',
          content: 'Test Content',
          photos: [],
        );

        // Assert
        expect(result.photoIds, isEmpty);
      });
    });

    group('Tags Generation Logic', () {
      test('should return cached tags when valid', () async {
        // Arrange
        final validTagsDate = DateTime.now().subtract(const Duration(days: 3));
        final entry = DiaryEntry(
          id: 'test-id',
          date: DateTime(2024, 1, 15),
          title: 'Test Title',
          content: 'Test Content',
          photoIds: ['photo1'],
          createdAt: DateTime(2024, 1, 15, 14, 0),
          updatedAt: DateTime(2024, 1, 15, 14, 0),
          cachedTags: ['cached-tag1', 'cached-tag2'],
          tagsGeneratedAt: validTagsDate,
        );

        // Act
        final result = await diaryService.getTagsForEntry(entry);

        // Assert
        expect(result, equals(['cached-tag1', 'cached-tag2']));
        verifyNever(() => mockAiService.generateTagsFromContent(
          title: any(named: 'title'),
          content: any(named: 'content'),
          date: any(named: 'date'),
          photoCount: any(named: 'photoCount'),
        ));
      });

      test('should generate new tags when cache is invalid', () async {
        // Arrange
        final oldTagsDate = DateTime.now().subtract(const Duration(days: 8));
        final entry = DiaryEntry(
          id: 'test-id',
          date: DateTime(2024, 1, 15),
          title: 'Test Title',
          content: 'Test Content',
          photoIds: ['photo1'],
          createdAt: DateTime(2024, 1, 15, 14, 0),
          updatedAt: DateTime(2024, 1, 15, 14, 0),
          cachedTags: ['old-tag'],
          tagsGeneratedAt: oldTagsDate,
        );

        when(() => mockAiService.generateTagsFromContent(
          title: 'Test Title',
          content: 'Test Content',
          date: DateTime(2024, 1, 15),
          photoCount: 1,
        )).thenAnswer((_) async => ['new-tag1', 'new-tag2']);

        // Act
        final result = await diaryService.getTagsForEntry(entry);

        // Assert
        expect(result, equals(['new-tag1', 'new-tag2']));
        verify(() => mockAiService.generateTagsFromContent(
          title: 'Test Title',
          content: 'Test Content',
          date: DateTime(2024, 1, 15),
          photoCount: 1,
        )).called(1);
      });

      test('should return fallback tags when AI service fails', () async {
        // Arrange
        final entry = DiaryEntry(
          id: 'test-id',
          date: DateTime(2024, 1, 15, 10, 30), // Morning time
          title: 'Test Title',
          content: 'Test Content',
          photoIds: ['photo1'],
          createdAt: DateTime(2024, 1, 15, 14, 0),
          updatedAt: DateTime(2024, 1, 15, 14, 0),
          cachedTags: null,
          tagsGeneratedAt: null,
        );

        when(() => mockAiService.generateTagsFromContent(
          title: any(named: 'title'),
          content: any(named: 'content'),
          date: any(named: 'date'),
          photoCount: any(named: 'photoCount'),
        )).thenThrow(Exception('AI service error'));

        // Act
        final result = await diaryService.getTagsForEntry(entry);

        // Assert
        expect(result, contains('朝')); // Should contain morning tag
        expect(result.length, equals(1));
      });
    });

    group('Fallback Tags Generation Logic', () {
      test('should generate morning tag for morning time', () async {
        // Arrange
        final entry = DiaryEntry(
          id: 'test-id',
          date: DateTime(2024, 1, 15, 8, 0), // 8 AM
          title: 'Morning Title',
          content: 'Morning Content',
          photoIds: ['photo1'],
          createdAt: DateTime(2024, 1, 15, 8, 0),
          updatedAt: DateTime(2024, 1, 15, 8, 0),
        );

        when(() => mockAiService.generateTagsFromContent(
          title: any(named: 'title'),
          content: any(named: 'content'),
          date: any(named: 'date'),
          photoCount: any(named: 'photoCount'),
        )).thenThrow(Exception('AI service error'));

        // Act
        final result = await diaryService.getTagsForEntry(entry);

        // Assert
        expect(result, contains('朝'));
      });

      test('should generate afternoon tag for afternoon time', () async {
        // Arrange
        final entry = DiaryEntry(
          id: 'test-id',
          date: DateTime(2024, 1, 15, 15, 0), // 3 PM
          title: 'Afternoon Title',
          content: 'Afternoon Content',
          photoIds: ['photo1'],
          createdAt: DateTime(2024, 1, 15, 15, 0),
          updatedAt: DateTime(2024, 1, 15, 15, 0),
        );

        when(() => mockAiService.generateTagsFromContent(
          title: any(named: 'title'),
          content: any(named: 'content'),
          date: any(named: 'date'),
          photoCount: any(named: 'photoCount'),
        )).thenThrow(Exception('AI service error'));

        // Act
        final result = await diaryService.getTagsForEntry(entry);

        // Assert
        expect(result, contains('昼'));
      });

      test('should generate evening tag for evening time', () async {
        // Arrange
        final entry = DiaryEntry(
          id: 'test-id',
          date: DateTime(2024, 1, 15, 19, 0), // 7 PM
          title: 'Evening Title',
          content: 'Evening Content',
          photoIds: ['photo1'],
          createdAt: DateTime(2024, 1, 15, 19, 0),
          updatedAt: DateTime(2024, 1, 15, 19, 0),
        );

        when(() => mockAiService.generateTagsFromContent(
          title: any(named: 'title'),
          content: any(named: 'content'),
          date: any(named: 'date'),
          photoCount: any(named: 'photoCount'),
        )).thenThrow(Exception('AI service error'));

        // Act
        final result = await diaryService.getTagsForEntry(entry);

        // Assert
        expect(result, contains('夕方'));
      });

      test('should generate night tag for night time', () async {
        // Arrange
        final entry = DiaryEntry(
          id: 'test-id',
          date: DateTime(2024, 1, 15, 23, 0), // 11 PM
          title: 'Night Title',
          content: 'Night Content',
          photoIds: ['photo1'],
          createdAt: DateTime(2024, 1, 15, 23, 0),
          updatedAt: DateTime(2024, 1, 15, 23, 0),
        );

        when(() => mockAiService.generateTagsFromContent(
          title: any(named: 'title'),
          content: any(named: 'content'),
          date: any(named: 'date'),
          photoCount: any(named: 'photoCount'),
        )).thenThrow(Exception('AI service error'));

        // Act
        final result = await diaryService.getTagsForEntry(entry);

        // Assert
        expect(result, contains('夜'));
      });
    });

    group('Dependency Injection Verification', () {
      test('should use injected AI service', () async {
        // This test verifies that the injected mock is being used
        final entry = DiaryEntry(
          id: 'test-id',
          date: DateTime(2024, 1, 15),
          title: 'Test Title',
          content: 'Test Content',
          photoIds: ['photo1'],
          createdAt: DateTime(2024, 1, 15, 14, 0),
          updatedAt: DateTime(2024, 1, 15, 14, 0),
          cachedTags: null,
          tagsGeneratedAt: null,
        );

        when(() => mockAiService.generateTagsFromContent(
          title: any(named: 'title'),
          content: any(named: 'content'),
          date: any(named: 'date'),
          photoCount: any(named: 'photoCount'),
        )).thenAnswer((_) async => ['injected-tag']);

        // Act
        await diaryService.getTagsForEntry(entry);

        // Assert
        verify(() => mockAiService.generateTagsFromContent(
          title: 'Test Title',
          content: 'Test Content',
          date: DateTime(2024, 1, 15),
          photoCount: 1,
        )).called(1);
      });

      test('should create instance with dependencies', () {
        // Act
        final service = DiaryService.createWithDependencies(
          aiService: mockAiService,
          photoService: mockPhotoService,
        );

        // Assert
        expect(service, isA<DiaryService>());
      });
    });

    group('Interface Compliance', () {
      test('should implement DiaryService interface', () {
        expect(diaryService, isA<DiaryService>());
      });

      test('should have all required service methods', () {
        expect(diaryService.saveDiaryEntry, isA<Function>());
        expect(diaryService.saveDiaryEntryWithPhotos, isA<Function>());
        expect(diaryService.getTagsForEntry, isA<Function>());
      });
    });
  });
}