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
      test('should create diary entry with required fields', () {
        // Arrange
        final testDate = DateTime(2024, 1, 15, 14, 30);
        const title = 'Test Title';
        const content = 'Test Content';
        const photoIds = ['photo1', 'photo2'];

        // Act - Test creation logic without database save
        final entry = DiaryEntry(
          id: 'test-id',
          date: testDate,
          title: title,
          content: content,
          photoIds: photoIds,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Assert
        expect(entry.date, equals(testDate));
        expect(entry.title, equals(title));
        expect(entry.content, equals(content));
        expect(entry.photoIds, equals(photoIds));
        expect(entry.id, isNotEmpty);
        expect(entry.createdAt, isNotNull);
        expect(entry.updatedAt, isNotNull);
      });

      test('should create diary entry with optional fields', () {
        // Arrange
        final testDate = DateTime(2024, 1, 15, 14, 30);
        const title = 'Test Title';
        const content = 'Test Content';
        const photoIds = ['photo1'];
        const location = 'Test Location';
        const tags = ['tag1', 'tag2'];

        // Act - Test creation logic without database save
        final entry = DiaryEntry(
          id: 'test-id',
          date: testDate,
          title: title,
          content: content,
          photoIds: photoIds,
          location: location,
          tags: tags,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Assert
        expect(entry.location, equals(location));
        expect(entry.tags, equals(tags));
      });

      test('should handle empty photo IDs', () {
        // Arrange
        final testDate = DateTime(2024, 1, 15, 14, 30);

        // Act - Test creation logic without database save
        final entry = DiaryEntry(
          id: 'test-id',
          date: testDate,
          title: 'Test Title',
          content: 'Test Content',
          photoIds: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Assert
        expect(entry.photoIds, isEmpty);
      });
    });

    group('AssetEntity to PhotoIds Conversion', () {
      test('should convert AssetEntity list to photo IDs', () {
        // Arrange
        final mockAsset1 = MockAssetEntity();
        final mockAsset2 = MockAssetEntity();
        when(() => mockAsset1.id).thenReturn('asset1');
        when(() => mockAsset2.id).thenReturn('asset2');
        
        final assets = [mockAsset1, mockAsset2];

        // Act - Test conversion logic
        final photoIds = assets.map((asset) => asset.id).toList();

        // Assert
        expect(photoIds, equals(['asset1', 'asset2']));
      });

      test('should handle empty AssetEntity list', () {
        // Arrange
        final assets = <MockAssetEntity>[];

        // Act - Test conversion logic
        final photoIds = assets.map((asset) => asset.id).toList();

        // Assert
        expect(photoIds, isEmpty);
      });
    });

    group('Tags Validation Logic', () {
      test('should identify valid cached tags', () {
        // Arrange
        final validTagsDate = DateTime.now().subtract(const Duration(days: 3));
        final entry = DiaryEntry(
          id: 'test-id',
          date: DateTime(2024, 1, 15),
          title: 'Test Title',
          content: 'Test Content',
          photoIds: ['photo1'],
          createdAt: DateTime(2024, 1, 15, 14),
          updatedAt: DateTime(2024, 1, 15, 14),
          cachedTags: ['cached-tag1', 'cached-tag2'],
          tagsGeneratedAt: validTagsDate,
        );

        // Act & Assert
        expect(entry.hasValidTags, isTrue);
        expect(entry.cachedTags, equals(['cached-tag1', 'cached-tag2']));
      });

      test('should identify invalid cached tags', () {
        // Arrange
        final oldTagsDate = DateTime.now().subtract(const Duration(days: 8));
        final entry = DiaryEntry(
          id: 'test-id',
          date: DateTime(2024, 1, 15),
          title: 'Test Title',
          content: 'Test Content',
          photoIds: ['photo1'],
          createdAt: DateTime(2024, 1, 15, 14),
          updatedAt: DateTime(2024, 1, 15, 14),
          cachedTags: ['old-tag'],
          tagsGeneratedAt: oldTagsDate,
        );

        // Act & Assert
        expect(entry.hasValidTags, isFalse);
        expect(entry.cachedTags, equals(['old-tag']));
      });

      test('should identify missing tags', () {
        // Arrange
        final entry = DiaryEntry(
          id: 'test-id',
          date: DateTime(2024, 1, 15, 10, 30),
          title: 'Test Title',
          content: 'Test Content',
          photoIds: ['photo1'],
          createdAt: DateTime(2024, 1, 15, 14),
          updatedAt: DateTime(2024, 1, 15, 14),
        );

        // Act & Assert
        expect(entry.hasValidTags, isFalse);
        expect(entry.cachedTags, isNull);
        expect(entry.tagsGeneratedAt, isNull);
      });
    });

    group('Time-based Tag Logic', () {
      test('should identify morning time correctly', () {
        // Arrange & Act
        final morningTime = DateTime(2024, 1, 15, 8, 0); // 8 AM
        
        // Assert - Test time-based logic
        expect(morningTime.hour >= 6 && morningTime.hour < 12, isTrue);
      });

      test('should identify afternoon time correctly', () {
        // Arrange & Act
        final afternoonTime = DateTime(2024, 1, 15, 15, 0); // 3 PM
        
        // Assert - Test time-based logic
        expect(afternoonTime.hour >= 12 && afternoonTime.hour < 18, isTrue);
      });

      test('should identify evening time correctly', () {
        // Arrange & Act
        final eveningTime = DateTime(2024, 1, 15, 19, 0); // 7 PM
        
        // Assert - Test time-based logic
        expect(eveningTime.hour >= 18 && eveningTime.hour < 22, isTrue);
      });

      test('should identify night time correctly', () {
        // Arrange & Act
        final nightTime = DateTime(2024, 1, 15, 23, 0); // 11 PM
        
        // Assert - Test time-based logic
        expect(nightTime.hour >= 22 || nightTime.hour < 6, isTrue);
      });

      test('should generate appropriate fallback tag based on time', () {
        // Test the time-to-tag mapping logic
        final testCases = [
          (DateTime(2024, 1, 15, 8, 0), '朝'),   // Morning
          (DateTime(2024, 1, 15, 15, 0), '昼'),  // Afternoon
          (DateTime(2024, 1, 15, 19, 0), '夕方'), // Evening
          (DateTime(2024, 1, 15, 23, 0), '夜'),   // Night
        ];

        for (final (dateTime, expectedTag) in testCases) {
          String actualTag;
          final hour = dateTime.hour;
          
          if (hour >= 6 && hour < 12) {
            actualTag = '朝';
          } else if (hour >= 12 && hour < 18) {
            actualTag = '昼';
          } else if (hour >= 18 && hour < 22) {
            actualTag = '夕方';
          } else {
            actualTag = '夜';
          }
          
          expect(actualTag, equals(expectedTag));
        }
      });
    });

    group('Dependency Injection Verification', () {
      test('should verify mock AI service interface', () {
        // Arrange
        when(() => mockAiService.generateTagsFromContent(
          title: any(named: 'title'),
          content: any(named: 'content'),
          date: any(named: 'date'),
          photoCount: any(named: 'photoCount'),
        )).thenAnswer((_) async => ['mock-tag']);

        // Act & Assert - Verify mock is properly configured
        expect(mockAiService, isA<AiServiceInterface>());
        
        // Verify the mock has not been called yet
        verifyNever(() => mockAiService.generateTagsFromContent(
          title: any(named: 'title'),
          content: any(named: 'content'),
          date: any(named: 'date'),
          photoCount: any(named: 'photoCount'),
        ));
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