import 'package:flutter/foundation.dart';

/// Service Locator pattern implementation for dependency injection
///
/// This class provides a centralized way to register and resolve service dependencies.
/// It supports singleton pattern, interface-based registration, and lazy initialization.
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  factory ServiceLocator() => _instance;

  ServiceLocator._internal();

  /// Storage for singleton instances
  final Map<Type, dynamic> _services = {};

  /// Storage for factory functions
  final Map<Type, Function> _factories = {};

  /// Register a singleton instance
  void registerSingleton<T>(T instance) {
    if (kDebugMode) {
      debugPrint('ServiceLocator: Registering singleton ${T.toString()}');
    }
    _services[T] = instance;
  }

  /// Register a factory function for lazy initialization
  void registerFactory<T>(T Function() factory) {
    if (kDebugMode) {
      debugPrint('ServiceLocator: Registering factory ${T.toString()}');
    }
    _factories[T] = factory;
  }

  /// Register an async factory function for services that require async initialization
  void registerAsyncFactory<T>(Future<T> Function() factory) {
    if (kDebugMode) {
      debugPrint('ServiceLocator: Registering async factory ${T.toString()}');
    }
    _factories[T] = factory;
  }

  /// Get a service instance
  T get<T>() {
    final type = T;

    // Check if singleton instance exists
    if (_services.containsKey(type)) {
      if (kDebugMode) {
        debugPrint(
          'ServiceLocator: Returning singleton instance of ${type.toString()}',
        );
      }
      return _services[type] as T;
    }

    // Check if factory exists
    if (_factories.containsKey(type)) {
      final factory = _factories[type]!;
      if (kDebugMode) {
        debugPrint(
          'ServiceLocator: Creating instance from factory ${type.toString()}',
        );
      }

      final instance = factory();

      // If it's a Future, throw an error - use getAsync instead
      if (instance is Future) {
        throw Exception(
          'Service $type requires async initialization. Use getAsync<$type>() instead.',
        );
      }

      // Register as singleton for future use
      _services[type] = instance;
      return instance as T;
    }

    throw Exception(
      'Service of type $type is not registered. Please register it first.',
    );
  }

  /// Get a service instance asynchronously
  Future<T> getAsync<T>() async {
    final type = T;

    // Check if singleton instance exists
    if (_services.containsKey(type)) {
      if (kDebugMode) {
        debugPrint(
          'ServiceLocator: Returning singleton instance of ${type.toString()}',
        );
      }
      return _services[type] as T;
    }

    // Check if factory exists
    if (_factories.containsKey(type)) {
      final factory = _factories[type]!;
      if (kDebugMode) {
        debugPrint(
          'ServiceLocator: Creating instance from async factory ${type.toString()}',
        );
      }

      final instance = await factory();

      // Register as singleton for future use
      _services[type] = instance;
      return instance as T;
    }

    throw Exception(
      'Service of type $type is not registered. Please register it first.',
    );
  }

  /// Check if a service is registered
  bool isRegistered<T>() {
    final type = T;
    return _services.containsKey(type) || _factories.containsKey(type);
  }

  /// Unregister a service (useful for testing)
  void unregister<T>() {
    final type = T;
    if (kDebugMode) {
      debugPrint('ServiceLocator: Unregistering ${type.toString()}');
    }
    _services.remove(type);
    _factories.remove(type);
  }

  /// Clear all services (useful for testing)
  void clear() {
    if (kDebugMode) {
      debugPrint('ServiceLocator: Clearing all services');
    }
    _services.clear();
    _factories.clear();
  }

  /// Get all registered service types (for debugging)
  List<Type> get registeredTypes {
    final Set<Type> types = {};
    types.addAll(_services.keys);
    types.addAll(_factories.keys);
    return types.toList();
  }

  /// Print debug information about registered services
  void debugPrintServices() {
    if (kDebugMode) {
      debugPrint('ServiceLocator registered services:');
      debugPrint('Singletons: ${_services.keys.toList()}');
      debugPrint('Factories: ${_factories.keys.toList()}');
    }
  }
}

/// Global service locator instance for convenience
final serviceLocator = ServiceLocator();
