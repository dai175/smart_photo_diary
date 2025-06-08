import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/result/result_extensions.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('should create success result', () {
        const value = 'test value';
        final result = Success(value);

        expect(result.isSuccess, true);
        expect(result.isFailure, false);
        expect(result.value, value);
        expect(result.valueOrNull, value);
      });

      test('should get value or default', () {
        const value = 'test value';
        const defaultValue = 'default';
        final result = Success(value);

        expect(result.getOrDefault(defaultValue), value);
      });

      test('should execute onSuccess callback', () {
        const value = 'test value';
        final result = Success(value);
        String? callbackValue;

        result.onSuccess((v) => callbackValue = v);
        
        expect(callbackValue, value);
      });

      test('should not execute onFailure callback', () {
        const value = 'test value';
        final result = Success(value);
        bool callbackExecuted = false;

        result.onFailure((_) => callbackExecuted = true);
        
        expect(callbackExecuted, false);
      });

      test('should map value successfully', () {
        const value = 'test';
        final result = Success(value);

        final mapped = result.map((v) => v.toUpperCase());

        expect(mapped.isSuccess, true);
        expect(mapped.value, 'TEST');
      });

      test('should fold to success path', () {
        const value = 'test value';
        final result = Success(value);

        final folded = result.fold(
          (v) => 'success: $v',
          (e) => 'failure: $e',
        );

        expect(folded, 'success: $value');
      });
    });

    group('Failure', () {
      test('should create failure result', () {
        final error = ServiceException('test error');
        final result = Failure<String>(error);

        expect(result.isSuccess, false);
        expect(result.isFailure, true);
        expect(result.error, error);
        expect(result.errorOrNull, error);
        expect(result.valueOrNull, null);
      });

      test('should get default value on failure', () {
        final error = ServiceException('test error');
        const defaultValue = 'default';
        final result = Failure<String>(error);

        expect(result.getOrDefault(defaultValue), defaultValue);
      });

      test('should not execute onSuccess callback', () {
        final error = ServiceException('test error');
        final result = Failure<String>(error);
        bool callbackExecuted = false;

        result.onSuccess((_) => callbackExecuted = true);
        
        expect(callbackExecuted, false);
      });

      test('should execute onFailure callback', () {
        final error = ServiceException('test error');
        final result = Failure<String>(error);
        AppException? callbackError;

        result.onFailure((e) => callbackError = e);
        
        expect(callbackError, error);
      });

      test('should not map value on failure', () {
        final error = ServiceException('test error');
        final result = Failure<String>(error);

        final mapped = result.map((v) => v.toUpperCase());

        expect(mapped.isFailure, true);
        expect(mapped.error, error);
      });

      test('should fold to failure path', () {
        final error = ServiceException('test error');
        final result = Failure<String>(error);

        final folded = result.fold(
          (v) => 'success: $v',
          (e) => 'failure: $e',
        );

        expect(folded, 'failure: $error');
      });

      test('should throw error when accessing value', () {
        final error = ServiceException('test error');
        final result = Failure<String>(error);

        expect(() => result.value, throwsStateError);
      });

      test('should throw error when accessing error from success', () {
        const value = 'test';
        final result = Success(value);

        expect(() => result.error, throwsStateError);
      });
    });

    group('ResultHelper', () {
      test('should create success result', () {
        const value = 'test';
        final result = ResultHelper.success(value);

        expect(result.isSuccess, true);
        expect(result.value, value);
      });

      test('should create failure result', () {
        final error = ServiceException('test error');
        final result = ResultHelper.failure<String>(error);

        expect(result.isFailure, true);
        expect(result.error, error);
      });

      test('should execute operation successfully', () {
        final result = ResultHelper.tryExecute(() => 'success');

        expect(result.isSuccess, true);
        expect(result.value, 'success');
      });

      test('should catch exception and return failure', () {
        final result = ResultHelper.tryExecute<String>(() {
          throw Exception('test error');
        });

        expect(result.isFailure, true);
        expect(result.error, isA<ServiceException>());
      });

      test('should execute async operation successfully', () async {
        final result = await ResultHelper.tryExecuteAsync(() async => 'success');

        expect(result.isSuccess, true);
        expect(result.value, 'success');
      });

      test('should catch async exception and return failure', () async {
        final result = await ResultHelper.tryExecuteAsync<String>(() async {
          throw Exception('test error');
        });

        expect(result.isFailure, true);
        expect(result.error, isA<ServiceException>());
      });

      test('should combine successful results', () {
        final results = [
          Success('a'),
          Success('b'),
          Success('c'),
        ];

        final combined = ResultHelper.combine(results);

        expect(combined.isSuccess, true);
        expect(combined.value, ['a', 'b', 'c']);
      });

      test('should return first failure when combining', () {
        final error = ServiceException('test error');
        final results = [
          Success('a'),
          Failure<String>(error),
          Success('c'),
        ];

        final combined = ResultHelper.combine(results);

        expect(combined.isFailure, true);
        expect(combined.error, error);
      });

      test('should create result from condition - true', () {
        final result = ResultHelper.fromCondition(
          true,
          () => 'success',
          () => ServiceException('error'),
        );

        expect(result.isSuccess, true);
        expect(result.value, 'success');
      });

      test('should create result from condition - false', () {
        final error = ServiceException('test error');
        final result = ResultHelper.fromCondition(
          false,
          () => 'success',
          () => error,
        );

        expect(result.isFailure, true);
        expect(result.error, error);
      });

      test('should create result from non-null value', () {
        const value = 'test';
        final result = ResultHelper.fromNullable(
          value,
          () => ServiceException('null error'),
        );

        expect(result.isSuccess, true);
        expect(result.value, value);
      });

      test('should create result from null value', () {
        final error = ServiceException('null error');
        final result = ResultHelper.fromNullable<String>(
          null,
          () => error,
        );

        expect(result.isFailure, true);
        expect(result.error, error);
      });
    });

    group('Equality', () {
      test('should be equal for same success values', () {
        final result1 = Success('test');
        final result2 = Success('test');

        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('should not be equal for different success values', () {
        final result1 = Success('test1');
        final result2 = Success('test2');

        expect(result1, isNot(equals(result2)));
      });

      test('should be equal for same failure errors', () {
        final error = ServiceException('test error');
        final result1 = Failure<String>(error);
        final result2 = Failure<String>(error);

        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('should not be equal for success and failure', () {
        final success = Success('test');
        final failure = Failure<String>(ServiceException('error'));

        expect(success, isNot(equals(failure)));
      });
    });

    group('String representation', () {
      test('should show success value in toString', () {
        final result = Success('test');
        expect(result.toString(), 'Success(test)');
      });

      test('should show failure error in toString', () {
        final error = ServiceException('test error');
        final result = Failure<String>(error);
        expect(result.toString(), contains('Failure'));
        expect(result.toString(), contains('test error'));
      });
    });
  });

  group('FutureResultExtensions', () {
    test('should map async result successfully', () async {
      Future<Result<String>> futureResult = Future.value(Success('test'));

      final mapped = await futureResult.mapAsync((value) async => value.toUpperCase());

      expect(mapped.isSuccess, true);
      expect(mapped.value, 'TEST');
    });

    test('should chain async results', () async {
      Future<Result<String>> futureResult = Future.value(Success('test'));

      final chained = await futureResult.chainAsync((value) async {
        return Success(value.toUpperCase());
      });

      expect(chained.isSuccess, true);
      expect(chained.value, 'TEST');
    });

    test('should get value or null from future result', () async {
      Future<Result<String>> futureSuccess = Future.value(Success('test'));
      Future<Result<String>> futureFailure = Future.value(
        Failure(ServiceException('error'))
      );

      final successValue = await futureSuccess.getValueOrNull();
      final failureValue = await futureFailure.getValueOrNull();

      expect(successValue, 'test');
      expect(failureValue, null);
    });

    test('should get or default from future result', () async {
      Future<Result<String>> futureSuccess = Future.value(Success('test'));
      Future<Result<String>> futureFailure = Future.value(
        Failure(ServiceException('error'))
      );

      final successValue = await futureSuccess.getOrDefault('default');
      final failureValue = await futureFailure.getOrDefault('default');

      expect(successValue, 'test');
      expect(failureValue, 'default');
    });
  });

  group('ListResultExtensions', () {
    test('should get success values only', () {
      final results = [
        Success('a'),
        Failure<String>(ServiceException('error')),
        Success('c'),
      ];

      final successValues = results.getSuccessValues();

      expect(successValues, ['a', 'c']);
    });

    test('should get failure errors only', () {
      final error1 = ServiceException('error1');
      final error2 = ServiceException('error2');
      final results = [
        Success('a'),
        Failure<String>(error1),
        Failure<String>(error2),
      ];

      final failureErrors = results.getFailureErrors();

      expect(failureErrors, [error1, error2]);
    });

    test('should check if all are success', () {
      final allSuccess = [Success('a'), Success('b'), Success('c')];
      final mixed = [Success('a'), Failure<String>(ServiceException('error'))];

      expect(allSuccess.allSuccess, true);
      expect(mixed.allSuccess, false);
    });

    test('should check if all are failure', () {
      final allFailure = [
        Failure<String>(ServiceException('error1')),
        Failure<String>(ServiceException('error2')),
      ];
      final mixed = [Success('a'), Failure<String>(ServiceException('error'))];

      expect(allFailure.allFailure, true);
      expect(mixed.allFailure, false);
    });

    test('should get first failure', () {
      final error = ServiceException('first error');
      final results = [
        Success('a'),
        Failure<String>(error),
        Failure<String>(ServiceException('second error')),
      ];

      final firstFailure = results.firstFailure;

      expect(firstFailure?.isFailure, true);
      expect(firstFailure?.error, error);
    });
  });
}