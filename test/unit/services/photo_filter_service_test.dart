import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/models/photo_type_filter.dart';
import 'package:smart_photo_diary/services/photo_filter_service.dart';

class MockAssetEntity extends Mock implements AssetEntity {}

MockAssetEntity createMockAsset(
  String id, {
  String? relativePath,
  int subtype = 0,
}) {
  final entity = MockAssetEntity();
  when(() => entity.id).thenReturn(id);
  when(() => entity.subtype).thenReturn(subtype);
  when(() => entity.relativePath).thenReturn(relativePath);
  return entity;
}

void main() {
  group('PhotoFilterService.filterByPhotoType', () {
    late List<MockAssetEntity> assets;
    const emptyScreenshotIds = <String>{};

    setUp(() {
      assets = List.generate(5, (i) => createMockAsset('asset-$i'));
    });

    test('all filter returns all assets unchanged', () {
      final result = PhotoFilterService.filterByPhotoType(
        assets,
        PhotoTypeFilter.all,
        emptyScreenshotIds,
      );
      expect(result.length, 5);
      expect(result, equals(assets));
    });

    test('photosOnly filter with empty list returns empty list', () {
      final result = PhotoFilterService.filterByPhotoType(
        [],
        PhotoTypeFilter.photosOnly,
        emptyScreenshotIds,
      );
      expect(result, isEmpty);
    });

    test('all filter with empty list returns empty list', () {
      final result = PhotoFilterService.filterByPhotoType(
        [],
        PhotoTypeFilter.all,
        emptyScreenshotIds,
      );
      expect(result, isEmpty);
    });

    group('screenshotAssetIds-based filtering', () {
      test('excludes assets whose IDs are in screenshotAssetIds', () {
        final photo = createMockAsset('photo-1');
        final screenshot = createMockAsset('screenshot-1');
        final screenshotIds = {'screenshot-1'};

        final result = PhotoFilterService.filterByPhotoType(
          [photo, screenshot],
          PhotoTypeFilter.photosOnly,
          screenshotIds,
        );

        expect(result.length, 1);
        expect(result.first, photo);
      });

      test('excludes multiple screenshots by ID', () {
        final photo = createMockAsset('photo-1');
        final ss1 = createMockAsset('ss-1');
        final ss2 = createMockAsset('ss-2');
        final screenshotIds = {'ss-1', 'ss-2'};

        final result = PhotoFilterService.filterByPhotoType(
          [photo, ss1, ss2],
          PhotoTypeFilter.photosOnly,
          screenshotIds,
        );

        expect(result.length, 1);
        expect(result.first, photo);
      });
    });

    group('photosOnly filter on Android-like assets (path-based)', () {
      test('excludes assets with screenshot in relativePath', () {
        final photo = createMockAsset('p1', relativePath: 'DCIM/Camera');
        final screenshot = createMockAsset(
          's1',
          relativePath: 'Pictures/Screenshots',
        );

        final result = PhotoFilterService.filterByPhotoType(
          [photo, screenshot],
          PhotoTypeFilter.photosOnly,
          emptyScreenshotIds,
        );

        expect(result.length, 1);
        expect(result.first, photo);
      });

      test('excludes assets with Screenshot in different cases', () {
        final upper = createMockAsset('u1', relativePath: 'DCIM/SCREENSHOT');
        final mixed = createMockAsset(
          'm1',
          relativePath: 'Pictures/ScreenShot',
        );
        final normal = createMockAsset('n1', relativePath: 'DCIM/Camera');

        final result = PhotoFilterService.filterByPhotoType(
          [upper, mixed, normal],
          PhotoTypeFilter.photosOnly,
          emptyScreenshotIds,
        );

        expect(result.length, 1);
        expect(result.first, normal);
      });

      test('handles null relativePath gracefully', () {
        final photo = createMockAsset('p1');

        final result = PhotoFilterService.filterByPhotoType(
          [photo],
          PhotoTypeFilter.photosOnly,
          emptyScreenshotIds,
        );

        expect(result.length, 1);
      });
    });
  });
}
