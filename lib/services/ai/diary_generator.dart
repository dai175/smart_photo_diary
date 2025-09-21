import 'dart:typed_data';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import 'ai_service_interface.dart';
import 'gemini_api_client.dart';
import '../logging_service.dart';
import '../../core/service_locator.dart';

/// 日記生成を担当するサービス
class DiaryGenerator {
  final GeminiApiClient _apiClient;

  DiaryGenerator({GeminiApiClient? apiClient})
    : _apiClient = apiClient ?? GeminiApiClient();

  LoggingService get _logger => serviceLocator.get<LoggingService>();

  bool _isJapanese(Locale locale) => locale.languageCode.toLowerCase() == 'ja';

  String _toLocaleTag(Locale locale) {
    final tag = locale.toLanguageTag();
    return tag.isEmpty ? locale.languageCode : tag;
  }

  String _formatDate(DateTime date, Locale locale) {
    return DateFormat.yMMMMd(_toLocaleTag(locale)).format(date);
  }

  String _formatTime(DateTime date, Locale locale) {
    final tag = _toLocaleTag(locale);
    return _isJapanese(locale)
        ? DateFormat.Hm(tag).format(date)
        : DateFormat.jm(tag).format(date);
  }

  String _locationLine(String? location, Locale locale) {
    if (location == null || location.trim().isEmpty) {
      return '';
    }
    return _isJapanese(locale) ? '場所: $location\n' : 'Location: $location\n';
  }

  /// プロンプト種別を分析
  String _analyzePromptType(String? prompt) {
    if (prompt == null || prompt.trim().isEmpty) {
      return 'emotion';
    }

    final lowerPrompt = prompt.toLowerCase();

    // 感情系キーワード / Emotional keywords
    if (lowerPrompt.contains('感情') ||
        lowerPrompt.contains('気持ち') ||
        lowerPrompt.contains('感じ') ||
        lowerPrompt.contains('心') ||
        lowerPrompt.contains('emotion') ||
        lowerPrompt.contains('feeling') ||
        lowerPrompt.contains('feelings') ||
        lowerPrompt.contains('heart')) {
      return 'emotion';
    }

    // 成長・発見系キーワード / Growth keywords
    if (lowerPrompt.contains('成長') ||
        lowerPrompt.contains('変化') ||
        lowerPrompt.contains('発見') ||
        lowerPrompt.contains('気づき') ||
        lowerPrompt.contains('growth') ||
        lowerPrompt.contains('change') ||
        lowerPrompt.contains('learning') ||
        lowerPrompt.contains('discovery')) {
      return 'growth';
    }

    // つながり系キーワード / Connection keywords
    if (lowerPrompt.contains('つながり') ||
        lowerPrompt.contains('人') ||
        lowerPrompt.contains('関係') ||
        lowerPrompt.contains('connection') ||
        lowerPrompt.contains('relationship') ||
        lowerPrompt.contains('together') ||
        lowerPrompt.contains('community')) {
      return 'connection';
    }

    // 癒し系キーワード / Healing keywords
    if (lowerPrompt.contains('癒し') ||
        lowerPrompt.contains('平和') ||
        lowerPrompt.contains('安らぎ') ||
        lowerPrompt.contains('healing') ||
        lowerPrompt.contains('calm') ||
        lowerPrompt.contains('peace') ||
        lowerPrompt.contains('restful')) {
      return 'healing';
    }

    return 'emotion'; // デフォルトは感情型
  }

