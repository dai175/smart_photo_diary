import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock platform channels for testing
class MockPlatformChannels {
  static void setupMocks() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'check':
            return 'wifi'; // Mock wifi connection
          case 'wifiName':
            return 'MockWifi';
          case 'wifiBSSID':
            return '00:00:00:00:00:00';
          case 'wifiIP':
            return '192.168.1.1';
          default:
            return null;
        }
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.fluttercandies/photo_manager'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'requestPermissionExtend':
            return {'result': 1, 'hasAll': true}; // Authorized
          case 'getAssetPathList':
            return []; // Empty photo list
          case 'getAssetListPaged':
            return {'data': [], 'hasMore': false};
          case 'getAssetListRange':
            return [];
          case 'getOriginBytes':
            return null;
          case 'getThumbnail':
            return null;
          default:
            return null;
        }
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.native/helper'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'requestPermission':
            return true;
          default:
            return null;
        }
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/permission_handler'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'requestPermissions':
            return {13: 1}; // PERMISSION_GRANTED for photos
          case 'checkPermissionStatus':
            return 1; // PERMISSION_GRANTED
          default:
            return null;
        }
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getApplicationDocumentsDirectory':
            return '/tmp/test_docs';
          case 'getTemporaryDirectory':
            return '/tmp';
          default:
            return null;
        }
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getAll':
            return <String, dynamic>{};
          case 'setBool':
          case 'setString':
          case 'setInt':
          case 'setDouble':
          case 'setStringList':
            return true;
          case 'remove':
            return true;
          case 'clear':
            return true;
          default:
            return null;
        }
      },
    );
  }

  static void clearMocks() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.fluttercandies/photo_manager'),
      null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.native/helper'),
      null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/permission_handler'),
      null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      null,
    );
  }
}