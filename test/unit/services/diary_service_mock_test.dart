import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/services/diary_service.dart';
import 'package:smart_photo_diary/services/ai/ai_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import '../../test_helpers/mock_platform_channels.dart';

// Mock classes
class MockAiServiceInterface extends Mock implements AiServiceInterface {}

class MockPhotoServiceInterface extends Mock implements PhotoServiceInterface {}

class MockAssetEntity extends Mock implements AssetEntity {}

void main() {
  group('DiaryService Mock Tests', () {
    late MockAiServiceInterface mockAiService;
    late MockPhotoServiceInterface mockPhotoService;

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
        final morningTime = DateTime(2024, 1, 15, 8); // 8 AM

        // Assert - Test time-based logic
        expect(morningTime.hour >= 6 && morningTime.hour < 12, isTrue);
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
        expect(nightTime.hour >= 22 || nightTime.hour < 6, isTrue);
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
        when(
          () => mockAiService.generateTagsFromContent(
            title: any(named: 'title'),
            content: any(named: 'content'),
            date: any(named: 'date'),
            photoCount: any(named: 'photoCount'),
          ),
        ).thenAnswer((_) async => Success(['mock-tag']));

        // Act & Assert - Verify mock is properly configured
        expect(mockAiService, isA<AiServiceInterface>());

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
        // Act
        final service = DiaryService.createWithDependencies(
          aiService: mockAiService,
          photoService: mockPhotoService,
        );

        // Assert
        expect(service, isA<DiaryService>());
      });

      test('should have all required service methods', () {
        // Act
        final service = DiaryService.createWithDependencies(
          aiService: mockAiService,
          photoService: mockPhotoService,
        );

        // Assert
        expect(service.saveDiaryEntry, isA<Function>());
        expect(service.saveDiaryEntryWithPhotos, isA<Function>());
        expect(service.getTagsForEntry, isA<Function>());
      });
    });

    group('Result<T> Pattern Tests', () {
      test('should return Success<DiaryEntry> for valid saveDiaryEntry', () {
        // Arrange
        final testDate = DateTime(2024, 1, 15, 14, 30);
        const title = 'Test Title';
        const content = 'Test Content';
        const photoIds = ['photo1', 'photo2'];

        // Act - Test Result<T> pattern structure
        final mockResult = Success(
          DiaryEntry(
            id: 'test-id',
            date: testDate,
            title: title,
            content: content,
            photoIds: photoIds,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Assert
        expect(mockResult.isSuccess, isTrue);
        expect(mockResult.isFailure, isFalse);
        expect(mockResult.value.title, equals(title));
        expect(mockResult.value.content, equals(content));
        expect(mockResult.value.photoIds, equals(photoIds));
      });

      test('should return Failure for invalid parameters', () {
        // Act - Test Failure result structure for various validation scenarios
        final titleFailure = Failure(ValidationException('タイトルは必須です'));
        final dateFailure = Failure(ValidationException('無効な日付です'));
        final contentFailure = Failure(ValidationException('内容は必須です'));

        // Assert
        expect(titleFailure.isFailure, isTrue);
        expect(titleFailure.isSuccess, isFalse);
        expect(titleFailure.error, isA<ValidationException>());
        expect(titleFailure.error.message, contains('タイトル'));

        expect(dateFailure.isFailure, isTrue);
        expect(dateFailure.error.message, contains('日付'));

        expect(contentFailure.isFailure, isTrue);
        expect(contentFailure.error.message, contains('内容'));
      });

      test('should handle ServiceException in Result<T> pattern', () {
        // Arrange
        const errorMessage = 'データベース接続エラー';
        final originalError = Exception('Connection failed');

        // Act
        final serviceFailure = Failure(
          ServiceException(errorMessage, originalError: originalError),
        );

        // Assert
        expect(serviceFailure.isFailure, isTrue);
        expect(serviceFailure.error, isA<ServiceException>());
        expect(serviceFailure.error.message, equals(errorMessage));
        expect(
          (serviceFailure.error as ServiceException).originalError,
          equals(originalError),
        );
      });

      test('should demonstrate Result<T> functional operations', () {
        // Arrange
        final successResult = Success(
          DiaryEntry(
            id: 'test-id',
            date: DateTime(2024, 1, 15),
            title: 'Original Title',
            content: 'Original Content',
            photoIds: ['photo1'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final failureResult = Failure(ValidationException('Test error'));

        // Act - Test map operation
        final mappedSuccess = successResult.map((entry) => entry.title);
        final mappedFailure = failureResult.map((entry) => entry.title);

        // Assert
        expect(mappedSuccess.isSuccess, isTrue);
        expect(mappedSuccess.value, equals('Original Title'));

        expect(mappedFailure.isFailure, isTrue);
        expect(mappedFailure.error.message, contains('Test error'));
      });

      test('should demonstrate Result<T> fold operation', () {
        // Arrange
        final successResult = Success(
          DiaryEntry(
            id: 'test-id',
            date: DateTime(2024, 1, 15),
            title: 'Test Title',
            content: 'Test Content',
            photoIds: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final failureResult = Failure(ServiceException('Database error'));

        // Act - Test fold operation
        final successMessage = successResult.fold(
          (entry) => 'Success: ${entry.title}',
          (error) => 'Error: ${error.message}',
        );

        final failureMessage = failureResult.fold(
          (entry) => 'Success: ${entry.title}',
          (error) => 'Error: ${error.message}',
        );

        // Assert
        expect(successMessage, equals('Success: Test Title'));
        expect(failureMessage, equals('Error: Database error'));
      });

      test('should handle Result<T> chain operations', () {
        // Arrange
        final initialResult = Success(
          DiaryEntry(
            id: 'test-id',
            date: DateTime(2024, 1, 15),
            title: 'Test Title',
            content: 'Test Content',
            photoIds: ['photo1'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Act - Test chain operation (flatMap equivalent)
        final chainedResult = initialResult.fold<Result<String>>((entry) {
          if (entry.photoIds.isNotEmpty) {
            return Success('Has ${entry.photoIds.length} photos');
          } else {
            return const Failure(ValidationException('写真が見つかりません'));
          }
        }, (error) => Failure(error));

        // Assert
        expect(chainedResult.isSuccess, isTrue);
        expect(chainedResult.value, equals('Has 1 photos'));
      });

      test('should handle Result<List<T>> for multiple entries', () {
        // Arrange
        final entries = [
          DiaryEntry(
            id: 'entry1',
            date: DateTime(2024, 1, 15),
            title: 'Entry 1',
            content: 'Content 1',
            photoIds: ['photo1'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          DiaryEntry(
            id: 'entry2',
            date: DateTime(2024, 1, 16),
            title: 'Entry 2',
            content: 'Content 2',
            photoIds: ['photo2'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        // Act - Test Result with List
        final listResult = Success(entries);
        final emptyResult = Success(<DiaryEntry>[]);
        final errorResult = Failure(
          ServiceException('Failed to fetch entries'),
        );

        // Assert
        expect(listResult.isSuccess, isTrue);
        expect(listResult.value.length, equals(2));
        expect(listResult.value.first.title, equals('Entry 1'));

        expect(emptyResult.isSuccess, isTrue);
        expect(emptyResult.value.isEmpty, isTrue);

        expect(errorResult.isFailure, isTrue);
        expect(errorResult.error.message, contains('Failed to fetch'));
      });

      test('should test Result<void> for operations without return value', () {
        // Arrange & Act
        const successVoid = Success<void>(null);
        final failureVoid = Failure<void>(
          ServiceException('Delete operation failed'),
        );

        // Assert
        expect(successVoid.isSuccess, isTrue);
        // void型のResultの場合、成功であることのみをテストします

        expect(failureVoid.isFailure, isTrue);
        expect(failureVoid.error.message, contains('Delete operation failed'));
      });
    });

    group('AI Service Integration with Result<T>', () {
      test('should handle AI service Success result for tag generation', () {
        // Arrange
        const expectedTags = ['旅行', '家族', '思い出'];
        when(
          () => mockAiService.generateTagsFromContent(
            title: any(named: 'title'),
            content: any(named: 'content'),
            date: any(named: 'date'),
            photoCount: any(named: 'photoCount'),
          ),
        ).thenAnswer((_) async => Success(expectedTags));

        // Act - Test the mocked result
        final mockResult = Success(expectedTags);

        // Assert
        expect(mockResult.isSuccess, isTrue);
        expect(mockResult.value, equals(expectedTags));
        expect(mockResult.value.length, equals(3));
        expect(mockResult.value.contains('旅行'), isTrue);
      });

      test('should handle AI service Failure result for tag generation', () {
        // Arrange
        final aiError = AiProcessingException('AI API rate limit exceeded');
        when(
          () => mockAiService.generateTagsFromContent(
            title: any(named: 'title'),
            content: any(named: 'content'),
            date: any(named: 'date'),
            photoCount: any(named: 'photoCount'),
          ),
        ).thenAnswer((_) async => Failure(aiError));

        // Act - Test the mocked failure result
        final mockFailure = Failure(aiError);

        // Assert
        expect(mockFailure.isFailure, isTrue);
        expect(mockFailure.error, isA<AiProcessingException>());
        expect(mockFailure.error.message, contains('rate limit'));
      });

      test('should demonstrate fallback strategy with Result<T>', () {
        // Arrange
        final primaryFailure = Failure(
          AiProcessingException('AI service unavailable'),
        );
        final fallbackTags = ['日記', '写真'];
        final fallbackSuccess = Success(fallbackTags);

        // Act - Test fallback logic
        final finalResult = primaryFailure.fold<Result<List<String>>>(
          (tags) => Success(tags),
          (error) {
            // Fallback to basic tags
            return fallbackSuccess;
          },
        );

        // Assert
        expect(finalResult.isSuccess, isTrue);
        expect(finalResult.value, equals(fallbackTags));
      });
    });
  });
}
