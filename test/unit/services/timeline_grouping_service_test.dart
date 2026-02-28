import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/services/timeline_grouping_service.dart';
import 'package:smart_photo_diary/models/timeline_photo_group.dart';

import '../../integration/mocks/mock_services.dart';

/// テスト用にcreateDateTime等を設定可能なMockAssetEntity
MockAssetEntity createMockPhoto(DateTime dateTime) {
  final mock = MockAssetEntity();
  when(() => mock.createDateTime).thenReturn(dateTime);
  when(() => mock.id).thenReturn('photo_${dateTime.millisecondsSinceEpoch}');
  return mock;
}

void main() {
  late TimelineGroupingService service;

  setUp(() {
    service = TimelineGroupingService();
  });

  group('TimelineGroupingService', () {
    group('groupPhotosForTimeline', () {
      test('空のリストを正しく処理する', () {
        final result = service.groupPhotosForTimelineLocalized(
          [],
          todayLabel: '今日',
          yesterdayLabel: '昨日',
          monthYearFormatter: (year, month) => '$year年$month月',
        );
        expect(result, isEmpty);
      });

      test('今日の写真1枚 → 1グループ「今日」', () {
        final now = DateTime.now();
        final photo = createMockPhoto(now);

        final result = service.groupPhotosForTimelineLocalized(
          [photo],
          todayLabel: '今日',
          yesterdayLabel: '昨日',
          monthYearFormatter: (year, month) => '$year年$month月',
        );

        expect(result, hasLength(1));
        expect(result[0].displayName, '今日');
        expect(result[0].type, TimelineGroupType.today);
        expect(result[0].photos, hasLength(1));
      });

      test('同日の写真複数枚 → 1グループにまとまる', () {
        final now = DateTime.now();
        final photo1 = createMockPhoto(
          DateTime(now.year, now.month, now.day, 10, 0),
        );
        final photo2 = createMockPhoto(
          DateTime(now.year, now.month, now.day, 14, 0),
        );

        final result = service.groupPhotosForTimelineLocalized(
          [photo1, photo2],
          todayLabel: '今日',
          yesterdayLabel: '昨日',
          monthYearFormatter: (year, month) => '$year年$month月',
        );

        expect(result, hasLength(1));
        expect(result[0].photos, hasLength(2));
      });

      test('昨日の写真 → 「昨日」グループ', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final photo = createMockPhoto(
          DateTime(yesterday.year, yesterday.month, yesterday.day, 12, 0),
        );

        final result = service.groupPhotosForTimelineLocalized(
          [photo],
          todayLabel: '今日',
          yesterdayLabel: '昨日',
          monthYearFormatter: (year, month) => '$year年$month月',
        );

        expect(result, hasLength(1));
        expect(result[0].displayName, '昨日');
        expect(result[0].type, TimelineGroupType.yesterday);
      });

      test('異なる月の写真 → 月別グループ（降順）', () {
        final photo1 = createMockPhoto(DateTime(2025, 6, 15));
        final photo2 = createMockPhoto(DateTime(2025, 8, 10));
        final photo3 = createMockPhoto(DateTime(2025, 3, 1));

        final result = service.groupPhotosForTimelineLocalized(
          [photo1, photo2, photo3],
          todayLabel: '今日',
          yesterdayLabel: '昨日',
          monthYearFormatter: (year, month) => '$year年$month月',
        );

        expect(result, hasLength(3));
        // 降順（新しい月が先）
        expect(result[0].displayName, '2025年8月');
        expect(result[1].displayName, '2025年6月');
        expect(result[2].displayName, '2025年3月');
      });

      test('今日・昨日・月の混在 → 正しい順序', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day, 10, 0);
        final yesterday = DateTime(
          now.year,
          now.month,
          now.day,
          10,
          0,
        ).subtract(const Duration(days: 1));
        final oldDate = DateTime(2025, 1, 15);

        final result = service.groupPhotosForTimelineLocalized(
          [
            createMockPhoto(today),
            createMockPhoto(yesterday),
            createMockPhoto(oldDate),
          ],
          todayLabel: '今日',
          yesterdayLabel: '昨日',
          monthYearFormatter: (year, month) => '$year年$month月',
        );

        expect(result, hasLength(3));
        expect(result[0].type, TimelineGroupType.today);
        expect(result[1].type, TimelineGroupType.yesterday);
        expect(result[2].type, TimelineGroupType.monthly);
      });
    });

    group('groupPhotosForTimelineLocalized', () {
      test('カスタムラベルで正しくグルーピング', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day, 10, 0);
        final yesterday = today.subtract(const Duration(days: 1));

        final result = service.groupPhotosForTimelineLocalized(
          [createMockPhoto(today), createMockPhoto(yesterday)],
          todayLabel: 'Today',
          yesterdayLabel: 'Yesterday',
          monthYearFormatter: (year, month) => '$month/$year',
        );

        expect(result, hasLength(2));
        expect(result[0].displayName, 'Today');
        expect(result[1].displayName, 'Yesterday');
      });

      test('月フォーマッターが正しく適用される', () {
        final photo = createMockPhoto(DateTime(2025, 6, 15));

        final result = service.groupPhotosForTimelineLocalized(
          [photo],
          todayLabel: '今日',
          yesterdayLabel: '昨日',
          monthYearFormatter: (year, month) => '$year/$month',
        );

        expect(result, hasLength(1));
        expect(result[0].displayName, '2025/6');
      });

      test('空リスト → 空リスト', () {
        final result = service.groupPhotosForTimelineLocalized(
          [],
          todayLabel: 'Today',
          yesterdayLabel: 'Yesterday',
          monthYearFormatter: (year, month) => '$month/$year',
        );

        expect(result, isEmpty);
      });
    });

    group('getTimelineHeader', () {
      test('今日のヘッダーテキストを正しく生成する', () {
        final today = DateTime.now();
        final result = service.getTimelineHeaderLocalized(
          today,
          TimelineGroupType.today,
          todayLabel: '今日',
          yesterdayLabel: '昨日',
          monthYearFormatter: (year, month) => '$year年$month月',
        );
        expect(result, '今日');
      });

      test('昨日のヘッダーテキストを正しく生成する', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final result = service.getTimelineHeaderLocalized(
          yesterday,
          TimelineGroupType.yesterday,
          todayLabel: '今日',
          yesterdayLabel: '昨日',
          monthYearFormatter: (year, month) => '$year年$month月',
        );
        expect(result, '昨日');
      });

      test('月単位のヘッダーテキストを正しく生成する', () {
        final date = DateTime(2025, 1, 15);
        final result = service.getTimelineHeaderLocalized(
          date,
          TimelineGroupType.monthly,
          todayLabel: '今日',
          yesterdayLabel: '昨日',
          monthYearFormatter: (year, month) => '$year年$month月',
        );
        expect(result, '2025年1月');
      });
    });

    group('getTimelineHeaderLocalized', () {
      test('今日 → todayLabel', () {
        final result = service.getTimelineHeaderLocalized(
          DateTime.now(),
          TimelineGroupType.today,
          todayLabel: 'Today',
          yesterdayLabel: 'Yesterday',
          monthYearFormatter: (year, month) => '$month/$year',
        );
        expect(result, 'Today');
      });

      test('昨日 → yesterdayLabel', () {
        final result = service.getTimelineHeaderLocalized(
          DateTime.now(),
          TimelineGroupType.yesterday,
          todayLabel: 'Today',
          yesterdayLabel: 'Yesterday',
          monthYearFormatter: (year, month) => '$month/$year',
        );
        expect(result, 'Yesterday');
      });

      test('月 → monthYearFormatter結果', () {
        final result = service.getTimelineHeaderLocalized(
          DateTime(2025, 6),
          TimelineGroupType.monthly,
          todayLabel: '今日',
          yesterdayLabel: '昨日',
          monthYearFormatter: (year, month) => '$year年$month月',
        );
        expect(result, '2025年6月');
      });
    });

    group('shouldShowDimmed', () {
      test('selectedDate=null → false', () {
        final photo = createMockPhoto(DateTime(2026, 1, 15));
        expect(service.shouldShowDimmed(photo, null), isFalse);
      });

      test('選択日と同じ日付 → false', () {
        final date = DateTime(2026, 1, 15, 10, 30);
        final photo = createMockPhoto(date);
        final selectedDate = DateTime(2026, 1, 15, 8, 0);
        expect(service.shouldShowDimmed(photo, selectedDate), isFalse);
      });

      test('選択日と異なる日付 → true', () {
        final photo = createMockPhoto(DateTime(2026, 1, 15));
        final selectedDate = DateTime(2026, 1, 16);
        expect(service.shouldShowDimmed(photo, selectedDate), isTrue);
      });
    });

    group('getSelectedDate', () {
      test('空リスト → null', () {
        expect(service.getSelectedDate([]), isNull);
      });

      test('写真あり → 先頭写真のcreateDateTime', () {
        final date = DateTime(2026, 1, 15, 10, 30);
        final photo = createMockPhoto(date);
        expect(service.getSelectedDate([photo]), date);
      });

      test('複数写真 → 先頭写真のcreateDateTime', () {
        final date1 = DateTime(2026, 1, 15);
        final date2 = DateTime(2026, 1, 16);
        final photo1 = createMockPhoto(date1);
        final photo2 = createMockPhoto(date2);
        expect(service.getSelectedDate([photo1, photo2]), date1);
      });
    });
  });
}
