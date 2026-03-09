import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('ローディング状態で CircularProgressIndicator を表示する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PhotoPlaceholder(size: 80))),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
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
  });
}
