import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/services/diary_service.dart';
import 'test_helpers/integration_test_helpers.dart';
import 'mocks/mock_services.dart';

void main() {
  group('DiaryService Past Photo Integration Tests', () {
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

      // Clear any existing entries
      final entriesResult = await diaryService.getSortedDiaryEntries();
      expect(entriesResult.isSuccess, isTrue);
      for (final entry in entriesResult.value) {
        await diaryService.deleteDiaryEntry(entry.id);
      }
    });

    tearDown(() async {
      // Clean up after each test
      final entriesResult = await diaryService.getSortedDiaryEntries();
      expect(entriesResult.isSuccess, isTrue);
      for (final entry in entriesResult.value) {
        await diaryService.deleteDiaryEntry(entry.id);
      }
    });

    group('createDiaryForPastPhoto', () {
      test(
        'should create diary entry with photo date, not current date',
        () async {
          // Arrange
          final photoDate = DateTime(2024, 7, 25, 10, 30);
          const title = '過去の思い出';
          const content = '素晴らしい一日でした';
          const photoIds = ['photo1', 'photo2'];
          const location = '東京タワー';
          const tags = ['思い出', '観光'];

          // Act
          final createResult = await diaryService.createDiaryForPastPhoto(
            photoDate: photoDate,
            title: title,
            content: content,
            photoIds: photoIds,
            location: location,
            tags: tags,
          );
          expect(createResult.isSuccess, isTrue);
          final result = createResult.value;

          // Assert
          expect(result.date.year, equals(photoDate.year));
          expect(result.date.month, equals(photoDate.month));
          expect(result.date.day, equals(photoDate.day));
          expect(result.date.hour, equals(10)); // 時刻も保存される
          expect(result.date.minute, equals(30));
          expect(result.date.second, equals(0));
          expect(result.title, equals(title));
          expect(result.content, equals(content));
          expect(result.photoIds, equals(photoIds));
          expect(result.location, equals(location));
          expect(result.effectiveTags, contains('思い出'));
          expect(result.effectiveTags, contains('観光'));

          // 作成日時は現在時刻に近いはず
          final now = DateTime.now();
          expect(result.createdAt.difference(now).inSeconds.abs(), lessThan(5));

          // DBに保存されていることを確認
          final getResult = await diaryService.getDiaryEntry(result.id);
          expect(getResult.isSuccess, isTrue);
          final savedEntry = getResult.value;
          expect(savedEntry, isNotNull);
          expect(savedEntry!.id, equals(result.id));
        },
      );

      test(
        'should handle multiple diary entries for same photo date',
        () async {
          // Arrange
          final photoDate = DateTime(2024, 7, 25);

          // Act - 同じ日付で複数の日記を作成
          final result1 = await diaryService.createDiaryForPastPhoto(
            photoDate: photoDate,
            title: '朝の思い出',
            content: '朝の写真から作成',
            photoIds: ['morning-photo'],
          );
          expect(result1.isSuccess, isTrue);
          final entry1 = result1.value;

          final result2 = await diaryService.createDiaryForPastPhoto(
            photoDate: photoDate,
            title: '夕方の思い出',
            content: '夕方の写真から作成',
            photoIds: ['evening-photo'],
          );
          expect(result2.isSuccess, isTrue);
          final entry2 = result2.value;

          // Assert
          expect(entry1.date, equals(entry2.date));
          expect(entry1.id, isNot(equals(entry2.id)));

          // 両方の日記が保存されていることを確認
          final dateResult = await diaryService.getDiaryByPhotoDate(photoDate);
          expect(dateResult.isSuccess, isTrue);
          final diariesForDate = dateResult.value;
          expect(diariesForDate.length, greaterThanOrEqualTo(2));

          final ids = diariesForDate.map((e) => e.id).toSet();
          expect(ids, contains(entry1.id));
          expect(ids, contains(entry2.id));
        },
      );

      test('should preserve photo date when creating diary entry', () async {
        // Arrange
        final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
        final photoDate = DateTime(
          oneYearAgo.year,
          oneYearAgo.month,
          oneYearAgo.day,
        );

        // Act
        final createResult = await diaryService.createDiaryForPastPhoto(
          photoDate: photoDate,
          title: '1年前の思い出',
          content: '昨年の今日の出来事',
          photoIds: ['old-photo'],
        );
        expect(createResult.isSuccess, isTrue);
        final result = createResult.value;

        // Assert
        expect(result.date, equals(photoDate));
        expect(result.createdAt.isAfter(photoDate), isTrue);

        // 日付が正しく保存されていることを確認
        final getResult = await diaryService.getDiaryEntry(result.id);
        expect(getResult.isSuccess, isTrue);
        final retrieved = getResult.value;
        expect(retrieved!.date, equals(photoDate));
      });

      test('should handle edge case dates correctly', () async {
        // Arrange - うるう年のテスト
        final leapYearDate = DateTime(2024, 2, 29);

        // Act
        final createResult = await diaryService.createDiaryForPastPhoto(
          photoDate: leapYearDate,
          title: 'うるう日の思い出',
          content: '4年に1度の特別な日',
          photoIds: ['leap-photo'],
        );
        expect(createResult.isSuccess, isTrue);
        final leapYearEntry = createResult.value;

        // Assert
        expect(leapYearEntry.date.year, equals(2024));
        expect(leapYearEntry.date.month, equals(2));
        expect(leapYearEntry.date.day, equals(29));
      });
    });

    group('getDiaryByPhotoDate', () {
      test('should return all diary entries for specified date', () async {
        // Arrange
        final targetDate = DateTime(2024, 7, 25);
        final otherDate = DateTime(2024, 7, 26);

        // 同じ日付で2つの日記を作成
        final result1 = await diaryService.createDiaryForPastPhoto(
          photoDate: targetDate,
          title: '朝の日記',
          content: '朝の内容',
          photoIds: ['photo1'],
        );
        expect(result1.isSuccess, isTrue);
        final entry1 = result1.value;

        final result2 = await diaryService.createDiaryForPastPhoto(
          photoDate: targetDate,
          title: '午後の日記',
          content: '午後の内容',
          photoIds: ['photo2'],
        );
        expect(result2.isSuccess, isTrue);
        final entry2 = result2.value;

        // 異なる日付で1つの日記を作成
        final result3 = await diaryService.createDiaryForPastPhoto(
          photoDate: otherDate,
          title: '別の日の日記',
          content: '別の日の内容',
          photoIds: ['photo3'],
        );
        expect(result3.isSuccess, isTrue);
        final entry3 = result3.value;

        // Act
        final dateResult = await diaryService.getDiaryByPhotoDate(targetDate);
        expect(dateResult.isSuccess, isTrue);
        final diaries = dateResult.value;

        // Assert
        expect(diaries.length, equals(2));
        expect(
          diaries.every(
            (entry) =>
                entry.date.year == 2024 &&
                entry.date.month == 7 &&
                entry.date.day == 25,
          ),
          isTrue,
        );

        final resultIds = diaries.map((e) => e.id).toSet();
        expect(resultIds, contains(entry1.id));
        expect(resultIds, contains(entry2.id));
        expect(resultIds, isNot(contains(entry3.id)));
      });

      test('should return empty list when no entries found for date', () async {
        // Arrange
        final targetDate = DateTime(2024, 7, 25);
        final otherDate = DateTime(2024, 7, 26);

        // 異なる日付で日記を作成
        await diaryService.createDiaryForPastPhoto(
          photoDate: otherDate,
          title: '別の日の日記',
          content: '内容',
          photoIds: ['photo1'],
        );

        // Act
        final dateResult = await diaryService.getDiaryByPhotoDate(targetDate);

        // Assert
        expect(dateResult.isSuccess, isTrue);
        expect(dateResult.value, isEmpty);
      });

      test('should handle time components correctly', () async {
        // Arrange
        final targetDate = DateTime(2024, 7, 25, 23, 59, 59); // 時刻付き

        // 同じ日の異なる時刻で作成された日記
        final result1 = await diaryService.saveDiaryEntry(
          date: DateTime(2024, 7, 25, 0, 0, 0), // 深夜
          title: '深夜の日記',
          content: '内容',
          photoIds: ['photo1'],
        );
        expect(result1.isSuccess, isTrue);
        final entry1 = result1.value;

        final result2 = await diaryService.saveDiaryEntry(
          date: DateTime(2024, 7, 25, 12, 0, 0), // 正午
          title: '昼の日記',
          content: '内容',
          photoIds: ['photo2'],
        );
        expect(result2.isSuccess, isTrue);
        final entry2 = result2.value;

        // Act
        final dateResult = await diaryService.getDiaryByPhotoDate(targetDate);
        expect(dateResult.isSuccess, isTrue);
        final diaries = dateResult.value;

        // Assert
        expect(diaries.length, equals(2));
        final resultIds = diaries.map((e) => e.id).toSet();
        expect(resultIds, contains(entry1.id));
        expect(resultIds, contains(entry2.id));
      });

      test('should correctly filter leap year dates', () async {
        // Arrange
        final targetDate = DateTime(2024, 2, 29); // うるう年

        await diaryService.createDiaryForPastPhoto(
          photoDate: targetDate,
          title: 'うるう日の日記',
          content: '内容',
          photoIds: ['photo1'],
        );

        await diaryService.createDiaryForPastPhoto(
          photoDate: DateTime(2024, 2, 28),
          title: '前日の日記',
          content: '内容',
          photoIds: ['photo2'],
        );

        // Act
        final dateResult = await diaryService.getDiaryByPhotoDate(targetDate);
        expect(dateResult.isSuccess, isTrue);
        final diaries = dateResult.value;

        // Assert
        expect(diaries.length, equals(1));
        expect(diaries.first.title, equals('うるう日の日記'));
        expect(diaries.first.date.day, equals(29));
      });
    });

    group(
      'Integration between createDiaryForPastPhoto and getDiaryByPhotoDate',
      () {
        test('should retrieve created past photo diary', () async {
          // Arrange
          final photoDate = DateTime(2024, 7, 25);

          // Act - 過去の写真から日記を作成
          final createResult = await diaryService.createDiaryForPastPhoto(
            photoDate: photoDate,
            title: '統合テスト用エントリー',
            content: '内容',
            photoIds: ['photo1'],
          );
          expect(createResult.isSuccess, isTrue);
          final createdEntry = createResult.value;

          // 作成した日記を日付で検索
          final dateResult = await diaryService.getDiaryByPhotoDate(photoDate);
          expect(dateResult.isSuccess, isTrue);
          final retrievedEntries = dateResult.value;

          // Assert
          expect(retrievedEntries.length, greaterThanOrEqualTo(1));
          expect(retrievedEntries.any((e) => e.id == createdEntry.id), isTrue);

          final matchingEntry = retrievedEntries.firstWhere(
            (e) => e.id == createdEntry.id,
          );
          expect(matchingEntry.title, equals('統合テスト用エントリー'));
          expect(matchingEntry.date, equals(photoDate));
        });

        test(
          'should maintain data consistency between create and retrieve',
          () async {
            // Arrange
            final testDate = DateTime(2024, 7, 25);
            const testData = {
              'title': 'データ整合性テスト',
              'content': '詳細な内容テキスト',
              'location': 'テスト場所',
              'tags': ['tag1', 'tag2', 'tag3'],
              'photoIds': ['photo1', 'photo2'],
            };

            // Act
            final createResult = await diaryService.createDiaryForPastPhoto(
              photoDate: testDate,
              title: testData['title'] as String,
              content: testData['content'] as String,
              photoIds: testData['photoIds'] as List<String>,
              location: testData['location'] as String,
              tags: testData['tags'] as List<String>,
            );
            expect(createResult.isSuccess, isTrue);
            final created = createResult.value;

            final dateResult = await diaryService.getDiaryByPhotoDate(testDate);
            expect(dateResult.isSuccess, isTrue);
            final retrieved = dateResult.value;
            final found = retrieved.firstWhere((e) => e.id == created.id);

            // Assert - 全てのデータが正しく保存・取得されることを確認
            expect(found.title, equals(testData['title']));
            expect(found.content, equals(testData['content']));
            expect(found.location, equals(testData['location']));
            expect(found.photoIds, equals(testData['photoIds']));
            expect(
              found.effectiveTags,
              containsAll(testData['tags'] as List<String>),
            );
          },
        );
      },
    );
  });
}
