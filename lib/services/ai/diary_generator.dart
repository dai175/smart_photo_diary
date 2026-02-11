import 'dart:typed_data';
import 'dart:ui';
import 'ai_service_interface.dart';
import 'gemini_api_client.dart';
import '../interfaces/logging_service_interface.dart';
import '../../core/service_locator.dart';
import 'diary_locale_utils.dart';
import 'diary_time_segment.dart';
import 'diary_prompt_builder.dart';

/// 日記生成を担当するサービス
class DiaryGenerator {
  final GeminiApiClient _apiClient;

  DiaryGenerator({GeminiApiClient? apiClient})
    : _apiClient = apiClient ?? GeminiApiClient();

  ILoggingService get _logger => serviceLocator.get<ILoggingService>();

  /// 画像から直接日記を生成
  Future<DiaryGenerationResult> generateFromImage({
    required Uint8List imageData,
    required DateTime date,
    String? location,
    List<DateTime>? photoTimes,
    String? prompt,
    required bool isOnline,
    required Locale locale,
  }) async {
    if (!isOnline) {
      throw Exception(
        DiaryLocaleUtils.isJapanese(locale)
            ? 'オフライン状態では日記を生成できません'
            : 'Cannot generate a diary while offline',
      );
    }

    try {
      // プロンプト種別分析と最適化パラメータ取得
      final promptType = DiaryPromptBuilder.analyzePromptType(prompt);
      final optimParams = DiaryPromptBuilder.getOptimizationParams(
        promptType,
        locale,
      );
      final emphasis = optimParams['emphasis'] as String;
      final maxTokens = optimParams['maxTokens'] as int;

      final finalPrompt = DiaryPromptBuilder.buildSingleImagePrompt(
        locale: locale,
        photoTimes: photoTimes,
        location: location,
        customPrompt: prompt,
        emphasis: emphasis,
      );

      // デバッグログ: プロンプト統合確認（感情深掘り型対応）
      _logger.debug(
        'AI生成プロンプト統合確認',
        context: 'generateFromImage',
        data: {
          'カスタムプロンプト': prompt ?? 'なし',
          'プロンプト種別': promptType,
          'maxTokens': maxTokens,
          'emphasis': emphasis,
          'locale': locale.toLanguageTag(),
          '統合後プロンプト長': finalPrompt.length,
          '感情深掘り型プロンプト統合': prompt != null ? '成功' : 'なし',
        },
      );

      final response = await _apiClient.sendVisionRequest(
        prompt: finalPrompt,
        imageData: imageData,
        maxOutputTokens: maxTokens, // 生成ロジック最適化: プロンプト種別に応じた動的調整
      );

      if (response != null) {
        final content = _apiClient.extractTextFromResponse(response);
        if (content != null) {
          return _parseGeneratedDiary(content, locale);
        }
      }

      // APIエラーの場合は例外を再スロー
      throw Exception(
        DiaryLocaleUtils.isJapanese(locale)
            ? 'AI日記生成に失敗しました: APIレスポンスが不正です'
            : 'Failed to generate the diary: invalid API response',
      );
    } catch (e) {
      _logger.error('画像ベース日記生成エラー', context: 'generateFromImage', error: e);
      // エラーが発生した場合は例外を再スローして、上位層でクレジット消費を防ぐ
      rethrow;
    }
  }