  /// プロンプト種別に応じた最適化パラメータを取得
  Map<String, dynamic> _getOptimizationParams(
    String promptType,
    Locale locale,
  ) {
    final isJapanese = _isJapanese(locale);
    switch (promptType) {
      case 'growth':
        return {
          'maxTokens': isJapanese ? 320 : 380,
          'emphasis': isJapanese
              ? '成長と変化に焦点を当てて'
              : 'highlights personal growth and change',
        };
      case 'connection':
        return {
          'maxTokens': isJapanese ? 310 : 370,
          'emphasis': isJapanese
              ? '人とのつながりや関係性を重視して'
              : 'emphasises meaningful relationships and connection',
        };
      case 'healing':
        return {
          'maxTokens': isJapanese ? 290 : 360,
          'emphasis': isJapanese
              ? '穏やかで心安らぐ文体で'
              : 'feels calm, gentle, and restorative',
        };
      case 'emotion':
      default:
        return {
          'maxTokens': isJapanese ? 300 : 360,
          'emphasis': isJapanese
              ? '感情の深みを大切にして'
              : 'captures emotional depth and nuance',
        };
    }
  }

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
        _isJapanese(locale)
            ? 'オフライン状態では日記を生成できません'
            : 'Cannot generate a diary while offline',
      );
    }

    try {
      // プロンプト種別分析と最適化パラメータ取得
      final promptType = _analyzePromptType(prompt);
      final optimParams = _getOptimizationParams(promptType, locale);
      final emphasis = optimParams['emphasis'] as String;
      final maxTokens = optimParams['maxTokens'] as int;

      final finalPrompt = _buildSingleImagePrompt(
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
        _isJapanese(locale)
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
        _isJapanese(locale) ? '画像が提供されていません' : 'No images were provided',
      );
    }

    if (!isOnline) {
      throw Exception(
        _isJapanese(locale)
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

      final defaultTitle = _isJapanese(locale) ? '今日の日記' : "Today's Journal";

      return DiaryGenerationResult(
        title: (title == null || title.isEmpty) ? defaultTitle : title,
        content: (content == null || content.isEmpty)
            ? generatedText.trim()
            : content,
      );
    } catch (e) {
      _logger.error('日記パース中のエラー', context: '_parseGeneratedDiary', error: e);
      final defaultTitle = _isJapanese(locale) ? '今日の日記' : "Today's Journal";
      return DiaryGenerationResult(
        title: defaultTitle,
        content: generatedText.trim(),
      );
    }
  }

  String _timeSegment(DateTime date) {
    final hour = date.hour;
    if (hour >= AiConstants.morningStartHour &&
        hour < AiConstants.afternoonStartHour) {
      return 'morning';
    }
    if (hour >= AiConstants.afternoonStartHour &&
        hour < AiConstants.eveningStartHour) {
      return 'afternoon';
    }
    if (hour >= AiConstants.eveningStartHour &&
        hour < AiConstants.nightStartHour) {
      return 'evening';
    }
    return 'night';
  }

  String _segmentLabel(String segment, Locale locale) {
    final isJapanese = _isJapanese(locale);
    switch (segment) {
      case 'morning':
        return isJapanese ? '朝' : 'Morning';
      case 'afternoon':
        return isJapanese ? '昼' : 'Afternoon';
      case 'evening':
        return isJapanese ? '夕方' : 'Evening';
      case 'night':
      default:
        return isJapanese ? '夜' : 'Night';
    }
  }

  int _segmentOrder(String segment) {
    switch (segment) {
      case 'morning':
        return 0;
      case 'afternoon':
        return 1;
      case 'evening':
        return 2;
      case 'night':
      default:
        return 3;
    }
  }

  String _throughoutDay(Locale locale) =>
      _isJapanese(locale) ? '一日を通して' : 'Throughout the day';

  String _combineSegments(Set<String> segments, Locale locale) {
    if (segments.isEmpty) {
      return _throughoutDay(locale);
    }
    if (segments.length == 1) {
      return _segmentLabel(segments.first, locale);
    }
    final sorted = segments.toList()
      ..sort((a, b) => _segmentOrder(a).compareTo(_segmentOrder(b)));
    if (sorted.length == 2) {
      final first = _segmentLabel(sorted.first, locale);
      final second = _segmentLabel(sorted.last, locale);
      if (_isJapanese(locale)) {
        return '$firstから$secondにかけて';
      }
      return '$first to $second';
    }
    return _throughoutDay(locale);
  }

  /// 時間帯の文字列を取得
  String _getTimeOfDay(DateTime date, Locale locale) {
    return _segmentLabel(_timeSegment(date), locale);
  }

  /// 複数写真の撮影時刻を考慮した時間帯を取得
  String _getTimeOfDayForPhotos(
    DateTime baseDate,
    List<DateTime>? photoTimes,
    Locale locale,
  ) {
    if (photoTimes == null || photoTimes.isEmpty) {
      return _getTimeOfDay(baseDate, locale);
    }

    if (photoTimes.length == 1) {
      return _getTimeOfDay(photoTimes.first, locale);
    }

    final segments = <String>{};
    for (final time in photoTimes) {
      segments.add(_timeSegment(time));
    }

    return _combineSegments(segments, locale);
  }

  String _buildSingleImagePrompt({
    required Locale locale,
    required List<DateTime>? photoTimes,
    String? location,
    String? customPrompt,
    required String emphasis,
  }) {
    final isJapanese = _isJapanese(locale);
    final locationLine = _locationLine(location, locale);
    final hasMultiplePhotos = photoTimes != null && photoTimes.length > 1;

    if (isJapanese) {
      final basePrompt =
          '''
あなたは感情豊かな日記作成の専門家です。提示されたシーンや場面をもとに、その瞬間の感情や心の動きを中心とした日記を日本語で作成してください。
写真は単なる記録ではなく、あなたが実際に体験したシーンを表しています。そのシーンで感じた気持ちや感情を深く掘り下げた個人的な日記を書いてください。

タイトルと本文を分けて、以下の形式で出力してください。

【タイトル】
（5-10文字程度で感情や印象を表現する簡潔なタイトル）

【本文】
（150-200文字程度で、感情や心の動きを中心とした自然で個人的な文体の本文${hasMultiplePhotos ? '。時系列に沿って感情の変化を描写してください' : ''}）

$locationLine''';

      if (customPrompt != null) {
        return '''$basePrompt
以下のライティングプロンプトを参考にして、このシーンで体験したことを深く掘り下げて日記を作成してください：

「$customPrompt」

このシーンを実際に体験した時の感情や思いを以下の観点で日記に表現してください：
- そのシーンで最初に感じた気持ちや感情
- なぜその感情が生まれたのかの理由や背景
- その瞬間に感じた心の動きや印象
- そのシーンで特に心に残った部分や体験
- その時間から得られた気づきや発見

$emphasis、個人的で心に響く日記を作成してください。''';
      }

      return '''$basePrompt
このシーンの詳細を把握して、以下の点を意識して日記を書いてください：
- そのシーンで実際に感じた気持ちや感情
- その瞬間の心の状態や印象
- そのシーンで体験した雰囲気や感覚
- 自分にとって意味のある瞬間や気づき

感情豊かで個人的な日記を作成してください。''';
    }

    final multiPhotoHint = hasMultiplePhotos
        ? ' and traces how the feelings shift across the moments.'
        : '.';

    final basePrompt =
        '''
You are an empathetic journaling companion. Using the scene details, craft a reflective diary entry in natural English that centres on the writer's emotions.
The photo represents a real lived experience—explore the personal meaning behind it.

Write the output using the following format. Do not include any explanatory text in parentheses:

[Title]
A concise 3-6 word phrase capturing the emotional tone

[Body]
Approximately 70-90 words in a warm, personal voice that explores the emotions$multiPhotoHint

$locationLine''';

    if (customPrompt != null) {
      return '''$basePrompt
Use the following writing prompt as additional inspiration:

"$customPrompt"

When writing the diary, reflect on:
- The first emotions that surfaced in the scene
- Why those feelings emerged and any background context
- How the inner state shifted moment by moment
- Details or discoveries that felt especially meaningful
- Insights or lessons gained from the experience

Use a tone that $emphasis and keep the entry personal and heartfelt. Do not include parenthetical explanations or meta-commentary in the title or body.''';
    }

    return '''$basePrompt
Consider the scene carefully and describe:
- The emotions you genuinely felt in that moment
- The atmosphere and sensory details you noticed
- Any thoughts or memories the scene evoked
- A personal insight or takeaway from the experience

Use a tone that $emphasis and keep the diary intimate and emotionally resonant. Do not include parenthetical explanations or meta-commentary in the title or body.''';
  }

  String _buildMultiImagePrompt({
    required Locale locale,
    required List<String> analyses,
    required List<DateTime> photoTimes,
    String? location,
    String? customPrompt,
    required String emphasis,
  }) {
    final isJapanese = _isJapanese(locale);
    final locationLine = _locationLine(location, locale);
    final analysesText = analyses.join('\n');
    final dateLabel = _formatDate(photoTimes.first, locale);
    final timeRange = _getTimeOfDayForPhotos(
      photoTimes.first,
      photoTimes,
      locale,
    );

    if (isJapanese) {
      final basePrompt =
          '''以下のシーン分析結果から、その日の感情や心の動きを中心とした日記を日本語で作成してください。
単なる出来事の記録ではなく、一日を通して体験したシーンで感じた気持ちや感情の変化を深く掘り下げた個人的な日記を書いてください。

タイトルと本文を分けて、以下の形式で出力してください。

【タイトル】
（5-10文字程度でその日の感情や印象を表現する簡潔なタイトル）

【本文】
（150-220文字程度で、感情や心の動きを中心とした自然で個人的な文体の本文。時系列に沿って感情の変化や発見を描写してください）

日付: $dateLabel
時間帯: $timeRange
$locationLine
シーン分析結果:
$analysesText''';

      if (customPrompt != null) {
        return '''$basePrompt

以下のライティングプロンプトを参考にして、このシーンで体験したことを深く掘り下げて日記を作成してください：

「$customPrompt」

シーンの分析結果を踏まえ、以下の観点で日記を書いてください：
- 一日を通して感じた感情の変化や流れ
- 時間とともに変わっていく気持ちや印象
- 各シーンで心に残った瞬間や体験
- その日を振り返って感じる発見や気づき
- その日の体験が自分に与えた影響

$emphasis、時系列に沿って個人的で心に響く日記を作成してください。''';
      }

      return '''$basePrompt

これらのシーンから読み取れる一日の流れや体験を、以下の点を意識して日記に表現してください：
- 一日を通して感じた感情の変化
- 時間の経過とともに変わる気持ちや印象
- 各シーンで心に残った瞬間や体験
- その日を振り返って得られる気づきや発見

感情豊かで個人的な日記を作成してください。''';
    }

    final basePrompt =
        '''Using the scene analyses below, craft a reflective diary entry in natural English that traces how the writer's emotions evolved throughout the day.
Do not simply list events—explore the inner experience and personal meaning behind each moment.

Write the output using the following format. Do not include any explanatory text in parentheses:

[Title]
A concise 3-6 word phrase that captures the day's emotional theme

[Body]
Approximately 80-100 words that follow the flow of the day and emphasise emotional insights and discoveries

Date: $dateLabel
Time span: $timeRange
$locationLine
Scene analyses:
$analysesText''';

    if (customPrompt != null) {
      return '''$basePrompt

Use the following writing prompt as additional inspiration:

"$customPrompt"

When crafting the diary, be sure to cover:
- How your feelings shifted across the day
- The details that stood out in each scene
- Moments that felt especially meaningful or surprising
- Insights or lessons that emerged from the experience
- The impact the day had on your perspective or mood

Use a tone that $emphasis and keep the writing personal and genuine. Do not include parenthetical explanations or meta-commentary in the title or body.''';
    }

    return '''$basePrompt

Reflect on the day by describing:
- The emotional flow from scene to scene
- How the atmosphere and details influenced your mood
- Key moments that stayed with you
- Any conclusions or insights you reached by the end of the day

Use a tone that $emphasis and ensure the diary feels intimate and emotionally resonant. Do not include parenthetical explanations or meta-commentary in the title or body.''';
  }

  String _analysisFailureMessage(Locale locale) =>
      _isJapanese(locale) ? '画像分析に失敗しました' : 'Image analysis failed';

  /// 1枚の画像を分析して説明を取得
  Future<String> _analyzeImage(
    Uint8List imageData,
    DateTime time,
    String? location,
    Locale locale,
  ) async {
    final timeStr = _formatTime(time, locale);
    final timeOfDay = _getTimeOfDay(time, locale);
    final timeLabel = _isJapanese(locale)
        ? '$timeStr($timeOfDay)'
        : '$timeStr ($timeOfDay)';
    final locationLine = _locationLine(location, locale);

    final prompt = _isJapanese(locale)
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

      return '$timeLabel: ${_analysisFailureMessage(locale)}';
    } catch (e) {
      _logger.error('画像分析エラー', context: '_analyzeImage', error: e);
      return '$timeLabel: ${_analysisFailureMessage(locale)}';
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
        _isJapanese(locale)
            ? '写真の分析結果がありません'
            : 'No analysis results are available',
      );
    }

    final promptType = _analyzePromptType(customPrompt);
    final optimParams = _getOptimizationParams(promptType, locale);
    final emphasis = optimParams['emphasis'] as String;
    final baseMaxTokens = optimParams['maxTokens'] as int;
    final multiImageMaxTokens = baseMaxTokens + (_isJapanese(locale) ? 50 : 60);

    final prompt = _buildMultiImagePrompt(
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
        _isJapanese(locale)
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
