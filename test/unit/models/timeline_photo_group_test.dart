import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/timeline_photo_group.dart';

void main() {
  group('TimelinePhotoGroup', () {
    test('正しく初期化される', () {
      final group = TimelinePhotoGroup(
        displayName: '今日',
        groupDate: DateTime(2025, 1, 15),
        type: TimelineGroupType.today,
        photos: const [],
      );

      expect(group.displayName, '今日');
      expect(group.groupDate, DateTime(2025, 1, 15));
      expect(group.type, TimelineGroupType.today);
      expect(group.photos, isEmpty);
    });

    test('isToday プロパティが正しく動作する', () {
      final todayGroup = TimelinePhotoGroup(
        displayName: '今日',
        groupDate: DateTime.now(),
        type: TimelineGroupType.today,
        photos: const [],
      );

      final yesterdayGroup = TimelinePhotoGroup(
        displayName: '昨日',
        groupDate: DateTime.now().subtract(const Duration(days: 1)),
        type: TimelineGroupType.yesterday,
        photos: const [],
      );

      expect(todayGroup.isToday, true);
      expect(yesterdayGroup.isToday, false);
    });

    test('isYesterday プロパティが正しく動作する', () {
      final todayGroup = TimelinePhotoGroup(
        displayName: '今日',
        groupDate: DateTime.now(),
        type: TimelineGroupType.today,
        photos: const [],
      );

      final yesterdayGroup = TimelinePhotoGroup(
        displayName: '昨日',
        groupDate: DateTime.now().subtract(const Duration(days: 1)),
        type: TimelineGroupType.yesterday,
        photos: const [],
      );

      expect(todayGroup.isYesterday, false);
      expect(yesterdayGroup.isYesterday, true);
    });

    test('isMonthly プロパティが正しく動作する', () {
      final todayGroup = TimelinePhotoGroup(
        displayName: '今日',
        groupDate: DateTime.now(),
        type: TimelineGroupType.today,
        photos: const [],
      );

      final monthlyGroup = TimelinePhotoGroup(
        displayName: '2025年1月',
        groupDate: DateTime(2025, 1),
        type: TimelineGroupType.monthly,
        photos: const [],
      );

      expect(todayGroup.isMonthly, false);
      expect(monthlyGroup.isMonthly, true);
    });

    test('等価性チェックが正しく動作する', () {
      final group1 = TimelinePhotoGroup(
        displayName: '今日',
        groupDate: DateTime(2025, 1, 15),
        type: TimelineGroupType.today,
        photos: const [],
      );

      final group2 = TimelinePhotoGroup(
        displayName: '今日',
        groupDate: DateTime(2025, 1, 15),
        type: TimelineGroupType.today,
        photos: const [],
      );

      final group3 = TimelinePhotoGroup(
        displayName: '昨日',
        groupDate: DateTime(2025, 1, 14),
        type: TimelineGroupType.yesterday,
        photos: const [],
      );

      expect(group1, equals(group2));
      expect(group1, isNot(equals(group3)));
      expect(group1.hashCode, equals(group2.hashCode));
    });

    test('toString が正しく動作する', () {
      final group = TimelinePhotoGroup(
        displayName: '今日',
        groupDate: DateTime(2025, 1, 15),
        type: TimelineGroupType.today,
        photos: const [],
      );

      final result = group.toString();
      expect(result, contains('TimelinePhotoGroup'));
      expect(result, contains('displayName: 今日'));
      expect(result, contains('type: TimelineGroupType.today'));
      expect(result, contains('photos: 0'));
    });
  });

  group('TimelineGroupType', () {
    test('全ての列挙値が存在する', () {
      expect(TimelineGroupType.today, isNotNull);
      expect(TimelineGroupType.yesterday, isNotNull);
      expect(TimelineGroupType.monthly, isNotNull);
    });
  });
}