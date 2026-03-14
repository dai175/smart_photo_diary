import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/utils/performance_monitor.dart';

class MockLoggingService extends Mock implements ILoggingService {}

void main() {
  late MockLoggingService mockLogger;

  setUp(() {
    mockLogger = MockLoggingService();
    if (serviceLocator.isRegistered<ILoggingService>()) {
      serviceLocator.unregister<ILoggingService>();
    }
    serviceLocator.registerSingleton<ILoggingService>(mockLogger);
    PerformanceMonitor.clearStats();
  });

  tearDown(() {
    PerformanceMonitor.clearStats();
    if (serviceLocator.isRegistered<ILoggingService>()) {
      serviceLocator.unregister<ILoggingService>();
    }
  });

  group('PerformanceMonitor', () {
    group('startMeasurement / endMeasurement', () {
      test('records measurement duration', () async {
        PerformanceMonitor.startMeasurement('test_op');

        // Small delay to ensure measurable duration
        await Future.delayed(const Duration(milliseconds: 10));

        await PerformanceMonitor.endMeasurement('test_op', context: 'test');

        verify(
          () => mockLogger.debug(
            any(that: contains('test_op')),
            context: any(named: 'context'),
          ),
        ).called(1);
      });

      test('warns when ending measurement that was not started', () async {
        await PerformanceMonitor.endMeasurement('nonexistent');

        verify(
          () => mockLogger.warning(
            any(that: contains('Measurement not started')),
            context: any(named: 'context'),
          ),
        ).called(1);
      });

      test('accumulates multiple measurements for same label', () async {
        for (int i = 0; i < 3; i++) {
          PerformanceMonitor.startMeasurement('repeat_op');
          await PerformanceMonitor.endMeasurement('repeat_op');
        }

        final stats = PerformanceMonitor.getAverageStats();
        expect(stats.containsKey('repeat_op'), isTrue);
        expect(stats['repeat_op'], isA<double>());
      });
    });

    group('clearStats', () {
      test('clears all measurements', () async {
        PerformanceMonitor.startMeasurement('clear_test');
        await PerformanceMonitor.endMeasurement('clear_test');

        expect(PerformanceMonitor.getAverageStats(), isNotEmpty);

        PerformanceMonitor.clearStats();

        expect(PerformanceMonitor.getAverageStats(), isEmpty);
      });
    });

    group('getAverageStats', () {
      test('returns empty map when no measurements', () {
        expect(PerformanceMonitor.getAverageStats(), isEmpty);
      });

      test('returns average for recorded measurements', () async {
        PerformanceMonitor.startMeasurement('avg_test');
        await PerformanceMonitor.endMeasurement('avg_test');

        final stats = PerformanceMonitor.getAverageStats();
        expect(stats['avg_test'], isNotNull);
        expect(stats['avg_test']!, greaterThanOrEqualTo(0.0));
      });
    });

    group('logMemoryUsage', () {
      test('logs memory usage', () async {
        await PerformanceMonitor.logMemoryUsage('test_context');

        verify(
          () => mockLogger.debug(
            any(that: contains('Memory usage recorded')),
            context: 'test_context',
            data: any(named: 'data'),
          ),
        ).called(1);
      });
    });
  });
}
