import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';

void main() {
  group('DiaryEntry', () {
    late DateTime testDate;
    late DateTime testCreatedAt;
    late DateTime testUpdatedAt;

    setUp(() {
      testDate = DateTime(2024, 1, 15, 14, 30);
      testCreatedAt = DateTime(2024, 1, 15, 14, 31);
      testUpdatedAt = DateTime(2024, 1, 15, 14, 32);
    });

    group('Constructor', () {
      test('should create diary entry with required fields', () {
        // Act
        final entry = DiaryEntry(
          id: 'test-id',
          date: testDate,
          title: 'Test Title',
          content: 'Test Content',
          photoIds: ['photo1', 'photo2'],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Assert
        expect(entry.id, equals('test-id'));
        expect(entry.date, equals(testDate));
        expect(entry.title, equals('Test Title'));
        expect(entry.content, equals('Test Content'));
        expect(entry.photoIds, equals(['photo1', 'photo2']));
        expect(entry.createdAt, equals(testCreatedAt));
        expect(entry.updatedAt, equals(testUpdatedAt));
        expect(entry.tags, isNull);
        expect(entry.tagsGeneratedAt, isNull);
        expect(entry.location, isNull);
      });

      test('should create diary entry with optional fields', () {
        // Act
        final entry = DiaryEntry(
          id: 'test-id',
          date: testDate,
          title: 'Test Title',
          content: 'Test Content',
          photoIds: ['photo1'],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          tags: ['tag1', 'tag2'],
          tagsGeneratedAt: testDate,
          location: 'Test Location',
        );

        // Assert
        expect(entry.tags, equals(['tag1', 'tag2']));
        expect(entry.tagsGeneratedAt, equals(testDate));
        expect(entry.location, equals('Test Location'));
      });
    });

    group('hasValidTags', () {
      test('should return false when tags is null', () {
        // Arrange
        final entry = DiaryEntry(
          id: 'test-id',
          date: testDate,
          title: 'Test Title',
          content: 'Test Content',
          photoIds: ['photo1'],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          tags: null,
          tagsGeneratedAt: DateTime.now(),
        );

        // Act & Assert
        expect(entry.hasValidTags, isFalse);
      });

      test('should return false when tagsGeneratedAt is null', () {
        // Arrange
        final entry = DiaryEntry(
          id: 'test-id',
          date: testDate,
          title: 'Test Title',
          content: 'Test Content',
          photoIds: ['photo1'],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          tags: ['tag1'],
          tagsGeneratedAt: null,
        );

        // Act & Assert
        expect(entry.hasValidTags, isFalse);
      });

      test('should return true when tags were generated within 7 days', () {
        // Arrange
        final recentTagsDate = DateTime.now().subtract(const Duration(days: 3));
        final entry = DiaryEntry(
          id: 'test-id',
          date: testDate,
          title: 'Test Title',
          content: 'Test Content',
          photoIds: ['photo1'],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          tags: ['tag1'],
          tagsGeneratedAt: recentTagsDate,
        );

        // Act & Assert
        expect(entry.hasValidTags, isTrue);
      });

      test(
        'should return false when tags were generated more than 7 days ago',
        () {
          // Arrange
          final oldTagsDate = DateTime.now().subtract(const Duration(days: 8));
          final entry = DiaryEntry(
            id: 'test-id',
            date: testDate,
            title: 'Test Title',
            content: 'Test Content',
            photoIds: ['photo1'],
            createdAt: testCreatedAt,
            updatedAt: testUpdatedAt,
            tags: ['tag1'],
            tagsGeneratedAt: oldTagsDate,
          );

          // Act & Assert
          expect(entry.hasValidTags, isFalse);
        },
      );

      test('should return true for tags generated exactly 6 days ago', () {
        // Arrange
        final exactDate = DateTime.now().subtract(const Duration(days: 6));
        final entry = DiaryEntry(
          id: 'test-id',
          date: testDate,
          title: 'Test Title',
          content: 'Test Content',
          photoIds: ['photo1'],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          tags: ['tag1'],
          tagsGeneratedAt: exactDate,
        );

        // Act & Assert
        expect(entry.hasValidTags, isTrue);
      });
    });

    group('effectiveTags', () {
      test('should return tags when tags exist', () {
        final entry = DiaryEntry(
          id: 'test-id',
          date: testDate,
          title: 'Test',
          content: 'Test',
          photoIds: ['photo1'],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          tags: ['tag1', 'tag2'],
        );

        expect(entry.effectiveTags, equals(['tag1', 'tag2']));
      });

      test('should return empty list when tags is null', () {
        final entry = DiaryEntry(
          id: 'test-id',
          date: testDate,
          title: 'Test',
          content: 'Test',
          photoIds: ['photo1'],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(entry.effectiveTags, isEmpty);
      });
    });

    group('copyWith', () {
      late DiaryEntry originalEntry;

      setUp(() {
        originalEntry = DiaryEntry(
          id: 'original-id',
          date: testDate,
          title: 'Original Title',
          content: 'Original Content',
          photoIds: ['photo1', 'photo2'],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          tags: ['original-tag'],
          tagsGeneratedAt: testDate,
          location: 'Original Location',
        );
      });

      test(
        'should return copy with unchanged fields when no parameters provided',
        () {
          // Act
          final copy = originalEntry.copyWith();

          // Assert
          expect(copy.id, equals(originalEntry.id));
          expect(copy.date, equals(originalEntry.date));
          expect(copy.title, equals(originalEntry.title));
          expect(copy.content, equals(originalEntry.content));
          expect(copy.photoIds, equals(originalEntry.photoIds));
          expect(copy.createdAt, equals(originalEntry.createdAt));
          expect(copy.updatedAt, equals(originalEntry.updatedAt));
          expect(copy.tags, equals(originalEntry.tags));
          expect(copy.tagsGeneratedAt, equals(originalEntry.tagsGeneratedAt));
          expect(copy.location, equals(originalEntry.location));
        },
      );

      test('should return copy with modified title and content', () {
        // Arrange
        final newUpdatedAt = DateTime.now();

        // Act
        final copy = originalEntry.copyWith(
          title: 'Updated Title',
          content: 'Updated Content',
          updatedAt: newUpdatedAt,
        );

        // Assert
        expect(copy.title, equals('Updated Title'));
        expect(copy.content, equals('Updated Content'));
        expect(copy.updatedAt, equals(newUpdatedAt));
        // Other fields should remain unchanged
        expect(copy.id, equals(originalEntry.id));
        expect(copy.date, equals(originalEntry.date));
        expect(copy.photoIds, equals(originalEntry.photoIds));
      });

      test('should return copy with all fields modified', () {
        // Arrange
        final newDate = DateTime(2024, 2, 1);
        final newCreatedAt = DateTime(2024, 2, 1, 10, 0);
        final newUpdatedAt = DateTime(2024, 2, 1, 11, 0);
        final newTagsGeneratedAt = DateTime(2024, 2, 1, 12, 0);

        // Act
        final copy = originalEntry.copyWith(
          id: 'new-id',
          date: newDate,
          title: 'New Title',
          content: 'New Content',
          photoIds: ['new-photo1'],
          createdAt: newCreatedAt,
          updatedAt: newUpdatedAt,
          tags: ['new-tag1', 'new-tag2'],
          tagsGeneratedAt: newTagsGeneratedAt,
          location: 'New Location',
        );

        // Assert
        expect(copy.id, equals('new-id'));
        expect(copy.date, equals(newDate));
        expect(copy.title, equals('New Title'));
        expect(copy.content, equals('New Content'));
        expect(copy.photoIds, equals(['new-photo1']));
        expect(copy.createdAt, equals(newCreatedAt));
        expect(copy.updatedAt, equals(newUpdatedAt));
        expect(copy.tags, equals(['new-tag1', 'new-tag2']));
        expect(copy.tagsGeneratedAt, equals(newTagsGeneratedAt));
        expect(copy.location, equals('New Location'));
      });

      test('should create different instances', () {
        // Act
        final copy = originalEntry.copyWith(title: 'Modified Title');

        // Assert
        expect(copy, isNot(same(originalEntry)));
        expect(copy.title, isNot(equals(originalEntry.title)));
      });
    });

    group('Edge Cases', () {
      test('should handle empty photo IDs list', () {
        // Act
        final entry = DiaryEntry(
          id: 'test-id',
          date: testDate,
          title: 'Test Title',
          content: 'Test Content',
          photoIds: [],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Assert
        expect(entry.photoIds, isEmpty);
      });

      test('should handle empty strings for title and content', () {
        // Act
        final entry = DiaryEntry(
          id: '',
          date: testDate,
          title: '',
          content: '',
          photoIds: [],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Assert
        expect(entry.id, equals(''));
        expect(entry.title, equals(''));
        expect(entry.content, equals(''));
      });

      test('should handle very long strings', () {
        // Arrange
        final longString = 'A' * 10000;

        // Act
        final entry = DiaryEntry(
          id: 'test-id',
          date: testDate,
          title: longString,
          content: longString,
          photoIds: ['photo1'],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Assert
        expect(entry.title.length, equals(10000));
        expect(entry.content.length, equals(10000));
      });
    });
  });
}
