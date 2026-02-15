import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/services/ai/diary_time_segment.dart';

void main() {
  group('timeSegment', () {
    test('5時 → "morning"', () {
      expect(DiaryTimeSegment.timeSegment(DateTime(2025, 1, 1, 5)), 'morning');
    });

    test('11時 → "morning"', () {
      expect(DiaryTimeSegment.timeSegment(DateTime(2025, 1, 1, 11)), 'morning');
    });

    test('12時 → "afternoon"', () {
      expect(
        DiaryTimeSegment.timeSegment(DateTime(2025, 1, 1, 12)),
        'afternoon',
      );
    });

    test('17時 → "afternoon"', () {
      expect(
        DiaryTimeSegment.timeSegment(DateTime(2025, 1, 1, 17)),
        'afternoon',
      );
    });

    test('18時 → "evening"', () {
      expect(DiaryTimeSegment.timeSegment(DateTime(2025, 1, 1, 18)), 'evening');
    });

    test('21時 → "evening"', () {
      expect(DiaryTimeSegment.timeSegment(DateTime(2025, 1, 1, 21)), 'evening');
    });

    test('22時 → "night"', () {
      expect(DiaryTimeSegment.timeSegment(DateTime(2025, 1, 1, 22)), 'night');
    });

    test('3時 → "night"', () {
      expect(DiaryTimeSegment.timeSegment(DateTime(2025, 1, 1, 3)), 'night');
    });

    test('0時 → "night"', () {
      expect(DiaryTimeSegment.timeSegment(DateTime(2025, 1, 1, 0)), 'night');
    });
  });

  group('segmentLabel', () {
    test('morning + ja → "朝"', () {
      expect(DiaryTimeSegment.segmentLabel('morning', const Locale('ja')), '朝');
    });

    test('morning + en → "Morning"', () {
      expect(
        DiaryTimeSegment.segmentLabel('morning', const Locale('en')),
        'Morning',
      );
    });

    test('afternoon + ja → "昼"', () {
      expect(
        DiaryTimeSegment.segmentLabel('afternoon', const Locale('ja')),
        '昼',
      );
    });

    test('afternoon + en → "Afternoon"', () {
      expect(
        DiaryTimeSegment.segmentLabel('afternoon', const Locale('en')),
        'Afternoon',
      );
    });

    test('evening + ja → "夕方"', () {
      expect(
        DiaryTimeSegment.segmentLabel('evening', const Locale('ja')),
        '夕方',
      );
    });

    test('evening + en → "Evening"', () {
      expect(
        DiaryTimeSegment.segmentLabel('evening', const Locale('en')),
        'Evening',
      );
    });

    test('night + ja → "夜"', () {
      expect(DiaryTimeSegment.segmentLabel('night', const Locale('ja')), '夜');
    });

    test('night + en → "Night"', () {
      expect(
        DiaryTimeSegment.segmentLabel('night', const Locale('en')),
        'Night',
      );
    });

    test('不明セグメント + ja → "夜"（default）', () {
      expect(DiaryTimeSegment.segmentLabel('unknown', const Locale('ja')), '夜');
    });

    test('不明セグメント + en → "Night"（default）', () {
      expect(
        DiaryTimeSegment.segmentLabel('unknown', const Locale('en')),
        'Night',
      );
    });
  });

  group('segmentOrder', () {
    test('morning → 0', () {
      expect(DiaryTimeSegment.segmentOrder('morning'), 0);
    });

    test('afternoon → 1', () {
      expect(DiaryTimeSegment.segmentOrder('afternoon'), 1);
    });

    test('evening → 2', () {
      expect(DiaryTimeSegment.segmentOrder('evening'), 2);
    });

    test('night → 3', () {
      expect(DiaryTimeSegment.segmentOrder('night'), 3);
    });

    test('不明 → 3', () {
      expect(DiaryTimeSegment.segmentOrder('unknown'), 3);
    });
  });

  group('throughoutDay', () {
    test('ja → "一日を通して"', () {
      expect(DiaryTimeSegment.throughoutDay(const Locale('ja')), '一日を通して');
    });

    test('en → "Throughout the day"', () {
      expect(
        DiaryTimeSegment.throughoutDay(const Locale('en')),
        'Throughout the day',
      );
    });
  });

  group('combineSegments', () {
    test('空Set → throughoutDay', () {
      expect(
        DiaryTimeSegment.combineSegments(<String>{}, const Locale('ja')),
        '一日を通して',
      );
    });

    test('1つのセグメント → そのラベル', () {
      expect(
        DiaryTimeSegment.combineSegments({'morning'}, const Locale('ja')),
        '朝',
      );
    });

    test('2つのセグメント(ja) → "XからYにかけて"', () {
      expect(
        DiaryTimeSegment.combineSegments({
          'morning',
          'afternoon',
        }, const Locale('ja')),
        '朝から昼にかけて',
      );
    });

    test('2つのセグメント(en) → "X to Y"', () {
      expect(
        DiaryTimeSegment.combineSegments({
          'morning',
          'evening',
        }, const Locale('en')),
        'Morning to Evening',
      );
    });

    test('2つのセグメント → segmentOrder順にソートされる', () {
      // evening(2) + morning(0) → morning to evening
      expect(
        DiaryTimeSegment.combineSegments({
          'evening',
          'morning',
        }, const Locale('en')),
        'Morning to Evening',
      );
    });

    test('3つ以上 → throughoutDay', () {
      expect(
        DiaryTimeSegment.combineSegments({
          'morning',
          'afternoon',
          'evening',
        }, const Locale('ja')),
        '一日を通して',
      );
    });
  });

  group('getTimeOfDay', () {
    test('朝の時刻 → 朝のラベル', () {
      expect(
        DiaryTimeSegment.getTimeOfDay(
          DateTime(2025, 1, 1, 8),
          const Locale('ja'),
        ),
        '朝',
      );
    });

    test('夜の時刻(en) → Night', () {
      expect(
        DiaryTimeSegment.getTimeOfDay(
          DateTime(2025, 1, 1, 23),
          const Locale('en'),
        ),
        'Night',
      );
    });
  });

  group('getTimeOfDayForPhotos', () {
    const ja = Locale('ja');
    const en = Locale('en');

    test('photoTimesがnull → baseDateの時間帯', () {
      expect(
        DiaryTimeSegment.getTimeOfDayForPhotos(
          DateTime(2025, 1, 1, 8),
          null,
          ja,
        ),
        '朝',
      );
    });

    test('photoTimesが空 → baseDateの時間帯', () {
      expect(
        DiaryTimeSegment.getTimeOfDayForPhotos(DateTime(2025, 1, 1, 8), [], ja),
        '朝',
      );
    });

    test('photoTimesが1枚 → その写真の時間帯', () {
      expect(
        DiaryTimeSegment.getTimeOfDayForPhotos(DateTime(2025, 1, 1, 8), [
          DateTime(2025, 1, 1, 14),
        ], ja),
        '昼',
      );
    });

    test('photoTimesが複数(同セグメント) → 単一ラベル', () {
      expect(
        DiaryTimeSegment.getTimeOfDayForPhotos(DateTime(2025, 1, 1, 8), [
          DateTime(2025, 1, 1, 6),
          DateTime(2025, 1, 1, 9),
        ], ja),
        '朝',
      );
    });

    test('photoTimesが複数(異セグメント) → combineSegments結果', () {
      expect(
        DiaryTimeSegment.getTimeOfDayForPhotos(DateTime(2025, 1, 1, 8), [
          DateTime(2025, 1, 1, 6),
          DateTime(2025, 1, 1, 14),
        ], en),
        'Morning to Afternoon',
      );
    });
  });
}
