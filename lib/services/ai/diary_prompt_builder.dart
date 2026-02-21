import 'dart:ui';
import '../../models/diary_length.dart';
import 'diary_locale_utils.dart';
import 'diary_time_segment.dart';

/// 日記生成プロンプトの構築を担当
class DiaryPromptBuilder {
  DiaryPromptBuilder._();

  // ── Max token constants per prompt type ──

  // Standard max tokens: {ja, en}
  static const int emotionTokensJaStandard = 300;
  static const int emotionTokensEnStandard = 360;
  static const int growthTokensJaStandard = 320;
  static const int growthTokensEnStandard = 380;
  static const int connectionTokensJaStandard = 310;
  static const int connectionTokensEnStandard = 370;
  static const int healingTokensJaStandard = 290;
  static const int healingTokensEnStandard = 360;

  // Short max tokens: {ja, en}
  static const int emotionTokensJaShort = 115;
  static const int emotionTokensEnShort = 145;
  static const int growthTokensJaShort = 125;
  static const int growthTokensEnShort = 155;
  static const int connectionTokensJaShort = 120;
  static const int connectionTokensEnShort = 150;
  static const int healingTokensJaShort = 110;
  static const int healingTokensEnShort = 140;

  // Additional tokens for multi-image generation
  static const int multiImageExtraTokensJaStandard = 50;
  static const int multiImageExtraTokensEnStandard = 60;
  static const int multiImageExtraTokensJaShort = 15;
  static const int multiImageExtraTokensEnShort = 20;

  // ── Length constants for prompt instructions ──

  // Japanese
  static const _jaTitleStandard = '5-10文字程度';
  static const _jaTitleShort = '3-6文字程度';
  static const _jaSingleBodyStandard = '150-200文字程度';
  static const _jaSingleBodyShort = '40-70文字程度';
  static const _jaMultiBodyStandard = '150-220文字程度';
  static const _jaMultiBodyShort = '50-80文字程度';

  // English
  static const _enTitleStandard = '3-6 word';
  static const _enTitleShort = '2-3 word';
  static const _enSingleBodyStandard = '70-90 words';
  static const _enSingleBodyShort = '15-25 words';
  static const _enMultiBodyStandard = '80-100 words';
  static const _enMultiBodyShort = '20-30 words';

