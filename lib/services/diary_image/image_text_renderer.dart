import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models/diary_entry.dart';
import '../../core/service_registration.dart';
import '../ai/diary_locale_utils.dart';
import '../interfaces/settings_service_interface.dart';
import '../interfaces/social_share_service_interface.dart';
import 'image_layout_calculator.dart';

/// テキスト・ブランディング描画ユーティリティ
class ImageTextRenderer {
  ImageTextRenderer._();

  /// テキストパネルを塗りつぶし（ソリッド、非重ね）
  static void fillTextPanel(Canvas canvas, Rect area, ShareFormat format) {
    final fill = Paint()..color = const Color(0xFF0F1117);
    canvas.drawRect(area, fill);
  }

  // ── スタイルヘルパー ──────────────────────────────────

  static TextStyle _dateStyle(double size) => TextStyle(
    color: Colors.white.withValues(alpha: 0.95),
    fontSize: size,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.8,
    fontFamily: 'NotoSansJP',
    height: 1.4,
  );

  static TextStyle _titleStyle(double size, {bool withShadows = false}) =>
      TextStyle(
        color: Colors.white,
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: 0.5,
        fontFamily: 'NotoSansJP',
        shadows: withShadows
            ? [
                Shadow(
                  offset: const Offset(0, 1),
                  blurRadius: 3,
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ]
            : null,
      );

  static TextStyle _contentStyle(
    double size,
    double lineHeight, {
    bool withShadows = false,
  }) => TextStyle(
    color: Colors.white.withValues(alpha: 0.98),
    fontSize: size,
    height: lineHeight,
    letterSpacing: 0.4,
    fontFamily: 'NotoSansJP',
    fontWeight: FontWeight.w400,
    shadows: withShadows
        ? [
            Shadow(
              offset: const Offset(0, 0.5),
              blurRadius: 2,
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ]
        : null,
  );

  // ── 描画メソッド ──────────────────────────────────

  /// 指定エリアに日付/タイトル/本文を描画（分離レイアウト用）
  static void drawTextElementsInArea(
    Canvas canvas,
    DiaryEntry diary,
    ShareFormat format,
    Rect contentArea,
  ) {
    final textAreaPadding = format.isSquare
        ? 24.0
        : (format.isPortrait ? 28.0 : 24.0);
    final textArea = contentArea.deflate(textAreaPadding);

    // 初期フォントサイズ
    final baseSizes = ImageLayoutCalculator.calculateTextSizes(format, diary);
    final spacing = ImageLayoutCalculator.calculateSpacing(format);

    // 最小フォントサイズ（可読性の下限）
    final minTitle = 36.0; // sp
    final minContent = 22.0; // sp
    double titleSize = baseSizes.titleSize;
    double contentSize = baseSizes.contentSize;
    double dateSize = baseSizes.dateSize; // 日付は基本維持
    double contentLineHeight = 1.6;

    // 計測しながら縮小して全文を収める
    for (int i = 0; i < 24; i++) {
      // 計測
      final datePainter = TextPainter(
        text: TextSpan(
          text: formatDate(diary.date),
          style: _dateStyle(dateSize),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: textArea.width);

      final titlePainter = TextPainter(
        text: TextSpan(
          text: diary.title,
          style: _titleStyle(titleSize, withShadows: true),
        ),
        textDirection: TextDirection.ltr,
        maxLines: baseSizes.titleMaxLines, // タイトルは最大行を維持
      )..layout(maxWidth: textArea.width);

      final contentPainter = TextPainter(
        text: TextSpan(
          text: diary.content, // 全文
          style: _contentStyle(
            contentSize,
            contentLineHeight,
            withShadows: true,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: textArea.width);

      final totalHeight =
          datePainter.height +
          spacing.afterDate +
          (diary.title.isNotEmpty
              ? titlePainter.height + spacing.afterTitle
              : 0) +
          contentPainter.height;

      if (totalHeight <= textArea.height) {
        // 収まったので描画して終了
        double currentY = textArea.top;
        datePainter.paint(canvas, Offset(textArea.left, currentY));
        currentY += datePainter.height + spacing.afterDate;

        if (diary.title.isNotEmpty) {
          titlePainter.paint(canvas, Offset(textArea.left, currentY));
          currentY += titlePainter.height + spacing.afterTitle;
        }

        contentPainter.paint(canvas, Offset(textArea.left, currentY));
        return;
      }

      // 収まらない場合は段階的に縮小
      if (contentSize > minContent) {
        contentSize = (contentSize - 2).clamp(minContent, contentSize);
      } else if (titleSize > minTitle) {
        titleSize = (titleSize - 2).clamp(minTitle, titleSize);
      } else if (contentLineHeight > 1.4) {
        contentLineHeight -= 0.05;
      } else {
        break; // 最小まで下げても収まらない場合は抜ける（実質ありえない長文対策）
      }
    }

    // フォールバック：ここに来るのは極端な長文だけ。末尾に…を付けて収める
    double currentY = textArea.top;
    final datePainterFallback = TextPainter(
      text: TextSpan(text: formatDate(diary.date), style: _dateStyle(dateSize)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textArea.width);
    datePainterFallback.paint(canvas, Offset(textArea.left, currentY));
    currentY += datePainterFallback.height + spacing.afterDate;

    if (diary.title.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(text: diary.title, style: _titleStyle(titleSize)),
        textDirection: TextDirection.ltr,
        maxLines: baseSizes.titleMaxLines,
        ellipsis: '…',
      )..layout(maxWidth: textArea.width);
      tp.paint(canvas, Offset(textArea.left, currentY));
      currentY += tp.height + spacing.afterTitle;
    }

    final remainingHeight = textArea.bottom - currentY;
    final maxLines = (remainingHeight / (contentSize * contentLineHeight))
        .floor();
    final tpContent = TextPainter(
      text: TextSpan(
        text: diary.content,
        style: _contentStyle(contentSize, contentLineHeight),
      ),
      textDirection: TextDirection.ltr,
      maxLines: maxLines > 0 ? maxLines : 1,
      ellipsis: '…',
    )..layout(maxWidth: textArea.width);
    tpContent.paint(canvas, Offset(textArea.left, currentY));
  }

  /// テキストパネル内の右下に最小限のブランドを配置
  static void drawBrandingInArea(Canvas canvas, ShareFormat format, Rect area) {
    final scale = (format.isHD ? format.scale : 1.0);
    final brandSpan = TextSpan(
      text: 'Smart Photo Diary',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.86),
        fontSize: ImageLayoutCalculator.calculateBrandFontSize(format),
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        fontFamily: 'NotoSansJP',
      ),
    );
    final tp = TextPainter(text: brandSpan, textDirection: TextDirection.ltr);
    tp.layout();
    final margin = 20.0 * scale;
    final x = area.right - tp.width - margin;
    final y = area.bottom - tp.height - margin;
    tp.paint(canvas, Offset(x, y));
  }

  /// 日付をフォーマット（多言語化対応）
  static String formatDate(DateTime date) {
    Locale locale;
    try {
      final settingsService = ServiceRegistration.get<ISettingsService>();
      locale = settingsService.locale ?? ui.PlatformDispatcher.instance.locale;
    } catch (_) {
      locale = ui.PlatformDispatcher.instance.locale;
    }
    return DiaryLocaleUtils.formatDate(date, locale);
  }
}
