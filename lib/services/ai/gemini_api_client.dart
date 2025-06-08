import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../constants/app_constants.dart';

/// Gemini APIクライアント - API通信を担当
class GeminiApiClient {
  // Google Gemini APIのエンドポイント
  static String get _apiUrl => 'https://generativelanguage.googleapis.com/v1beta/models/${AiConstants.geminiModelName}:generateContent';

  // APIキーを.envファイルから取得
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  /// テキストベースのAPIリクエストを送信
  Future<Map<String, dynamic>?> sendTextRequest({
    required String prompt,
    double? temperature,
    int? maxOutputTokens,
  }) async {
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
            'temperature': temperature ?? AiConstants.defaultTemperature,
            'maxOutputTokens': maxOutputTokens ?? AiConstants.defaultMaxOutputTokens,
            'topP': AiConstants.defaultTopP,
            'topK': AiConstants.defaultTopK,
            'thinkingConfig': {
              'thinkingBudget': 0
            }
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Gemini API レスポンス: $data');
        return data;
      } else {
        debugPrint('Gemini API エラー: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Gemini API リクエストエラー: $e');
      return null;
    }
  }

  /// 画像付きのAPIリクエストを送信（Vision API）
  Future<Map<String, dynamic>?> sendVisionRequest({
    required String prompt,
    required Uint8List imageData,
    double? temperature,
    int? maxOutputTokens,
  }) async {
    try {
      // Base64エンコード
      final base64Image = base64Encode(imageData);

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
            'temperature': temperature ?? AiConstants.defaultTemperature,
            'maxOutputTokens': maxOutputTokens ?? AiConstants.defaultMaxOutputTokens,
            'topP': AiConstants.defaultTopP,
            'topK': AiConstants.defaultTopK,
            'thinkingConfig': {
              'thinkingBudget': 0
            }
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Gemini Vision API レスポンス: $data');
        return data;
      } else {
        debugPrint('Gemini Vision API エラー: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Gemini Vision API リクエストエラー: $e');
      return null;
    }
  }

  /// APIレスポンスからテキストコンテンツを抽出
  String? extractTextFromResponse(Map<String, dynamic> data) {
    try {
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
          return null;
        }
      } else {
        debugPrint('レスポンス構造が予期されたものと異なります: $data');
        return null;
      }
    } catch (e) {
      debugPrint('レスポンス解析エラー: $e');
      return null;
    }
  }
}