  /// 複数画像から順次日記を生成
  Future<DiaryGenerationResult> generateFromMultipleImages({
    required List<({Uint8List imageData, DateTime time})> imagesWithTimes,
    String? location,
    String? prompt,
    Function(int current, int total)? onProgress,
    required bool isOnline,
    required Locale locale,
  }) async {
    if (imagesWithTimes.isEmpty) {
      throw Exception(
        DiaryLocaleUtils.isJapanese(locale)
            ? '画像が提供されていません'
            : 'No images were provided',
      );
    }

    if (!isOnline) {
      throw Exception(
        DiaryLocaleUtils.isJapanese(locale)
            ? 'オフライン状態では日記を生成できません'
            : 'Cannot generate a diary while offline',
      );
    }

    try {
      // 時刻順にソート
      final sortedImages = List.from(imagesWithTimes);
      sortedImages.sort((a, b) => a.time.compareTo(b.time));

      // 各画像を順次分析
      final List<String> photoAnalyses = [];

      for (int i = 0; i < sortedImages.length; i++) {
        final imageWithTime = sortedImages[i];
        onProgress?.call(i + 1, sortedImages.length);

        _logger.info(
          '画像分析中',
          context: 'generateFromMultipleImages',
          data: {'現在': i + 1, '総数': sortedImages.length},
        );

        final analysis = await _analyzeImage(
          imageWithTime.imageData,
          imageWithTime.time,
          location,
          locale,
        );

        photoAnalyses.add(analysis);
      }

      // 全分析結果を統合して日記を生成
      final List<DateTime> photoTimesList = sortedImages
          .map<DateTime>((e) => e.time)
          .toList();
      return await _generateDiaryFromAnalyses(
        photoAnalyses,
        photoTimesList,
        location,
        prompt,
        locale,
      );
    } catch (e) {
      _logger.error(
        '複数画像日記生成エラー',
        context: 'generateFromMultipleImages',
        error: e,
      );
      // エラーが発生した場合は例外を再スローして、上位層でクレジット消費を防ぐ
      rethrow;
    }
  }

  /// 生成された日記テキストをタイトルと本文に分割
  DiaryGenerationResult _parseGeneratedDiary(
    String generatedText,
    Locale locale,
  ) {
    try {
      final titleMatchJa = RegExp(
        r'【タイトル】\s*(.+?)(?=【本文】|$)',
        dotAll: true,
      ).firstMatch(generatedText);
      final contentMatchJa = RegExp(
        r'【本文】\s*(.+?)$',
        dotAll: true,
      ).firstMatch(generatedText);

      String? title = titleMatchJa?.group(1)?.trim();
      String? content = contentMatchJa?.group(1)?.trim();

      if (title == null ||
          title.isEmpty ||
          content == null ||
          content.isEmpty) {
        final titleMatchEn = RegExp(
          r'\[Title\]\s*(.+?)(?=\[Body\]|$)',
          dotAll: true,
          caseSensitive: false,
        ).firstMatch(generatedText);
        final contentMatchEn = RegExp(
          r'\[Body\]\s*(.+?)$',
          dotAll: true,
          caseSensitive: false,
        ).firstMatch(generatedText);

        title = titleMatchEn?.group(1)?.trim() ?? title;
        content = contentMatchEn?.group(1)?.trim() ?? content;
      }

      if (title == null ||
          title.isEmpty ||
          content == null ||
          content.isEmpty) {
        final lines = generatedText
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
        if (lines.isNotEmpty) {
          title = lines.first.trim();
          content = lines.skip(1).join('\n').trim();
        }
      }

      final defaultTitle = DiaryLocaleUtils.isJapanese(locale)
          ? '今日の日記'
          : "Today's Journal";

      return DiaryGenerationResult(
        title: (title == null || title.isEmpty) ? defaultTitle : title,
        content: (content == null || content.isEmpty)
            ? generatedText.trim()
            : content,
      );
    } catch (e) {
      _logger.error('日記パース中のエラー', context: '_parseGeneratedDiary', error: e);
      final defaultTitle = DiaryLocaleUtils.isJapanese(locale)
          ? '今日の日記'
          : "Today's Journal";
      return DiaryGenerationResult(
        title: defaultTitle,
        content: generatedText.trim(),
      );
    }
  }

