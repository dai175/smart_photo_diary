import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/diary_length.dart';

void main() {
  group('DiaryLength', () {
    test('has exactly 2 values', () {
      expect(DiaryLength.values.length, 2);
    });

    test('short has index 0', () {
      expect(DiaryLength.short.index, 0);
    });

    test('standard has index 1', () {
      expect(DiaryLength.standard.index, 1);
    });

    test('values list contains short and standard', () {
      expect(DiaryLength.values, contains(DiaryLength.short));
      expect(DiaryLength.values, contains(DiaryLength.standard));
    });

    test('can be looked up by index', () {
      expect(DiaryLength.values[0], DiaryLength.short);
      expect(DiaryLength.values[1], DiaryLength.standard);
    });
  });
}
