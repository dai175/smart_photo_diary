import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/services/diary_statistics_service.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import '../helpers/hive_test_helpers.dart';

class MockLoggingService extends Mock implements ILoggingService {}

void main() {
  late DiaryStatisticsService statisticsService;
  late MockLoggingService mockLogger;
  late Box<DiaryEntry> diaryBox;

  setUpAll(() async {
    await HiveTestHelpers.setupHiveForTesting();
  });

  setUp(() async {
    await HiveTestHelpers.clearDiaryBox();
    mockLogger = MockLoggingService();
    diaryBox = await Hive.openBox<DiaryEntry>('diary_entries');
    statisticsService = DiaryStatisticsService(logger: mockLogger);
  });

  tearDown(() async {
    if (diaryBox.isOpen) {
      await diaryBox.close();
    }
  });

  tearDownAll(() async {
    await HiveTestHelpers.closeHive();
  });

  DiaryEntry createEntry({required String id, required DateTime date}) {
    return DiaryEntry(
      id: id,
      date: date,
      title: 'Test $id',
      content: 'Content $id',
      photoIds: ['photo_$id'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  group('getTotalDiaryCount', () {
    test('Box 未オープン時は Success(0)', () async {
      await diaryBox.close();
      final service = DiaryStatisticsService(logger: mockLogger);

      final result = await service.getTotalDiaryCount();
      expect(result.isSuccess, isTrue);
      expect(result.value, equals(0));
    });

    test('空の Box で Success(0)', () async {
      final result = await statisticsService.getTotalDiaryCount();
      expect(result.isSuccess, isTrue);
      expect(result.value, equals(0));
    });

    test('N件の場合 Success(N)', () async {
      for (int i = 0; i < 5; i++) {
        await diaryBox.put(
          'entry_$i',
          createEntry(id: 'entry_$i', date: DateTime.now()),
        );
      }

      final result = await statisticsService.getTotalDiaryCount();
      expect(result.isSuccess, isTrue);
      expect(result.value, equals(5));
    });
  });

  group('getDiaryCountInPeriod', () {
    test('期間内エントリーのみカウント', () async {
      final now = DateTime(2025, 6, 15);
      await diaryBox.put(
        'e1',
        createEntry(id: 'e1', date: DateTime(2025, 6, 10)),
      );
      await diaryBox.put(
        'e2',
        createEntry(id: 'e2', date: DateTime(2025, 6, 14)),
      );
      await diaryBox.put(
        'e3',
        createEntry(id: 'e3', date: DateTime(2025, 5, 1)),
      );
      await diaryBox.put(
        'e4',
        createEntry(id: 'e4', date: DateTime(2025, 7, 1)),
      );

      final result = await statisticsService.getDiaryCountInPeriod(
        DateTime(2025, 6, 1),
        now,
      );
      expect(result.isSuccess, isTrue);
      expect(result.value, equals(2));
    });

    test('start/end 境界値を含む（inclusive）', () async {
      final start = DateTime(2025, 6, 1);
      final end = DateTime(2025, 6, 30);

      await diaryBox.put('e_start', createEntry(id: 'e_start', date: start));
      await diaryBox.put('e_end', createEntry(id: 'e_end', date: end));

      final result = await statisticsService.getDiaryCountInPeriod(start, end);
      expect(result.isSuccess, isTrue);
      expect(result.value, equals(2));
    });

    test('該当なしで Success(0)', () async {
      await diaryBox.put(
        'e1',
        createEntry(id: 'e1', date: DateTime(2025, 1, 1)),
      );

      final result = await statisticsService.getDiaryCountInPeriod(
        DateTime(2025, 6, 1),
        DateTime(2025, 6, 30),
      );
      expect(result.isSuccess, isTrue);
      expect(result.value, equals(0));
    });

    test('Box 未オープン時は Success(0)', () async {
      await diaryBox.close();
      final service = DiaryStatisticsService(logger: mockLogger);

      final result = await service.getDiaryCountInPeriod(
        DateTime(2025, 1, 1),
        DateTime(2025, 12, 31),
      );
      expect(result.isSuccess, isTrue);
      expect(result.value, equals(0));
    });
  });
}
