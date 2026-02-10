import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/controllers/photo_selection_controller.dart';

class MockAssetEntity extends Mock implements AssetEntity {}

MockAssetEntity createMockAsset(String id, {DateTime? createDateTime}) {
  final asset = MockAssetEntity();
  when(() => asset.id).thenReturn(id);
  when(
    () => asset.createDateTime,
  ).thenReturn(createDateTime ?? DateTime(2024, 1, 15));
  return asset;
}

void main() {
  late PhotoSelectionController controller;

  setUp(() {
    controller = PhotoSelectionController();
  });

  tearDown(() {
    controller.dispose();
  });

  group('PhotoSelectionController', () {
    group('初期状態', () {
      test('初期状態が正しく設定されている', () {
        expect(controller.photoAssets, isEmpty);
        expect(controller.selected, isEmpty);
        expect(controller.isLoading, isTrue);
        expect(controller.hasPermission, isFalse);
        expect(controller.hasMorePhotos, isTrue);
        expect(controller.selectedCount, 0);
        expect(controller.selectedPhotos, isEmpty);
        expect(controller.usedPhotoIds, isEmpty);
      });
    });

    group('setPhotoAssets', () {
      test('写真アセットを設定し選択状態をリセットする', () {
        final assets = [
          createMockAsset('photo1'),
          createMockAsset('photo2'),
          createMockAsset('photo3'),
        ];

        controller.setPhotoAssets(assets);

        expect(controller.photoAssets.length, 3);
        expect(controller.selected.length, 3);
        expect(controller.selected.every((s) => !s), isTrue);
        expect(controller.selectedCount, 0);
      });

      test('既存の選択状態がリセットされる', () {
        final assets = [createMockAsset('photo1'), createMockAsset('photo2')];
        controller.setPhotoAssets(assets);
        controller.toggleSelect(0);
        expect(controller.selectedCount, 1);

        // 新しいアセットを設定すると選択がリセットされる
        final newAssets = [
          createMockAsset('photo3'),
          createMockAsset('photo4'),
        ];
        controller.setPhotoAssets(newAssets);

        expect(controller.selectedCount, 0);
        expect(controller.photoAssets[0].id, 'photo3');
      });
    });

    group('toggleSelect', () {
      test('写真を選択できる', () {
        final assets = [createMockAsset('photo1'), createMockAsset('photo2')];
        controller.setPhotoAssets(assets);

        controller.toggleSelect(0);

        expect(controller.selected[0], isTrue);
        expect(controller.selectedCount, 1);
        expect(controller.selectedPhotos.length, 1);
        expect(controller.selectedPhotos[0].id, 'photo1');
      });

      test('選択済みの写真を解除できる', () {
        final assets = [createMockAsset('photo1')];
        controller.setPhotoAssets(assets);

        controller.toggleSelect(0);
        expect(controller.selected[0], isTrue);

        controller.toggleSelect(0);
        expect(controller.selected[0], isFalse);
        expect(controller.selectedCount, 0);
      });

      test('最大選択数(3枚)に達すると追加選択できない', () {
        final assets = [
          createMockAsset('photo1'),
          createMockAsset('photo2'),
          createMockAsset('photo3'),
          createMockAsset('photo4'),
        ];
        controller.setPhotoAssets(assets);

        controller.toggleSelect(0);
        controller.toggleSelect(1);
        controller.toggleSelect(2);
        expect(controller.selectedCount, 3);

        // 4枚目は選択できない
        controller.toggleSelect(3);
        expect(controller.selectedCount, 3);
        expect(controller.selected[3], isFalse);
      });

      test('使用済み写真は選択できない', () {
        final assets = [
          createMockAsset('photo1'),
          createMockAsset('used_photo'),
        ];
        controller.setPhotoAssets(assets);
        controller.setUsedPhotoIds({'used_photo'});

        controller.toggleSelect(1);

        expect(controller.selected[1], isFalse);
        expect(controller.selectedCount, 0);
      });

      test('日付制限が有効な場合、異なる日付の写真は選択できない', () {
        final assets = [
          createMockAsset('photo1', createDateTime: DateTime(2024, 1, 15)),
          createMockAsset('photo2', createDateTime: DateTime(2024, 1, 16)),
        ];
        controller.setPhotoAssets(assets);
        controller.setDateRestrictionEnabled(true);

        // 1枚目を選択（日付が記録される）
        controller.toggleSelect(0);
        expect(controller.selectedCount, 1);

        // 別の日付の写真は選択できない
        controller.toggleSelect(1);
        expect(controller.selectedCount, 1);
        expect(controller.selected[1], isFalse);
      });

      test('日付制限が有効でも同じ日付の写真は選択できる', () {
        final assets = [
          createMockAsset('photo1', createDateTime: DateTime(2024, 1, 15, 10)),
          createMockAsset('photo2', createDateTime: DateTime(2024, 1, 15, 14)),
        ];
        controller.setPhotoAssets(assets);
        controller.setDateRestrictionEnabled(true);

        controller.toggleSelect(0);
        controller.toggleSelect(1);

        expect(controller.selectedCount, 2);
        expect(controller.selected[0], isTrue);
        expect(controller.selected[1], isTrue);
      });

      test('境界外のインデックスでは何も起こらない', () {
        final assets = [createMockAsset('photo1')];
        controller.setPhotoAssets(assets);

        controller.toggleSelect(-1);
        controller.toggleSelect(1);
        controller.toggleSelect(999);

        expect(controller.selectedCount, 0);
      });
    });

    group('clearSelection', () {
      test('すべての選択をクリアする', () {
        final assets = [
          createMockAsset('photo1'),
          createMockAsset('photo2'),
          createMockAsset('photo3'),
        ];
        controller.setPhotoAssets(assets);
        controller.toggleSelect(0);
        controller.toggleSelect(1);
        expect(controller.selectedCount, 2);

        controller.clearSelection();

        expect(controller.selectedCount, 0);
        expect(controller.selected.every((s) => !s), isTrue);
      });
    });

    group('selectedPhotos / selectedCount', () {
      test('選択された写真のリストと数を正しく返す', () {
        final assets = [
          createMockAsset('photo1'),
          createMockAsset('photo2'),
          createMockAsset('photo3'),
        ];
        controller.setPhotoAssets(assets);

        controller.toggleSelect(0);
        controller.toggleSelect(2);

        expect(controller.selectedCount, 2);
        expect(controller.selectedPhotos.length, 2);
        expect(controller.selectedPhotos[0].id, 'photo1');
        expect(controller.selectedPhotos[1].id, 'photo3');
      });
    });

    group('setPhotoAssetsPreservingSelection', () {
      test('写真リスト更新時にIDベースで選択状態を保持する', () {
        final assets = [
          createMockAsset('photo1'),
          createMockAsset('photo2'),
          createMockAsset('photo3'),
        ];
        controller.setPhotoAssets(assets);
        controller.toggleSelect(0); // photo1を選択
        controller.toggleSelect(2); // photo3を選択

        // 順序が変わった新しいリスト（photo2が先頭、photo1とphoto3はそのまま存在）
        final updatedAssets = [
          createMockAsset('photo2'),
          createMockAsset('photo1'),
          createMockAsset('photo4'),
          createMockAsset('photo3'),
        ];
        controller.setPhotoAssetsPreservingSelection(updatedAssets);

        expect(controller.photoAssets.length, 4);
        expect(controller.selected[0], isFalse); // photo2: 未選択
        expect(controller.selected[1], isTrue); // photo1: 選択維持
        expect(controller.selected[2], isFalse); // photo4: 新規、未選択
        expect(controller.selected[3], isTrue); // photo3: 選択維持
        expect(controller.selectedCount, 2);
      });

      test('選択していた写真が新しいリストにない場合は選択が消える', () {
        final assets = [createMockAsset('photo1')];
        controller.setPhotoAssets(assets);
        controller.toggleSelect(0);
        expect(controller.selectedCount, 1);

        final updatedAssets = [
          createMockAsset('photo2'),
          createMockAsset('photo3'),
        ];
        controller.setPhotoAssetsPreservingSelection(updatedAssets);

        expect(controller.selectedCount, 0);
      });
    });

    group('usedPhotoIds管理', () {
      test('setUsedPhotoIdsで使用済みIDを設定する', () {
        controller.setUsedPhotoIds({'id1', 'id2'});
        expect(controller.usedPhotoIds, {'id1', 'id2'});
      });

      test('addUsedPhotoIdsで使用済みIDを追加する', () {
        controller.setUsedPhotoIds({'id1'});
        controller.addUsedPhotoIds(['id2', 'id3']);
        expect(controller.usedPhotoIds, {'id1', 'id2', 'id3'});
      });

      test('addUsedPhotoIdsで既存IDを追加しても通知されない', () {
        controller.setUsedPhotoIds({'id1', 'id2'});

        var notified = false;
        controller.addListener(() => notified = true);
        controller.addUsedPhotoIds(['id1', 'id2']);

        expect(notified, isFalse);
      });

      test('removeUsedPhotoIdsで使用済みIDを削除する', () {
        controller.setUsedPhotoIds({'id1', 'id2', 'id3'});
        controller.removeUsedPhotoIds(['id2']);
        expect(controller.usedPhotoIds, {'id1', 'id3'});
      });

      test('removeUsedPhotoIdsで存在しないIDを指定しても通知されない', () {
        controller.setUsedPhotoIds({'id1'});

        var notified = false;
        controller.addListener(() => notified = true);
        controller.removeUsedPhotoIds(['nonexistent']);

        expect(notified, isFalse);
      });
    });

    group('isPhotoUsed / canSelectPhoto', () {
      test('isPhotoUsedが使用済み写真を正しく判定する', () {
        final assets = [
          createMockAsset('photo1'),
          createMockAsset('used_photo'),
        ];
        controller.setPhotoAssets(assets);
        controller.setUsedPhotoIds({'used_photo'});

        expect(controller.isPhotoUsed(0), isFalse);
        expect(controller.isPhotoUsed(1), isTrue);
      });

      test('isPhotoUsedで境界外インデックスはfalseを返す', () {
        expect(controller.isPhotoUsed(-1), isFalse);
        expect(controller.isPhotoUsed(100), isFalse);
      });

      test('canSelectPhotoが選択可能性を正しく判定する', () {
        final assets = [
          createMockAsset('photo1'),
          createMockAsset('photo2'),
          createMockAsset('photo3'),
          createMockAsset('photo4'),
          createMockAsset('used_photo'),
        ];
        controller.setPhotoAssets(assets);
        controller.setUsedPhotoIds({'used_photo'});

        // 未選択・未使用・上限未達 -> 選択可能
        expect(controller.canSelectPhoto(0), isTrue);

        // 使用済み -> 選択不可
        expect(controller.canSelectPhoto(4), isFalse);

        // 3枚選択して上限到達
        controller.toggleSelect(0);
        controller.toggleSelect(1);
        controller.toggleSelect(2);

        // 上限到達で未選択 -> 選択不可
        expect(controller.canSelectPhoto(3), isFalse);

        // 既に選択済み -> 解除のため選択可能
        expect(controller.canSelectPhoto(0), isTrue);
      });

      test('canSelectPhotoで境界外インデックスはfalseを返す', () {
        expect(controller.canSelectPhoto(-1), isFalse);
        expect(controller.canSelectPhoto(100), isFalse);
      });
    });

    group('setDateRestrictionEnabled', () {
      test('日付制限を有効/無効に切り替える', () {
        controller.setDateRestrictionEnabled(true);

        final assets = [
          createMockAsset('photo1', createDateTime: DateTime(2024, 1, 15)),
          createMockAsset('photo2', createDateTime: DateTime(2024, 1, 16)),
        ];
        controller.setPhotoAssets(assets);

        // 日付制限ON: 異なる日付は選択不可
        controller.toggleSelect(0);
        controller.toggleSelect(1);
        expect(controller.selectedCount, 1);

        // 日付制限OFF: 異なる日付も選択可能
        controller.clearSelection();
        controller.setDateRestrictionEnabled(false);
        controller.toggleSelect(0);
        controller.toggleSelect(1);
        expect(controller.selectedCount, 2);
      });

      test('日付制限を無効にすると選択日付がクリアされる', () {
        final assets = [
          createMockAsset('photo1', createDateTime: DateTime(2024, 1, 15)),
          createMockAsset('photo2', createDateTime: DateTime(2024, 1, 16)),
        ];
        controller.setPhotoAssets(assets);
        controller.setDateRestrictionEnabled(true);

        // 1枚目を選択して日付を記録
        controller.toggleSelect(0);
        expect(controller.selectedCount, 1);

        // 日付制限を無効化 -> 日付制限がクリアされる
        controller.setDateRestrictionEnabled(false);

        // 別の日付の写真も選択可能
        controller.toggleSelect(1);
        expect(controller.selectedCount, 2);
      });
    });

    group('addCapturedPhoto', () {
      test('撮影した写真をリストの先頭に追加し自動選択する', () {
        final assets = [createMockAsset('photo1'), createMockAsset('photo2')];
        controller.setPhotoAssets(assets);

        final newPhoto = createMockAsset('captured1');
        controller.addCapturedPhoto(newPhoto);

        expect(controller.photoAssets.length, 3);
        expect(controller.photoAssets[0].id, 'captured1');
        expect(controller.selected[0], isTrue); // 自動選択
        expect(controller.selectedCount, 1);
      });

      test('既存の選択に加えて撮影写真が自動選択される', () {
        final assets = [createMockAsset('photo1'), createMockAsset('photo2')];
        controller.setPhotoAssets(assets);
        controller.toggleSelect(0);
        expect(controller.selectedCount, 1);

        final newPhoto = createMockAsset('captured1');
        controller.addCapturedPhoto(newPhoto);

        expect(controller.selectedCount, 2);
        expect(controller.selected[0], isTrue); // captured1 (先頭)
        expect(controller.selected[1], isTrue); // photo1 (既存の選択)
      });
    });

    group('refreshPhotosWithNewCapture', () {
      test('写真リストを更新し既存の選択を保持しつつ撮影写真を自動選択する', () {
        final assets = [createMockAsset('photo1'), createMockAsset('photo2')];
        controller.setPhotoAssets(assets);
        controller.toggleSelect(0); // photo1を選択

        final updatedAssets = [
          createMockAsset('captured1'),
          createMockAsset('photo1'),
          createMockAsset('photo2'),
        ];
        controller.refreshPhotosWithNewCapture(updatedAssets, 'captured1');

        expect(controller.photoAssets.length, 3);
        expect(controller.selected[0], isTrue); // captured1: 自動選択
        expect(controller.selected[1], isTrue); // photo1: 選択維持
        expect(controller.selected[2], isFalse); // photo2: 未選択のまま
        expect(controller.selectedCount, 2);
      });

      test('撮影写真IDがリストに存在しない場合は自動選択しない', () {
        final assets = [createMockAsset('photo1')];
        controller.setPhotoAssets(assets);

        final updatedAssets = [
          createMockAsset('photo1'),
          createMockAsset('photo2'),
        ];
        controller.refreshPhotosWithNewCapture(updatedAssets, 'nonexistent_id');

        expect(controller.selectedCount, 0);
      });
    });

    group('dispose', () {
      test('disposeでリソースがクリーンアップされる', () {
        // tearDownとの二重disposeを避けるため専用インスタンスを使用
        final disposableController = PhotoSelectionController();
        final assets = [createMockAsset('photo1'), createMockAsset('photo2')];
        disposableController.setPhotoAssets(assets);
        disposableController.setUsedPhotoIds({'used1'});
        disposableController.toggleSelect(0);

        // dispose実行
        disposableController.dispose();

        // dispose後にリスナー登録を試みるとエラーになることで確認
        expect(
          () => disposableController.addListener(() {}),
          throwsFlutterError,
        );
      });
    });
  });
}
