import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import 'ai_service_interface.dart';
import 'gemini_api_client.dart';
import 'offline_fallback_service.dart';

/// 日記生成を担当するサービス
class DiaryGenerator {
  final GeminiApiClient _apiClient;
  final OfflineFallbackService _offlineService;

  DiaryGenerator({
    GeminiApiClient? apiClient,
    OfflineFallbackService? offlineService,
  }) : _apiClient = apiClient ?? GeminiApiClient(),
       _offlineService = offlineService ?? OfflineFallbackService();

  /// プロンプト種別を分析
  String _analyzePromptType(String? prompt) {
    if (prompt == null) return 'general';

    final lowerPrompt = prompt.toLowerCase();

    // 感情系キーワード
    if (lowerPrompt.contains('感情') ||
        lowerPrompt.contains('気持ち') ||
        lowerPrompt.contains('感じ') ||
        lowerPrompt.contains('心')) {
      return 'emotion';
    }

    // 成長・発見系キーワード
    if (lowerPrompt.contains('成長') ||
        lowerPrompt.contains('変化') ||
        lowerPrompt.contains('発見') ||
        lowerPrompt.contains('気づき')) {
      return 'growth';
    }

    // つながり系キーワード
    if (lowerPrompt.contains('つながり') ||
        lowerPrompt.contains('人') ||
        lowerPrompt.contains('関係')) {
      return 'connection';
    }

    // 癒し系キーワード
    if (lowerPrompt.contains('癒し') ||
        lowerPrompt.contains('平和') ||
        lowerPrompt.contains('安らぎ')) {
      return 'healing';
    }

    return 'emotion'; // デフォルトは感情型
  }

