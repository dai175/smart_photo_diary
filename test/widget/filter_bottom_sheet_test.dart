import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/shared/filter_bottom_sheet.dart';
import 'package:smart_photo_diary/models/diary_filter.dart';
import 'package:smart_photo_diary/services/diary_service.dart';
import 'package:smart_photo_diary/constants/app_constants.dart';
import '../test_helpers/widget_test_helpers.dart';

// Mock classes
class MockDiaryService extends Mock implements DiaryService {}

// Mock implementation to avoid real service initialization
DiaryService createMockDiaryService() {
  final mockService = MockDiaryService();
  when(() => mockService.getPopularTags(limit: any(named: 'limit')))
      .thenAnswer((_) async => ['tag1', 'tag2', 'tag3']);
  return mockService;
}

void main() {
  group('FilterBottomSheet', () {
    late DiaryFilter testFilter;
    late MockDiaryService mockDiaryService;

    setUpAll(() async {
      await WidgetTestHelpers.setUpTestEnvironment();
    });

    tearDownAll(() async {
      await WidgetTestHelpers.tearDownTestEnvironment();
    });

    setUp(() {
      testFilter = DiaryFilter.empty;
      mockDiaryService = MockDiaryService();
      
      // Setup default mock behavior
      when(() => mockDiaryService.getPopularTags(limit: any(named: 'limit')))
          .thenAnswer((_) async => ['tag1', 'tag2', 'tag3']);
    });
    
    // Helper function to create FilterBottomSheet with mock service
    Widget createFilterBottomSheet({
      DiaryFilter? filter,
      Function(DiaryFilter)? onApply,
      DiaryService? customMockService,
    }) {
      return WidgetTestHelpers.wrapWithMaterialApp(
        Scaffold(
          body: FilterBottomSheet(
            initialFilter: filter ?? testFilter,
            onApply: onApply ?? (filter) {},
            diaryService: customMockService ?? mockDiaryService,
          ),
        ),
      );
    }

    group('Basic Rendering', () {
      testWidgets('should render filter bottom sheet', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createFilterBottomSheet());
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.byType(FilterBottomSheet), findsOneWidget);
        expect(find.byType(Container), findsAtLeastNWidgets(1));
      });

      testWidgets('should display header with title and clear button', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createFilterBottomSheet());
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        WidgetTestHelpers.expectTextExists('フィルタ');
        WidgetTestHelpers.expectTextExists('すべてクリア');
        expect(find.byType(TextButton), findsAtLeastNWidgets(1));
      });

      testWidgets('should display handle indicator', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createFilterBottomSheet());
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        final containers = tester.widgetList<Container>(find.byType(Container));
        expect(containers.any((container) => 
          container.decoration != null && 
          container.constraints?.maxWidth == 40 && 
          container.constraints?.maxHeight == 4), isTrue);
      });

      testWidgets('should display all filter sections', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createFilterBottomSheet());
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        WidgetTestHelpers.expectTextExists('日付範囲');
        WidgetTestHelpers.expectTextExists('タグ');
        WidgetTestHelpers.expectTextExists('時間帯');
      });
    });

    group('Date Range Section', () {
      testWidgets('should display date range picker', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createFilterBottomSheet());
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        WidgetTestHelpers.expectTextExists('期間を選択');
        expect(find.byIcon(Icons.calendar_today), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
        expect(find.byType(Card), findsAtLeastNWidgets(1));
      });

      testWidgets('should display selected date range', (WidgetTester tester) async {
        // Arrange
        final dateRange = DateTimeRange(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
        );
        final filterWithDate = testFilter.copyWith(dateRange: dateRange);

        // Act
        await tester.pumpWidget(createFilterBottomSheet(filter: filterWithDate));
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.textContaining('1/1 - 1/31'), findsOneWidget);
        expect(find.byIcon(Icons.clear), findsOneWidget);
      });

      testWidgets('should open date picker when tapped', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createFilterBottomSheet());
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Tap on date range selector
        await WidgetTestHelpers.tapAndPump(tester, find.byType(ListTile).first);

        // Assert - DatePicker should appear
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(DatePickerDialog), findsOneWidget);
      });

      testWidgets('should clear date range when clear button tapped', (WidgetTester tester) async {
        // Arrange
        final dateRange = DateTimeRange(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
        );
        final filterWithDate = testFilter.copyWith(dateRange: dateRange);

        // Act
        await tester.pumpWidget(createFilterBottomSheet(filter: filterWithDate));
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Tap clear button
        await WidgetTestHelpers.tapAndPump(tester, find.byIcon(Icons.clear));

        // Assert
        WidgetTestHelpers.expectTextExists('期間を選択');
        expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
      });
    });

    group('Tags Section', () {
      testWidgets('should show loading indicator while loading tags', (WidgetTester tester) async {
        // Arrange
        final slowMockService = MockDiaryService();
        final completer = Completer<List<String>>();
        when(() => slowMockService.getPopularTags(limit: any(named: 'limit')))
            .thenAnswer((_) => completer.future);

        // Act
        await tester.pumpWidget(createFilterBottomSheet(customMockService: slowMockService));
        await tester.pump(); // Don't wait for settle to see loading state

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        
        // Complete the future to clean up
        completer.complete(['tag1', 'tag2']);
        await tester.pumpAndSettle();
      });

      testWidgets('should display tags as filter chips', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createFilterBottomSheet());
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.byType(FilterChip), findsAtLeastNWidgets(3));
        WidgetTestHelpers.expectTextExists('#tag1');
        WidgetTestHelpers.expectTextExists('#tag2');
        WidgetTestHelpers.expectTextExists('#tag3');
      });

      testWidgets('should show selected tags', (WidgetTester tester) async {
        // Arrange
        final filterWithTags = testFilter.copyWith(
          selectedTags: {'tag1', 'tag2'},
        );

        // Act
        await tester.pumpWidget(createFilterBottomSheet(filter: filterWithTags));
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        final filterChips = tester.widgetList<FilterChip>(find.byType(FilterChip));
        final selectedChips = filterChips.where((chip) => chip.selected).toList();
        expect(selectedChips.length, equals(2));
      });

      testWidgets('should toggle tag selection when tapped', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createFilterBottomSheet());
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Tap on first tag
        await WidgetTestHelpers.tapAndPump(tester, find.byType(FilterChip).first);

        // Assert - Tag should be selected
        final filterChips = tester.widgetList<FilterChip>(find.byType(FilterChip));
        expect(filterChips.first.selected, isTrue);
      });

      testWidgets('should show no tags message when empty', (WidgetTester tester) async {
        // Arrange
        final emptyMockService = MockDiaryService();
        when(() => emptyMockService.getPopularTags(limit: any(named: 'limit')))
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(createFilterBottomSheet(customMockService: emptyMockService));
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        WidgetTestHelpers.expectTextExists('タグがありません');
      });
    });

    group('Time of Day Section', () {
      testWidgets('should display time of day filter chips', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createFilterBottomSheet());
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        WidgetTestHelpers.expectTextExists('朝');
        WidgetTestHelpers.expectTextExists('昼');
        WidgetTestHelpers.expectTextExists('夕方');
        WidgetTestHelpers.expectTextExists('夜');
      });

      testWidgets('should show selected time of day', (WidgetTester tester) async {
        // Arrange
        final filterWithTime = testFilter.copyWith(
          timeOfDay: {'朝', '夜'},
        );

        // Act
        await tester.pumpWidget(createFilterBottomSheet(filter: filterWithTime));
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        final timeChips = tester.widgetList<FilterChip>(find.byType(FilterChip))
            .where((chip) => 
              chip.label is Text && 
              ['朝', '昼', '夕方', '夜'].contains((chip.label as Text).data))
            .toList();
        final selectedTimeChips = timeChips.where((chip) => chip.selected).toList();
        expect(selectedTimeChips.length, equals(2));
      });

      testWidgets('should toggle time of day selection when tapped', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createFilterBottomSheet());
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Find and tap the "朝" chip
        final morningChip = find.widgetWithText(FilterChip, '朝');
        await WidgetTestHelpers.tapAndPump(tester, morningChip);

        // Assert - Morning chip should be selected
        final updatedMorningChip = tester.widget<FilterChip>(morningChip);
        expect(updatedMorningChip.selected, isTrue);
      });
    });

    group('Apply Button', () {
      testWidgets('should display apply button', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createFilterBottomSheet());
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.byType(ElevatedButton), findsOneWidget);
        WidgetTestHelpers.expectTextExists('フィルタを適用');
      });

      testWidgets('should show filter count when filters are active', (WidgetTester tester) async {
        // Arrange
        final activeFilter = testFilter.copyWith(
          selectedTags: {'tag1'},
          timeOfDay: {'朝'},
        );

        // Act
        await tester.pumpWidget(createFilterBottomSheet(filter: activeFilter));
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.textContaining('フィルタを適用 ('), findsOneWidget);
      });

      testWidgets('should call onApply and close when button tapped', (WidgetTester tester) async {
        // Arrange
        DiaryFilter? appliedFilter;
        
        // Act
        await tester.pumpWidget(createFilterBottomSheet(
          onApply: (filter) {
            appliedFilter = filter;
          },
        ));
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        await WidgetTestHelpers.tapAndPump(tester, find.byType(ElevatedButton));

        // Assert
        expect(appliedFilter, isNotNull);
        expect(appliedFilter, equals(testFilter));
      });
    });

    group('Clear All Functionality', () {
      testWidgets('should clear all filters when clear all button tapped', (WidgetTester tester) async {
        // Arrange
        final activeFilter = testFilter.copyWith(
          selectedTags: {'tag1', 'tag2'},
          timeOfDay: {'朝', '夜'},
          dateRange: DateTimeRange(
            start: DateTime(2024, 1, 1),
            end: DateTime(2024, 1, 31),
          ),
        );

        // Act
        await tester.pumpWidget(createFilterBottomSheet(filter: activeFilter));
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Tap clear all button
        await WidgetTestHelpers.tapAndPump(tester, find.text('すべてクリア'));

        // Assert
        WidgetTestHelpers.expectTextExists('期間を選択');
        WidgetTestHelpers.expectTextExists('フィルタを適用');
        
        // All filter chips should be unselected
        final filterChips = tester.widgetList<FilterChip>(find.byType(FilterChip));
        final selectedChips = filterChips.where((chip) => chip.selected).toList();
        expect(selectedChips.length, equals(0));
      });
    });

    group('Error Handling', () {
      testWidgets('should handle tag loading error gracefully', (WidgetTester tester) async {
        // Arrange
        when(() => mockDiaryService.getPopularTags(limit: any(named: 'limit')))
            .thenThrow(Exception('Network error'));

        // Act
        await tester.pumpWidget(createFilterBottomSheet());
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert - Should not crash
        expect(find.byType(FilterBottomSheet), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle date picker cancellation', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createFilterBottomSheet());
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Tap on date range selector
        await WidgetTestHelpers.tapAndPump(tester, find.byType(ListTile).first);
        await tester.pump(const Duration(milliseconds: 100));

        // Cancel date picker
        await WidgetTestHelpers.tapAndPump(tester, find.text('キャンセル'));

        // Assert - Should return to normal state
        WidgetTestHelpers.expectTextExists('期間を選択');
      });
    });

    group('Responsive Design', () {
      testWidgets('should adapt to different screen sizes', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMediaQuery(
            createFilterBottomSheet(),
            size: const Size(400, 800), // Phone size
          ),
        );
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.byType(FilterBottomSheet), findsOneWidget);
        
        // Check height ratio
        final container = tester.widget<Container>(find.byType(Container).first);
        expect(container.constraints?.maxHeight, equals(800 * AppConstants.bottomSheetHeightRatio));
      });

      testWidgets('should handle tag wrap overflow', (WidgetTester tester) async {
        // Arrange - Many tags
        when(() => mockDiaryService.getPopularTags(limit: any(named: 'limit')))
            .thenAnswer((_) async => List.generate(20, (i) => 'very_long_tag_name_$i'));

        // Act
        await tester.pumpWidget(createFilterBottomSheet());
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert - Should not overflow
        expect(find.byType(Wrap), findsAtLeastNWidgets(1));
        expect(tester.takeException(), isNull);
      });
    });

    group('Accessibility', () {
      testWidgets('should be accessible', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createFilterBottomSheet());
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        await WidgetTestHelpers.testAccessibility(tester);
      });

      testWidgets('should have semantic information for interactive elements', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createFilterBottomSheet());
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Assert
        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(find.byType(TextButton), findsAtLeastNWidgets(1));
        expect(find.byType(FilterChip), findsAtLeastNWidgets(1));
      });
    });

    group('Performance', () {
      testWidgets('should render efficiently', (WidgetTester tester) async {
        // Arrange
        final stopwatch = Stopwatch()..start();

        // Act
        await tester.pumpWidget(createFilterBottomSheet());
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Should render within 2 seconds
        expect(find.byType(FilterBottomSheet), findsOneWidget);
      });

      testWidgets('should handle rapid filter changes', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createFilterBottomSheet());
        await WidgetTestHelpers.pumpAndSettleWithTimeout(tester);

        // Rapid tapping on different filter chips
        final filterChips = find.byType(FilterChip);
        for (int i = 0; i < 5; i++) {
          await WidgetTestHelpers.tapAndPump(tester, filterChips.at(i % 3));
        }

        // Assert - Should not crash
        expect(tester.takeException(), isNull);
      });
    });
  });
}