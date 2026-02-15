import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/services/diary_image/image_layout_calculator.dart';
import 'package:smart_photo_diary/services/interfaces/social_share_service_interface.dart';

void main() {
  DiaryEntry createDiary({
    String title = 'Test Title',
    String content = 'Test Content',
  }) {
    return DiaryEntry(
      id: 'test-id',
      date: DateTime(2025, 1, 1),
      title: title,
      content: content,
      photoIds: ['photo1'],
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );
  }

  group('getSplitLayout', () {
    test('portrait → 上部写真、下部テキスト', () {
      final layout = ImageLayoutCalculator.getSplitLayout(ShareFormat.portrait);
      // 写真が上部
      expect(layout.photoRect.top, 0);
      expect(layout.photoRect.left, 0);
      // テキストが写真の下
      expect(layout.textRect.top, greaterThan(layout.photoRect.bottom));
    });

    test('portraitHD → スケール適用された上部写真、下部テキスト', () {
      final layout = ImageLayoutCalculator.getSplitLayout(
        ShareFormat.portraitHD,
      );
      expect(layout.photoRect.top, 0);
      expect(layout.textRect.top, greaterThan(layout.photoRect.bottom));
      // HD版は幅がscaledWidth
      expect(
        layout.photoRect.width,
        ShareFormat.portraitHD.scaledWidth.toDouble(),
      );
    });

    test('square → 左部写真、右部テキスト', () {
      final layout = ImageLayoutCalculator.getSplitLayout(ShareFormat.square);
      // 写真が左
      expect(layout.photoRect.left, 0);
      expect(layout.photoRect.top, 0);
      // テキストが写真の右
      expect(layout.textRect.left, greaterThan(layout.photoRect.right));
    });

    test('各フォーマットでphotoRectとtextRectが重ならない', () {
      for (final format in ShareFormat.values) {
        final layout = ImageLayoutCalculator.getSplitLayout(format);
        final intersection = layout.photoRect.intersect(layout.textRect);
        expect(
          intersection.isEmpty ||
              intersection.width <= 0 ||
              intersection.height <= 0,
          isTrue,
          reason: '$format: photoRect and textRect should not overlap',
        );
      }
    });
  });

  group('calculateCropRect', () {
    test('画像が横長 → 高さに合わせてクロップ', () {
      final rect = ImageLayoutCalculator.calculateCropRect(
        2000, // imageWidth (横長)
        1000, // imageHeight
        500, // targetWidth
        500, // targetHeight (1:1)
      );
      // 高さはそのまま、幅をクロップ
      expect(rect.height, 1000);
      expect(rect.width, 1000);
      // 中央クロップ
      expect(rect.left, 500);
      expect(rect.top, 0);
    });

    test('画像が縦長 → 幅に合わせてクロップ', () {
      final rect = ImageLayoutCalculator.calculateCropRect(
        1000, // imageWidth
        2000, // imageHeight (縦長)
        500, // targetWidth
        500, // targetHeight (1:1)
      );
      // 幅はそのまま、高さをクロップ
      expect(rect.width, 1000);
      expect(rect.height, 1000);
      expect(rect.left, 0);
      // 中央クロップ
      expect(rect.top, 500);
    });

    test('同アスペクト比 → クロップなし（全体）', () {
      final rect = ImageLayoutCalculator.calculateCropRect(
        1000,
        1000,
        500,
        500,
      );
      expect(rect.left, 0);
      expect(rect.top, 0);
      expect(rect.width, 1000);
      expect(rect.height, 1000);
    });
  });

  group('calculateTextSizes', () {
    test('portrait + 短いタイトル → baseTitleFontSize使用', () {
      final diary = createDiary(title: 'Short');
      final sizes = ImageLayoutCalculator.calculateTextSizes(
        ShareFormat.portrait,
        diary,
      );
      expect(sizes.titleSize, greaterThan(0));
      expect(sizes.titleMaxLines, ImageLayoutCalculator.titleMaxLines);
    });

    test('portrait + 長いタイトル(>20文字) → baseTitleFontSizeLong使用', () {
      final diary = createDiary(title: 'A' * 25);
      final sizes = ImageLayoutCalculator.calculateTextSizes(
        ShareFormat.portrait,
        diary,
      );
      // 長いタイトルは小さいフォント
      final shortDiary = createDiary(title: 'Short');
      final shortSizes = ImageLayoutCalculator.calculateTextSizes(
        ShareFormat.portrait,
        shortDiary,
      );
      expect(sizes.titleSize, lessThan(shortSizes.titleSize));
    });

    test('portrait + 長いタイトル(>30文字) → titleMaxLinesLong', () {
      final diary = createDiary(title: 'A' * 35);
      final sizes = ImageLayoutCalculator.calculateTextSizes(
        ShareFormat.portrait,
        diary,
      );
      expect(sizes.titleMaxLines, ImageLayoutCalculator.titleMaxLinesLong);
    });

    test('portrait + 長いコンテンツ(>200文字) → baseContentFontSizeLong', () {
      final diary = createDiary(content: 'A' * 250);
      final sizes = ImageLayoutCalculator.calculateTextSizes(
        ShareFormat.portrait,
        diary,
      );
      final shortDiary = createDiary(content: 'Short');
      final shortSizes = ImageLayoutCalculator.calculateTextSizes(
        ShareFormat.portrait,
        shortDiary,
      );
      expect(sizes.contentSize, lessThan(shortSizes.contentSize));
    });

    test('square → 正のフォントサイズが計算される', () {
      final diary = createDiary();
      final sizes = ImageLayoutCalculator.calculateTextSizes(
        ShareFormat.square,
        diary,
      );
      expect(sizes.dateSize, greaterThan(0));
      expect(sizes.titleSize, greaterThan(0));
      expect(sizes.contentSize, greaterThan(0));
    });
  });

  group('calculateSpacing', () {
    test('各フォーマットでafterDate/afterTitleが正のdouble', () {
      for (final format in ShareFormat.values) {
        final spacing = ImageLayoutCalculator.calculateSpacing(format);
        expect(
          spacing.afterDate,
          greaterThan(0),
          reason: '$format afterDate should be positive',
        );
        expect(
          spacing.afterTitle,
          greaterThan(0),
          reason: '$format afterTitle should be positive',
        );
      }
    });
  });

  group('calculateBrandFontSize', () {
    test('各フォーマットで正のdouble', () {
      for (final format in ShareFormat.values) {
        final size = ImageLayoutCalculator.calculateBrandFontSize(format);
        expect(
          size,
          greaterThan(0),
          reason: '$format brand font size should be positive',
        );
      }
    });
  });
}
