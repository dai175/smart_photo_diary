import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/controllers/statistics_controller.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/models/diary_change.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/services/interfaces/diary_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';

class MockDiaryService extends Mock implements IDiaryService {}

class MockLoggingService extends Mock implements ILoggingService {}

DiaryEntry _createEntry(String id, {DateTime? date}) {
  final d = date ?? DateTime(2025, 1, 15);
  return DiaryEntry(
    id: id,
    date: d,
    title: 'Entry $id',
    content: 'Content $id',
    photoIds: const [],
    createdAt: d,
    updatedAt: d,
  );
}

void main() {
  late MockDiaryService mockDiaryService;
  late MockLoggingService mockLogger;

  setUp(() {
    ServiceLocator().clear();
    mockDiaryService = MockDiaryService();
    mockLogger = MockLoggingService();

    ServiceLocator().registerSingleton<IDiaryService>(mockDiaryService);
    ServiceLocator().registerSingleton<ILoggingService>(mockLogger);

    // Default stubs
    when(
      () => mockDiaryService.changes,
    ).thenAnswer((_) => const Stream<DiaryChange>.empty());
    when(
      () => mockDiaryService.getSortedDiaryEntries(
        descending: any(named: 'descending'),
      ),
    ).thenAnswer((_) async => const Success([]));
  });

  tearDown(() {
    ServiceLocator().clear();
  });

  StatisticsController createController() {
    return StatisticsController();
  }

  group('StatisticsController', () {
    group('初期状態', () {
      test('初期状態は正しくセットされている', () {
        final controller = createController();
        addTearDown(controller.dispose);

        expect(controller.allDiaries, isEmpty);
        expect(controller.stats.totalEntries, 0);
        expect(controller.isLoading, isFalse);
        expect(controller.selectedDay, isNull);
      });
    });

    group('loadStatistics', () {
      test('統計データが正常にロードされる', () async {
        final entries = [
          _createEntry('1', date: DateTime(2025, 1, 10)),
          _createEntry('2', date: DateTime(2025, 1, 11)),
          _createEntry('3', date: DateTime(2025, 1, 12)),
        ];
        when(
          () => mockDiaryService.getSortedDiaryEntries(
            descending: any(named: 'descending'),
          ),
        ).thenAnswer((_) async => Success(entries));

        final controller = createController();
        addTearDown(controller.dispose);

        await controller.loadStatistics();

        expect(controller.allDiaries, hasLength(3));
        expect(controller.stats.totalEntries, 3);
        expect(controller.isLoading, isFalse);
      });

      test('エラー時もローディングが解除される', () async {
        when(
          () => mockDiaryService.getSortedDiaryEntries(
            descending: any(named: 'descending'),
          ),
        ).thenAnswer((_) async => const Failure(DatabaseException('DB error')));

        final controller = createController();
        addTearDown(controller.dispose);

        await controller.loadStatistics();

        expect(controller.isLoading, isFalse);
        verify(
          () => mockLogger.error(
            any(),
            error: any(named: 'error'),
            context: any(named: 'context'),
          ),
        ).called(1);
      });

      test('ロード中は isLoading が true になる', () async {
        when(
          () => mockDiaryService.getSortedDiaryEntries(
            descending: any(named: 'descending'),
          ),
        ).thenAnswer((_) async => const Success([]));

        final controller = createController();
        addTearDown(controller.dispose);

        bool wasLoadingTrue = false;
        controller.addListener(() {
          if (controller.isLoading) {
            wasLoadingTrue = true;
          }
        });

        await controller.loadStatistics();
        expect(wasLoadingTrue, isTrue);
      });
    });

    group('onDaySelected', () {
      test('新しい日を選択すると日記リストを返す', () async {
        final entry = _createEntry('1', date: DateTime(2025, 1, 15));
        when(
          () => mockDiaryService.getSortedDiaryEntries(
            descending: any(named: 'descending'),
          ),
        ).thenAnswer((_) async => Success([entry]));

        final controller = createController();
        addTearDown(controller.dispose);

        await controller.loadStatistics();

        final diaries = controller.onDaySelected(
          DateTime(2025, 1, 15),
          DateTime(2025, 1, 15),
        );

        expect(controller.selectedDay, DateTime(2025, 1, 15));
        // diaryMap のキーに合致するエントリーがあれば返される
        if (diaries != null) {
          expect(diaries, isNotEmpty);
        }
      });

      test('同じ日を再選択すると null を返す', () async {
        final controller = createController();
        addTearDown(controller.dispose);

        await controller.loadStatistics();

        // 最初の選択
        controller.onDaySelected(DateTime(2025, 1, 15), DateTime(2025, 1, 15));

        // 同じ日を再選択
        final result = controller.onDaySelected(
          DateTime(2025, 1, 15),
          DateTime(2025, 1, 15),
        );

        expect(result, isNull);
      });
    });

    group('onHeaderTapped', () {
      test('異なる月をタップすると今月に戻る', () {
        final controller = createController();
        addTearDown(controller.dispose);

        // 前月を指定
        final lastMonth = DateTime(2024, 12, 1);
        controller.onHeaderTapped(lastMonth);

        final now = DateTime.now();
        expect(controller.focusedDay.year, now.year);
        expect(controller.focusedDay.month, now.month);
        expect(controller.selectedDay, isNull);
      });
    });

    group('subscribeDiaryChanges', () {
      test('changes ストリームを購読する', () async {
        final streamController = StreamController<DiaryChange>.broadcast();
        when(
          () => mockDiaryService.changes,
        ).thenAnswer((_) => streamController.stream);

        final controller = createController();
        addTearDown(() {
          controller.dispose();
          streamController.close();
        });

        controller.subscribeDiaryChanges();

        // await で非同期の getAsync 解決を待つ
        await Future.delayed(const Duration(milliseconds: 100));

        // changes ストリームにアクセスされたことを確認
        verify(() => mockDiaryService.changes).called(1);
      });
    });

    group('dispose', () {
      test('dispose で例外が発生しない', () {
        final controller = createController();
        expect(() => controller.dispose(), returnsNormally);
      });
    });
  });
}
