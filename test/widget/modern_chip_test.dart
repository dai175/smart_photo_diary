import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/ui/components/modern_chip.dart';
import 'package:smart_photo_diary/ui/design_system/app_colors.dart';
import 'package:smart_photo_diary/ui/design_system/app_typography.dart';
import '../test_helpers/widget_test_helpers.dart';

void main() {
  group('ModernChip.tonedTag', () {
    const colorCases = [
      (0, AppColors.tagPrimaryBg),
      (1, AppColors.tagSecondaryBg),
      (2, AppColors.tagAccentBg),
      (3, AppColors.tagPrimaryBg), // cycles
    ];

    for (final (index, expectedColor) in colorCases) {
      testWidgets('index $index maps to correct background', (tester) async {
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithMaterialApp(
            ModernChip.tonedTag('tag', index: index),
          ),
        );
        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        expect((container.decoration as BoxDecoration).color, expectedColor);
      });
    }

    testWidgets('applies design spec typography (11.5/w600/ls0.15)', (
      tester,
    ) async {
      await tester.pumpWidget(
        WidgetTestHelpers.wrapWithMaterialApp(
          ModernChip.tonedTag('hello', index: 0),
        ),
      );
      final text = tester.widget<Text>(find.text('hello'));
      expect(text.style?.fontSize, 11.5);
      expect(text.style?.fontWeight, FontWeight.w600);
      expect(text.style?.letterSpacing, 0.15);
    });

    testWidgets('uses cornerRadius 8', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.wrapWithMaterialApp(
          ModernChip.tonedTag('tag', index: 0),
        ),
      );
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      expect(
        (container.decoration as BoxDecoration).borderRadius,
        BorderRadius.circular(8.0),
      );
    });
  });

  group('ModernChip textStyle override', () {
    testWidgets('custom textStyle is applied to Text widget', (tester) async {
      const style = TextStyle(fontSize: 20, fontWeight: FontWeight.w900);
      await tester.pumpWidget(
        WidgetTestHelpers.wrapWithMaterialApp(
          const ModernChip(label: 'test', textStyle: style),
        ),
      );
      final text = tester.widget<Text>(find.text('test'));
      expect(text.style?.fontSize, 20);
      expect(text.style?.fontWeight, FontWeight.w900);
    });

    testWidgets('null textStyle falls back to size-based style', (
      tester,
    ) async {
      await tester.pumpWidget(
        WidgetTestHelpers.wrapWithMaterialApp(
          const ModernChip(label: 'test', size: ChipSize.medium),
        ),
      );
      final text = tester.widget<Text>(find.text('test'));
      expect(text.style?.fontSize, AppTypography.labelMedium.fontSize);
      expect(
        text.style?.letterSpacing,
        AppTypography.labelMedium.letterSpacing,
      );
    });
  });

  group('ModernChip.tag and .badge backward compatibility', () {
    testWidgets('.tag renders label without errors', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.wrapWithMaterialApp(
          const ModernChip.tag(label: 'mytag'),
        ),
      );
      expect(find.text('mytag'), findsOneWidget);
    });

    testWidgets('.badge renders label and icon without errors', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.wrapWithMaterialApp(
          const ModernChip.badge(label: '3', icon: Icons.label_outline),
        ),
      );
      expect(find.text('3'), findsOneWidget);
    });
  });
}
