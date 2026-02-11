import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/services/logging_service.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';

void main() {
  late LoggingService logger;

  setUp(() {
    logger = LoggingService();
  });

  group('LoggingService', () {
    test('implements ILoggingService', () {
      expect(logger, isA<ILoggingService>());
    });

    test('debug() はエラーなく実行できる', () {
      expect(() => logger.debug('test debug message'), returnsNormally);
    });

    test('debug() にcontext/dataオプション付きで実行できる', () {
      expect(
        () => logger.debug(
          'test debug message',
          context: 'TestContext',
          data: {'key': 'value'},
        ),
        returnsNormally,
      );
    });

    test('info() はエラーなく実行できる', () {
      expect(() => logger.info('test info message'), returnsNormally);
    });

    test('warning() はエラーなく実行できる', () {
      expect(
        () => logger.warning('test warning message', context: 'TestWarning'),
        returnsNormally,
      );
    });

    test('error() はエラーなく実行できる', () {
      expect(
        () => logger.error(
          'test error message',
          context: 'TestError',
          error: Exception('test exception'),
        ),
        returnsNormally,
      );
    });

    test('error() にstackTrace付きでもエラーなく実行できる', () {
      expect(
        () => logger.error(
          'test error with stack trace',
          context: 'TestError',
          error: Exception('test'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('startTimer() は動作中のStopwatchを返す', () {
      final stopwatch = logger.startTimer('test operation');

      expect(stopwatch, isA<Stopwatch>());
      expect(stopwatch.isRunning, isTrue);

      // クリーンアップ
      stopwatch.stop();
    });

    test('endTimer() はStopwatchを停止する', () {
      final stopwatch = logger.startTimer('test operation');
      expect(stopwatch.isRunning, isTrue);

      logger.endTimer(stopwatch, 'test operation', context: 'TestTimer');

      expect(stopwatch.isRunning, isFalse);
    });
  });
}
