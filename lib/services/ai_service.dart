import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// AIを使用して日記文を生成するサービスクラス
class AiService {
  // OpenAI APIのエンドポイント
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  // APIキーを.envファイルから取得
  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

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
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': 'あなたは日記作成の専門家です。自然で個人的な日本語の文体で書いてください。',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 300,
        }),
      );

      // レスポンスの処理
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return content.trim();
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

  /// 時間帯の文字列を取得
  String _getTimeOfDay(DateTime date) {
    final hour = date.hour;
    if (hour >= 5 && hour < 12) return '朝';
    if (hour >= 12 && hour < 18) return '昼';
    if (hour >= 18 && hour < 22) return '夕方';
    return '夜';
  }
}
