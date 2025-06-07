import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 日記生成結果を保持するクラス
class DiaryGenerationResult {
  final String title;
  final String content;

  DiaryGenerationResult({required this.title, required this.content});
}

/// 写真の時刻とラベルのペア
class PhotoTimeLabel {
  final DateTime time;
  final List<String> labels;

  PhotoTimeLabel({required this.time, required this.labels});
}

/// AIを使用して日記文を生成するサービスクラス
class AiService {
  // Google Gemini APIのエンドポイント
  static const String _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-04-17:generateContent';

  // APIキーを.envファイルから取得
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  /// インターネット接続があるかどうかを確認
  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// 検出されたラベルから日記のタイトルと本文を生成
  ///
  /// [labels]: 画像から検出されたラベルのリスト
  /// [date]: 写真の撮影日時
  /// [location]: 撮影場所（オプション）
  /// [photoTimes]: 複数写真の場合の全撮影時刻（オプション）
  /// [photoTimeLabels]: 写真ごとの時刻とラベルのペア（オプション）
  Future<DiaryGenerationResult> generateDiaryFromLabels({
    required List<String> labels,
    required DateTime date,
    String? location,
    List<DateTime>? photoTimes,
    List<PhotoTimeLabel>? photoTimeLabels,
  }) async {
    try {
      // オンライン状態を確認
      final online = await isOnline();
      if (!online) {
        return _generateOfflineDiary(labels, date, location, photoTimes);
      }

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
      final prompt =
          '''
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

      // APIリクエストの作成
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'あなたは日記作成の専門家です。自然で個人的な日本語の文体で書いてください。\n\n$prompt'
                }
              ],
              'role': 'user'
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1000,
            'topP': 0.8,
            'topK': 10,
            'thinkingConfig': {
              'thinkingBudget': 0
            }
          },
        }),
      );

      // レスポンスの処理
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('API レスポンス: $data');
        
        // null安全性チェック
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          
          // Gemini 2.5の場合、異なるレスポンス構造の可能性を考慮
          String? content;
          
          // 通常の構造をチェック
          if (candidate['content'] != null && 
              candidate['content']['parts'] != null &&
              candidate['content']['parts'].isNotEmpty &&
              candidate['content']['parts'][0]['text'] != null) {
            content = candidate['content']['parts'][0]['text'];
          }
          // 代替構造をチェック（直接textフィールド）
          else if (candidate['content'] != null && candidate['content']['text'] != null) {
            content = candidate['content']['text'];
          }
          // 思考プロセス用の構造をチェック
          else if (candidate['text'] != null) {
            content = candidate['text'];
          }
          
          if (content != null && content.isNotEmpty) {
            return _parseGeneratedDiary(content.trim());
          } else {
            debugPrint('テキストコンテンツが見つかりません。finishReason: ${candidate['finishReason']}');
            return _generateOfflineDiary(labels, date, location, null);
          }
        } else {
          debugPrint('レスポンス構造が予期されたものと異なります: $data');
          return _generateOfflineDiary(labels, date, location, null);
        }
      } else {
        debugPrint('API エラー: ${response.statusCode} - ${response.body}');
        return _generateOfflineDiary(labels, date, location, null);
      }
    } catch (e) {
      debugPrint('日記生成エラー: $e');
      return _generateOfflineDiary(labels, date, location, photoTimes);
    }
  }

  /// オフライン時のシンプルな日記生成
  DiaryGenerationResult _generateOfflineDiary(
    List<String> labels,
    DateTime date,
    String? location,
    List<DateTime>? photoTimes,
  ) {
    final dateStr = DateFormat('yyyy年MM月dd日').format(date);
    final timeOfDay = _getTimeOfDayForPhotos(date, photoTimes);

    // シンプルなテンプレートベースの日記
    final locationText = location != null && location.isNotEmpty
        ? '$locationで'
        : '';

    String title;
    String content;

    if (labels.isEmpty) {
      title = '今日の記録';
      content = '$dateStr、$locationText過ごした一日の記録です。';
    } else if (labels.length == 1) {
      title = '${labels[0]}の$timeOfDay';
      content = '$dateStr、$timeOfDayに$locationText${labels[0]}について過ごしました。';
    } else {
      title = '${labels.first}と${labels.length - 1}つの出来事';
      content = '$dateStr、$timeOfDayに$locationText${labels.join('や')}などについて過ごしました。';
    }

    return DiaryGenerationResult(title: title, content: content);
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

  /// 複数画像から順次日記を生成（Gemini Vision API使用）
  ///
  /// [imagesWithTimes]: 画像データと撮影時刻のペアリスト
  /// [location]: 撮影場所（オプション）
  /// [onProgress]: 進捗コールバック（現在の画像番号, 総画像数）
  Future<DiaryGenerationResult> generateDiaryFromMultipleImages({
    required List<({Uint8List imageData, DateTime time})> imagesWithTimes,
    String? location,
    Function(int current, int total)? onProgress,
  }) async {
    if (imagesWithTimes.isEmpty) {
      throw Exception('画像が提供されていません');
    }

    try {
      // オンライン状態を確認
      final online = await isOnline();
      if (!online) {
        final List<DateTime> offlineTimesList = imagesWithTimes.map<DateTime>((e) => e.time).toList();
        return _generateOfflineDiary([], imagesWithTimes.first.time, location, offlineTimesList);
      }

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
      return _generateOfflineDiary([], imagesWithTimes.first.time, location, fallbackTimesList);
    }
  }

  /// 画像から直接日記を生成（Gemini Vision API使用）
  ///
  /// [imageData]: 画像のバイナリデータ
  /// [date]: 写真の撮影日時
  /// [location]: 撮影場所（オプション）
  /// [photoTimes]: 複数写真の場合の全撮影時刻（オプション）
  Future<DiaryGenerationResult> generateDiaryFromImage({
    required Uint8List imageData,
    required DateTime date,
    String? location,
    List<DateTime>? photoTimes,
  }) async {
    try {
      // オンライン状態を確認
      final online = await isOnline();
      if (!online) {
        return _generateOfflineDiary([], date, location, null);
      }

      // 時間情報を取得（必要な場合のみ）
      // 現在は日付と時間情報をプロンプトから除外しているため、これらの変数は使用しない

      // Base64エンコード
      final base64Image = base64Encode(imageData);

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

      // APIリクエストの作成
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inlineData': {
                    'mimeType': 'image/jpeg',
                    'data': base64Image
                  }
                }
              ],
              'role': 'user'
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1000,
            'topP': 0.8,
            'topK': 10,
            'thinkingConfig': {
              'thinkingBudget': 0
            }
          },
        }),
      );

      // レスポンスの処理
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Vision API レスポンス: $data');
        
        // null安全性チェック
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          
          // Gemini 2.5の場合、異なるレスポンス構造の可能性を考慮
          String? content;
          
          // 通常の構造をチェック
          if (candidate['content'] != null && 
              candidate['content']['parts'] != null &&
              candidate['content']['parts'].isNotEmpty &&
              candidate['content']['parts'][0]['text'] != null) {
            content = candidate['content']['parts'][0]['text'];
          }
          // 代替構造をチェック（直接textフィールド）
          else if (candidate['content'] != null && candidate['content']['text'] != null) {
            content = candidate['content']['text'];
          }
          // 思考プロセス用の構造をチェック
          else if (candidate['text'] != null) {
            content = candidate['text'];
          }
          
          if (content != null && content.isNotEmpty) {
            return _parseGeneratedDiary(content.trim());
          } else {
            debugPrint('Vision APIでテキストコンテンツが見つかりません。finishReason: ${candidate['finishReason']}');
            return _generateOfflineDiary([], date, location, null);
          }
        } else {
          debugPrint('Vision APIレスポンス構造が予期されたものと異なります: $data');
          return _generateOfflineDiary([], date, location, null);
        }
      } else {
        debugPrint('Vision API エラー: ${response.statusCode} - ${response.body}');
        return _generateOfflineDiary([], date, location, null);
      }
    } catch (e) {
      debugPrint('Vision API日記生成エラー: $e');
      return _generateOfflineDiary([], date, location, null);
    }
  }

  /// 時間帯の文字列を取得
  String _getTimeOfDay(DateTime date) {
    final hour = date.hour;
    if (hour >= 5 && hour < 12) return '朝';
    if (hour >= 12 && hour < 18) return '昼';
    if (hour >= 18 && hour < 22) return '夕方';
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
    
    // Base64エンコード
    final base64Image = base64Encode(imageData);

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
      // APIリクエストの作成
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inlineData': {
                    'mimeType': 'image/jpeg',
                    'data': base64Image
                  }
                }
              ],
              'role': 'user'
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 500,
            'topP': 0.8,
            'topK': 10,
            'thinkingConfig': {
              'thinkingBudget': 0
            }
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          
          String? content;
          if (candidate['content'] != null && 
              candidate['content']['parts'] != null &&
              candidate['content']['parts'].isNotEmpty &&
              candidate['content']['parts'][0]['text'] != null) {
            content = candidate['content']['parts'][0]['text'];
          }
          
          if (content != null && content.isNotEmpty) {
            return '$timeStr($timeOfDay): ${content.trim()}';
          }
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
      return _generateOfflineDiary([], DateTime.now(), location, photoTimes);
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
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ],
              'role': 'user'
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1000,
            'topP': 0.8,
            'topK': 10,
            'thinkingConfig': {
              'thinkingBudget': 0
            }
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('統合日記生成 API レスポンス: $data');
        
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          
          String? content;
          if (candidate['content'] != null && 
              candidate['content']['parts'] != null &&
              candidate['content']['parts'].isNotEmpty &&
              candidate['content']['parts'][0]['text'] != null) {
            content = candidate['content']['parts'][0]['text'];
          }
          
          if (content != null && content.isNotEmpty) {
            return _parseGeneratedDiary(content.trim());
          }
        }
      }
      
      debugPrint('統合日記生成 API エラー: ${response.statusCode} - ${response.body}');
      return _generateOfflineDiary([], photoTimes.first, location, photoTimes);
    } catch (e) {
      debugPrint('統合日記生成エラー: $e');
      return _generateOfflineDiary([], photoTimes.first, location, photoTimes);
    }
  }
}
