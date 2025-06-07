import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  /// 検出されたラベルから日記文を生成
  ///
  /// [labels]: 画像から検出されたラベルのリスト
  /// [date]: 写真の撮影日時
  /// [location]: 撮影場所（オプション）
  Future<String> generateDiaryFromLabels({
    required List<String> labels,
    required DateTime date,
    String? location,
  }) async {
    try {
      // オンライン状態を確認
      final online = await isOnline();
      if (!online) {
        return _generateOfflineDiary(labels, date, location);
      }

      // 日付のフォーマット
      final dateStr = DateFormat('yyyy年MM月dd日').format(date);
      final timeOfDay = _getTimeOfDay(date);

      // プロンプトの作成
      final prompt =
          '''
あなたは日記作成の専門家です。以下の情報から、その日の出来事を振り返る日記を日本語で作成してください。
自然で個人的な文体で、150-200文字程度にまとめてください。

日付: $dateStr
時間帯: $timeOfDay
${location != null ? '場所: $location\n' : ''}
キーワード: ${labels.join(', ')}

日記:
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
            return content.trim();
          } else {
            debugPrint('テキストコンテンツが見つかりません。finishReason: ${candidate['finishReason']}');
            return _generateOfflineDiary(labels, date, location);
          }
        } else {
          debugPrint('レスポンス構造が予期されたものと異なります: $data');
          return _generateOfflineDiary(labels, date, location);
        }
      } else {
        debugPrint('API エラー: ${response.statusCode} - ${response.body}');
        return _generateOfflineDiary(labels, date, location);
      }
    } catch (e) {
      debugPrint('日記生成エラー: $e');
      return _generateOfflineDiary(labels, date, location);
    }
  }

  /// オフライン時のシンプルな日記生成
  String _generateOfflineDiary(
    List<String> labels,
    DateTime date,
    String? location,
  ) {
    final dateStr = DateFormat('yyyy年MM月dd日').format(date);
    final timeOfDay = _getTimeOfDay(date);

    // シンプルなテンプレートベースの日記
    final locationText = location != null && location.isNotEmpty
        ? '$locationで'
        : '';

    if (labels.isEmpty) {
      return '$dateStr、$locationText過ごした一日の記録です。';
    } else if (labels.length == 1) {
      return '$dateStr、$timeOfDayに$locationText${labels[0]}について過ごしました。';
    } else {
      return '$dateStr、$timeOfDayに$locationText${labels.join('や')}などについて過ごしました。';
    }
  }

  /// 画像から直接日記を生成（Gemini Vision API使用）
  ///
  /// [imageData]: 画像のバイナリデータ
  /// [date]: 写真の撮影日時
  /// [location]: 撮影場所（オプション）
  Future<String> generateDiaryFromImage({
    required Uint8List imageData,
    required DateTime date,
    String? location,
  }) async {
    try {
      // オンライン状態を確認
      final online = await isOnline();
      if (!online) {
        return _generateOfflineDiary([], date, location);
      }

      // 日付のフォーマット
      final dateStr = DateFormat('yyyy年MM月dd日').format(date);
      final timeOfDay = _getTimeOfDay(date);

      // Base64エンコード
      final base64Image = base64Encode(imageData);

      // プロンプトの作成
      final prompt = '''
あなたは日記作成の専門家です。この写真を見て、その日の出来事を振り返る日記を日本語で作成してください。
自然で個人的な文体で、150-200文字程度にまとめてください。

日付: $dateStr
時間帯: $timeOfDay
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
            return content.trim();
          } else {
            debugPrint('Vision APIでテキストコンテンツが見つかりません。finishReason: ${candidate['finishReason']}');
            return _generateOfflineDiary([], date, location);
          }
        } else {
          debugPrint('Vision APIレスポンス構造が予期されたものと異なります: $data');
          return _generateOfflineDiary([], date, location);
        }
      } else {
        debugPrint('Vision API エラー: ${response.statusCode} - ${response.body}');
        return _generateOfflineDiary([], date, location);
      }
    } catch (e) {
      debugPrint('Vision API日記生成エラー: $e');
      return _generateOfflineDiary([], date, location);
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
}
