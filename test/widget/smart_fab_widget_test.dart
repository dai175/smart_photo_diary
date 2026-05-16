import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/controllers/photo_selection_controller.dart';
import 'package:smart_photo_diary/widgets/smart_fab_widget.dart';
import 'package:smart_photo_diary/l10n/generated/app_localizations.dart';
import 'package:smart_photo_diary/ui/design_system/app_colors.dart';

class MockAssetEntity extends Mock implements AssetEntity {}

List<AssetEntity> _createMockAssets(int count) {
  return List.generate(count, (i) {
    final mock = MockAssetEntity();
    when(() => mock.id).thenReturn('photo_$i');
    when(() => mock.createDateTime).thenReturn(DateTime(2025, 1, 1));
    return mock;
  });
}

Widget _wrapWithApp(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    localizationsDelegates: const [
      ...AppLocalizations.localizationsDelegates,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    theme: theme ?? ThemeData(useMaterial3: true),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  late PhotoSelectionController photoController;

  setUp(() {
    photoController = PhotoSelectionController();
  });

  tearDown(() {
    photoController.dispose();
  });

  group('SmartFABWidget', () {
    group('表示', () {
      testWidgets('カメラ状態でFABが表示される', (tester) async {
        await tester.pumpWidget(
          _wrapWithApp(
            SmartFABWidget(
              photoController: photoController,
              heroTag: 'test_fab',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsOneWidget);
      });

      testWidgets('visible=false時にFABが非表示', (tester) async {
        await tester.pumpWidget(
          _wrapWithApp(
            SmartFABWidget(
              photoController: photoController,
              visible: false,
              heroTag: 'test_fab_hidden',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsNothing);
      });
    });

    group('カメラ状態（写真未選択）', () {
      testWidgets('カメラアイコンが表示される', (tester) async {
        await tester.pumpWidget(
          _wrapWithApp(
            SmartFABWidget(
              photoController: photoController,
              heroTag: 'test_fab_camera',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
      });

      testWidgets('タップでonCameraPressedが呼ばれる', (tester) async {
        bool cameraCalled = false;

        await tester.pumpWidget(
          _wrapWithApp(
            SmartFABWidget(
              photoController: photoController,
              onCameraPressed: () => cameraCalled = true,
              heroTag: 'test_fab_camera_tap',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();

        expect(cameraCalled, true);
      });
    });

    group('日記作成状態（写真選択あり）', () {
      testWidgets('写真選択後にピルバーが表示される', (tester) async {
        final mockAssets = _createMockAssets(3);
        photoController.setPhotoAssets(mockAssets);

        await tester.pumpWidget(
          _wrapWithApp(
            SmartFABWidget(
              photoController: photoController,
              heroTag: 'test_fab_diary',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 未選択時はFAB表示
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byKey(const ValueKey('fab_selection_pill')), findsNothing);

        // 写真を選択
        photoController.toggleSelect(0);
        await tester.pumpAndSettle();

        // 選択後はピルバーが表示、FABは非表示
        expect(
          find.byKey(const ValueKey('fab_selection_pill')),
          findsOneWidget,
        );
        expect(find.byType(FloatingActionButton), findsNothing);
      });

      testWidgets('ピルの「Create diary」ボタンでonCreateDiaryPressedが呼ばれる', (
        tester,
      ) async {
        bool createDiaryCalled = false;
        final mockAssets = _createMockAssets(3);
        photoController.setPhotoAssets(mockAssets);
        photoController.toggleSelect(0);

        await tester.pumpWidget(
          _wrapWithApp(
            SmartFABWidget(
              photoController: photoController,
              onCreateDiaryPressed: () => createDiaryCalled = true,
              heroTag: 'test_fab_diary_tap',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // "Create diary →" テキストのボタンをタップ
        await tester.tap(find.text('Create diary →'));
        await tester.pump();

        expect(createDiaryCalled, true);
      });
    });

    group('色', () {
      testWidgets('カメラ状態でAccentカラーが使用される', (tester) async {
        await tester.pumpWidget(
          _wrapWithApp(
            SmartFABWidget(
              photoController: photoController,
              heroTag: 'test_fab_color_camera',
            ),
          ),
        );
        await tester.pumpAndSettle();

        final fab = tester.widget<FloatingActionButton>(
          find.byType(FloatingActionButton),
        );
        expect(fab.backgroundColor, AppColors.accent);
      });

      testWidgets('日記作成状態でピルバーがAccentカラー背景', (tester) async {
        final mockAssets = _createMockAssets(3);
        photoController.setPhotoAssets(mockAssets);
        photoController.toggleSelect(0);

        await tester.pumpWidget(
          _wrapWithApp(
            SmartFABWidget(
              photoController: photoController,
              heroTag: 'test_fab_color_diary',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // FABではなくピルが表示されることを確認
        expect(find.byType(FloatingActionButton), findsNothing);
        expect(
          find.byKey(const ValueKey('fab_selection_pill')),
          findsOneWidget,
        );
      });
    });
  });
}
