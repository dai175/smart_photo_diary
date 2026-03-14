import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/result/result_extensions.dart';

void main() {
  group('ResultHelper', () {
    group('tryExecute', () {
      test('returns Success on successful operation', () {
        final result = ResultHelper.tryExecute(() => 42);

        expect(result.isSuccess, isTrue);
        expect(result.value, 42);
      });

      test('returns Failure with AppException on AppException throw', () {
        final result = ResultHelper.tryExecute<int>(
          () => throw const ServiceException('test error'),
        );

        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
        expect(result.error.message, 'test error');
      });

      test('returns Failure with ServiceException on generic throw', () {
        final result = ResultHelper.tryExecute<int>(
          () => throw Exception('generic'),
          context: 'myOp',
        );

        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
        expect(result.error.message, contains('[myOp]'));
      });

      test('wraps error without context', () {
        final result = ResultHelper.tryExecute<int>(
          () => throw Exception('generic'),
        );

        expect(result.isFailure, isTrue);
        expect(result.error.message, 'An error occurred during processing');
      });
    });

    group('tryExecuteAsync', () {
      test('returns Success on successful async operation', () async {
        final result = await ResultHelper.tryExecuteAsync(() async => 'hello');

        expect(result.isSuccess, isTrue);
        expect(result.value, 'hello');
      });

      test('returns Failure on async error', () async {
        final result = await ResultHelper.tryExecuteAsync<int>(
          () async => throw Exception('async fail'),
          context: 'asyncOp',
        );

        expect(result.isFailure, isTrue);
        expect(result.error.message, contains('[asyncOp]'));
      });

      test('preserves AppException in async', () async {
        final result = await ResultHelper.tryExecuteAsync<int>(
          () async => throw const ServiceException('async service error'),
        );

        expect(result.isFailure, isTrue);
        expect(result.error.message, 'async service error');
      });
    });

    group('combine', () {
      test('returns Success with all values when all succeed', () {
        final results = [
          const Success<int>(1),
          const Success<int>(2),
          const Success<int>(3),
        ];

        final combined = ResultHelper.combine(results);

        expect(combined.isSuccess, isTrue);
        expect(combined.value, [1, 2, 3]);
      });

      test('returns first Failure when any fails', () {
        final results = <Result<int>>[
          const Success(1),
          const Failure(ServiceException('fail')),
          const Success(3),
        ];

        final combined = ResultHelper.combine(results);

        expect(combined.isFailure, isTrue);
        expect(combined.error.message, 'fail');
      });

      test('handles empty list', () {
        final combined = ResultHelper.combine<int>([]);

        expect(combined.isSuccess, isTrue);
        expect(combined.value, isEmpty);
      });
    });

    group('fromCondition', () {
      test('returns Success when condition is true', () {
        final result = ResultHelper.fromCondition<int>(
          true,
          () => 42,
          () => const ServiceException('false'),
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, 42);
      });

      test('returns Failure when condition is false', () {
        final result = ResultHelper.fromCondition<int>(
          false,
          () => 42,
          () => const ServiceException('condition false'),
        );

        expect(result.isFailure, isTrue);
        expect(result.error.message, 'condition false');
      });
    });

    group('fromNullable', () {
      test('returns Success when value is not null', () {
        final result = ResultHelper.fromNullable<int>(
          42,
          () => const ServiceException('null'),
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, 42);
      });

      test('returns Failure when value is null', () {
        final result = ResultHelper.fromNullable<int>(
          null,
          () => const ServiceException('was null'),
        );

        expect(result.isFailure, isTrue);
        expect(result.error.message, 'was null');
      });
    });
  });

  group('FutureResultExtensions', () {
    group('mapAsync', () {
      test('maps successful Future<Result> value', () async {
        final futureResult = Future.value(const Success<int>(10));

        final mapped = await futureResult.mapAsync((value) async => value * 2);

        expect(mapped.isSuccess, isTrue);
        expect(mapped.value, 20);
      });

      test('propagates Failure through mapAsync', () async {
        final futureResult = Future.value(
          const Failure<int>(ServiceException('fail')),
        );

        final mapped = await futureResult.mapAsync((value) async => value * 2);

        expect(mapped.isFailure, isTrue);
      });
    });

    group('chainAsync', () {
      test('chains successful results', () async {
        final futureResult = Future.value(const Success<int>(5));

        final chained = await futureResult.chainAsync(
          (value) async => Success<String>('value: $value'),
        );

        expect(chained.isSuccess, isTrue);
        expect(chained.value, 'value: 5');
      });

      test('short-circuits on Failure', () async {
        final futureResult = Future.value(
          const Failure<int>(ServiceException('fail')),
        );

        var called = false;
        final chained = await futureResult.chainAsync((value) async {
          called = true;
          return Success<String>('$value');
        });

        expect(chained.isFailure, isTrue);
        expect(called, isFalse);
      });
    });

    group('getValueOrNull', () {
      test('returns value on Success', () async {
        final result = await Future.value(
          const Success<int>(42),
        ).getValueOrNull();

        expect(result, 42);
      });

      test('returns null on Failure', () async {
        final result = await Future.value(
          const Failure<int>(ServiceException('fail')),
        ).getValueOrNull();

        expect(result, isNull);
      });
    });

    group('getOrDefault', () {
      test('returns value on Success', () async {
        final result = await Future.value(
          const Success<int>(42),
        ).getOrDefault(0);

        expect(result, 42);
      });

      test('returns default on Failure', () async {
        final result = await Future.value(
          const Failure<int>(ServiceException('fail')),
        ).getOrDefault(0);

        expect(result, 0);
      });
    });
  });

  group('ListResultExtensions', () {
    group('getSuccessValues', () {
      test('extracts only successful values', () {
        final results = <Result<int>>[
          const Success(1),
          const Failure(ServiceException('fail')),
          const Success(3),
        ];

        expect(results.getSuccessValues(), [1, 3]);
      });

      test('returns empty list when all fail', () {
        final results = <Result<int>>[
          const Failure(ServiceException('a')),
          const Failure(ServiceException('b')),
        ];

        expect(results.getSuccessValues(), isEmpty);
      });
    });

    group('allSuccess', () {
      test('returns true when all succeed', () {
        final results = <Result<int>>[const Success(1), const Success(2)];

        expect(results.allSuccess, isTrue);
      });

      test('returns false when any fails', () {
        final results = <Result<int>>[
          const Success(1),
          const Failure(ServiceException('fail')),
        ];

        expect(results.allSuccess, isFalse);
      });
    });

    group('firstFailure', () {
      test('returns first failure', () {
        final results = <Result<int>>[
          const Success(1),
          const Failure(ServiceException('first')),
          const Failure(ServiceException('second')),
        ];

        final failure = results.firstFailure;

        expect(failure, isNotNull);
        expect(failure!.isFailure, isTrue);
        expect(failure.error.message, 'first');
      });

      test('returns null when all succeed', () {
        final results = <Result<int>>[const Success(1), const Success(2)];

        expect(results.firstFailure, isNull);
      });
    });
  });
}
