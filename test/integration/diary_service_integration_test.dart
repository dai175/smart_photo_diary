import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/services/diary_service.dart';
import 'package:smart_photo_diary/services/ai/ai_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'test_helpers/integration_test_helpers.dart';
import 'mocks/mock_services.dart';

// Mock classes for integration testing with real database
class MockAiServiceInterface extends Mock implements AiServiceInterface {}
class MockPhotoServiceInterface extends Mock implements PhotoServiceInterface {}
class MockAssetEntity extends Mock implements AssetEntity {}

void main() {
  group('DiaryService Integration Tests', () {
    late MockAiServiceInterface mockAiService;
    late MockPhotoServiceInterface mockPhotoService;
    late DiaryService diaryService;

    setUpAll(() async {
      registerMockFallbacks();
      await IntegrationTestHelpers.setUpIntegrationEnvironment();
    });

    tearDownAll(() async {
      await IntegrationTestHelpers.tearDownIntegrationEnvironment();
    });

    setUp(() async {
      mockAiService = MockAiServiceInterface();
      mockPhotoService = MockPhotoServiceInterface();
      
      // Initialize DiaryService with real Hive database
      diaryService = await DiaryService.getInstance();
    });

    group('Database Operations', () {
      test('should save and retrieve diary entry', () async {
        // Arrange
        final testDate = DateTime(2024, 1, 15, 14, 30);
        const title = 'Integration Test Title';
        const content = 'Integration Test Content';
        const photoIds = ['photo1', 'photo2'];

        // Act
        final savedEntry = await diaryService.saveDiaryEntry(
          date: testDate,
          title: title,
          content: content,
          photoIds: photoIds,
        );

        // Retrieve the entry
        final retrievedEntry = await diaryService.getDiaryEntry(savedEntry.id);

        // Assert
        expect(retrievedEntry, isNotNull);
        expect(retrievedEntry!.id, equals(savedEntry.id));
        expect(retrievedEntry.title, equals(title));
        expect(retrievedEntry.content, equals(content));
        expect(retrievedEntry.photoIds, equals(photoIds));
      });

      test('should update diary entry', () async {
        // Arrange
        final originalEntry = await diaryService.saveDiaryEntry(
          date: DateTime(2024, 1, 15),
          title: 'Original Title',
          content: 'Original Content',
          photoIds: ['photo1'],
        );

        final updatedEntry = originalEntry.copyWith(
          title: 'Updated Title',
          content: 'Updated Content',
          updatedAt: DateTime.now(),
        );

        // Act
        await diaryService.updateDiaryEntry(updatedEntry);
        final retrievedEntry = await diaryService.getDiaryEntry(originalEntry.id);

        // Assert
        expect(retrievedEntry, isNotNull);
        expect(retrievedEntry!.title, equals('Updated Title'));
        expect(retrievedEntry.content, equals('Updated Content'));
      });

      test('should delete diary entry', () async {
        // Arrange
        final entry = await diaryService.saveDiaryEntry(
          date: DateTime(2024, 1, 15),
          title: 'To Delete',
          content: 'This will be deleted',
          photoIds: [],
        );

        // Act
        await diaryService.deleteDiaryEntry(entry.id);
        final retrievedEntry = await diaryService.getDiaryEntry(entry.id);

        // Assert
        expect(retrievedEntry, isNull);
      });

    });

    group('Statistics Operations', () {
      test('should return total diary count', () async {
        // Arrange - Clear existing entries
        final allEntries = await diaryService.getAllDiaryEntries();
        for (final entry in allEntries) {
          await diaryService.deleteDiaryEntry(entry.id);
        }

        // Add test entries
        await diaryService.saveDiaryEntry(
          date: DateTime(2024, 1, 15),
          title: 'Test Entry 1',
          content: 'Content 1',
          photoIds: [],
        );
        await diaryService.saveDiaryEntry(
          date: DateTime(2024, 1, 16),
          title: 'Test Entry 2',
          content: 'Content 2',
          photoIds: [],
        );

        // Act
        final count = await diaryService.getTotalDiaryCount();

        // Assert
        expect(count, equals(2));
      });

      test('should return diary count in period', () async {
        // Arrange
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 31);

        // Clear existing entries
        final allEntries = await diaryService.getAllDiaryEntries();
        for (final entry in allEntries) {
          await diaryService.deleteDiaryEntry(entry.id);
        }

        // Add entries within period
        await diaryService.saveDiaryEntry(
          date: DateTime(2024, 1, 15),
          title: 'Within Period',
          content: 'Content',
          photoIds: [],
        );

        // Add entry outside period
        await diaryService.saveDiaryEntry(
          date: DateTime(2024, 2, 1),
          title: 'Outside Period',
          content: 'Content',
          photoIds: [],
        );

        // Act
        final count = await diaryService.getDiaryCountInPeriod(start, end);

        // Assert
        expect(count, equals(1));
      });

    });

    group('AssetEntity Conversion Integration', () {
      test('should convert AssetEntity list to photo IDs with real data', () async {
        // Arrange
        final mockAsset1 = MockAssetEntity();
        final mockAsset2 = MockAssetEntity();
        when(() => mockAsset1.id).thenReturn('real_asset_1');
        when(() => mockAsset2.id).thenReturn('real_asset_2');
        
        final testDate = DateTime(2024, 1, 15, 14, 30);
        final assets = [mockAsset1, mockAsset2];

        // Act
        final result = await diaryService.saveDiaryEntryWithPhotos(
          date: testDate,
          title: 'Asset Test',
          content: 'Testing asset conversion',
          photos: assets,
        );

        // Retrieve to verify
        final retrievedEntry = await diaryService.getDiaryEntry(result.id);

        // Assert
        expect(retrievedEntry, isNotNull);
        expect(retrievedEntry!.photoIds, equals(['real_asset_1', 'real_asset_2']));
      });
    });

    group('Error Handling Integration', () {
      test('should handle invalid diary entry ID gracefully', () async {
        // Act
        final result = await diaryService.getDiaryEntry('non_existent_id');

        // Assert
        expect(result, isNull);
      });

      test('should handle duplicate deletion gracefully', () async {
        // Arrange
        final entry = await diaryService.saveDiaryEntry(
          date: DateTime(2024, 1, 15),
          title: 'Test Entry',
          content: 'Test Content',
          photoIds: [],
        );

        // Act - Delete twice
        await diaryService.deleteDiaryEntry(entry.id);
        
        // Should not throw error on second deletion
        expect(
          () => diaryService.deleteDiaryEntry(entry.id),
          returnsNormally,
        );
      });
    });
  });
}