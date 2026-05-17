import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/photo_date_range_service.dart';

class MockAssetEntity extends Mock implements AssetEntity {}

class MockLoggingService extends Mock implements ILoggingService {}

MockAssetEntity createMockAsset(String id, {DateTime? createDateTime}) {
  final entity = MockAssetEntity();
  when(() => entity.id).thenReturn(id);
  if (createDateTime != null) {
    when(() => entity.createDateTime).thenReturn(createDateTime);
  }
  return entity;
}

void setupMockLogger(MockLoggingService logger) {
  when(
    () => logger.warning(
      any(),
      context: any(named: 'context'),
      data: any(named: 'data'),
    ),
  ).thenReturn(null);
  when(
    () => logger.debug(
      any(),
      context: any(named: 'context'),
      data: any(named: 'data'),
    ),
  ).thenReturn(null);
}

void main() {
  group('PhotoDateRangeService.buildDateFilter', () {
    test('returns filter with descending order when no dates given', () {
      final filter = PhotoDateRangeService.buildDateFilter();
      expect(filter.orders, isNotEmpty);
      expect(filter.orders.first.type, OrderOptionType.createDate);
      expect(filter.orders.first.asc, isFalse);
    });

    test('returns DateTimeCond filter when only startDate provided', () {
      final start = DateTime(2024, 1, 1);
      final filter = PhotoDateRangeService.buildDateFilter(startDate: start);
      expect(filter.createTimeCond, isNotNull);
      expect(filter.createTimeCond.min, start);
    });

    test('returns DateTimeCond filter when only endDate provided', () {
      final end = DateTime(2024, 12, 31);
      final filter = PhotoDateRangeService.buildDateFilter(endDate: end);
      expect(filter.createTimeCond, isNotNull);
      expect(filter.createTimeCond.min, DateTime(1970));
      expect(filter.createTimeCond.max, end);
    });

    test('returns DateTimeCond filter when both dates provided', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 12, 31);
      final filter = PhotoDateRangeService.buildDateFilter(
        startDate: start,
        endDate: end,
      );
      expect(filter.createTimeCond, isNotNull);
      expect(filter.createTimeCond.min, start);
      expect(filter.createTimeCond.max, end);
    });

    test('orders are descending by createDate', () {
      final filter = PhotoDateRangeService.buildDateFilter();
      expect(filter.orders.first.type, OrderOptionType.createDate);
      expect(filter.orders.first.asc, isFalse);
    });
  });

  group('PhotoDateRangeService.filterByDateRange', () {
    late MockLoggingService logger;

    setUp(() {
      logger = MockLoggingService();
      setupMockLogger(logger);
    });

    test('keeps assets within the valid range', () {
      final asset = createMockAsset(
        'a1',
        createDateTime: DateTime(2024, 6, 15, 12),
      );
      final result = PhotoDateRangeService.filterByDateRange(
        [asset],
        startDate: DateTime(2024, 6, 1),
        endDate: DateTime(2024, 6, 30, 23, 59, 59),
        logger: logger,
        logContext: 'test',
      );
      expect(result.length, 1);
    });

    test('skips assets with createDate.year < 1970', () {
      final asset = createMockAsset('a1', createDateTime: DateTime(1969, 6, 1));
      final result = PhotoDateRangeService.filterByDateRange(
        [asset],
        startDate: DateTime(1960, 1, 1),
        endDate: DateTime(1969, 12, 31),
        logger: logger,
        logContext: 'test',
      );
      expect(result, isEmpty);
    });

    test('skips assets with createDate in the future', () {
      final asset = createMockAsset('a1', createDateTime: DateTime(2099, 1, 1));
      final result = PhotoDateRangeService.filterByDateRange(
        [asset],
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2099, 12, 31),
        logger: logger,
        logContext: 'test',
      );
      expect(result, isEmpty);
    });

    test('skips assets before startDate after local conversion', () {
      final asset = createMockAsset(
        'a1',
        createDateTime: DateTime(2024, 6, 14, 23, 59, 59),
      );
      final result = PhotoDateRangeService.filterByDateRange(
        [asset],
        startDate: DateTime(2024, 6, 15),
        endDate: DateTime(2024, 6, 15, 23, 59, 59),
        logger: logger,
        logContext: 'test',
      );
      expect(result, isEmpty);
    });

    test('skips assets after endDate after local conversion', () {
      final asset = createMockAsset(
        'a1',
        createDateTime: DateTime(2024, 6, 16),
      );
      final result = PhotoDateRangeService.filterByDateRange(
        [asset],
        startDate: DateTime(2024, 6, 15),
        endDate: DateTime(2024, 6, 15, 23, 59, 59),
        logger: logger,
        logContext: 'test',
      );
      expect(result, isEmpty);
    });

    test('handles exception in date access gracefully and continues', () {
      final validAsset = createMockAsset(
        'valid-1',
        createDateTime: DateTime(2024, 6, 15, 12),
      );
      final errorAsset = MockAssetEntity();
      when(() => errorAsset.id).thenReturn('error-1');
      when(() => errorAsset.createDateTime).thenThrow(Exception('date error'));

      final result = PhotoDateRangeService.filterByDateRange(
        [errorAsset, validAsset],
        startDate: DateTime(2024, 6, 1),
        endDate: DateTime(2024, 6, 30, 23, 59, 59),
        logger: logger,
        logContext: 'test',
      );

      expect(result.length, 1);
      expect(result.first, validAsset);
    });

    test('returns empty list for empty input', () {
      final result = PhotoDateRangeService.filterByDateRange(
        [],
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
        logger: logger,
        logContext: 'test',
      );
      expect(result, isEmpty);
    });
  });
}
