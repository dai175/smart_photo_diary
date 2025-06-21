import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/core/service_locator.dart';

// Test service classes
class TestService {
  final String name;
  TestService(this.name);
}

abstract class TestServiceInterface {
  String getName();
}

class TestServiceImpl implements TestServiceInterface {
  final String _name;
  TestServiceImpl(this._name);

  @override
  String getName() => _name;
}

class AsyncTestService {
  final String value;
  AsyncTestService(this.value);

  static Future<AsyncTestService> create(String value) async {
    // Simulate async initialization
    await Future.delayed(const Duration(milliseconds: 10));
    return AsyncTestService(value);
  }
}

void main() {
  group('ServiceLocator', () {
    late ServiceLocator serviceLocator;

    setUp(() {
      serviceLocator = ServiceLocator();
      serviceLocator.clear(); // Clear any existing registrations
    });

    tearDown(() {
      serviceLocator.clear();
    });

    group('Singleton Registration', () {
      test('should register and return singleton instance', () {
        // Arrange
        final testService = TestService('test');

        // Act
        serviceLocator.registerSingleton<TestService>(testService);
        final retrieved = serviceLocator.get<TestService>();

        // Assert
        expect(retrieved, same(testService));
        expect(retrieved.name, equals('test'));
      });

      test('should return same instance on multiple calls', () {
        // Arrange
        final testService = TestService('test');
        serviceLocator.registerSingleton<TestService>(testService);

        // Act
        final first = serviceLocator.get<TestService>();
        final second = serviceLocator.get<TestService>();

        // Assert
        expect(first, same(second));
      });

      test('should support interface-based registration', () {
        // Arrange
        final impl = TestServiceImpl('interface-test');
        serviceLocator.registerSingleton<TestServiceInterface>(impl);

        // Act
        final retrieved = serviceLocator.get<TestServiceInterface>();

        // Assert
        expect(retrieved, same(impl));
        expect(retrieved.getName(), equals('interface-test'));
      });
    });

    group('Factory Registration', () {
      test('should register and create instance from factory', () {
        // Arrange
        serviceLocator.registerFactory<TestService>(
          () => TestService('factory-test'),
        );

        // Act
        final retrieved = serviceLocator.get<TestService>();

        // Assert
        expect(retrieved.name, equals('factory-test'));
      });

      test('should create singleton after first factory call', () {
        // Arrange
        serviceLocator.registerFactory<TestService>(
          () => TestService('factory-singleton'),
        );

        // Act
        final first = serviceLocator.get<TestService>();
        final second = serviceLocator.get<TestService>();

        // Assert
        expect(first, same(second));
        expect(first.name, equals('factory-singleton'));
      });

      test('should support interface-based factory registration', () {
        // Arrange
        serviceLocator.registerFactory<TestServiceInterface>(
          () => TestServiceImpl('factory-interface'),
        );

        // Act
        final retrieved = serviceLocator.get<TestServiceInterface>();

        // Assert
        expect(retrieved.getName(), equals('factory-interface'));
      });
    });

    group('Async Factory Registration', () {
      test('should register and create instance from async factory', () async {
        // Arrange
        serviceLocator.registerAsyncFactory<AsyncTestService>(
          () => AsyncTestService.create('async-test'),
        );

        // Act
        final retrieved = await serviceLocator.getAsync<AsyncTestService>();

        // Assert
        expect(retrieved.value, equals('async-test'));
      });

      test('should create singleton after first async factory call', () async {
        // Arrange
        serviceLocator.registerAsyncFactory<AsyncTestService>(
          () => AsyncTestService.create('async-singleton'),
        );

        // Act
        final first = await serviceLocator.getAsync<AsyncTestService>();
        final second = await serviceLocator.getAsync<AsyncTestService>();

        // Assert
        expect(first, same(second));
        expect(first.value, equals('async-singleton'));
      });

      test(
        'should return existing singleton for getAsync after registration',
        () async {
          // Arrange
          serviceLocator.registerAsyncFactory<AsyncTestService>(
            () => AsyncTestService.create('existing-async'),
          );
          final first = await serviceLocator.getAsync<AsyncTestService>();

          // Act
          final second = await serviceLocator.getAsync<AsyncTestService>();

          // Assert
          expect(first, same(second));
        },
      );
    });

    group('Error Handling', () {
      test('should throw exception for unregistered service', () {
        // Act & Assert
        expect(
          () => serviceLocator.get<TestService>(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Service of type TestService is not registered'),
            ),
          ),
        );
      });

      test('should throw exception for async service used with sync get', () {
        // Arrange
        serviceLocator.registerAsyncFactory<AsyncTestService>(
          () => AsyncTestService.create('error-test'),
        );

        // Act & Assert
        expect(
          () => serviceLocator.get<AsyncTestService>(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('requires async initialization'),
            ),
          ),
        );
      });

      test('should throw exception for unregistered async service', () async {
        // Act & Assert
        expect(
          () => serviceLocator.getAsync<AsyncTestService>(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Service of type AsyncTestService is not registered'),
            ),
          ),
        );
      });
    });

    group('Utility Methods', () {
      test('isRegistered should return true for registered services', () {
        // Arrange
        serviceLocator.registerSingleton<TestService>(TestService('test'));

        // Act & Assert
        expect(serviceLocator.isRegistered<TestService>(), isTrue);
        expect(serviceLocator.isRegistered<AsyncTestService>(), isFalse);
      });

      test('isRegistered should return true for factory services', () {
        // Arrange
        serviceLocator.registerFactory<TestService>(() => TestService('test'));

        // Act & Assert
        expect(serviceLocator.isRegistered<TestService>(), isTrue);
      });

      test('unregister should remove service', () {
        // Arrange
        serviceLocator.registerSingleton<TestService>(TestService('test'));
        expect(serviceLocator.isRegistered<TestService>(), isTrue);

        // Act
        serviceLocator.unregister<TestService>();

        // Assert
        expect(serviceLocator.isRegistered<TestService>(), isFalse);
      });

      test('clear should remove all services', () {
        // Arrange
        serviceLocator.registerSingleton<TestService>(TestService('test1'));
        serviceLocator.registerFactory<TestServiceInterface>(
          () => TestServiceImpl('test2'),
        );
        expect(serviceLocator.registeredTypes.length, equals(2));

        // Act
        serviceLocator.clear();

        // Assert
        expect(serviceLocator.registeredTypes, isEmpty);
      });

      test('registeredTypes should return all registered types', () {
        // Arrange
        serviceLocator.registerSingleton<TestService>(TestService('test'));
        serviceLocator.registerFactory<TestServiceInterface>(
          () => TestServiceImpl('test'),
        );

        // Act
        final types = serviceLocator.registeredTypes;

        // Assert
        expect(types.length, equals(2));
        expect(types, contains(TestService));
        expect(types, contains(TestServiceInterface));
      });
    });

    group('Global Instance', () {
      test('global serviceLocator should be singleton', () {
        // This test ensures the global instance works
        final global1 = serviceLocator;
        final global2 = ServiceLocator();

        expect(global1, same(global2));
      });
    });
  });
}
