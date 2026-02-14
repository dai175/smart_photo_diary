import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/services/diary_service.dart';
import 'test_helpers/integration_test_helpers.dart';
import 'mocks/mock_services.dart';

// Mock classes for integration testing with real database
class MockAssetEntity extends Mock implements AssetEntity {}

void main() {
  group('DiaryService Integration Tests', () {
    late DiaryService diaryService;

    setUpAll(() async {
      registerMockFallbacks();
      await IntegrationTestHelpers.setUpIntegrationEnvironment();
    });

    tearDownAll(() async {
      await IntegrationTestHelpers.tearDownIntegrationEnvironment();
    });

    setUp(() async {
      // Initialize DiaryService with real Hive database
      diaryService = DiaryService.createWithDependencies();
      await diaryService.initialize();
    });

    group('Database Operations', () {
      test('should save and retrieve diary entry', () async {
        // Arrange
        final testDate = DateTime(2024, 1, 15, 14, 30);
        const title = 'Integration Test Title';
        const content = 'Integration Test Content';
        const photoIds = ['photo1', 'photo2'];

        // Act
        final saveResult = await diaryService.saveDiaryEntry(
          date: testDate,
          title: title,
          content: content,
          photoIds: photoIds,
        );
        expect(saveResult.isSuccess, isTrue);
        final savedEntry = saveResult.value;

        // Retrieve the entry
        final getResult = await diaryService.getDiaryEntry(savedEntry.id);
        expect(getResult.isSuccess, isTrue);
        final retrievedEntry = getResult.value;

        // Assert
        expect(retrievedEntry, isNotNull);
        expect(retrievedEntry!.id, equals(savedEntry.id));
        expect(retrievedEntry.title, equals(title));
        expect(retrievedEntry.content, equals(content));
        expect(retrievedEntry.photoIds, equals(photoIds));
      });

      test('should update diary entry', () async {
        // Arrange
        final saveResult = await diaryService.saveDiaryEntry(
          date: DateTime(2024, 1, 15),
          title: 'Original Title',
          content: 'Original Content',
          photoIds: ['photo1'],
        );
        expect(saveResult.isSuccess, isTrue);
        final originalEntry = saveResult.value;

        final updatedEntry = originalEntry.copyWith(
          title: 'Updated Title',
          content: 'Updated Content',
          updatedAt: DateTime.now(),
        );

        // Act
        final updateResult = await diaryService.updateDiaryEntry(updatedEntry);
        expect(updateResult.isSuccess, isTrue);
        final getResult = await diaryService.getDiaryEntry(originalEntry.id);
        expect(getResult.isSuccess, isTrue);
        final retrievedEntry = getResult.value;

        // Assert
        expect(retrievedEntry, isNotNull);
        expect(retrievedEntry!.title, equals('Updated Title'));
        expect(retrievedEntry.content, equals('Updated Content'));
      });

      test('should delete diary entry', () async {
        // Arrange
        final saveResult = await diaryService.saveDiaryEntry(
          date: DateTime(2024, 1, 15),
          title: 'To Delete',
          content: 'This will be deleted',
          photoIds: [],
        );
        expect(saveResult.isSuccess, isTrue);
        final entry = saveResult.value;

        // Act
        await diaryService.deleteDiaryEntry(entry.id);
        final getResult = await diaryService.getDiaryEntry(entry.id);

        // Assert
        expect(getResult.value, isNull);
      });
    });

    group('Query Operations', () {
      test('should return sorted diary entries', () async {
        // Arrange - Clear existing entries
        final allResult = await diaryService.getSortedDiaryEntries();
        expect(allResult.isSuccess, isTrue);
        for (final entry in allResult.value) {
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
        final sortedResult = await diaryService.getSortedDiaryEntries();

        // Assert
        expect(sortedResult.isSuccess, isTrue);
        expect(sortedResult.value.length, equals(2));
      });
    });

    group('AssetEntity Conversion Integration', () {
      test(
        'should convert AssetEntity list to photo IDs with real data',
        () async {
          // Arrange
          final mockAsset1 = MockAssetEntity();
          final mockAsset2 = MockAssetEntity();
          when(() => mockAsset1.id).thenReturn('real_asset_1');
          when(() => mockAsset2.id).thenReturn('real_asset_2');

          final testDate = DateTime(2024, 1, 15, 14, 30);
          final assets = [mockAsset1, mockAsset2];

          // Act
          final saveResult = await diaryService.saveDiaryEntryWithPhotos(
            date: testDate,
            title: 'Asset Test',
            content: 'Testing asset conversion',
            photos: assets,
          );
          expect(saveResult.isSuccess, isTrue);
          final result = saveResult.value;

          // Retrieve to verify
          final getResult = await diaryService.getDiaryEntry(result.id);
          expect(getResult.isSuccess, isTrue);
          final retrievedEntry = getResult.value;

          // Assert
          expect(retrievedEntry, isNotNull);
          expect(
            retrievedEntry!.photoIds,
            equals(['real_asset_1', 'real_asset_2']),
          );
        },
      );
    });

    group('Error Handling Integration', () {
      test('should handle invalid diary entry ID gracefully', () async {
        // Act
        final result = await diaryService.getDiaryEntry('non_existent_id');

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isNull);
      });

      test('should handle duplicate deletion gracefully', () async {
        // Arrange
        final saveResult = await diaryService.saveDiaryEntry(
          date: DateTime(2024, 1, 15),
          title: 'Test Entry',
          content: 'Test Content',
          photoIds: [],
        );
        expect(saveResult.isSuccess, isTrue);
        final entry = saveResult.value;

        // Act - Delete twice
        await diaryService.deleteDiaryEntry(entry.id);

        // Should not throw error on second deletion
        final secondDelete = await diaryService.deleteDiaryEntry(entry.id);
        expect(secondDelete.isSuccess, isTrue);
      });
    });
  });
}
