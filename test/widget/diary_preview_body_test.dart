import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/writing_prompt.dart';
import 'package:smart_photo_diary/screens/diary_preview/diary_preview_body.dart';
import 'package:smart_photo_diary/screens/diary_preview/diary_preview_editor.dart';
import 'package:smart_photo_diary/screens/diary_preview/diary_preview_loading_states.dart';

import '../integration/mocks/mock_services.dart';
import '../test_helpers/mock_platform_channels.dart';
import '../test_helpers/widget_test_helpers.dart';

void main() {
  late TextEditingController titleController;
  late TextEditingController contentController;

  setUpAll(() {
    registerMockFallbacks();
    MockPlatformChannels.setupMocks();
  });

  setUp(() {
    titleController = TextEditingController();
    contentController = TextEditingController();
  });

  tearDown(() {
    titleController.dispose();
    contentController.dispose();
  });

  tearDownAll(() {
    MockPlatformChannels.clearMocks();
  });

  final testPrompt = WritingPrompt(
    id: 'test-prompt',
    text: 'What made you smile today?',
    category: PromptCategory.emotion,
    isPremiumOnly: false,
    tags: ['smile', 'daily'],
    priority: 1,
    createdAt: DateTime(2025, 1, 1),
    isActive: true,
    localizedTexts: {'en': 'What made you smile today?', 'ja': '今日笑顔になれたこと'},
  );

  Widget buildBody({
    bool isInitializing = false,
    bool isLoading = false,
    bool isSaving = false,
    bool hasError = false,
    String errorMessage = '',
    bool isAnalyzingPhotos = false,
    int currentPhotoIndex = 0,
    int totalPhotos = 0,
    WritingPrompt? selectedPrompt,
    String title = '',
    String content = '',
  }) {
    titleController.text = title;
    contentController.text = content;

    return WidgetTestHelpers.wrapWithLocalizedApp(
      Scaffold(
        body: DiaryPreviewBody(
          selectedAssets: const [],
          photoDateTime: DateTime(2025, 1, 15),
          selectedPrompt: selectedPrompt,
          isInitializing: isInitializing,
          isLoading: isLoading,
          isSaving: isSaving,
          hasError: hasError,
          errorMessage: errorMessage,
          isAnalyzingPhotos: isAnalyzingPhotos,
          currentPhotoIndex: currentPhotoIndex,
          totalPhotos: totalPhotos,
          titleController: titleController,
          contentController: contentController,
        ),
      ),
    );
  }

  group('DiaryPreviewBody', () {
    group('Loading states', () {
      // Loading states contain CircularProgressIndicator which never settles,
      // so we use pump() with a duration instead of pumpAndSettle().

      testWidgets('shows loading when initializing', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildBody(isInitializing: true));
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(DiaryPreviewLoadingStates), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Preparing prompt services...'), findsOneWidget);
      });

      testWidgets('shows loading when generating diary', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildBody(isLoading: true));
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(DiaryPreviewLoadingStates), findsOneWidget);
        expect(find.text('Creating your diary...'), findsOneWidget);
      });

      testWidgets('shows saving state', (WidgetTester tester) async {
        await tester.pumpWidget(buildBody(isSaving: true));
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(DiaryPreviewLoadingStates), findsOneWidget);
        expect(find.text('Saving diary...'), findsOneWidget);
      });

      testWidgets('shows photo analysis progress for multiple photos', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildBody(
            isLoading: true,
            isAnalyzingPhotos: true,
            currentPhotoIndex: 2,
            totalPhotos: 5,
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Analyzing photos...'), findsOneWidget);
        expect(find.text('Processed 2 of 5 photos'), findsOneWidget);
      });
    });

    group('Error state', () {
      testWidgets('shows error message and icon', (WidgetTester tester) async {
        await tester.pumpWidget(
          buildBody(hasError: true, errorMessage: 'Failed to generate diary'),
        );
        await tester.pumpAndSettle();

        expect(find.text('An error occurred'), findsOneWidget);
        expect(find.text('Failed to generate diary'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      });

      testWidgets('shows Back button on error', (WidgetTester tester) async {
        await tester.pumpWidget(
          buildBody(hasError: true, errorMessage: 'Error'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Back'), findsOneWidget);
      });
    });

    group('Content display', () {
      testWidgets('shows date card with calendar icon', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildBody());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
        // Date label
        expect(find.text('Diary date'), findsOneWidget);
      });

      testWidgets('shows editor when not loading or errored', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildBody(title: 'My Day', content: 'Great day'),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DiaryPreviewEditor), findsOneWidget);
      });

      testWidgets('shows prompt display when prompt is selected', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildBody(selectedPrompt: testPrompt));
        await tester.pumpAndSettle();

        // Prompt tag should be visible in the editor section
        expect(find.text('Prompt in use'), findsOneWidget);
      });
    });
  });
}
