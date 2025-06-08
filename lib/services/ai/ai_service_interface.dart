import 'dart:typed_data';

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

/// AIサービスのインターフェース
abstract class AiServiceInterface {
  /// インターネット接続があるかどうかを確認
  Future<bool> isOnline();

  /// 検出されたラベルから日記のタイトルと本文を生成
  Future<DiaryGenerationResult> generateDiaryFromLabels({
    required List<String> labels,
    required DateTime date,
    String? location,
    List<DateTime>? photoTimes,
    List<PhotoTimeLabel>? photoTimeLabels,
  });

  /// 画像から直接日記を生成（Vision API使用）
  Future<DiaryGenerationResult> generateDiaryFromImage({
    required Uint8List imageData,
    required DateTime date,
    String? location,
    List<DateTime>? photoTimes,
  });

  /// 複数画像から順次日記を生成（Vision API使用）
  Future<DiaryGenerationResult> generateDiaryFromMultipleImages({
    required List<({Uint8List imageData, DateTime time})> imagesWithTimes,
    String? location,
    Function(int current, int total)? onProgress,
  });

  /// 日記の内容からタグを自動生成
  Future<List<String>> generateTagsFromContent({
    required String title,
    required String content,
    required DateTime date,
    required int photoCount,
  });
}