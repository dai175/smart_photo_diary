import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/errors/error_handler.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';

class MockLoggingService extends Mock implements ILoggingService {}

void main() {
  late MockLoggingService mockLogger;

  setUp(() {
    mockLogger = MockLoggingService();
    ErrorHandler.configure(logger: mockLogger);
  });

  group('ErrorHandler', () {
    group('handleError', () {
      test('returns same AppException when given AppException', () {
        const exception = ServiceException('test error');

        final result = ErrorHandler.handleError(exception, context: 'test');

        expect(result, isA<ServiceException>());
        expect(result.message, 'test error');
        verify(
          () => mockLogger.error(
            any(),
            context: any(named: 'context'),
            error: any(named: 'error'),
          ),
        ).called(1);
      });

      test('wraps non-AppException in ServiceException', () {
        final error = Exception('generic error');

        final result = ErrorHandler.handleError(error, context: 'test');

        expect(result, isA<ServiceException>());
        expect(result.message, 'An unexpected error occurred');
        expect(result.originalError, error);
      });

      test('handles String error', () {
        final result = ErrorHandler.handleError('string error');

        expect(result, isA<ServiceException>());
      });

      test(
        'falls back to debugPrint when LoggingService is not configured',
        () {
          ErrorHandler.resetForTesting();

          final result = ErrorHandler.handleError(
            Exception('test'),
            context: 'fallback',
          );

          expect(result, isA<ServiceException>());
        },
      );
    });

    group('logError', () {
      test('logs error with context and stackTrace', () {
        final error = Exception('test');
        final stackTrace = StackTrace.current;

        ErrorHandler.logError(error, context: 'test', stackTrace: stackTrace);

        verify(
          () => mockLogger.error(
            any(),
            context: 'test',
            error: error,
            stackTrace: stackTrace,
          ),
        ).called(1);
      });

      test('falls back to debugPrint when LoggingService unavailable', () {
        ErrorHandler.resetForTesting();

        // Should not throw
        ErrorHandler.logError(Exception('test'), context: 'fallback');
      });
    });

    group('toFailure', () {
      test('returns Failure with AppException', () {
        const exception = ServiceException('test');

        final result = ErrorHandler.toFailure<String>(exception);

        expect(result, isA<Failure<String>>());
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
      });

      test('wraps generic error in Failure', () {
        final result = ErrorHandler.toFailure<int>('generic', context: 'test');

        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
      });
    });

    group('safeExecute', () {
      test('returns result on success', () async {
        final result = await ErrorHandler.safeExecute<int>(
          () async => 42,
          context: 'test',
        );

        expect(result, 42);
      });

      test('returns fallbackValue on error', () async {
        final result = await ErrorHandler.safeExecute<int>(
          () async => throw Exception('fail'),
          context: 'test',
          fallbackValue: -1,
        );

        expect(result, -1);
      });

      test('returns null on error without fallback', () async {
        final result = await ErrorHandler.safeExecute<int>(
          () async => throw Exception('fail'),
          context: 'test',
        );

        expect(result, isNull);
      });
    });

    group('safeExecuteSync', () {
      test('returns result on success', () {
        final result = ErrorHandler.safeExecuteSync<int>(
          () => 42,
          context: 'test',
        );

        expect(result, 42);
      });

      test('returns fallbackValue on error', () {
        final result = ErrorHandler.safeExecuteSync<int>(
          () => throw Exception('fail'),
          context: 'test',
          fallbackValue: -1,
        );

        expect(result, -1);
      });

      test('returns null on error without fallback', () {
        final result = ErrorHandler.safeExecuteSync<int>(
          () => throw Exception('fail'),
        );

        expect(result, isNull);
      });
    });
  });
}
