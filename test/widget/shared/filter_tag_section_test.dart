import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/shared/filter_tag_section.dart';
import 'package:smart_photo_diary/shared/filter_selection_chip.dart';

import '../../test_helpers/widget_test_helpers.dart';

void main() {
  Widget buildWidget({
    List<String> availableTags = const [],
    Set<String> selectedTags = const {},
    bool isLoading = false,
    ValueChanged<String>? onTagToggled,
  }) {
    return WidgetTestHelpers.wrapWithLocalizedApp(
      Scaffold(
        body: FilterTagSection(
          availableTags: availableTags,
          selectedTags: selectedTags,
          isLoading: isLoading,
          onTagToggled: onTagToggled ?? (_) {},
        ),
      ),
    );
  }

  group('FilterTagSection', () {
    group('loading state', () {
      testWidgets('shows CircularProgressIndicator when loading', (
        tester,
      ) async {
        await tester.pumpWidget(buildWidget(isLoading: true));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('hides chips when loading', (tester) async {
        await tester.pumpWidget(
          buildWidget(availableTags: ['flutter', 'dart'], isLoading: true),
        );
        await tester.pump();

        expect(find.byType(FilterSelectionChip), findsNothing);
      });
    });

    group('empty state', () {
      testWidgets('shows no-tags message when availableTags is empty', (
        tester,
      ) async {
        await tester.pumpWidget(buildWidget(availableTags: []));
        await tester.pump();

        expect(find.textContaining('tag', findRichText: true), findsWidgets);
      });
    });

    group('tag list', () {
      testWidgets('shows one chip per available tag', (tester) async {
        await tester.pumpWidget(
          buildWidget(availableTags: ['flutter', 'dart', 'mobile']),
        );
        await tester.pump();

        expect(find.byType(FilterSelectionChip), findsNWidgets(3));
      });

      testWidgets('prefixes each tag label with #', (tester) async {
        await tester.pumpWidget(buildWidget(availableTags: ['flutter']));
        await tester.pump();

        expect(find.text('#flutter'), findsOneWidget);
      });

      testWidgets('shows check icon for selected tag', (tester) async {
        await tester.pumpWidget(
          buildWidget(
            availableTags: ['flutter', 'dart'],
            selectedTags: {'flutter'},
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('hides check icon for unselected tag', (tester) async {
        await tester.pumpWidget(
          buildWidget(availableTags: ['flutter'], selectedTags: {}),
        );
        await tester.pump();

        expect(find.byIcon(Icons.check), findsNothing);
      });
    });

    group('callbacks', () {
      testWidgets('fires onTagToggled with tag when unselected chip tapped', (
        tester,
      ) async {
        String? toggled;
        await tester.pumpWidget(
          buildWidget(
            availableTags: ['flutter'],
            onTagToggled: (t) => toggled = t,
          ),
        );
        await tester.pump();

        await tester.tap(find.byType(FilterSelectionChip).first);
        expect(toggled, 'flutter');
      });

      testWidgets('fires onTagToggled with tag when selected chip tapped', (
        tester,
      ) async {
        String? toggled;
        await tester.pumpWidget(
          buildWidget(
            availableTags: ['flutter'],
            selectedTags: {'flutter'},
            onTagToggled: (t) => toggled = t,
          ),
        );
        await tester.pump();

        await tester.tap(find.byType(FilterSelectionChip).first);
        expect(toggled, 'flutter');
      });
    });
  });
}
