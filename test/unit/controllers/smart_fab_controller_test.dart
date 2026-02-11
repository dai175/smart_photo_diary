import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/controllers/photo_selection_controller.dart';
import 'package:smart_photo_diary/controllers/smart_fab_controller.dart';

class MockAssetEntity extends Mock implements AssetEntity {}

/// テスト用のモックAssetEntityリストを生成するヘルパー
List<AssetEntity> _createMockAssets(int count) {
  return List.generate(count, (i) {
    final mock = MockAssetEntity();
    when(() => mock.id).thenReturn('photo_$i');
    when(() => mock.createDateTime).thenReturn(DateTime(2025, 1, 1));
    return mock;
  });
}

void main() {
  late PhotoSelectionController photoController;
  late SmartFABController fabController;

  setUp(() {
    photoController = PhotoSelectionController();
    fabController = SmartFABController(photoController: photoController);
  });

  tearDown(() {
    fabController.dispose();
    photoController.dispose();
  });

  group('SmartFABController', () {
    group('初期状態', () {
      test('写真未選択時のcurrentStateはSmartFABState.camera', () {
        expect(fabController.currentState, SmartFABState.camera);
      });

      test('shouldShowは常にtrue', () {
        expect(fabController.shouldShow, true);
      });

      test('selectedCountは0', () {
        expect(fabController.selectedCount, 0);
      });
    });

    group('写真選択時の状態変化', () {
      test('写真が選択されるとcurrentStateがSmartFABState.createDiaryに変わる', () {
        // Arrange
        final mockAssets = _createMockAssets(3);
        photoController.setPhotoAssets(mockAssets);

        // Act
        photoController.toggleSelect(0);

        // Assert
        expect(fabController.currentState, SmartFABState.createDiary);
        expect(fabController.selectedCount, 1);
      });

      test('写真選択が解除されるとcurrentStateがSmartFABState.cameraに戻る', () {
        // Arrange
        final mockAssets = _createMockAssets(3);
        photoController.setPhotoAssets(mockAssets);
        photoController.toggleSelect(0);
        expect(fabController.currentState, SmartFABState.createDiary);

        // Act
        photoController.toggleSelect(0);

        // Assert
        expect(fabController.currentState, SmartFABState.camera);
        expect(fabController.selectedCount, 0);
      });
    });

    group('icon', () {
      test('camera状態ではphoto_camera_roundedアイコン', () {
        expect(fabController.icon, Icons.photo_camera_rounded);
      });

      test('createDiary状態ではauto_awesome_roundedアイコン', () {
        // Arrange
        final mockAssets = _createMockAssets(3);
        photoController.setPhotoAssets(mockAssets);
        photoController.toggleSelect(0);

        // Assert
        expect(fabController.icon, Icons.auto_awesome_rounded);
      });
    });

    group('getLocalizedTooltip', () {
      test('camera状態ではcameraTextが返される', () {
        final result = fabController.getLocalizedTooltip(
          cameraText: 'Take photo',
          createDiaryText: (count) => 'Create diary with $count photos',
        );
        expect(result, 'Take photo');
      });

      test('createDiary状態ではcreateDiaryTextが選択数付きで返される', () {
        // Arrange
        final mockAssets = _createMockAssets(5);
        photoController.setPhotoAssets(mockAssets);
        photoController.toggleSelect(0);
        photoController.toggleSelect(1);

        // Act
        final result = fabController.getLocalizedTooltip(
          cameraText: 'Take photo',
          createDiaryText: (count) => 'Create diary with $count photos',
        );

        // Assert
        expect(result, 'Create diary with 2 photos');
      });
    });

    group('getBackgroundColor / getForegroundColor', () {
      test('camera状態ではcolorScheme.primaryを使用', () {
        // Arrange
        const colorScheme = ColorScheme.light();

        // Assert
        expect(
          fabController.getBackgroundColor(colorScheme),
          colorScheme.primary,
        );
        expect(
          fabController.getForegroundColor(colorScheme),
          colorScheme.onPrimary,
        );
      });

      test('createDiary状態ではcolorScheme.tertiaryを使用', () {
        // Arrange
        const colorScheme = ColorScheme.light();
        final mockAssets = _createMockAssets(3);
        photoController.setPhotoAssets(mockAssets);
        photoController.toggleSelect(0);

        // Assert
        expect(
          fabController.getBackgroundColor(colorScheme),
          colorScheme.tertiary,
        );
        expect(
          fabController.getForegroundColor(colorScheme),
          colorScheme.onTertiary,
        );
      });
    });

    group('リスナー通知', () {
      test('写真選択変更時にリスナーが通知される', () {
        // Arrange
        int notifyCount = 0;
        fabController.addListener(() {
          notifyCount++;
        });

        final mockAssets = _createMockAssets(3);

        // Act - setPhotoAssetsもnotifyListenersを呼ぶ
        photoController.setPhotoAssets(mockAssets);
        final countAfterSetAssets = notifyCount;

        photoController.toggleSelect(0);

        // Assert - toggleSelectで少なくとも1回通知される
        expect(notifyCount, greaterThan(countAfterSetAssets));
      });
    });
  });
}
