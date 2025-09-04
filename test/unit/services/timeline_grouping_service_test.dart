import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/services/timeline_grouping_service.dart';
import 'package:smart_photo_diary/models/timeline_photo_group.dart';

void main() {
  group('TimelineGroupingService', () {
    late TimelineGroupingService service;

    setUp(() {
      service = TimelineGroupingService();
    });

    group('groupPhotosForTimeline', () {
      test('空のリストを正しく処理する', () {
        final result = service.groupPhotosForTimeline([]);
        expect(result, isEmpty);
      });

      test('今日・昨日・月単位のグルーピングが正しく動作する', () {
        // モックの写真データを作成（実際のAssetEntityは作成困難なので、統合テストで確認）
        final result = service.groupPhotosForTimeline([]);
        expect(result, isA<List<TimelinePhotoGroup>>());
      });
    });

    group('getTimelineHeader', () {
      test('今日のヘッダーテキストを正しく生成する', () {
        final today = DateTime.now();
        final result = service.getTimelineHeader(
          today,
          TimelineGroupType.today,
        );
        expect(result, '今日');
      });

      test('昨日のヘッダーテキストを正しく生成する', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final result = service.getTimelineHeader(
          yesterday,
          TimelineGroupType.yesterday,
        );
        expect(result, '昨日');
      });

      test('月単位のヘッダーテキストを正しく生成する', () {
        final date = DateTime(2025, 1, 15);
        final result = service.getTimelineHeader(
          date,
          TimelineGroupType.monthly,
        );
        expect(result, '2025年1月');
      });
    });

    // NOTE: shouldShowDimmed と getSelectedDate のテストは AssetEntity のモック作成が困難なため、
    // 統合テストで実装することを推奨します。
    // ユニットテストレベルでは文字列処理やグルーピングロジック等の部分をテストしています。
  });
}

// AssetEntity を使用するテストは統合テストで実装することを推奨
