import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/main.dart';
import 'package:smart_photo_diary/screens/diary_preview_screen.dart';
import 'package:smart_photo_diary/screens/diary_detail_screen.dart';
import 'package:smart_photo_diary/widgets/photo_grid_widget.dart';
import 'package:smart_photo_diary/constants/app_constants.dart';
import 'test_helpers/integration_test_helpers.dart';
import 'mocks/mock_services.dart';

void main() {
  group('Diary Flow Integration Tests', () {
    setUpAll(() {
      registerMockFallbacks();
    });

    setUp(() async {
      await IntegrationTestHelpers.setUpIntegrationEnvironment();
    });

    tearDown(() async {
      await IntegrationTestHelpers.tearDownIntegrationEnvironment();
    });

    group('Photo Selection to Diary Creation Flow', () {
      testWidgets('should complete full diary creation flow with photos', (WidgetTester tester) async {
        // Arrange
        final mockAssets = IntegrationTestHelpers.createMockAssets(3);
        IntegrationTestHelpers.setupMockTodayPhotos(mockAssets);
        IntegrationTestHelpers.setupMockPhotoPermission(true);

        // Act & Assert - Step 1: App launches successfully
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Verify home screen loads
        expect(find.text(AppConstants.appTitle), findsOneWidget);
        expect(find.byType(PhotoGridWidget), findsOneWidget);

        // Step 2: Photos should be loaded and displayed
        await IntegrationTestHelpers.waitForWidget(tester, find.byType(PhotoGridWidget));
        
        // Verify photos are displayed
        expect(find.text('3'), findsOneWidget); // Photo count
        
        // Step 3: Select photos
        final photoItems = find.byType(GestureDetector);
        expect(photoItems, findsAtLeastNWidgets(3));
        
        // Select first two photos
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, photoItems.at(0));
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, photoItems.at(1));

        // Verify selection count updates
        expect(find.textContaining('2枚の写真で日記を作成'), findsOneWidget);

        // Step 4: Tap create diary button
        final createButton = find.byType(ElevatedButton);
        expect(createButton, findsOneWidget);
        
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, createButton);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Step 5: Should navigate to diary preview screen
        expect(find.byType(DiaryPreviewScreen), findsOneWidget);

        // Verify preview content
        expect(find.textContaining('テスト日記のタイトル'), findsOneWidget);
        expect(find.textContaining('これはテスト用に生成された'), findsOneWidget);

        // Step 6: Save the diary
        final saveButton = find.text('保存');
        expect(saveButton, findsOneWidget);
        
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, saveButton);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Step 7: Should return to home screen and show success
        expect(find.text(AppConstants.appTitle), findsOneWidget);
        
        // Verify diary appears in recent diaries
        expect(find.textContaining('テスト日記のタイトル'), findsOneWidget);
      });

      testWidgets('should handle photo selection without permission', (WidgetTester tester) async {
        // Arrange
        IntegrationTestHelpers.setupMockPhotoPermission(false);

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Assert
        expect(find.text(AppConstants.appTitle), findsOneWidget);
        expect(find.byIcon(Icons.no_photography), findsOneWidget);
        expect(find.text(AppConstants.permissionMessage), findsOneWidget);
        expect(find.text(AppConstants.requestPermissionButton), findsOneWidget);

        // Test permission request
        await IntegrationTestHelpers.tapAndWaitForNavigation(
          tester, 
          find.text(AppConstants.requestPermissionButton),
        );
        
        // Permission dialog should appear or permission should be requested
        await tester.pump();
      });

      testWidgets('should handle empty photo selection', (WidgetTester tester) async {
        // Arrange
        IntegrationTestHelpers.setupMockTodayPhotos([]);
        IntegrationTestHelpers.setupMockPhotoPermission(true);

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Assert
        expect(find.text(AppConstants.noPhotosMessage), findsOneWidget);
        
        // Create diary button should be disabled
        final createButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(createButton.onPressed, isNull);
      });

      testWidgets('should enforce photo selection limit', (WidgetTester tester) async {
        // Arrange
        final mockAssets = IntegrationTestHelpers.createMockAssets(AppConstants.maxPhotosSelection + 2);
        IntegrationTestHelpers.setupMockTodayPhotos(mockAssets);
        IntegrationTestHelpers.setupMockPhotoPermission(true);

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Select maximum number of photos
        final photoItems = find.byType(GestureDetector);
        
        for (int i = 0; i < AppConstants.maxPhotosSelection; i++) {
          await IntegrationTestHelpers.tapAndWaitForNavigation(tester, photoItems.at(i));
        }

        // Verify selection count
        expect(find.textContaining('${AppConstants.maxPhotosSelection}枚の写真で日記を作成'), findsOneWidget);

        // Try to select one more photo - should be prevented
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, photoItems.at(AppConstants.maxPhotosSelection));
        
        // Count should not exceed maximum
        expect(find.textContaining('${AppConstants.maxPhotosSelection + 1}枚'), findsNothing);
      });
    });

    group('Diary Detail Flow', () {
      testWidgets('should navigate to diary detail and display content', (WidgetTester tester) async {
        // Arrange
        final mockAssets = IntegrationTestHelpers.createMockAssets(2);
        IntegrationTestHelpers.setupMockTodayPhotos(mockAssets);
        IntegrationTestHelpers.setupMockPhotoPermission(true);

        // Create and save a diary first
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Select photos and create diary
        final photoItems = find.byType(GestureDetector);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, photoItems.at(0));
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, photoItems.at(1));

        final createButton = find.byType(ElevatedButton);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, createButton);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        final saveButton = find.text('保存');
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, saveButton);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Act - Tap on the created diary in recent diaries
        final diaryCard = find.textContaining('テスト日記のタイトル');
        expect(diaryCard, findsOneWidget);
        
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, diaryCard);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Assert - Should navigate to diary detail screen
        expect(find.byType(DiaryDetailScreen), findsOneWidget);
        expect(find.textContaining('テスト日記のタイトル'), findsOneWidget);
        expect(find.textContaining('これはテスト用に生成された'), findsOneWidget);
      });
    });

    group('Error Handling Flow', () {
      testWidgets('should handle AI service errors gracefully', (WidgetTester tester) async {
        // Arrange
        final mockAssets = IntegrationTestHelpers.createMockAssets(2);
        IntegrationTestHelpers.setupMockTodayPhotos(mockAssets);
        IntegrationTestHelpers.setupMockPhotoPermission(true);

        // Setup AI service to throw error
        when(() => IntegrationTestHelpers.mockAiService.generateDiaryFromLabels(
          labels: any(named: 'labels'),
          date: any(named: 'date'),
          location: any(named: 'location'),
          photoTimes: any(named: 'photoTimes'),
          photoTimeLabels: any(named: 'photoTimeLabels'),
        )).thenThrow(Exception('AI service error'));

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Select photos and try to create diary
        final photoItems = find.byType(GestureDetector);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, photoItems.at(0));

        final createButton = find.byType(ElevatedButton);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, createButton);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Assert - Should show error handling or fallback content
        // (The actual behavior depends on how error handling is implemented)
        expect(find.byType(DiaryPreviewScreen), findsOneWidget);
      });

      testWidgets('should handle network connectivity issues', (WidgetTester tester) async {
        // Arrange
        final mockAssets = IntegrationTestHelpers.createMockAssets(1);
        IntegrationTestHelpers.setupMockTodayPhotos(mockAssets);
        IntegrationTestHelpers.setupMockPhotoPermission(true);

        // Setup AI service to simulate network error
        when(() => IntegrationTestHelpers.mockAiService.generateDiaryFromLabels(
          labels: any(named: 'labels'),
          date: any(named: 'date'),
          location: any(named: 'location'),
          photoTimes: any(named: 'photoTimes'),
          photoTimeLabels: any(named: 'photoTimeLabels'),
        )).thenThrow(Exception('Network error'));

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Select photo and create diary
        final photoItems = find.byType(GestureDetector);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, photoItems.at(0));

        final createButton = find.byType(ElevatedButton);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, createButton);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Assert - Should handle network error gracefully
        expect(find.byType(DiaryPreviewScreen), findsOneWidget);
      });
    });

    group('Performance and Stability', () {
      testWidgets('should handle rapid user interactions', (WidgetTester tester) async {
        // Arrange
        final mockAssets = IntegrationTestHelpers.createMockAssets(5);
        IntegrationTestHelpers.setupMockTodayPhotos(mockAssets);
        IntegrationTestHelpers.setupMockPhotoPermission(true);

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Rapid photo selection/deselection
        final photoItems = find.byType(GestureDetector);
        
        for (int i = 0; i < 5; i++) {
          await tester.tap(photoItems.at(0));
          await tester.pump(const Duration(milliseconds: 50));
          await tester.tap(photoItems.at(1));
          await tester.pump(const Duration(milliseconds: 50));
        }

        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Assert - App should remain stable
        expect(find.text(AppConstants.appTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle multiple diary creation attempts', (WidgetTester tester) async {
        // Arrange
        final mockAssets = IntegrationTestHelpers.createMockAssets(3);
        IntegrationTestHelpers.setupMockTodayPhotos(mockAssets);
        IntegrationTestHelpers.setupMockPhotoPermission(true);

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Create multiple diaries
        for (int i = 0; i < 3; i++) {
          // Select photos
          final photoItems = find.byType(GestureDetector);
          await IntegrationTestHelpers.tapAndWaitForNavigation(tester, photoItems.at(i));

          // Create diary
          final createButton = find.byType(ElevatedButton);
          await IntegrationTestHelpers.tapAndWaitForNavigation(tester, createButton);
          await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

          // Save diary
          final saveButton = find.text('保存');
          await IntegrationTestHelpers.tapAndWaitForNavigation(tester, saveButton);
          await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

          // Should return to home screen
          expect(find.text(AppConstants.appTitle), findsOneWidget);
        }

        // Assert - Multiple diaries should be created
        expect(find.textContaining('テスト日記のタイトル'), findsAtLeastNWidgets(1));
      });
    });

    group('Accessibility Integration', () {
      testWidgets('should be fully accessible throughout diary creation flow', (WidgetTester tester) async {
        // Arrange
        final mockAssets = IntegrationTestHelpers.createMockAssets(2);
        IntegrationTestHelpers.setupMockTodayPhotos(mockAssets);
        IntegrationTestHelpers.setupMockPhotoPermission(true);

        // Act
        await tester.pumpWidget(const MyApp());
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Test accessibility at each step
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

        // Select photo and navigate to preview
        final photoItems = find.byType(GestureDetector);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, photoItems.at(0));

        final createButton = find.byType(ElevatedButton);
        await IntegrationTestHelpers.tapAndWaitForNavigation(tester, createButton);
        await IntegrationTestHelpers.pumpAndSettleWithExtendedTimeout(tester);

        // Test accessibility in preview screen
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        // Assert - All screens should be accessible
        expect(find.byType(DiaryPreviewScreen), findsOneWidget);
      });
    });
  });
}