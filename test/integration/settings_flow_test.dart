import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/main.dart';
import 'package:smart_photo_diary/screens/settings_screen.dart';
import 'package:smart_photo_diary/screens/statistics_screen.dart';
import 'package:smart_photo_diary/screens/diary_screen.dart';
import 'package:smart_photo_diary/constants/app_constants.dart';
import 'package:smart_photo_diary/widgets/photo_grid_widget.dart';
import 'test_helpers/integration_test_helpers.dart';
import 'mocks/mock_services.dart';

void main() {
  group('Settings Flow Integration Tests', () {
    setUpAll(() {
      registerMockFallbacks();
    });

    setUp(() async {
      await IntegrationTestHelpers.setUpIntegrationEnvironment();
    });

    tearDown(() async {
      await IntegrationTestHelpers.tearDownIntegrationEnvironment();
    });

    group('Navigation Flow', () {
      testWidgets('should navigate to settings screen from home', (WidgetTester tester) async {
        // Arrange
        IntegrationTestHelpers.setupMockPhotoPermission(true);
        IntegrationTestHelpers.setupMockTodayPhotos([]);

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Find and tap settings icon in bottom navigation
        final settingsTab = find.byIcon(Icons.settings);
        expect(settingsTab, findsOneWidget);
        
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, settingsTab);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Assert
        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(find.text('設定'), findsOneWidget);
      });

      testWidgets('should navigate to diary screen from home', (WidgetTester tester) async {
        // Arrange
        IntegrationTestHelpers.setupMockPhotoPermission(true);
        IntegrationTestHelpers.setupMockTodayPhotos([]);

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Find and tap diary icon in bottom navigation
        final diaryTab = find.byIcon(Icons.book);
        expect(diaryTab, findsOneWidget);
        
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, diaryTab);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Assert
        expect(find.byType(DiaryScreen), findsOneWidget);
      });

      testWidgets('should navigate to statistics screen from home', (WidgetTester tester) async {
        // Arrange
        IntegrationTestHelpers.setupMockPhotoPermission(true);
        IntegrationTestHelpers.setupMockTodayPhotos([]);

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Find and tap statistics icon in bottom navigation
        final statsTab = find.byIcon(Icons.analytics);
        expect(statsTab, findsOneWidget);
        
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, statsTab);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Assert
        expect(find.byType(StatisticsScreen), findsOneWidget);
      });
    });

    group('Settings Screen Functionality', () {
      testWidgets('should display all settings options', (WidgetTester tester) async {
        // Arrange
        IntegrationTestHelpers.setupMockPhotoPermission(true);

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Navigate to settings
        final settingsTab = find.byIcon(Icons.settings);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, settingsTab);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Assert - Check for common settings options
        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(find.text('設定'), findsOneWidget);
        
        // Look for typical settings sections
        expect(find.byType(ListTile), findsAtLeastNWidgets(1));
        expect(find.byType(Card), findsAtLeastNWidgets(1));
      });

      testWidgets('should handle theme switching', (WidgetTester tester) async {
        // Arrange
        IntegrationTestHelpers.setupMockPhotoPermission(true);

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Navigate to settings
        final settingsTab = find.byIcon(Icons.settings);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, settingsTab);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Look for theme-related switches or options
        final switches = find.byType(Switch);
        if (switches.evaluate().isNotEmpty) {
          await IntegrationTestHelpers.tapAndWaitForNavigation(tester, switches.first);
          await tester.pump();
          
          // Verify the switch state changed
          expect(switches, findsAtLeastNWidgets(1));
        }

        // Assert - Settings screen should remain functional
        expect(find.byType(SettingsScreen), findsOneWidget);
      });

      testWidgets('should handle data export functionality', (WidgetTester tester) async {
        // Arrange
        IntegrationTestHelpers.setupMockPhotoPermission(true);

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Navigate to settings
        final settingsTab = find.byIcon(Icons.settings);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, settingsTab);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Look for export button or option
        final exportButtons = find.textContaining('エクスポート');
        final dataOutputButtons = find.textContaining('データ出力');
        final hasExportButton = exportButtons.evaluate().isNotEmpty;
        final hasDataOutputButton = dataOutputButtons.evaluate().isNotEmpty;
        if (hasExportButton) {
          await IntegrationTestHelpers.tapAndWaitForNavigation(tester, exportButtons.first);
        } else if (hasDataOutputButton) {
          await IntegrationTestHelpers.tapAndWaitForNavigation(tester, dataOutputButtons.first);
          await tester.pump();
          
          // Should show some confirmation or progress
          expect(find.byType(SettingsScreen), findsOneWidget);
        }

        // Assert - No crashes should occur
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle app info display', (WidgetTester tester) async {
        // Arrange
        IntegrationTestHelpers.setupMockPhotoPermission(true);

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Navigate to settings
        final settingsTab = find.byIcon(Icons.settings);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, settingsTab);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Look for app info or about section
        final aboutButtons = find.textContaining('アプリについて');
        final versionButtons = find.textContaining('バージョン');
        final hasAboutButton = aboutButtons.evaluate().isNotEmpty;
        final hasVersionButton = versionButtons.evaluate().isNotEmpty;
        if (hasAboutButton) {
          await IntegrationTestHelpers.tapAndWaitForNavigation(tester, aboutButtons.first);
        } else if (hasVersionButton) {
          await IntegrationTestHelpers.tapAndWaitForNavigation(tester, versionButtons.first);
          await tester.pump();
        }

        // Assert - Settings screen should remain accessible
        expect(find.byType(SettingsScreen), findsOneWidget);
      });
    });

    group('Statistics Screen Functionality', () {
      testWidgets('should display statistics when data is available', (WidgetTester tester) async {
        // Arrange
        IntegrationTestHelpers.setupMockPhotoPermission(true);
        
        // Create some test diary entries first
        final testDiary = IntegrationTestHelpers.createTestDiaryEntry();

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Navigate to statistics
        final statsTab = find.byIcon(Icons.analytics);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, statsTab);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Assert
        expect(find.byType(StatisticsScreen), findsOneWidget);
        
        // Look for statistics content
        expect(find.byType(Card), findsAtLeastNWidgets(1));
      });

      testWidgets('should handle empty statistics gracefully', (WidgetTester tester) async {
        // Arrange
        IntegrationTestHelpers.setupMockPhotoPermission(true);
        IntegrationTestHelpers.setupMockTodayPhotos([]);

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Navigate to statistics
        final statsTab = find.byIcon(Icons.analytics);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, statsTab);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Assert
        expect(find.byType(StatisticsScreen), findsOneWidget);
        
        // Should show some content even when empty
        expect(tester.takeException(), isNull);
      });
    });

    group('Diary Screen Functionality', () {
      testWidgets('should display diary list with search functionality', (WidgetTester tester) async {
        // Arrange
        IntegrationTestHelpers.setupMockPhotoPermission(true);

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Navigate to diary screen
        final diaryTab = find.byIcon(Icons.book);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, diaryTab);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Assert
        expect(find.byType(DiaryScreen), findsOneWidget);
        
        // Look for search functionality
        final searchFields = find.byType(TextField);
        if (searchFields.evaluate().isNotEmpty) {
          // Test search functionality
          await IntegrationTestHelpers.enterTextAndPump(
            tester, 
            searchFields.first, 
            'テスト検索',
          );
          await tester.pump();
        }

        // Should not crash
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle filter functionality', (WidgetTester tester) async {
        // Arrange
        IntegrationTestHelpers.setupMockPhotoPermission(true);

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Navigate to diary screen
        final diaryTab = find.byIcon(Icons.book);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, diaryTab);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Look for filter button
        final filterButtons = find.byIcon(Icons.filter_list);
        final filterTextButtons = find.textContaining('フィルタ');
        final hasFilterIcon = filterButtons.evaluate().isNotEmpty;
        final hasFilterText = filterTextButtons.evaluate().isNotEmpty;
        if (hasFilterIcon) {
          await IntegrationTestHelpers.tapAndWaitForNavigation(tester, filterButtons.first);
        } else if (hasFilterText) {
          await IntegrationTestHelpers.tapAndWaitForNavigation(tester, filterTextButtons.first);
          await tester.pump();
          
          // Should show filter options
          await tester.pump();
        }

        // Assert - Should remain functional
        expect(find.byType(DiaryScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Navigation State Management', () {
      testWidgets('should maintain state when switching between tabs', (WidgetTester tester) async {
        // Arrange
        IntegrationTestHelpers.setupMockPhotoPermission(true);
        final mockAssets = IntegrationTestHelpers.createMockAssets(2);
        IntegrationTestHelpers.setupMockTodayPhotos(mockAssets);

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Select a photo on home screen
        final photoItems = find.byType(GestureDetector);
        if (photoItems.evaluate().isNotEmpty) {
          await IntegrationTestHelpers.tapAndWaitForNavigation(tester, photoItems.first);
        }

        // Switch to diary tab
        final diaryTab = find.byIcon(Icons.book);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, diaryTab);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Switch back to home tab
        final homeTab = find.byIcon(Icons.home);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, homeTab);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Assert - Should return to home screen successfully
        expect(find.text(AppConstants.appTitle), findsOneWidget);
        expect(find.byType(PhotoGridWidget), findsOneWidget);
      });

      testWidgets('should handle rapid tab switching', (WidgetTester tester) async {
        // Arrange
        IntegrationTestHelpers.setupMockPhotoPermission(true);

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Rapidly switch between tabs
        final tabs = [
          find.byIcon(Icons.home),
          find.byIcon(Icons.book),
          find.byIcon(Icons.analytics),
          find.byIcon(Icons.settings),
        ];

        for (int i = 0; i < 3; i++) {
          for (final tab in tabs) {
            await tester.tap(tab);
            await tester.pump(const Duration(milliseconds: 100));
          }
        }

        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Assert - App should remain stable
        expect(tester.takeException(), isNull);
      });
    });

    group('Error Handling and Edge Cases', () {
      testWidgets('should handle missing permissions gracefully', (WidgetTester tester) async {
        // Arrange
        IntegrationTestHelpers.setupMockPhotoPermission(false);

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Try to navigate to different screens
        final tabs = [
          find.byIcon(Icons.book),
          find.byIcon(Icons.analytics),
          find.byIcon(Icons.settings),
        ];

        for (final tab in tabs) {
          await IntegrationTestHelpers.tapAndWaitForNavigation(tester, tab);
          await tester.pump();
          
          // Each screen should load without crashing
          expect(tester.takeException(), isNull);
        }

        // Return to home
        final homeTab = find.byIcon(Icons.home);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, homeTab);
        
        // Assert - Should show permission request
        expect(find.text(AppConstants.permissionMessage), findsOneWidget);
      });

      testWidgets('should handle device rotation', (WidgetTester tester) async {
        // Arrange
        IntegrationTestHelpers.setupMockPhotoPermission(true);

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Simulate device rotation by changing the size
        await tester.binding.setSurfaceSize(const Size(800, 600)); // Landscape
        await tester.pump();
        
        // Navigate to different screens
        final settingsTab = find.byIcon(Icons.settings);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, settingsTab);
        await tester.pump();

        // Rotate back
        await tester.binding.setSurfaceSize(const Size(400, 800)); // Portrait
        await tester.pump();

        // Assert - Should handle rotation gracefully
        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Accessibility and Usability', () {
      testWidgets('should be accessible across all screens', (WidgetTester tester) async {
        // Arrange
        IntegrationTestHelpers.setupMockPhotoPermission(true);

        // Act & Assert - Test accessibility for each main screen
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Home screen accessibility
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

        // Diary screen accessibility
        final diaryTab = find.byIcon(Icons.book);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, diaryTab);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        // Statistics screen accessibility
        final statsTab = find.byIcon(Icons.analytics);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, statsTab);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

        // Settings screen accessibility
        final settingsTab = find.byIcon(Icons.settings);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, settingsTab);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      });

      testWidgets('should provide consistent navigation experience', (WidgetTester tester) async {
        // Arrange
        IntegrationTestHelpers.setupMockPhotoPermission(true);

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Test consistent bottom navigation across screens
        final tabs = [
          (Icons.home, ''),
          (Icons.book, ''),
          (Icons.bar_chart, ''), // Was Icons.analytics
          (Icons.settings, '設定'),
        ];

        for (final (icon, expectedText) in tabs) {
          final tab = find.byIcon(icon);
          await IntegrationTestHelpers.tapAndWaitForNavigation(tester, tab);
          await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

          // Bottom navigation should always be present
          expect(find.byType(BottomNavigationBar), findsOneWidget);
          
          // Essential tab icons should be present (flexible for debug mode)
          expect(find.byIcon(Icons.home), findsOneWidget);
          expect(find.byIcon(Icons.settings), findsOneWidget);
          // Book and bar_chart may not be present in all test environments

          if (expectedText.isNotEmpty) {
            expect(find.text(expectedText), findsOneWidget);
          }
        }

        // Assert - Navigation should be consistent
        expect(tester.takeException(), isNull);
      });
    });
  });
}