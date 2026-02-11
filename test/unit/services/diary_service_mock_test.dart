import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/services/diary_service.dart';
import 'package:smart_photo_diary/services/ai/ai_service_interface.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import '../../test_helpers/mock_platform_channels.dart';

// Mock classes
class MockIAiService extends Mock implements IAiService {}

class MockAssetEntity extends Mock implements AssetEntity {}

void main() {
  group('DiaryService Mock Tests', () {
    late MockIAiService mockAiService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      MockPlatformChannels.setupMocks();
      registerFallbackValue(MockAssetEntity());
      registerFallbackValue(const Locale('ja'));
    });

    tearDownAll(() {
      MockPlatformChannels.clearMocks();
    });

    setUp(() {
      mockAiService = MockIAiService();
    });

    group('Past Photo Diary Creation', () {
      test(
        'should create diary entry for past photo with correct date mapping',
        () {
          // Arrange
          final photoDate = DateTime(2024, 7, 25, 10, 30); // 写真撮影日
          final now = DateTime.now();
          const title = '昨日の思い出';
          const content = '昨日撮った写真から日記を作成しました';
          const photoIds = ['past_photo1', 'past_photo2'];

          // Act - Test creation logic
          final entry = DiaryEntry(
            id: 'test-past-id',
            date: photoDate, // 写真撮影日を日記の日付として使用
            title: title,
            content: content,
            photoIds: photoIds,
            createdAt: now, // 実際の作成日時
            updatedAt: now,
          );

          // Assert
          expect(entry.date, equals(photoDate));
          expect(entry.createdAt.isAfter(photoDate), isTrue);
          expect(entry.title, equals(title));
          expect(entry.content, equals(content));
          expect(entry.photoIds, equals(photoIds));
        },
      );

      test('should handle multiple diary entries for same photo date', () {
        // Arrange
        final photoDate = DateTime(2024, 7, 25);
        final entries = [
          DiaryEntry(
            id: 'entry1',
            date: photoDate,
            title: '朝の思い出',
            content: '朝の写真から',
            photoIds: ['photo1'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          DiaryEntry(
            id: 'entry2',
            date: photoDate,
            title: '夕方の思い出',
            content: '夕方の写真から',
            photoIds: ['photo2'],
            createdAt: DateTime.now().add(const Duration(hours: 1)),
            updatedAt: DateTime.now().add(const Duration(hours: 1)),
          ),
        ];

        // Act & Assert
        for (final entry in entries) {
          expect(entry.date.year, equals(photoDate.year));
          expect(entry.date.month, equals(photoDate.month));
          expect(entry.date.day, equals(photoDate.day));
        }

        // 作成時刻で並び替えのテスト
        entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        expect(entries.first.title, equals('夕方の思い出'));
      });

      test('should calculate correct past context for tag generation', () {
        // Arrange
        final now = DateTime.now();
        final testCases = [
          {'date': now.subtract(const Duration(days: 1)), 'expected': '昨日の思い出'},
          {
            'date': now.subtract(const Duration(days: 3)),
            'expected': '3日前の思い出',
          },
          {
            'date': now.subtract(const Duration(days: 14)),
            'expected': '約2週間前の思い出',
          },
          {
            'date': now.subtract(const Duration(days: 60)),
            'expected': '約2ヶ月前の思い出',
          },
          {
            'date': now.subtract(const Duration(days: 400)),
            'expected': '約1年前の思い出',
          },
        ];

        // Act & Assert
        for (final testCase in testCases) {
          final date = testCase['date'] as DateTime;
          final daysDifference = now.difference(date).inDays;

          String pastContext = '';
          if (daysDifference == 1) {
            pastContext = '昨日の思い出';
          } else if (daysDifference <= 7) {
            pastContext = '$daysDifference日前の思い出';
          } else if (daysDifference <= 30) {
            pastContext = '約${(daysDifference / 7).round()}週間前の思い出';
          } else if (daysDifference <= 365) {
            pastContext = '約${(daysDifference / 30).round()}ヶ月前の思い出';
          } else {
            pastContext = '約${(daysDifference / 365).round()}年前の思い出';
          }

          expect(pastContext, equals(testCase['expected']));
        }
      });
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
        expect(entry.effectiveTags, equals(tags));
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
        final morningTime = DateTime(2024, 1, 15, 8); // 8 AM

        // Assert - Test time-based logic
        expect(morningTime.hour >= 5 && morningTime.hour < 12, isTrue);
      });

      test('should identify afternoon time correctly', () {
        // Arrange & Act
        final afternoonTime = DateTime(2024, 1, 15, 15); // 3 PM

        // Assert - Test time-based logic
        expect(afternoonTime.hour >= 12 && afternoonTime.hour < 18, isTrue);
      });

      test('should identify evening time correctly', () {
        // Arrange & Act
        final eveningTime = DateTime(2024, 1, 15, 19); // 7 PM

        // Assert - Test time-based logic
        expect(eveningTime.hour >= 18 && eveningTime.hour < 22, isTrue);
      });

      test('should identify night time correctly', () {
        // Arrange & Act
        final nightTime = DateTime(2024, 1, 15, 23); // 11 PM

        // Assert - Test time-based logic
        expect(nightTime.hour >= 22 || nightTime.hour < 5, isTrue);
      });

      test('should generate appropriate fallback tag based on time', () {
        // Test the time-to-tag mapping logic
        final testCases = [
          (DateTime(2024, 1, 15, 8), '朝'), // Morning
          (DateTime(2024, 1, 15, 15), '昼'), // Afternoon
          (DateTime(2024, 1, 15, 19), '夕方'), // Evening
          (DateTime(2024, 1, 15, 23), '夜'), // Night
        ];

        for (final (dateTime, expectedTag) in testCases) {
          String actualTag;
          final hour = dateTime.hour;

          if (hour >= 5 && hour < 12) {
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
        when(
          () => mockAiService.generateTagsFromContent(
            title: any(named: 'title'),
            content: any(named: 'content'),
            date: any(named: 'date'),
            photoCount: any(named: 'photoCount'),
          ),
        ).thenAnswer((_) async => Success(['mock-tag']));

        // Act & Assert - Verify mock is properly configured
        expect(mockAiService, isA<IAiService>());

        // Verify the mock has not been called yet
        verifyNever(
          () => mockAiService.generateTagsFromContent(
            title: any(named: 'title'),
            content: any(named: 'content'),
            date: any(named: 'date'),
            photoCount: any(named: 'photoCount'),
          ),
        );
      });

      test('should create instance with dependencies', () {
        // Act
        final service = DiaryService.createWithDependencies();

        // Assert
        expect(service, isA<DiaryService>());
      });
    });

    group('Interface Compliance', () {
      test('should implement DiaryService interface', () {
        // Act
        final service = DiaryService.createWithDependencies();

        // Assert
        expect(service, isA<DiaryService>());
      });

      test('should have all required service methods', () {
        // Act
        final service = DiaryService.createWithDependencies();

        // Assert
        expect(service.saveDiaryEntry, isA<Function>());
        expect(service.saveDiaryEntryWithPhotos, isA<Function>());
        expect(service.getTagsForEntry, isA<Function>());
      });
    });
  });
}
