import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/widgets/timeline/timeline_empty_states.dart';

import '../test_helpers/widget_test_helpers.dart';

void main() {
  Widget build({
    required bool requiresSettings,
    bool isLoading = false,
    VoidCallback? onRequestPermission,
  }) {
    return WidgetTestHelpers.wrapWithLocalizedApp(
      Scaffold(
        body: TimelinePermissionDeniedState(
          requiresSettings: requiresSettings,
          isLoading: isLoading,
          onRequestPermission: onRequestPermission,
        ),
      ),
    );
  }

  testWidgets('shows Allow when settings are not required', (tester) async {
    await tester.pumpWidget(
      build(requiresSettings: false, onRequestPermission: () {}),
    );
    await tester.pump();

    expect(find.text('Photo access permission is required'), findsOneWidget);
    expect(find.text('Allow'), findsOneWidget);
    expect(find.text('Open Settings'), findsNothing);
  });

  testWidgets('shows Open Settings when re-prompt is not available', (
    tester,
  ) async {
    await tester.pumpWidget(
      build(requiresSettings: true, onRequestPermission: () {}),
    );
    await tester.pump();

    expect(
      find.text('Turn on photo access in Settings to see your timeline.'),
      findsOneWidget,
    );
    expect(find.text('Open Settings'), findsOneWidget);
    expect(find.text('Allow'), findsNothing);
  });

  testWidgets('shows loading instead of action button while retrying', (
    tester,
  ) async {
    await tester.pumpWidget(
      build(
        requiresSettings: false,
        isLoading: true,
        onRequestPermission: () {},
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Allow'), findsNothing);
  });

  testWidgets('invokes callback when action is tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      build(requiresSettings: true, onRequestPermission: () => tapped = true),
    );
    await tester.pump();

    await tester.tap(find.text('Open Settings'));
    expect(tapped, isTrue);
  });
}
