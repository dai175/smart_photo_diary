import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
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
    late DiaryService diaryService;

    setUpAll(() async {
      registerMockFallbacks();
      await IntegrationTestHelpers.setUpIntegrationEnvironment();
    });

    tearDownAll(() async {
      await IntegrationTestHelpers.tearDownIntegrationEnvironment();
    });

    setUp(() async {
      // Initialize services for integration testing

      // Initialize DiaryService with real Hive database
      diaryService = await DiaryService.getInstance();
      
      // テスト環境でバックグラウンド処理を無効化（CI環境での非同期処理継続問題を回避）
      diaryService.disableBackgroundProcessing();
    });

    group('Database Operations', () {
      test('should save and retrieve diary entry', () async {
        // Arrange
        final testDate = DateTime(2024, 1, 15, 14, 30);
        const title = 'Integration Test Title';
        const content = 'Integration Test Content';
        const photoIds = ['photo1', 'photo2'];

        // Act
        final savedEntryResult = await diaryService.saveDiaryEntry(
          date: testDate,
          title: title,
          content: content,
          photoIds: photoIds,
        );
        final savedEntry = savedEntryResult.fold(
          (entry) => entry,
          (error) => throw error,
        );

        // Retrieve the entry
        final retrievedEntryResult = await diaryService.getDiaryEntry(
          savedEntry.id,
        );
        final retrievedEntry = retrievedEntryResult.fold(
          (entry) => entry,
          (error) => null,
        );

        // Assert
        expect(retrievedEntry, isNotNull);
        expect(retrievedEntry!.id, equals(savedEntry.id));
        expect(retrievedEntry.title, equals(title));
        expect(retrievedEntry.content, equals(content));
        expect(retrievedEntry.photoIds, equals(photoIds));
      });

      test('should update diary entry', () async {
        // Arrange
        final originalEntryResult = await diaryService.saveDiaryEntry(
          date: DateTime(2024, 1, 15),
          title: 'Original Title',
          content: 'Original Content',
          photoIds: ['photo1'],
        );
        final originalEntry = originalEntryResult.fold(
          (entry) => entry,
          (error) => throw error,
        );

        final updatedEntry = originalEntry.copyWith(
          title: 'Updated Title',
          content: 'Updated Content',
          updatedAt: DateTime.now(),
        );

        // Act
        final updateResult = await diaryService.updateDiaryEntry(updatedEntry);
        updateResult.fold((entry) => entry, (error) => throw error);
        final retrievedEntryResult = await diaryService.getDiaryEntry(
          originalEntry.id,
        );
        final retrievedEntry = retrievedEntryResult.fold(
          (entry) => entry,
          (error) => null,
        );

        // Assert
        expect(retrievedEntry, isNotNull);
        expect(retrievedEntry!.title, equals('Updated Title'));
        expect(retrievedEntry.content, equals('Updated Content'));
      });

      test('should delete diary entry', () async {
        // Arrange
        final entryResult = await diaryService.saveDiaryEntry(
          date: DateTime(2024, 1, 15),
          title: 'To Delete',
          content: 'This will be deleted',
          photoIds: [],
        );
        final entry = entryResult.fold(
          (entry) => entry,
          (error) => throw error,
        );

        // Act
        final deleteResult = await diaryService.deleteDiaryEntry(entry.id);
        deleteResult.fold((_) {}, (error) => throw error);
        final retrievedEntryResult = await diaryService.getDiaryEntry(entry.id);
        final retrievedEntry = retrievedEntryResult.fold(
          (entry) => entry,
          (error) => null,
        );

        // Assert
        expect(retrievedEntry, isNull);
      });
    });

    group('Statistics Operations', () {
      test('should return total diary count', () async {
        // Arrange - Clear existing entries
        final allEntriesResult = await diaryService.getAllDiaryEntries();
        allEntriesResult.fold((allEntries) async {
          for (final entry in allEntries) {
            final deleteResult = await diaryService.deleteDiaryEntry(entry.id);
            deleteResult.fold((_) {}, (error) => throw error);
          }
        }, (error) => throw error);

        // Add test entries
        final entry1Result = await diaryService.saveDiaryEntry(
          date: DateTime(2024, 1, 15),
          title: 'Test Entry 1',
          content: 'Content 1',
          photoIds: [],
        );
        entry1Result.fold((entry) => entry, (error) => throw error);
        final entry2Result = await diaryService.saveDiaryEntry(
          date: DateTime(2024, 1, 16),
          title: 'Test Entry 2',
          content: 'Content 2',
          photoIds: [],
        );
        entry2Result.fold((entry) => entry, (error) => throw error);

        // Act
        final countResult = await diaryService.getTotalDiaryCount();
        final count = countResult.fold(
          (count) => count,
          (error) => throw error,
        );

        // Assert
        expect(count, equals(2));
      });

      test('should return diary count in period', () async {
        // Arrange
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 31);

        // Clear existing entries
        final allEntriesResult = await diaryService.getAllDiaryEntries();
        allEntriesResult.fold((allEntries) async {
          for (final entry in allEntries) {
            final deleteResult = await diaryService.deleteDiaryEntry(entry.id);
            deleteResult.fold((_) {}, (error) => throw error);
          }
        }, (error) => throw error);

        // Add entries within period
        final withinPeriodResult = await diaryService.saveDiaryEntry(
          date: DateTime(2024, 1, 15),
          title: 'Within Period',
          content: 'Content',
          photoIds: [],
        );
        withinPeriodResult.fold((entry) => entry, (error) => throw error);

        // Add entry outside period
        final outsidePeriodResult = await diaryService.saveDiaryEntry(
          date: DateTime(2024, 2, 1),
          title: 'Outside Period',
          content: 'Content',
          photoIds: [],
        );
        outsidePeriodResult.fold((entry) => entry, (error) => throw error);

        // Act
        final countResult = await diaryService.getDiaryCountInPeriod(
          start,
          end,
        );
        final count = countResult.fold(
          (count) => count,
          (error) => throw error,
        );

        // Assert
        expect(count, equals(1));
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
          final resultEntry = await diaryService.saveDiaryEntryWithPhotos(
            date: testDate,
            title: 'Asset Test',
            content: 'Testing asset conversion',
            photos: assets,
          );
          final result = resultEntry.fold(
            (entry) => entry,
            (error) => throw error,
          );

          // Retrieve to verify
          final retrievedEntryResult = await diaryService.getDiaryEntry(
            result.id,
          );
          final retrievedEntry = retrievedEntryResult.fold(
            (entry) => entry,
            (error) => null,
          );

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
        final resultEntry = await diaryService.getDiaryEntry('non_existent_id');
        final result = resultEntry.fold((entry) => entry, (error) => null);

        // Assert
        expect(result, isNull);
      });

      test('should handle duplicate deletion gracefully', () async {
        // Arrange
        final entryResult = await diaryService.saveDiaryEntry(
          date: DateTime(2024, 1, 15),
          title: 'Test Entry',
          content: 'Test Content',
          photoIds: [],
        );
        final entry = entryResult.fold(
          (entry) => entry,
          (error) => throw error,
        );

        // Act - Delete twice
        final firstDeleteResult = await diaryService.deleteDiaryEntry(entry.id);
        firstDeleteResult.fold((_) {}, (error) => throw error);

        // Should not throw error on second deletion
        final secondDeleteResult = await diaryService.deleteDiaryEntry(
          entry.id,
        );
        expect(
          () => secondDeleteResult.fold((_) {}, (error) => error),
          returnsNormally,
        );
      });
    });
  });
}
