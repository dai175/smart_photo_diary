import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/models/photo_type_filter.dart';
import 'package:smart_photo_diary/services/photo_query_service.dart';

class MockAssetEntity extends Mock implements AssetEntity {}

void main() {
  group('PhotoQueryService.filterByPhotoType', () {
    late List<MockAssetEntity> assets;
    const emptyScreenshotIds = <String>{};

    setUp(() {
      assets = List.generate(5, (i) {
        final entity = MockAssetEntity();
        when(() => entity.id).thenReturn('asset-$i');
        when(() => entity.subtype).thenReturn(0);
        when(() => entity.relativePath).thenReturn(null);
        return entity;
      });
    });

    test('all filter returns all assets unchanged', () {
      final result = PhotoQueryService.filterByPhotoType(
        assets,
        PhotoTypeFilter.all,
        emptyScreenshotIds,
      );
      expect(result.length, 5);
      expect(result, equals(assets));
    });

    test('photosOnly filter with empty list returns empty list', () {
      final result = PhotoQueryService.filterByPhotoType(
        [],
        PhotoTypeFilter.photosOnly,
        emptyScreenshotIds,
      );
      expect(result, isEmpty);
    });

    test('all filter with empty list returns empty list', () {
      final result = PhotoQueryService.filterByPhotoType(
        [],
        PhotoTypeFilter.all,
        emptyScreenshotIds,
      );
      expect(result, isEmpty);
    });

    group('screenshotAssetIds-based filtering', () {
      test('excludes assets whose IDs are in screenshotAssetIds', () {
        final photo = MockAssetEntity();
        when(() => photo.id).thenReturn('photo-1');
        when(() => photo.subtype).thenReturn(0);
        when(() => photo.relativePath).thenReturn(null);

        final screenshot = MockAssetEntity();
        when(() => screenshot.id).thenReturn('screenshot-1');
        when(() => screenshot.subtype).thenReturn(0);
        when(() => screenshot.relativePath).thenReturn(null);

        final screenshotIds = {'screenshot-1'};

        final result = PhotoQueryService.filterByPhotoType(
          [photo, screenshot],
          PhotoTypeFilter.photosOnly,
          screenshotIds,
        );

        expect(result.length, 1);
        expect(result.first, photo);
      });

      test('excludes multiple screenshots by ID', () {
        final photo = MockAssetEntity();
        when(() => photo.id).thenReturn('photo-1');
        when(() => photo.subtype).thenReturn(0);
        when(() => photo.relativePath).thenReturn(null);

        final ss1 = MockAssetEntity();
        when(() => ss1.id).thenReturn('ss-1');
        when(() => ss1.subtype).thenReturn(0);
        when(() => ss1.relativePath).thenReturn(null);

        final ss2 = MockAssetEntity();
        when(() => ss2.id).thenReturn('ss-2');
        when(() => ss2.subtype).thenReturn(0);
        when(() => ss2.relativePath).thenReturn(null);

        final screenshotIds = {'ss-1', 'ss-2'};

        final result = PhotoQueryService.filterByPhotoType(
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
        final photo = MockAssetEntity();
        when(() => photo.id).thenReturn('p1');
        when(() => photo.subtype).thenReturn(0);
        when(() => photo.relativePath).thenReturn('DCIM/Camera');

        final screenshot = MockAssetEntity();
        when(() => screenshot.id).thenReturn('s1');
        when(() => screenshot.subtype).thenReturn(0);
        when(() => screenshot.relativePath).thenReturn('Pictures/Screenshots');

        final result = PhotoQueryService.filterByPhotoType(
          [photo, screenshot],
          PhotoTypeFilter.photosOnly,
          emptyScreenshotIds,
        );

        expect(result.length, 1);
        expect(result.first, photo);
      });

      test('excludes assets with Screenshot in different cases', () {
        final upper = MockAssetEntity();
        when(() => upper.id).thenReturn('u1');
        when(() => upper.subtype).thenReturn(0);
        when(() => upper.relativePath).thenReturn('DCIM/SCREENSHOT');

        final mixed = MockAssetEntity();
        when(() => mixed.id).thenReturn('m1');
        when(() => mixed.subtype).thenReturn(0);
        when(() => mixed.relativePath).thenReturn('Pictures/ScreenShot');

        final normal = MockAssetEntity();
        when(() => normal.id).thenReturn('n1');
        when(() => normal.subtype).thenReturn(0);
        when(() => normal.relativePath).thenReturn('DCIM/Camera');

        final result = PhotoQueryService.filterByPhotoType(
          [upper, mixed, normal],
          PhotoTypeFilter.photosOnly,
          emptyScreenshotIds,
        );

        expect(result.length, 1);
        expect(result.first, normal);
      });

      test('handles null relativePath gracefully', () {
        final photo = MockAssetEntity();
        when(() => photo.id).thenReturn('p1');
        when(() => photo.subtype).thenReturn(0);
        when(() => photo.relativePath).thenReturn(null);

        final result = PhotoQueryService.filterByPhotoType(
          [photo],
          PhotoTypeFilter.photosOnly,
          emptyScreenshotIds,
        );

        expect(result.length, 1);
      });
    });
  });
}