  /// 1枚の画像を分析して説明を取得
  Future<String> _analyzeImage(
    Uint8List imageData,
    DateTime time,
    String? location,
    Locale locale,
  ) async {
    final timeStr = DiaryLocaleUtils.formatTime(time, locale);
    final timeOfDay = DiaryTimeSegment.getTimeOfDay(time, locale);
    final isJapanese = DiaryLocaleUtils.isJapanese(locale);
    final timeLabel = isJapanese
        ? '$timeStr($timeOfDay)'
        : '$timeStr ($timeOfDay)';
    final locationLine = DiaryLocaleUtils.locationLine(location, locale);

    final prompt = isJapanese
        ? '''
このシーンの内容を詳しく分析して、簡潔に説明してください。
以下の形式で回答してください。

このシーンには[主な被写体・物・場面]があります。[具体的な詳細や特徴、雰囲気など50文字程度で]

時刻: $timeLabel
$locationLine
シーンの詳細を観察して、その時の状況や雰囲気を含めて分析してください。'''
        : '''
Carefully analyse the scene and describe it in concise English sentences.
Respond using this structure:

This scene includes [main subjects or elements]. [Highlight notable details, atmosphere, and context in 2-3 sentences.]

Time: $timeLabel
$locationLine
Describe the situation and mood you infer from the image, including any emotional cues you notice.''';

    try {
      final response = await _apiClient.sendVisionRequest(
        prompt: prompt,
        imageData: imageData,
        maxOutputTokens: 500,
      );

      if (response != null) {
        final content = _apiClient.extractTextFromResponse(response);
        if (content != null) {
          return '$timeLabel: ${content.trim()}';
        }
      }

      return '$timeLabel: ${DiaryLocaleUtils.analysisFailureMessage(locale)}';
    } catch (e) {
      _logger.error('画像分析エラー', context: '_analyzeImage', error: e);
      return '$timeLabel: ${DiaryLocaleUtils.analysisFailureMessage(locale)}';
    }
  }

  /// 複数の分析結果を統合して日記を生成
  Future<DiaryGenerationResult> _generateDiaryFromAnalyses(
    List<String> photoAnalyses,
    List<DateTime> photoTimes,
    String? location,
    String? customPrompt,
    Locale locale,
  ) async {
    if (photoAnalyses.isEmpty) {
      throw Exception(
        DiaryLocaleUtils.isJapanese(locale)
            ? '写真の分析結果がありません'
            : 'No analysis results are available',
      );
    }

    final promptType = DiaryPromptBuilder.analyzePromptType(customPrompt);
    final optimParams = DiaryPromptBuilder.getOptimizationParams(
      promptType,
      locale,
    );
    final emphasis = optimParams['emphasis'] as String;
    final baseMaxTokens = optimParams['maxTokens'] as int;
    final multiImageMaxTokens =
        baseMaxTokens + (DiaryLocaleUtils.isJapanese(locale) ? 50 : 60);

    final prompt = DiaryPromptBuilder.buildMultiImagePrompt(
      locale: locale,
      analyses: photoAnalyses,
      photoTimes: photoTimes,
      location: location,
      customPrompt: customPrompt,
      emphasis: emphasis,
    );

    _logger.debug(
      '複数画像AI生成プロンプト統合確認',
      context: '_generateDiaryFromAnalyses',
      data: {
        'カスタムプロンプト': customPrompt ?? 'なし',
        'プロンプト種別': promptType,
        'maxTokens': multiImageMaxTokens,
        'emphasis': emphasis,
        'locale': locale.toLanguageTag(),
        '統合後プロンプト長': prompt.length,
      },
    );

    try {
      final response = await _apiClient.sendTextRequest(
        prompt: prompt,
        maxOutputTokens: multiImageMaxTokens,
      );

      if (response != null) {
        final content = _apiClient.extractTextFromResponse(response);
        if (content != null) {
          return _parseGeneratedDiary(content, locale);
        }
      }

      throw Exception(
        DiaryLocaleUtils.isJapanese(locale)
            ? 'AI日記生成に失敗しました: APIレスポンスが不正です'
            : 'Failed to generate the diary: invalid API response',
      );
    } catch (e) {
      _logger.error(
        '統合日記生成エラー',
        context: '_generateDiaryFromAnalyses',
        error: e,
      );
      rethrow;
    }
  }
}
