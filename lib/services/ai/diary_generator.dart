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

  /// 検出されたラベルから日記のタイトルと本文を生成
  Future<DiaryGenerationResult> generateFromLabels({
    required List<String> labels,
    required DateTime date,
    String? location,
    List<DateTime>? photoTimes,
    List<PhotoTimeLabel>? photoTimeLabels,
    required bool isOnline,
  }) async {
    if (!isOnline) {
      return _offlineService.generateDiary(labels, date, location, photoTimes);
    }

    try {
      // 日付のフォーマット
      final dateStr = DateFormat('yyyy年MM月dd日').format(date);
      
      // 写真ごとの時間情報を活用したプロンプトを作成
      String timeInfo;
      if (photoTimeLabels != null && photoTimeLabels.isNotEmpty) {
        timeInfo = _buildTimeBasedPrompt(photoTimeLabels);
      } else {
        final timeOfDay = _getTimeOfDayForPhotos(date, photoTimes);
        timeInfo = '時間帯: $timeOfDay\nキーワード: ${labels.join(', ')}';
      }

      // プロンプトの作成
      final prompt = '''
あなたは日記作成の専門家です。以下の情報から、その日の出来事を振り返る日記を日本語で作成してください。
タイトルと本文を分けて、以下の形式で出力してください。

【タイトル】
（5-10文字程度の簡潔なタイトル）

【本文】
（150-200文字程度の自然で個人的な文体の本文。時系列に沿って出来事を描写してください）

日付: $dateStr
${location != null ? '場所: $location\n' : ''}
$timeInfo
''';

      final response = await _apiClient.sendTextRequest(prompt: prompt);
      
      if (response != null) {
        final content = _apiClient.extractTextFromResponse(response);
        if (content != null) {
          return _parseGeneratedDiary(content);
        }
      }
      
      return _offlineService.generateDiary(labels, date, location, photoTimes);
    } catch (e) {
      debugPrint('ラベルベース日記生成エラー: $e');
      return _offlineService.generateDiary(labels, date, location, photoTimes);
    }
  }

  /// 画像から直接日記を生成
  Future<DiaryGenerationResult> generateFromImage({
    required Uint8List imageData,
    required DateTime date,
    String? location,
    List<DateTime>? photoTimes,
    required bool isOnline,
  }) async {
    if (!isOnline) {
      return _offlineService.generateDiary([], date, location, null);
    }

    try {
      // プロンプトの作成
      final prompt = '''
あなたは日記作成の専門家です。この写真を見て、その日の出来事を振り返る日記を日本語で作成してください。
タイトルと本文を分けて、以下の形式で出力してください。

【タイトル】
（5-10文字程度の簡潔なタイトル）

【本文】
（150-200文字程度の自然で個人的な文体の本文${photoTimes != null && photoTimes.length > 1 ? '。時系列に沿って出来事を描写してください' : ''}）

${location != null ? '場所: $location\n' : ''}
写真の内容を詳しく観察して、その時の気持ちや体験を想像しながら書いてください。
''';

      final response = await _apiClient.sendVisionRequest(
        prompt: prompt,
        imageData: imageData,
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
    Function(int current, int total)? onProgress,
    required bool isOnline,
  }) async {
    if (imagesWithTimes.isEmpty) {
      throw Exception('画像が提供されていません');
    }

    if (!isOnline) {
      final List<DateTime> offlineTimesList = imagesWithTimes.map<DateTime>((e) => e.time).toList();
      return _offlineService.generateDiary([], imagesWithTimes.first.time, location, offlineTimesList);
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
      final List<DateTime> photoTimesList = sortedImages.map<DateTime>((e) => e.time).toList();
      return await _generateDiaryFromAnalyses(photoAnalyses, photoTimesList, location);
      
    } catch (e) {
      debugPrint('複数画像日記生成エラー: $e');
      final List<DateTime> fallbackTimesList = imagesWithTimes.map<DateTime>((e) => e.time).toList();
      return _offlineService.generateDiary([], imagesWithTimes.first.time, location, fallbackTimesList);
    }
  }

  /// 生成された日記テキストをタイトルと本文に分割
  DiaryGenerationResult _parseGeneratedDiary(String generatedText) {
    try {
      // 【タイトル】と【本文】で分割
      final titleMatch = RegExp(r'【タイトル】\s*(.+?)(?=【本文】|$)', dotAll: true).firstMatch(generatedText);
      final contentMatch = RegExp(r'【本文】\s*(.+?)$', dotAll: true).firstMatch(generatedText);

      String title = titleMatch?.group(1)?.trim() ?? '';
      String content = contentMatch?.group(1)?.trim() ?? '';

      // フォールバック：形式が異なる場合は最初の行をタイトル、残りを本文とする
      if (title.isEmpty || content.isEmpty) {
        final lines = generatedText.split('\n').where((line) => line.trim().isNotEmpty).toList();
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
      return DiaryGenerationResult(title: '今日の日記', content: generatedText.trim());
    }
  }

  /// 時間帯の文字列を取得
  String _getTimeOfDay(DateTime date) {
    final hour = date.hour;
    if (hour >= AiConstants.morningStartHour && hour < AiConstants.afternoonStartHour) return '朝';
    if (hour >= AiConstants.afternoonStartHour && hour < AiConstants.eveningStartHour) return '昼';
    if (hour >= AiConstants.eveningStartHour && hour < AiConstants.nightStartHour) return '夕方';
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

  /// 写真ごとの時間とラベル情報から時系列プロンプトを構築
  String _buildTimeBasedPrompt(List<PhotoTimeLabel> photoTimeLabels) {
    if (photoTimeLabels.isEmpty) return '';
    
    // 時刻順にソート
    final sortedPhotos = List<PhotoTimeLabel>.from(photoTimeLabels);
    sortedPhotos.sort((a, b) => a.time.compareTo(b.time));
    
    final buffer = StringBuffer();
    buffer.writeln('写真情報（時系列順）:');
    
    for (int i = 0; i < sortedPhotos.length; i++) {
      final photo = sortedPhotos[i];
      final timeStr = DateFormat('HH:mm').format(photo.time);
      final timeOfDay = _getTimeOfDay(photo.time);
      
      buffer.writeln('${i + 1}. $timeStr頃（$timeOfDay）: ${photo.labels.join(', ')}');
    }
    
    return buffer.toString().trim();
  }

  /// 1枚の画像を分析して説明を取得
  Future<String> _analyzeImage(Uint8List imageData, DateTime time, String? location) async {
    final timeStr = DateFormat('HH:mm').format(time);
    final timeOfDay = _getTimeOfDay(time);
    
    // 分析専用プロンプト
    final prompt = '''
この写真の内容を詳しく分析して、簡潔に説明してください。
以下の形式で回答してください：

この写真には[主な被写体・物・場面]が写っています。[具体的な詳細や特徴、雰囲気など50文字程度で]

時刻: $timeStr($timeOfDay)
${location != null ? '場所: $location\n' : ''}

写真の詳細を観察して、その時の状況や雰囲気を含めて分析してください。
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
  ) async {
    if (photoAnalyses.isEmpty) {
      return _offlineService.generateDiary([], DateTime.now(), location, photoTimes);
    }

    final dateStr = DateFormat('yyyy年MM月dd日').format(photoTimes.first);
    final timeRange = _getTimeOfDayForPhotos(photoTimes.first, photoTimes);
    
    // 統合プロンプト
    final analysesText = photoAnalyses.join('\n');
    final prompt = '''
以下の写真分析結果から、その日の出来事を振り返る日記を日本語で作成してください。
タイトルと本文を分けて、以下の形式で出力してください。

【タイトル】
（5-10文字程度の簡潔なタイトル）

【本文】
（150-200文字程度の自然で個人的な文体の本文。時系列に沿って出来事を描写してください）

日付: $dateStr
時間帯: $timeRange
${location != null ? '場所: $location\n' : ''}

写真分析結果:
$analysesText

これらの写真から読み取れる一日の流れや体験を、自然な日記の文体で表現してください。
''';

    try {
      final response = await _apiClient.sendTextRequest(prompt: prompt);

      if (response != null) {
        final content = _apiClient.extractTextFromResponse(response);
        if (content != null) {
          return _parseGeneratedDiary(content);
        }
      }
      
      return _offlineService.generateDiary([], photoTimes.first, location, photoTimes);
    } catch (e) {
      debugPrint('統合日記生成エラー: $e');
      return _offlineService.generateDiary([], photoTimes.first, location, photoTimes);
    }
  }
}