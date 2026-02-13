import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/screens/diary_detail/diary_detail_screen.dart';
import 'package:smart_photo_diary/services/interfaces/diary_service_interface.dart';

import '../integration/mocks/mock_services.dart';
import '../test_helpers/mock_platform_channels.dart';
import '../test_helpers/widget_test_helpers.dart';

void main() {
  late MockIDiaryService mockDiaryService;

  final testEntry = DiaryEntry(
    id: 'test-id-1',
    date: DateTime(2025, 1, 15),
    title: 'A beautiful sunny day',
    content: 'Today was a wonderful day full of sunshine and joy.',
    photoIds: [],
    createdAt: DateTime(2025, 1, 15),
    updatedAt: DateTime(2025, 1, 15),
    tags: ['sunny', 'happy'],
  );

  setUpAll(() {
    registerMockFallbacks();
    MockPlatformChannels.setupMocks();
  });

  setUp(() {
    serviceLocator.clear();
    TestServiceSetup.clearAllMocks();

    mockDiaryService = TestServiceSetup.getDiaryService();
    serviceLocator.registerSingleton<IDiaryService>(mockDiaryService);
  });

  tearDown(() {
    serviceLocator.clear();
    TestServiceSetup.clearAllMocks();
  });

  tearDownAll(() {
    MockPlatformChannels.clearMocks();
  });

  Widget buildDiaryDetailScreen({String diaryId = 'test-id-1'}) {
    return WidgetTestHelpers.wrapWithLocalizedApp(
      DiaryDetailScreen(diaryId: diaryId),
    );
  }

  group('DiaryDetailScreen', () {
    group('Loading state', () {
      testWidgets('shows CircularProgressIndicator while loading', (
        WidgetTester tester,
      ) async {
        // Use a Completer that never completes to keep loading state
        when(
          () => mockDiaryService.getDiaryEntry('test-id-1'),
        ).thenAnswer((_) => Completer<Result<DiaryEntry?>>().future);

        await tester.pumpWidget(buildDiaryDetailScreen());
        // Fire the post-frame callback
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Content display', () {
      testWidgets('shows diary entry title and content', (
        WidgetTester tester,
      ) async {
        when(
          () => mockDiaryService.getDiaryEntry('test-id-1'),
        ).thenAnswer((_) async => Success(testEntry));

        await tester.pumpWidget(buildDiaryDetailScreen());
        await tester.pumpAndSettle();

        expect(find.text('A beautiful sunny day'), findsOneWidget);
        expect(
          find.text('Today was a wonderful day full of sunshine and joy.'),
          findsOneWidget,
        );
      });

      testWidgets('shows edit, delete, and share buttons', (
        WidgetTester tester,
      ) async {
        when(
          () => mockDiaryService.getDiaryEntry('test-id-1'),
        ).thenAnswer((_) async => Success(testEntry));

        await tester.pumpWidget(buildDiaryDetailScreen());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
        expect(find.byIcon(Icons.delete_rounded), findsOneWidget);
        expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      });

      testWidgets('AppBar shows view title in read mode', (
        WidgetTester tester,
      ) async {
        when(
          () => mockDiaryService.getDiaryEntry('test-id-1'),
        ).thenAnswer((_) async => Success(testEntry));

        await tester.pumpWidget(buildDiaryDetailScreen());
        await tester.pumpAndSettle();

        expect(find.text('Diary details'), findsOneWidget);
      });
    });

    group('Error state', () {
      testWidgets('shows error when getDiaryEntry fails', (
        WidgetTester tester,
      ) async {
        when(() => mockDiaryService.getDiaryEntry('test-id-1')).thenAnswer(
          (_) async => const Failure(DatabaseException('Database error')),
        );

        await tester.pumpWidget(buildDiaryDetailScreen());
        await tester.pumpAndSettle();

        expect(find.text('An error occurred'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      });

      testWidgets('shows Back button on error', (WidgetTester tester) async {
        when(() => mockDiaryService.getDiaryEntry('test-id-1')).thenAnswer(
          (_) async => const Failure(DatabaseException('Database error')),
        );

        await tester.pumpWidget(buildDiaryDetailScreen());
        await tester.pumpAndSettle();

        expect(find.text('Back'), findsOneWidget);
      });
    });

    group('Not found state', () {
      testWidgets('shows not-found message when entry is null', (
        WidgetTester tester,
      ) async {
        // When getDiaryEntry returns Success(null), the code sets _hasError=true
        // with _errorMessage = diaryNotFoundMessage, so it renders error state.
        when(
          () => mockDiaryService.getDiaryEntry('nonexistent'),
        ).thenAnswer((_) async => const Success(null));

        await tester.pumpWidget(buildDiaryDetailScreen(diaryId: 'nonexistent'));
        await tester.pumpAndSettle();

        expect(find.text('Diary not found'), findsOneWidget);
        expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
      });

      testWidgets('shows Back button on not-found', (
        WidgetTester tester,
      ) async {
        when(
          () => mockDiaryService.getDiaryEntry('nonexistent'),
        ).thenAnswer((_) async => const Success(null));

        await tester.pumpWidget(buildDiaryDetailScreen(diaryId: 'nonexistent'));
        await tester.pumpAndSettle();

        expect(find.text('Back'), findsOneWidget);
      });
    });

    group('Edit mode', () {
      testWidgets('tapping edit icon switches to edit mode', (
        WidgetTester tester,
      ) async {
        when(
          () => mockDiaryService.getDiaryEntry('test-id-1'),
        ).thenAnswer((_) async => Success(testEntry));

        await tester.pumpWidget(buildDiaryDetailScreen());
        await tester.pumpAndSettle();

        // Tap edit button
        await tester.tap(find.byIcon(Icons.edit_rounded));
        await tester.pumpAndSettle();

        // Edit icon changes to check (save) icon
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);
        // "Edit diary" appears in AppBar AND content editor section
        expect(find.text('Edit diary'), findsAtLeastNWidgets(1));
      });

      testWidgets('bottom bar shows save and cancel in edit mode', (
        WidgetTester tester,
      ) async {
        when(
          () => mockDiaryService.getDiaryEntry('test-id-1'),
        ).thenAnswer((_) async => Success(testEntry));

        await tester.pumpWidget(buildDiaryDetailScreen());
        await tester.pumpAndSettle();

        // Enter edit mode
        await tester.tap(find.byIcon(Icons.edit_rounded));
        await tester.pumpAndSettle();

        // Bottom bar should show cancel and save
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
      });

      testWidgets('cancel reverts to view mode', (WidgetTester tester) async {
        when(
          () => mockDiaryService.getDiaryEntry('test-id-1'),
        ).thenAnswer((_) async => Success(testEntry));

        await tester.pumpWidget(buildDiaryDetailScreen());
        await tester.pumpAndSettle();

        // Enter edit mode
        await tester.tap(find.byIcon(Icons.edit_rounded));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check_rounded), findsOneWidget);

        // Tap cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Should revert to view mode
        expect(find.text('Diary details'), findsOneWidget);
        // Bottom bar should disappear
        expect(find.text('Cancel'), findsNothing);
        // edit_rounded icon should return (AppBar + content section)
        expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
      });

      testWidgets('share button is hidden in edit mode', (
        WidgetTester tester,
      ) async {
        when(
          () => mockDiaryService.getDiaryEntry('test-id-1'),
        ).thenAnswer((_) async => Success(testEntry));

        await tester.pumpWidget(buildDiaryDetailScreen());
        await tester.pumpAndSettle();

        // Share visible in view mode
        expect(find.byIcon(Icons.share_rounded), findsOneWidget);

        // Enter edit mode
        await tester.tap(find.byIcon(Icons.edit_rounded));
        await tester.pumpAndSettle();

        // Share should be hidden in edit mode
        expect(find.byIcon(Icons.share_rounded), findsNothing);
      });
    });
  });
}
