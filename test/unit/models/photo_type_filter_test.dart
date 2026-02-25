import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/photo_type_filter.dart';

void main() {
  group('PhotoTypeFilter', () {
    test('has exactly 2 values', () {
      expect(PhotoTypeFilter.values.length, 2);
    });

    test('all is index 0', () {
      expect(PhotoTypeFilter.all.index, 0);
    });

    test('photosOnly is index 1', () {
      expect(PhotoTypeFilter.photosOnly.index, 1);
    });

    test('values can be looked up by index', () {
      expect(PhotoTypeFilter.values[0], PhotoTypeFilter.all);
      expect(PhotoTypeFilter.values[1], PhotoTypeFilter.photosOnly);
    });
  });
}
