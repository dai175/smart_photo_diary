import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../models/diary_entry.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../core/service_locator.dart';
import '../core/service_registration.dart';
import '../services/interfaces/settings_service_interface.dart';
import 'interfaces/social_share_service_interface.dart';

/// 日記画像生成専用クラス
///
/// Canvas描画システムを使用して、日記の内容と写真を組み合わせた
/// 美しいシェア用画像を生成します。
class DiaryImageGenerator {
  // ============= 定数定義 =============

  /// 基準画像サイズ（Instagram Stories標準）
  static const double _baseWidth = 1080.0;
  static const double _baseHeight = 1920.0;

  /// スケール制限
  static const double _minScale = 0.8;
  static const double _maxScale = 2.0;

  /// ベースフォントサイズ（px）
  static const double _baseDateFontSize = 36.0;
  static const double _baseTitleFontSize = 66.0;
  static const double _baseTitleFontSizeLong = 56.0;
  static const double _baseContentFontSize = 38.0;
  static const double _baseContentFontSizeLong = 34.0;
  static const double _baseBrandFontSize = 28.0;

  /// ベーススペーシング（px）
  static const double _baseAfterDateSpacing = 32.0;
  static const double _baseAfterTitleSpacing = 40.0;

  /// テキスト長の閾値
  static const int _titleLengthThreshold = 20;
  static const int _titleMaxLengthThreshold = 30;
  static const int _contentLengthThreshold = 200;

  /// 最大行数
  static const int _titleMaxLines = 3;
  static const int _titleMaxLinesLong = 4;
  static const int _contentMaxLines = 15;

  // 旧: 最大文字数・最大枚数は未使用となったため削除

  /// 写真間のスペーシング
  static const double _photoSpacing = 6.0;

  /// DI用の公開コンストラクタ
  DiaryImageGenerator();

  /// ログサービスを取得
  ILoggingService get _logger => serviceLocator.get<ILoggingService>();

  /// 共有用画像を生成
  Future<Result<File>> generateImage({
    required DiaryEntry diary,
    required ShareFormat format,
    List<AssetEntity>? photos,
  }) async {
    try {
      _logger.info(
        '画像生成開始: ${format.displayName}',
        context: 'DiaryImageGenerator.generateImage',
        data: 'diary_id: ${diary.id}',
      );

      // 一時ディレクトリを取得
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'diary_${diary.id}_${format.name}_$timestamp.png';
      final outputFile = File('${tempDir.path}/$fileName');

      // キャンバスサイズを設定（スケール対応）
      final actualWidth = format.isHD ? format.scaledWidth : format.width;
      final actualHeight = format.isHD ? format.scaledHeight : format.height;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, actualWidth.toDouble(), actualHeight.toDouble()),
      );

      // 画像を描画（分離レイアウト既定）
      await _drawCompositeImageSplit(canvas, diary, format, photos);

