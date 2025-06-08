import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/main.dart';
import 'package:smart_photo_diary/constants/app_constants.dart';
import 'test_helpers/integration_test_helpers.dart';
import 'mocks/mock_services.dart';

void main() {
  group('Basic Integration Tests', () {
    setUpAll(() {
      registerMockFallbacks();
    });

    setUp(() async {
      await IntegrationTestHelpers.setUpIntegrationEnvironment();
    });

    tearDown(() async {
      await IntegrationTestHelpers.tearDownIntegrationEnvironment();
    });

    testWidgets('should launch app successfully', (WidgetTester tester) async {
      // Arrange
      IntegrationTestHelpers.setupMockPhotoPermission(true);
      IntegrationTestHelpers.setupMockTodayPhotos([]);

      // Act
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Assert
      expect(find.text(AppConstants.appTitle), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('should display permission message without photos access', (WidgetTester tester) async {
      // Arrange
      IntegrationTestHelpers.setupMockPhotoPermission(false);

      // Act
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Assert
      expect(find.text(AppConstants.appTitle), findsOneWidget);
      expect(find.text(AppConstants.permissionMessage), findsOneWidget);
      expect(find.text(AppConstants.requestPermissionButton), findsOneWidget);
    });

    testWidgets('should navigate between bottom navigation tabs', (WidgetTester tester) async {
      // Arrange
      IntegrationTestHelpers.setupMockPhotoPermission(true);
      IntegrationTestHelpers.setupMockTodayPhotos([]);

      // Act
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Test navigation to each tab
      final tabs = [
        Icons.book,
        Icons.analytics,
        Icons.settings,
        Icons.home,
      ];

      for (final tabIcon in tabs) {
        final tab = find.byIcon(tabIcon);
        expect(tab, findsOneWidget);
        
        await tester.tap(tab);
        await tester.pump(const Duration(milliseconds: 300));
        
        // Should remain stable
        expect(find.byType(BottomNavigationBar), findsOneWidget);
      }

      // Assert
      expect(tester.takeException(), isNull);
    });
  });
}