import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/ui/components/loading_shimmer.dart';
import 'package:smart_photo_diary/ui/components/photo_placeholder.dart';

void main() {
  group('PhotoPlaceholder', () {
    testWidgets('エラー状態で broken_image アイコンを表示する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PhotoPlaceholder(size: 80, isError: true)),
        ),
      );

      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
      expect(find.byType(ImageShimmer), findsNothing);
    });

    testWidgets('ローディング状態で ImageShimmer を表示する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PhotoPlaceholder(size: 80))),
      );

      expect(find.byType(ImageShimmer), findsOneWidget);
      expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
    });

    testWidgets('指定されたサイズで描画される', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PhotoPlaceholder(size: 100, isError: true)),
        ),
      );

      final renderBox = tester.renderObject<RenderBox>(
        find.byType(PhotoPlaceholder),
      );
      expect(renderBox.size.width, 100);
      expect(renderBox.size.height, 100);
    });

    testWidgets('ローディング状態で指定されたサイズの ImageShimmer を表示する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PhotoPlaceholder(size: 120))),
      );

      final shimmer = tester.widget<ImageShimmer>(find.byType(ImageShimmer));
      expect(shimmer.width, 120);
      expect(shimmer.height, 120);
    });
  });
}