  /// プロンプト種別に応じた最適化パラメータを取得
  Map<String, dynamic> _getOptimizationParams(String promptType) {
    switch (promptType) {
      case 'growth':
        return {
          'maxTokens': 320, // 成長系は少し長めの記述
          'emphasis': '成長と変化に焦点を当てて',
        };
      case 'connection':
        return {
          'maxTokens': 310, // つながり系は人間関係の描写
          'emphasis': '人とのつながりや関係性を重視して',
        };
      case 'healing':
        return {
          'maxTokens': 290, // 癒し系は静かで穏やかな文体
          'emphasis': '穏やかで心安らぐ文体で',
        };
      case 'emotion':
      default:
        return {
          'maxTokens': 300, // 感情系は標準
          'emphasis': '感情の深みを大切にして',
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
  }) async {
    if (!isOnline) {
      return _offlineService.generateDiary([], date, location, null);
    }

    try {
      // プロンプト種別分析と最適化パラメータ取得
      final promptType = _analyzePromptType(prompt);
      final optimParams = _getOptimizationParams(promptType);
      final emphasis = optimParams['emphasis'] as String;
      final maxTokens = optimParams['maxTokens'] as int;

      // プロンプトの作成（感情深掘り型対応）
      final basePrompt =
          '''
あなたは感情豊かな日記作成の専門家です。提示されたシーンや場面をもとに、その瞬間の感情や心の動きを中心とした日記を日本語で作成してください。
写真は単なる記録ではなく、あなたが実際に体験したシーンを表しています。そのシーンで感じた気持ちや感情を深く掘り下げた個人的な日記を書いてください。

タイトルと本文を分けて、以下の形式で出力してください。

【タイトル】
（5-10文字程度で感情や印象を表現する簡潔なタイトル）

【本文】
（150-200文字程度で、感情や心の動きを中心とした自然で個人的な文体の本文${photoTimes != null && photoTimes.length > 1 ? '。時系列に沿って感情の変化を描写してください' : ''}）

${location != null ? '場所: $location\n' : ''}''';

      // カスタムプロンプトが指定されている場合は統合（感情深掘り型対応）
      final finalPrompt = prompt != null
          ? '''$basePrompt

以下のライティングプロンプトを参考にして、このシーンで体験したことを深く掘り下げて日記を作成してください：

「$prompt」

このシーンを実際に体験した時の感情や思いを以下の観点で日記に表現してください：
- そのシーンで最初に感じた気持ちや感情
- なぜその感情が生まれたのかの理由や背景
- その瞬間に感じた心の動きや印象
- そのシーンで特に心に残った部分や体験
- その時間から得られた気づきや発見

$emphasis、個人的で心に響く日記を作成してください。'''
          : '''$basePrompt

このシーンの詳細を把握して、以下の点を意識して日記を書いてください：
- そのシーンで実際に感じた気持ちや感情
- その瞬間の心の状態や印象
- そのシーンで体験した雰囲気や感覚
- 自分にとって意味のある瞬間や気づき

感情豊かで個人的な日記を作成してください。''';

      // デバッグログ: プロンプト統合確認（感情深掘り型対応）
      debugPrint('=== AI生成プロンプト統合確認 ===');
      debugPrint('カスタムプロンプト: ${prompt ?? "なし"}');
      debugPrint('プロンプト種別: $promptType');
      debugPrint('最適化パラメータ: maxTokens=$maxTokens, emphasis=$emphasis');
      debugPrint('統合後プロンプト長: ${finalPrompt.length}文字');
      if (prompt != null) {
        debugPrint('感情深掘り型プロンプト統合: 成功');
      }

      final response = await _apiClient.sendVisionRequest(
        prompt: finalPrompt,
        imageData: imageData,
        maxOutputTokens: maxTokens, // 生成ロジック最適化: プロンプト種別に応じた動的調整
      );

      if (response != null) {
        final content = _apiClient.extractTextFromResponse(response);
        if (content != null) {
          return _parseGeneratedDiary(content);
        }
      }

      return _offlineService.generateDiary([], date, location, null);
    } catch (e) {
      debugPrint('画像ベース日記生成エラー: $e');
      return _offlineService.generateDiary([], date, location, null);
    }
  }

  /// 複数画像から順次日記を生成
  Future<DiaryGenerationResult> generateFromMultipleImages({
    required List<({Uint8List imageData, DateTime time})> imagesWithTimes,
    String? location,
    String? prompt,
    Function(int current, int total)? onProgress,
    required bool isOnline,
  }) async {
    if (imagesWithTimes.isEmpty) {
      throw Exception('画像が提供されていません');
    }

    if (!isOnline) {
      final List<DateTime> offlineTimesList = imagesWithTimes
          .map<DateTime>((e) => e.time)
          .toList();
      return _offlineService.generateDiary(
        [],
        imagesWithTimes.first.time,
        location,
        offlineTimesList,
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

        debugPrint('画像 ${i + 1}/${sortedImages.length} を分析中...');

        final analysis = await _analyzeImage(
          imageWithTime.imageData,
          imageWithTime.time,
          location,
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
      );
    } catch (e) {
      debugPrint('複数画像日記生成エラー: $e');
      final List<DateTime> fallbackTimesList = imagesWithTimes
          .map<DateTime>((e) => e.time)
          .toList();
      return _offlineService.generateDiary(
        [],
        imagesWithTimes.first.time,
        location,
        fallbackTimesList,
      );
    }
  }

  /// 生成された日記テキストをタイトルと本文に分割
  DiaryGenerationResult _parseGeneratedDiary(String generatedText) {
    try {
      // 【タイトル】と【本文】で分割
      final titleMatch = RegExp(
        r'【タイトル】\s*(.+?)(?=【本文】|$)',
        dotAll: true,
      ).firstMatch(generatedText);
      final contentMatch = RegExp(
        r'【本文】\s*(.+?)$',
        dotAll: true,
      ).firstMatch(generatedText);

      String title = titleMatch?.group(1)?.trim() ?? '';
      String content = contentMatch?.group(1)?.trim() ?? '';

      // フォールバック：形式が異なる場合は最初の行をタイトル、残りを本文とする
      if (title.isEmpty || content.isEmpty) {
        final lines = generatedText
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
        if (lines.isNotEmpty) {
          title = lines.first.trim();
          content = lines.skip(1).join('\n').trim();
        }
      }

      // 最終フォールバック
      if (title.isEmpty) title = '今日の日記';
      if (content.isEmpty) content = generatedText.trim();

      return DiaryGenerationResult(title: title, content: content);
    } catch (e) {
      debugPrint('日記パース中のエラー: $e');
      return DiaryGenerationResult(
        title: '今日の日記',
        content: generatedText.trim(),
      );
    }
  }

  /// 時間帯の文字列を取得
  String _getTimeOfDay(DateTime date) {
    final hour = date.hour;
    if (hour >= AiConstants.morningStartHour &&
        hour < AiConstants.afternoonStartHour)
      return '朝';
    if (hour >= AiConstants.afternoonStartHour &&
        hour < AiConstants.eveningStartHour)
      return '昼';
    if (hour >= AiConstants.eveningStartHour &&
        hour < AiConstants.nightStartHour)
      return '夕方';
    return '夜';
  }

  /// 複数写真の撮影時刻を考慮した時間帯を取得
  String _getTimeOfDayForPhotos(DateTime baseDate, List<DateTime>? photoTimes) {
    if (photoTimes == null || photoTimes.isEmpty) {
      return _getTimeOfDay(baseDate);
    }

    if (photoTimes.length == 1) {
      return _getTimeOfDay(photoTimes.first);
    }

    // 複数写真の場合、異なる時間帯にまたがっているかチェック
    final timeOfDaySet = <String>{};
    for (final time in photoTimes) {
      timeOfDaySet.add(_getTimeOfDay(time));
    }

    if (timeOfDaySet.length == 1) {
      // 全て同じ時間帯
      return timeOfDaySet.first;
    } else {
      // 複数の時間帯にまたがっている場合
      final sortedTimes = timeOfDaySet.toList();
      if (sortedTimes.contains('朝') && sortedTimes.contains('昼')) {
        return '朝から昼にかけて';
      } else if (sortedTimes.contains('昼') && sortedTimes.contains('夕方')) {
        return '昼から夕方にかけて';
      } else if (sortedTimes.contains('夕方') && sortedTimes.contains('夜')) {
        return '夕方から夜にかけて';
      } else {
        return '一日を通して';
      }
    }
  }

  /// 1枚の画像を分析して説明を取得
  Future<String> _analyzeImage(
    Uint8List imageData,
    DateTime time,
    String? location,
  ) async {
    final timeStr = DateFormat('HH:mm').format(time);
    final timeOfDay = _getTimeOfDay(time);

    // 分析専用プロンプト
    final prompt =
        '''
このシーンの内容を詳しく分析して、簡潔に説明してください。
以下の形式で回答してください：

このシーンには[主な被写体・物・場面]があります。[具体的な詳細や特徴、雰囲気など50文字程度で]

時刻: $timeStr($timeOfDay)
${location != null ? '場所: $location\n' : ''}

シーンの詳細を観察して、その時の状況や雰囲気を含めて分析してください。
''';

    try {
      final response = await _apiClient.sendVisionRequest(
        prompt: prompt,
        imageData: imageData,
        maxOutputTokens: 500,
      );

      if (response != null) {
        final content = _apiClient.extractTextFromResponse(response);
        if (content != null) {
          return '$timeStr($timeOfDay): ${content.trim()}';
        }
      }

      return '$timeStr($timeOfDay): 画像分析に失敗しました';
    } catch (e) {
      debugPrint('画像分析エラー: $e');
      return '$timeStr($timeOfDay): 画像分析に失敗しました';
    }
  }

  /// 複数の分析結果を統合して日記を生成
  Future<DiaryGenerationResult> _generateDiaryFromAnalyses(
    List<String> photoAnalyses,
    List<DateTime> photoTimes,
    String? location,
    String? customPrompt,
  ) async {
    if (photoAnalyses.isEmpty) {
      return _offlineService.generateDiary(
        [],
        DateTime.now(),
        location,
        photoTimes,
      );
    }

    // プロンプト種別分析と最適化パラメータ取得
    final promptType = _analyzePromptType(customPrompt);
    final optimParams = _getOptimizationParams(promptType);
    final emphasis = optimParams['emphasis'] as String;
    final baseMaxTokens = optimParams['maxTokens'] as int;
    final multiImageMaxTokens = baseMaxTokens + 50; // 複数画像は少し多めに

    final dateStr = DateFormat('yyyy年MM月dd日').format(photoTimes.first);
    final timeRange = _getTimeOfDayForPhotos(photoTimes.first, photoTimes);

    // 統合プロンプト（感情深掘り型対応）
    final analysesText = photoAnalyses.join('\n');
    final basePrompt =
        '''
以下のシーン分析結果から、その日の感情や心の動きを中心とした日記を日本語で作成してください。
単なる出来事の記録ではなく、一日を通して体験したシーンで感じた気持ちや感情の変化を深く掘り下げた個人的な日記を書いてください。

タイトルと本文を分けて、以下の形式で出力してください。

【タイトル】
（5-10文字程度でその日の感情や印象を表現する簡潔なタイトル）

【本文】
（150-200文字程度で、感情や心の動きを中心とした自然で個人的な文体の本文。時系列に沿って感情の変化や発見を描写してください）

日付: $dateStr
時間帯: $timeRange
${location != null ? '場所: $location\n' : ''}

シーン分析結果:
$analysesText''';

    // カスタムプロンプトが指定されている場合は統合（感情深掘り型対応）
    final prompt = customPrompt != null
        ? '''$basePrompt

以下のライティングプロンプトを参考にして、このシーンで体験したことを深く掘り下げて日記を作成してください：

「$customPrompt」

シーンの分析結果を踏まえ、以下の観点で日記を書いてください：
- 一日を通して感じた感情の変化や流れ
- 時間とともに変わっていく気持ちや印象
- 各シーンで心に残った瞬間や体験
- その日を振り返って感じる発見や気づき
- その日の体験が自分に与えた影響

$emphasis、時系列に沿って個人的で心に響く日記を作成してください。'''
        : '''$basePrompt

これらのシーンから読み取れる一日の流れや体験を、以下の点を意識して日記に表現してください：
- 一日を通して感じた感情の変化
- 時間の経過とともに変わる気持ちや印象
- 各シーンで心に残った瞬間や体験
- その日を振り返って得られる気づきや発見

感情豊かで個人的な日記を作成してください。''';

    // デバッグログ: 複数画像プロンプト統合確認（感情深掘り型対応）
    debugPrint('=== 複数画像AI生成プロンプト統合確認 ===');
    debugPrint('カスタムプロンプト: ${customPrompt ?? "なし"}');
    debugPrint('プロンプト種別: $promptType');
    debugPrint('最適化パラメータ: maxTokens=$multiImageMaxTokens, emphasis=$emphasis');
    debugPrint('統合後プロンプト長: ${prompt.length}文字');
    if (customPrompt != null) {
      debugPrint('複数画像感情深掘り型プロンプト統合: 成功');
    }

    try {
      final response = await _apiClient.sendTextRequest(
        prompt: prompt,
        maxOutputTokens: multiImageMaxTokens, // 生成ロジック最適化: プロンプト種別に応じた動的調整
      );

      if (response != null) {
        final content = _apiClient.extractTextFromResponse(response);
        if (content != null) {
          return _parseGeneratedDiary(content);
        }
      }

      return _offlineService.generateDiary(
        [],
        photoTimes.first,
        location,
        photoTimes,
      );
    } catch (e) {
      debugPrint('統合日記生成エラー: $e');
      return _offlineService.generateDiary(
        [],
        photoTimes.first,
        location,
        photoTimes,
      );
    }
  }
}