      // Pictureからイメージに変換（スケール対応）
      final picture = recorder.endRecording();
      final image = await picture.toImage(actualWidth, actualHeight);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        return const Failure<File>(ImageGenerationException('画像データの変換に失敗しました'));
      }

      // ファイルに保存
      await outputFile.writeAsBytes(byteData.buffer.asUint8List());

      _logger.info(
        '画像生成完了',
        context: 'DiaryImageGenerator.generateImage',
        data:
            'file_path: ${outputFile.path}, size: ${(await outputFile.length())} bytes',
      );

      return Success<File>(outputFile);
    } catch (e) {
      _logger.error(
        '画像生成エラー',
        context: 'DiaryImageGenerator.generateImage',
        error: e,
      );
      return Failure<File>(
        ImageGenerationException('画像の生成に失敗しました', originalError: e),
      );
    }
  }

  /// 新: 分離レイアウト（写真とテキストを重ねない）
  Future<void> _drawCompositeImageSplit(
    Canvas canvas,
    DiaryEntry diary,
    ShareFormat format,
    List<AssetEntity>? photos,
  ) async {
    // ベース背景（ごく薄いグラデ）
    final w = (format.isHD ? format.scaledWidth : format.width).toDouble();
    final h = (format.isHD ? format.scaledHeight : format.height).toDouble();
    final baseBg = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(w, h),
      [const Color(0xFF0E0F12), const Color(0xFF151821)],
      [0.0, 1.0],
    );
    final bgPaint = Paint()..shader = baseBg;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // レイアウト領域を決定
    final split = _getSplitLayout(format);

    // 写真領域に描画（なければスキップ）
    if (photos != null && photos.isNotEmpty) {
      await _drawPhotosIntoArea(canvas, photos, split.photoRect, format);
    } else {
      // 写真が無い場合、写真領域も背景色で塗りつぶし（少し明るめ）
      final photoFill = Paint()..color = const Color(0xFF232632);
      canvas.drawRect(split.photoRect, photoFill);
    }

    // テキストパネル（ソリッド）
    _fillTextPanel(canvas, split.textRect, format);

    // テキスト描画
    await _drawTextElementsInArea(canvas, diary, format, split.textRect);

    // 最小ブランドはテキストパネル右下に
    _drawBrandingInArea(canvas, format, split.textRect);
  }

  /// 分離レイアウト用：領域に写真を描画
  Future<void> _drawPhotosIntoArea(
    Canvas canvas,
    List<AssetEntity> photos,
    Rect area,
    ShareFormat format,
  ) async {
    final gap = _photoSpacing * (format.isHD ? format.scale : 1.0);
    if (photos.length == 1) {
      final bytes = await photos.first.originBytes;
      if (bytes != null) {
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final image = frame.image;
        final src = _calculateCropRect(
          image.width.toDouble(),
          image.height.toDouble(),
          area.width,
          area.height,
        );
        canvas.drawImageRect(image, src, area, Paint());
      }
      return;
    }

    if (photos.length == 2) {
      if (format.isSquare) {
        final cellW = (area.width - gap) / 2;
        final rects = [
          Rect.fromLTWH(area.left, area.top, cellW, area.height),
          Rect.fromLTWH(area.left + cellW + gap, area.top, cellW, area.height),
        ];
        await _drawAssetsIntoRects(canvas, photos, rects);
      } else {
        final cellH = (area.height - gap) / 2;
        final rects = [
          Rect.fromLTWH(area.left, area.top, area.width, cellH),
          Rect.fromLTWH(area.left, area.top + cellH + gap, area.width, cellH),
        ];
        await _drawAssetsIntoRects(canvas, photos, rects);
      }
      return;
    }

    // 3枚（上2/下1）
    final topH = (area.height - gap) * 0.55;
    final bottomH = (area.height - gap) - topH;
    final topCellW = (area.width - gap) / 2;
    final rects = [
      Rect.fromLTWH(area.left, area.top, topCellW, topH),
      Rect.fromLTWH(area.left + topCellW + gap, area.top, topCellW, topH),
      Rect.fromLTWH(area.left, area.top + topH + gap, area.width, bottomH),
    ];
    await _drawAssetsIntoRects(canvas, photos, rects);
  }

  /// 分離レイアウトの領域（写真/テキスト）
  ({Rect photoRect, Rect textRect}) _getSplitLayout(ShareFormat format) {
    final w = (format.isHD ? format.scaledWidth : format.width).toDouble();
    final h = (format.isHD ? format.scaledHeight : format.height).toDouble();
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

  /// テキストパネルを塗りつぶし（ソリッド、非重ね）
  void _fillTextPanel(Canvas canvas, Rect area, ShareFormat format) {
    final fill = Paint()..color = const Color(0xFF0F1117);
    canvas.drawRect(area, fill);
  }

  /// 指定エリアに日付/タイトル/本文を描画（分離レイアウト用）
  Future<void> _drawTextElementsInArea(
    Canvas canvas,
    DiaryEntry diary,
    ShareFormat format,
    Rect contentArea,
  ) async {
    final textAreaPadding = format.isSquare
        ? 24.0
        : (format.isPortrait ? 28.0 : 24.0);
    final textArea = contentArea.deflate(textAreaPadding);

    // 初期フォントサイズ
    final baseSizes = _calculateTextSizes(format, diary);
    final spacing = _calculateSpacing(format);

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
          text: _formatDate(diary.date),
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: dateSize,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
            fontFamily: 'NotoSansJP',
            height: 1.4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: textArea.width);

      final titlePainter = TextPainter(
        text: TextSpan(
          text: diary.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            height: 1.3,
            letterSpacing: 0.5,
            fontFamily: 'NotoSansJP',
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 3,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: baseSizes.titleMaxLines, // タイトルは最大行を維持
      )..layout(maxWidth: textArea.width);

      final contentPainter = TextPainter(
        text: TextSpan(
          text: diary.content, // 全文
          style: TextStyle(
            color: Colors.white.withOpacity(0.98),
            fontSize: contentSize,
            height: contentLineHeight,
            letterSpacing: 0.4,
            fontFamily: 'NotoSansJP',
            fontWeight: FontWeight.w400,
            shadows: [
              Shadow(
                offset: const Offset(0, 0.5),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.2),
              ),
            ],
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
      text: TextSpan(
        text: _formatDate(diary.date),
        style: TextStyle(
          color: Colors.white.withOpacity(0.95),
          fontSize: dateSize,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
          fontFamily: 'NotoSansJP',
          height: 1.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textArea.width);
    datePainterFallback.paint(canvas, Offset(textArea.left, currentY));
    currentY += datePainterFallback.height + spacing.afterDate;

    if (diary.title.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: diary.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            height: 1.3,
            letterSpacing: 0.5,
            fontFamily: 'NotoSansJP',
          ),
        ),
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
        style: TextStyle(
          color: Colors.white.withOpacity(0.98),
          fontSize: contentSize,
          height: contentLineHeight,
          letterSpacing: 0.4,
          fontFamily: 'NotoSansJP',
          fontWeight: FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: maxLines > 0 ? maxLines : 1,
      ellipsis: '…',
    )..layout(maxWidth: textArea.width);
    tpContent.paint(canvas, Offset(textArea.left, currentY));
  }

  Future<void> _drawAssetsIntoRects(
    Canvas canvas,
    List<AssetEntity> assets,
    List<Rect> rects,
  ) async {
    for (int i = 0; i < rects.length && i < assets.length; i++) {
      final bytes = await assets[i].originBytes;
      if (bytes == null) continue;
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final src = _calculateCropRect(
        image.width.toDouble(),
        image.height.toDouble(),
        rects[i].width,
        rects[i].height,
      );
      canvas.drawImageRect(image, src, rects[i], Paint());
    }
  }

  /// 写真用オーバーレイ描画

  /// クロップ用の矩形を計算
  Rect _calculateCropRect(
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
  _TextSizes _calculateTextSizes(ShareFormat format, DiaryEntry diary) {
    // 画像サイズに基づく基準スケール計算
    final actualWidth = format.isHD ? format.scaledWidth : format.width;
    final actualHeight = format.isHD ? format.scaledHeight : format.height;

    // フォーマットに応じたスケール計算
    late final double baseScale;
    if (format.isSquare) {
      // 正方形の場合は幅基準でスケール計算
      baseScale = actualWidth / _baseWidth;
    } else {
      // 縦長の場合は幅と高さの平均
      final widthScale = actualWidth / _baseWidth;
      final heightScale = actualHeight / _baseHeight;
      baseScale = (widthScale + heightScale) / 2;
    }

    // 最小・最大スケールを制限
    final scale = baseScale.clamp(_minScale, _maxScale);

    final titleLength = diary.title.length;
    final contentLength = diary.content.length;

    // スケールに応じてフォントサイズを調整
    return _TextSizes(
      dateSize: (_baseDateFontSize * scale).round().toDouble(),
      titleSize: titleLength > _titleLengthThreshold
          ? (_baseTitleFontSizeLong * scale).round().toDouble()
          : (_baseTitleFontSize * scale).round().toDouble(),
      titleMaxLines: titleLength > _titleMaxLengthThreshold
          ? _titleMaxLinesLong
          : _titleMaxLines,
      contentSize: contentLength > _contentLengthThreshold
          ? (_baseContentFontSizeLong * scale).round().toDouble()
          : (_baseContentFontSize * scale).round().toDouble(),
      contentMaxLines: _contentMaxLines,
    );
  }

  /// スペーシングを計算
  _Spacing _calculateSpacing(ShareFormat format) {
    // 画像サイズに基づくスケール計算
    final actualWidth = format.isHD ? format.scaledWidth : format.width;
    final actualHeight = format.isHD ? format.scaledHeight : format.height;

    final widthScale = actualWidth / _baseWidth;
    final heightScale = actualHeight / _baseHeight;
    final scale = ((widthScale + heightScale) / 2).clamp(_minScale, _maxScale);

    return _Spacing(
      afterDate: (_baseAfterDateSpacing * scale).round().toDouble(),
      afterTitle: (_baseAfterTitleSpacing * scale).round().toDouble(),
    );
  }

  /// テキストパネル内の右下に最小限のブランドを配置
  void _drawBrandingInArea(Canvas canvas, ShareFormat format, Rect area) {
    final scale = (format.isHD ? format.scale : 1.0);
    final brandSpan = TextSpan(
      text: 'Smart Photo Diary',
      style: TextStyle(
        color: Colors.white.withOpacity(0.86),
        fontSize: _calculateBrandFontSize(format),
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

  /// ブランディング用フォントサイズを計算
  double _calculateBrandFontSize(ShareFormat format) {
    final actualWidth = format.isHD ? format.scaledWidth : format.width;
    final actualHeight = format.isHD ? format.scaledHeight : format.height;

    final widthScale = actualWidth / _baseWidth;
    final heightScale = actualHeight / _baseHeight;
    final scale = ((widthScale + heightScale) / 2).clamp(_minScale, _maxScale);

    return (_baseBrandFontSize * scale).round().toDouble();
  }

  /// 日付をフォーマット（多言語化対応）
  String _formatDate(DateTime date) {
    try {
      // SettingsServiceからロケールを取得
      Locale? locale;
      try {
        final settingsService = ServiceRegistration.get<ISettingsService>();
        locale = settingsService.locale;
      } catch (_) {
        locale = null;
      }
      final resolvedLocale = locale ?? ui.PlatformDispatcher.instance.locale;

      if (resolvedLocale.languageCode == 'ja') {
        // 日本語フォーマット
        final months = [
          '1月',
          '2月',
          '3月',
          '4月',
          '5月',
          '6月',
          '7月',
          '8月',
          '9月',
          '10月',
          '11月',
          '12月',
        ];
        return '${date.year}年 ${months[date.month - 1]} ${date.day}日';
      } else {
        // 英語フォーマット
        final months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];
        return '${months[date.month - 1]} ${date.day}, ${date.year}';
      }
    } catch (e) {
      // フォールバック：設定取得に失敗した場合はプラットフォームロケールを使用
      final platformLocale = ui.PlatformDispatcher.instance.locale;
      if (platformLocale.languageCode == 'ja') {
        final months = [
          '1月',
          '2月',
          '3月',
          '4月',
          '5月',
          '6月',
          '7月',
          '8月',
          '9月',
          '10月',
          '11月',
          '12月',
        ];
        return '${date.year}年 ${months[date.month - 1]} ${date.day}日';
      } else {
        final months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];
        return '${months[date.month - 1]} ${date.day}, ${date.year}';
      }
    }
  }
}

/// テキストサイズ設定
class _TextSizes {
  final double dateSize;
  final double titleSize;
  final int titleMaxLines;
  final double contentSize;
  final int contentMaxLines;

  _TextSizes({
    required this.dateSize,
    required this.titleSize,
    required this.titleMaxLines,
    required this.contentSize,
    required this.contentMaxLines,
  });
}

/// スペーシング設定
class _Spacing {
  final double afterDate;
  final double afterTitle;

  _Spacing({required this.afterDate, required this.afterTitle});
}
