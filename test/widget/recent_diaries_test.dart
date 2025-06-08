import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/widgets/recent_diaries_widget.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/constants/app_constants.dart';
import '../test_helpers/widget_test_helpers.dart';

void main() {
  group('RecentDiariesWidget', () {
    late List<DiaryEntry> testDiaries;

    setUpAll(() async {
      await WidgetTestHelpers.setUpTestEnvironment();
    });

    tearDownAll(() async {
      await WidgetTestHelpers.tearDownTestEnvironment();
    });

    setUp(() {
      testDiaries = WidgetTestHelpers.createTestDiaryEntries(3);
    });
    
    // Helper function to create constrained widget for testing
    Widget createConstrainedRecentDiariesWidget({
      required List<DiaryEntry> recentDiaries,
      required bool isLoading,
      required Function(String) onDiaryTap,
      double height = 500,
    }) {
      return WidgetTestHelpers.wrapWithMaterialApp(
        SizedBox(
          height: height,
          child: SingleChildScrollView(
            child: RecentDiariesWidget(
              recentDiaries: recentDiaries,
              isLoading: isLoading,
              onDiaryTap: onDiaryTap,
            ),
          ),
        ),
      );
    }

    group('Basic Rendering', () {
      testWidgets('should render recent diaries widget', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(
          createConstrainedRecentDiariesWidget(
            recentDiaries: testDiaries,
            isLoading: false,
            onDiaryTap: (id) {},
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.byType(RecentDiariesWidget), findsOneWidget);
        expect(find.byType(Column), findsAtLeastNWidgets(1));
      });

      testWidgets('should display header', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: testDiaries,
              isLoading: false,
              onDiaryTap: (id) {},
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        WidgetTestHelpers.expectTextExists(AppConstants.recentDiariesTitle);
      });

      testWidgets('should display diary cards for each diary', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: testDiaries,
              isLoading: false,
              onDiaryTap: (id) {},
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.byType(GestureDetector), findsNWidgets(3));
        expect(find.byType(Container), findsAtLeastNWidgets(3)); // Cards
      });
    });

    group('Loading State', () {
      testWidgets('should show loading indicator when loading', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: [],
              isLoading: true,
              onDiaryTap: (id) {},
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(GestureDetector), findsNothing);
      });

      testWidgets('should not show diary cards when loading', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: testDiaries,
              isLoading: true,
              onDiaryTap: (id) {},
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(GestureDetector), findsNothing);
      });
    });

    group('Empty State', () {
      testWidgets('should show empty message when no diaries', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: [],
              isLoading: false,
              onDiaryTap: (id) {},
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        WidgetTestHelpers.expectTextExists(AppConstants.noDiariesMessage);
        expect(find.byType(GestureDetector), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('Diary Card Content', () {
      testWidgets('should display diary date', (WidgetTester tester) async {
        // Arrange
        final diary = WidgetTestHelpers.createTestDiaryEntry(
          date: DateTime(2024, 1, 15),
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: [diary],
              isLoading: false,
              onDiaryTap: (id) {},
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.textContaining('2024年01月15日'), findsOneWidget);
      });

      testWidgets('should display diary title', (WidgetTester tester) async {
        // Arrange
        final diary = WidgetTestHelpers.createTestDiaryEntry(
          title: 'Beautiful Day',
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: [diary],
              isLoading: false,
              onDiaryTap: (id) {},
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        WidgetTestHelpers.expectTextExists('Beautiful Day');
      });

      testWidgets('should display "無題" for empty title', (WidgetTester tester) async {
        // Arrange
        final diary = WidgetTestHelpers.createTestDiaryEntry(
          title: '',
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: [diary],
              isLoading: false,
              onDiaryTap: (id) {},
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        WidgetTestHelpers.expectTextExists('無題');
      });

      testWidgets('should display diary content', (WidgetTester tester) async {
        // Arrange
        final diary = WidgetTestHelpers.createTestDiaryEntry(
          content: 'This is a beautiful day at the park.',
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: [diary],
              isLoading: false,
              onDiaryTap: (id) {},
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.textContaining('This is a beautiful day'), findsOneWidget);
      });

      testWidgets('should truncate long content', (WidgetTester tester) async {
        // Arrange
        final diary = WidgetTestHelpers.createTestDiaryEntry(
          content: 'This is a very long content that should be truncated when displayed in the recent diaries widget because it exceeds the maximum lines allowed for preview.',
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: [diary],
              isLoading: false,
              onDiaryTap: (id) {},
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        final textWidget = tester.widget<Text>(
          find.textContaining('This is a very long content').first,
        );
        expect(textWidget.maxLines, equals(2));
        expect(textWidget.overflow, equals(TextOverflow.ellipsis));
      });

      testWidgets('should truncate long title', (WidgetTester tester) async {
        // Arrange
        final diary = WidgetTestHelpers.createTestDiaryEntry(
          title: 'This is a very long title that should be truncated when displayed',
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: [diary],
              isLoading: false,
              onDiaryTap: (id) {},
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        final titleWidgets = tester.widgetList<Text>(
          find.textContaining('This is a very long title'),
        );
        final titleWidget = titleWidgets.firstWhere(
          (widget) => widget.maxLines == 1,
        );
        expect(titleWidget.maxLines, equals(1));
        expect(titleWidget.overflow, equals(TextOverflow.ellipsis));
      });
    });

    group('Interaction', () {
      testWidgets('should call onDiaryTap when diary card is tapped', (WidgetTester tester) async {
        // Arrange
        String? tappedId;
        final diary = WidgetTestHelpers.createTestDiaryEntry(
          id: 'test-diary-id',
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: [diary],
              isLoading: false,
              onDiaryTap: (id) {
                tappedId = id;
              },
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        await WidgetTestHelpers.tapAndPump(tester, find.byType(GestureDetector));

        // Assert
        expect(tappedId, equals('test-diary-id'));
      });

      testWidgets('should handle multiple diary taps', (WidgetTester tester) async {
        // Arrange
        final tappedIds = <String>[];
        final diaries = [
          WidgetTestHelpers.createTestDiaryEntry(id: 'diary-1'),
          WidgetTestHelpers.createTestDiaryEntry(id: 'diary-2'),
          WidgetTestHelpers.createTestDiaryEntry(id: 'diary-3'),
        ];

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: diaries,
              isLoading: false,
              onDiaryTap: (id) {
                tappedIds.add(id);
              },
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Tap all diary cards
        final gestureDetectors = find.byType(GestureDetector);
        for (int i = 0; i < gestureDetectors.evaluate().length; i++) {
          await WidgetTestHelpers.tapAndPump(tester, gestureDetectors.at(i));
        }

        // Assert
        expect(tappedIds.length, equals(3));
        expect(tappedIds, containsAll(['diary-1', 'diary-2', 'diary-3']));
      });
    });

    group('Theming', () {
      testWidgets('should apply light theme correctly', (WidgetTester tester) async {
        // Arrange
        final lightTheme = WidgetTestHelpers.createTestTheme(brightness: Brightness.light);
        final diary = WidgetTestHelpers.createTestDiaryEntry();

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: [diary],
              isLoading: false,
              onDiaryTap: (id) {},
            ),
            theme: lightTheme,
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.byType(RecentDiariesWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should apply dark theme correctly', (WidgetTester tester) async {
        // Arrange
        final darkTheme = WidgetTestHelpers.createTestTheme(brightness: Brightness.dark);
        final diary = WidgetTestHelpers.createTestDiaryEntry();

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: [diary],
              isLoading: false,
              onDiaryTap: (id) {},
            ),
            theme: darkTheme,
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.byType(RecentDiariesWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should use theme colors for text', (WidgetTester tester) async {
        // Arrange
        final diary = WidgetTestHelpers.createTestDiaryEntry(
          title: 'Test Title',
          content: 'Test Content',
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: [diary],
              isLoading: false,
              onDiaryTap: (id) {},
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        final titleWidget = tester.widget<Text>(find.text('Test Title'));
        final contentWidget = tester.widget<Text>(find.text('Test Content'));
        
        expect(titleWidget.style?.color, isNotNull);
        expect(contentWidget.style?.color, isNotNull);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle empty content gracefully', (WidgetTester tester) async {
        // Arrange
        final diary = WidgetTestHelpers.createTestDiaryEntry(
          content: '',
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: [diary],
              isLoading: false,
              onDiaryTap: (id) {},
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.byType(RecentDiariesWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle very old dates', (WidgetTester tester) async {
        // Arrange
        final diary = WidgetTestHelpers.createTestDiaryEntry(
          date: DateTime(1990, 1, 1),
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: [diary],
              isLoading: false,
              onDiaryTap: (id) {},
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.textContaining('1990年01月01日'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle future dates', (WidgetTester tester) async {
        // Arrange
        final diary = WidgetTestHelpers.createTestDiaryEntry(
          date: DateTime(2030, 12, 31),
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: [diary],
              isLoading: false,
              onDiaryTap: (id) {},
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.textContaining('2030年12月31日'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle null callback gracefully', (WidgetTester tester) async {
        // Arrange
        final diary = WidgetTestHelpers.createTestDiaryEntry();

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: [diary],
              isLoading: false,
              onDiaryTap: (id) {}, // Empty callback
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Tap diary card
        await WidgetTestHelpers.tapAndPump(tester, find.byType(GestureDetector));

        // Assert - Should not throw
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle large number of diaries', (WidgetTester tester) async {
        // Arrange
        final largeDiaryList = WidgetTestHelpers.createTestDiaryEntries(50);

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            SingleChildScrollView(
              child: RecentDiariesWidget(
                recentDiaries: largeDiaryList,
                isLoading: false,
                onDiaryTap: (id) {},
              ),
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.byType(GestureDetector), findsNWidgets(50));
        expect(tester.takeException(), isNull);
      });
    });

    group('Responsive Design', () {
      testWidgets('should adapt to different screen sizes', (WidgetTester tester) async {
        // Arrange
        final diary = WidgetTestHelpers.createTestDiaryEntry();

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMediaQuery(
            WidgetTestHelpers.wrapWithMaterialApp(
              RecentDiariesWidget(
                recentDiaries: [diary],
                isLoading: false,
                onDiaryTap: (id) {},
              ),
            ),
            size: const Size(300, 600), // Narrow screen
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.byType(RecentDiariesWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle card layout properly', (WidgetTester tester) async {
        // Arrange
        final diary = WidgetTestHelpers.createTestDiaryEntry();

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: [diary],
              isLoading: false,
              onDiaryTap: (id) {},
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        final containers = tester.widgetList<Container>(find.byType(Container));
        final cardContainers = containers.where((container) => 
          container.decoration != null && 
          container.margin != null).toList();
        expect(cardContainers.length, greaterThan(0));
      });
    });

    group('Accessibility', () {
      testWidgets('should be accessible', (WidgetTester tester) async {
        // Arrange
        final diary = WidgetTestHelpers.createTestDiaryEntry();

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: [diary],
              isLoading: false,
              onDiaryTap: (id) {},
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        await WidgetTestHelpers.testAccessibility(tester);
      });

      testWidgets('should have semantic information for diary cards', (WidgetTester tester) async {
        // Arrange
        final diary = WidgetTestHelpers.createTestDiaryEntry(
          title: 'Accessible Diary',
        );

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: [diary],
              isLoading: false,
              onDiaryTap: (id) {},
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        final gestureDetector = find.byType(GestureDetector);
        expect(gestureDetector, findsOneWidget);
      });
    });

    group('Performance', () {
      testWidgets('should render efficiently', (WidgetTester tester) async {
        // Arrange
        final diaries = WidgetTestHelpers.createTestDiaryEntries(10);
        final stopwatch = Stopwatch()..start();

        // Act
        await tester.pumpWidget(
          createConstrainedRecentDiariesWidget(
            recentDiaries: diaries,
            isLoading: false,
            onDiaryTap: (id) {},
            height: 800, // Larger height for 10 items
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should render within 1 second
        expect(find.byType(GestureDetector), findsNWidgets(10));
      });

      testWidgets('should handle rapid state changes', (WidgetTester tester) async {
        // Arrange
        final diaries = WidgetTestHelpers.createTestDiaryEntries(5);

        // Act - Start with loading
        await tester.pumpWidget(
          createConstrainedRecentDiariesWidget(
            recentDiaries: [],
            isLoading: true,
            onDiaryTap: (id) {},
          ),
        );
        await tester.pump();

        // Change to loaded state
        await tester.pumpWidget(
          createConstrainedRecentDiariesWidget(
            recentDiaries: diaries,
            isLoading: false,
            onDiaryTap: (id) {},
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert - Should handle state change gracefully
        expect(find.byType(GestureDetector), findsNWidgets(5));
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle rapid taps efficiently', (WidgetTester tester) async {
        // Arrange
        int tapCount = 0;
        final diary = WidgetTestHelpers.createTestDiaryEntry();

        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            RecentDiariesWidget(
              recentDiaries: [diary],
              isLoading: false,
              onDiaryTap: (id) {
                tapCount++;
              },
            ),
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Rapid tapping
        for (int i = 0; i < 5; i++) {
          await WidgetTestHelpers.tapAndPump(tester, find.byType(GestureDetector));
        }

        // Assert
        expect(tapCount, equals(5));
        expect(tester.takeException(), isNull);
      });
    });
  });
}