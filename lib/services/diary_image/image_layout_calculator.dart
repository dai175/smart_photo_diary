import 'dart:ui';
import '../interfaces/social_share_service_interface.dart';
import '../../models/diary_entry.dart';

/// テキストサイズ設定
class TextSizes {
  final double dateSize;
  final double titleSize;
  final int titleMaxLines;
  final double contentSize;
  final int contentMaxLines;

  TextSizes({
    required this.dateSize,
    required this.titleSize,
    required this.titleMaxLines,
    required this.contentSize,
    required this.contentMaxLines,
  });
}

/// スペーシング設定
class Spacing {
  final double afterDate;
  final double afterTitle;

  Spacing({required this.afterDate, required this.afterTitle});
}

/// 画像レイアウト・サイズ計算ユーティリティ
class ImageLayoutCalculator {
  ImageLayoutCalculator._();

  /// 基準画像サイズ（Instagram Stories標準）
  static const double baseWidth = 1080.0;
  static const double baseHeight = 1920.0;

  /// スケール制限
  static const double minScale = 0.8;
  static const double maxScale = 2.0;

  /// ベースフォントサイズ（px）
  static const double baseDateFontSize = 36.0;
  static const double baseTitleFontSize = 66.0;
  static const double baseTitleFontSizeLong = 56.0;
  static const double baseContentFontSize = 38.0;
  static const double baseContentFontSizeLong = 34.0;
  static const double baseBrandFontSize = 28.0;

  /// ベーススペーシング（px）
  static const double baseAfterDateSpacing = 32.0;
  static const double baseAfterTitleSpacing = 40.0;

  /// テキスト長の閾値
  static const int titleLengthThreshold = 20;
  static const int titleMaxLengthThreshold = 30;
  static const int contentLengthThreshold = 200;

  /// 最大行数
  static const int titleMaxLines = 3;
  static const int titleMaxLinesLong = 4;
  static const int contentMaxLines = 15;

  /// 写真間のスペーシング
  static const double photoSpacing = 6.0;

  /// フォーマットに基づくスケール係数を計算（幅・高さの平均、clamp済み）
  static double _calculateScale(ShareFormat format) {
    final widthScale = format.actualWidth / baseWidth;
    final heightScale = format.actualHeight / baseHeight;
    return ((widthScale + heightScale) / 2).clamp(minScale, maxScale);
  }

  /// 分離レイアウトの領域（写真/テキスト）
  static ({Rect photoRect, Rect textRect}) getSplitLayout(ShareFormat format) {
    final w = format.actualWidth.toDouble();
    final h = format.actualHeight.toDouble();
    final scale = (format.isHD ? format.scale : 1.0);
    final gap = 12.0 * scale;

    if (format.isSquare) {
      final double photoW = (w * 0.56).clamp(0.0, w - 80.0 * scale).toDouble();
      final photoRect = Rect.fromLTWH(0, 0, photoW, h);
      final textRect = Rect.fromLTWH(
        photoRect.right + gap,
        0,
        w - photoRect.width - gap,
        h,
      );
      return (photoRect: photoRect, textRect: textRect);
    }

    // 縦長: 上部に写真、下部にテキスト
    final double photoH = (h * 0.62).clamp(0.0, h - 200.0 * scale).toDouble();
    final photoRect = Rect.fromLTWH(0, 0, w, photoH);
    final textRect = Rect.fromLTWH(
      0,
      photoRect.bottom + gap,
      w,
      h - photoH - gap,
    );
    return (photoRect: photoRect, textRect: textRect);
  }

  /// クロップ用の矩形を計算
  static Rect calculateCropRect(
    double imageWidth,
    double imageHeight,
    double targetWidth,
    double targetHeight,
  ) {
    final imageAspect = imageWidth / imageHeight;
    final targetAspect = targetWidth / targetHeight;

    double cropWidth, cropHeight;
    double offsetX = 0, offsetY = 0;

    if (imageAspect > targetAspect) {
      // 画像が横長 - 高さに合わせて幅をクロップ
      cropHeight = imageHeight;
      cropWidth = cropHeight * targetAspect;
      offsetX = (imageWidth - cropWidth) / 2;
    } else {
      // 画像が縦長 - 幅に合わせて高さをクロップ
      cropWidth = imageWidth;
      cropHeight = cropWidth / targetAspect;
      offsetY = (imageHeight - cropHeight) / 2;
    }

    return Rect.fromLTWH(offsetX, offsetY, cropWidth, cropHeight);
  }

  /// フォーマットに応じたテキストサイズを計算
  static TextSizes calculateTextSizes(ShareFormat format, DiaryEntry diary) {
    // フォーマットに応じたスケール計算
    late final double scale;
    if (format.isSquare) {
      // 正方形の場合は幅基準でスケール計算
      scale = (format.actualWidth / baseWidth).clamp(minScale, maxScale);
    } else {
      scale = _calculateScale(format);
    }

    final titleLen = diary.title.length;
    final contentLen = diary.content.length;

    // スケールに応じてフォントサイズを調整
    return TextSizes(
      dateSize: (baseDateFontSize * scale).round().toDouble(),
      titleSize: titleLen > titleLengthThreshold
          ? (baseTitleFontSizeLong * scale).round().toDouble()
          : (baseTitleFontSize * scale).round().toDouble(),
      titleMaxLines: titleLen > titleMaxLengthThreshold
          ? ImageLayoutCalculator.titleMaxLinesLong
          : ImageLayoutCalculator.titleMaxLines,
      contentSize: contentLen > contentLengthThreshold
          ? (baseContentFontSizeLong * scale).round().toDouble()
          : (baseContentFontSize * scale).round().toDouble(),
      contentMaxLines: ImageLayoutCalculator.contentMaxLines,
    );
  }

  /// スペーシングを計算
  static Spacing calculateSpacing(ShareFormat format) {
    final scale = _calculateScale(format);

    return Spacing(
      afterDate: (baseAfterDateSpacing * scale).round().toDouble(),
      afterTitle: (baseAfterTitleSpacing * scale).round().toDouble(),
    );
  }

  /// ブランディング用フォントサイズを計算
  static double calculateBrandFontSize(ShareFormat format) {
    final scale = _calculateScale(format);

    return (baseBrandFontSize * scale).round().toDouble();
  }
}