  /// プロンプト種別を分析
  static String analyzePromptType(String? prompt) {
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
  static Map<String, dynamic> getOptimizationParams(
    String promptType,
    Locale locale, {
    DiaryLength diaryLength = DiaryLength.standard,
  }) {
    final isJapanese = DiaryLocaleUtils.isJapanese(locale);
    final isShort = diaryLength == DiaryLength.short;
    switch (promptType) {
      case 'growth':
        return {
          'maxTokens': isJapanese
              ? (isShort ? growthTokensJaShort : growthTokensJaStandard)
              : (isShort ? growthTokensEnShort : growthTokensEnStandard),
          'emphasis': isJapanese
              ? '成長と変化に焦点を当てて'
              : 'highlights personal growth and change',
        };
      case 'connection':
        return {
          'maxTokens': isJapanese
              ? (isShort ? connectionTokensJaShort : connectionTokensJaStandard)
              : (isShort
                    ? connectionTokensEnShort
                    : connectionTokensEnStandard),
          'emphasis': isJapanese
              ? '人とのつながりや関係性を重視して'
              : 'emphasises meaningful relationships and connection',
        };
      case 'healing':
        return {
          'maxTokens': isJapanese
              ? (isShort ? healingTokensJaShort : healingTokensJaStandard)
              : (isShort ? healingTokensEnShort : healingTokensEnStandard),
          'emphasis': isJapanese
              ? '穏やかで心安らぐ文体で'
              : 'feels calm, gentle, and restorative',
        };
      case 'emotion':
      default:
        return {
          'maxTokens': isJapanese
              ? (isShort ? emotionTokensJaShort : emotionTokensJaStandard)
              : (isShort ? emotionTokensEnShort : emotionTokensEnStandard),
          'emphasis': isJapanese
              ? '感情の深みを大切にして'
              : 'captures emotional depth and nuance',
        };
    }
  }

  /// contextText をプロンプトに注入するための行を構築
  static String _buildContextLine(String? contextText, Locale locale) {
    if (contextText == null || contextText.trim().isEmpty) return '';
    // Defense in depth: sanitize length and newlines at service layer
    const maxLength = 100;
    var safe = contextText.trim().replaceAll(RegExp(r'[\r\n]+'), ' ');
    if (safe.length > maxLength) safe = safe.substring(0, maxLength);
    return DiaryLocaleUtils.isJapanese(locale)
        ? '\n状況・背景：「$safe」\n上記の状況を踏まえて、'
        : '\nContext: "$safe"\nWith this context in mind,';
  }

  /// 単一画像用プロンプトを構築
  static String buildSingleImagePrompt({
    required Locale locale,
    required List<DateTime>? photoTimes,
    String? location,
    String? customPrompt,
    String? contextText,
    required String emphasis,
    DiaryLength diaryLength = DiaryLength.standard,
  }) {
    final isJapanese = DiaryLocaleUtils.isJapanese(locale);
    final locationLine = DiaryLocaleUtils.locationLine(location, locale);
    final hasMultiplePhotos = photoTimes != null && photoTimes.length > 1;
    final isShort = diaryLength == DiaryLength.short;

    if (isJapanese) {
      final titleLength = isShort ? _jaTitleShort : _jaTitleStandard;
      final bodyLength = isShort ? _jaSingleBodyShort : _jaSingleBodyStandard;
      final contextLine = _buildContextLine(contextText, locale);
      final basePrompt =
          '''
あなたは感情豊かな日記作成の専門家です。提示されたシーンや場面をもとに、その瞬間の感情や心の動きを中心とした日記を日本語で作成してください。
写真は単なる記録ではなく、あなたが実際に体験したシーンを表しています。そのシーンで感じた気持ちや感情を深く掘り下げた個人的な日記を書いてください。

タイトルと本文を分けて、以下の形式で出力してください。

【タイトル】
（$titleLengthで感情や印象を表現する簡潔なタイトル）

【本文】
（$bodyLengthで、感情や心の動きを中心とした自然で個人的な文体の本文${hasMultiplePhotos ? '。時系列に沿って感情の変化を描写してください' : ''}）
${isShort ? '\n※この日記はX（旧Twitter）投稿用です。タイトル＋本文の合計を必ず100文字以内に収めてください。' : ''}
$locationLine''';

      if (customPrompt != null) {
        return '''$basePrompt$contextLine
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

      return '''$basePrompt$contextLine
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

    final titleLength = isShort ? _enTitleShort : _enTitleStandard;
    final bodyLength = isShort ? _enSingleBodyShort : _enSingleBodyStandard;
    final contextLine = _buildContextLine(contextText, locale);
    final basePrompt =
        '''
You are an empathetic journaling companion. Using the scene details, craft a reflective diary entry in natural English that centres on the writer's emotions.
The photo represents a real lived experience—explore the personal meaning behind it.

Write the output using the following format. Do not include any explanatory text in parentheses:

[Title]
A concise $titleLength phrase capturing the emotional tone

[Body]
Approximately $bodyLength in a warm, personal voice that explores the emotions$multiPhotoHint
${isShort ? '\nNote: This diary is for an X (Twitter) post. The combined title + body MUST fit within 240 characters total.' : ''}
$locationLine''';

    if (customPrompt != null) {
      return '''$basePrompt$contextLine
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

    return '''$basePrompt$contextLine
Consider the scene carefully and describe:
- The emotions you genuinely felt in that moment
- The atmosphere and sensory details you noticed
- Any thoughts or memories the scene evoked
- A personal insight or takeaway from the experience

Use a tone that $emphasis and keep the diary intimate and emotionally resonant. Do not include parenthetical explanations or meta-commentary in the title or body.''';
  }

  /// 複数画像用プロンプトを構築
  static String buildMultiImagePrompt({
    required Locale locale,
    required List<String> analyses,
    required List<DateTime> photoTimes,
    String? location,
    String? customPrompt,
    String? contextText,
    required String emphasis,
    DiaryLength diaryLength = DiaryLength.standard,
  }) {
    final isJapanese = DiaryLocaleUtils.isJapanese(locale);
    final locationLine = DiaryLocaleUtils.locationLine(location, locale);
    final analysesText = analyses.join('\n');
    final dateLabel = DiaryLocaleUtils.formatDate(photoTimes.first, locale);
    final timeRange = DiaryTimeSegment.getTimeOfDayForPhotos(
      photoTimes.first,
      photoTimes,
      locale,
    );

    final isShort = diaryLength == DiaryLength.short;

    if (isJapanese) {
      final titleLength = isShort ? _jaTitleShort : _jaTitleStandard;
      final bodyLength = isShort ? _jaMultiBodyShort : _jaMultiBodyStandard;
      final contextLine = _buildContextLine(contextText, locale);
      final basePrompt =
          '''以下のシーン分析結果から、その日の感情や心の動きを中心とした日記を日本語で作成してください。
単なる出来事の記録ではなく、一日を通して体験したシーンで感じた気持ちや感情の変化を深く掘り下げた個人的な日記を書いてください。

タイトルと本文を分けて、以下の形式で出力してください。

【タイトル】
（$titleLengthでその日の感情や印象を表現する簡潔なタイトル）

【本文】
（$bodyLengthで、感情や心の動きを中心とした自然で個人的な文体の本文。時系列に沿って感情の変化や発見を描写してください）
${isShort ? '\n※この日記はX（旧Twitter）投稿用です。タイトル＋本文の合計を必ず100文字以内に収めてください。' : ''}
日付: $dateLabel
時間帯: $timeRange
$locationLine
シーン分析結果:
$analysesText''';

      if (customPrompt != null) {
        return '''$basePrompt$contextLine

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

      return '''$basePrompt$contextLine

これらのシーンから読み取れる一日の流れや体験を、以下の点を意識して日記に表現してください：
- 一日を通して感じた感情の変化
- 時間の経過とともに変わる気持ちや印象
- 各シーンで心に残った瞬間や体験
- その日を振り返って得られる気づきや発見

感情豊かで個人的な日記を作成してください。''';
    }

    final enTitleLength = isShort ? _enTitleShort : _enTitleStandard;
    final enBodyLength = isShort ? _enMultiBodyShort : _enMultiBodyStandard;
    final contextLine = _buildContextLine(contextText, locale);
    final basePrompt =
        '''Using the scene analyses below, craft a reflective diary entry in natural English that traces how the writer's emotions evolved throughout the day.
Do not simply list events—explore the inner experience and personal meaning behind each moment.

Write the output using the following format. Do not include any explanatory text in parentheses:

[Title]
A concise $enTitleLength phrase that captures the day's emotional theme

[Body]
Approximately $enBodyLength, following the flow of the day and emphasising emotional insights and discoveries
${isShort ? '\nNote: This diary is for an X (Twitter) post. The combined title + body MUST fit within 240 characters total.' : ''}
Date: $dateLabel
Time span: $timeRange
$locationLine
Scene analyses:
$analysesText''';

    if (customPrompt != null) {
      return '''$basePrompt$contextLine

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

    return '''$basePrompt$contextLine

Reflect on the day by describing:
- The emotional flow from scene to scene
- How the atmosphere and details influenced your mood
- Key moments that stayed with you
- Any conclusions or insights you reached by the end of the day

Use a tone that $emphasis and ensure the diary feels intimate and emotionally resonant. Do not include parenthetical explanations or meta-commentary in the title or body.''';
  }
}
