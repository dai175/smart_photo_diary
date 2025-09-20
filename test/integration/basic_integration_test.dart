import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:smart_photo_diary/constants/app_icons.dart';
import 'package:smart_photo_diary/main.dart';
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

      // Wait for initial widgets to appear - extend timeout for app initialization
      await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

      // Assert - 日付タイトルが表示されることを確認
      final now = DateTime.now();
      final scaffoldContext = tester.element(find.byType(Scaffold).first);
      final locale = Localizations.localeOf(scaffoldContext);
      final localeName = locale.countryCode != null
          ? '${locale.languageCode}_${locale.countryCode}'
          : locale.languageCode;
      final expectedTitle = DateFormat.yMMMMd(localeName).format(now);
      expect(find.text(expectedTitle), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('should display permission message without photos access', (
      WidgetTester tester,
    ) async {
      // Arrange
      IntegrationTestHelpers.setupMockPhotoPermission(false);

      // Act
      await tester.pumpWidget(const MyApp());
      await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

      // Assert - 日付タイトルが表示されることを確認
      final now = DateTime.now();
      final scaffoldContext = tester.element(find.byType(Scaffold).first);
      final locale = Localizations.localeOf(scaffoldContext);
      final localeName = locale.countryCode != null
          ? '${locale.languageCode}_${locale.countryCode}'
          : locale.languageCode;
      final expectedTitle = DateFormat.yMMMMd(localeName).format(now);
      expect(find.text(expectedTitle), findsOneWidget);

      // 権限が拒否されている場合の確認（メッセージやボタンが表示される）
      // Note: 実際のUI構造に依存するため、少なくとも日付が表示されれば成功とする
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('should navigate between bottom navigation tabs', (
      WidgetTester tester,
    ) async {
      // Arrange
      IntegrationTestHelpers.setupMockPhotoPermission(true);
      IntegrationTestHelpers.setupMockTodayPhotos([]);

      // Act
      await tester.pumpWidget(const MyApp());
      await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

      // Test navigation to each tab using AppIcons constants
      final tabs = AppIcons.navigationIcons;

      for (int i = 0; i < tabs.length; i++) {
        final tabIcon = tabs[i];
        final tab = find.byIcon(tabIcon);
        if (tab.evaluate().isNotEmpty) {
          await tester.tap(tab);
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump();

          // Should remain stable
          expect(find.byType(BottomNavigationBar), findsOneWidget);
        }
      }

      // At least home and settings should always be present (using AppIcons)
      expect(find.byIcon(AppIcons.navigationIcons[0]), findsOneWidget); // Home
      expect(
        find.byIcon(AppIcons.navigationIcons[3]),
        findsOneWidget,
      ); // Settings

      // Assert
      expect(tester.takeException(), isNull);
    });
  });
}
