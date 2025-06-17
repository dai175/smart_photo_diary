import 'dart:typed_data';
import '../../core/result/result.dart';

/// 日記生成結果を保持するクラス
class DiaryGenerationResult {
  final String title;
  final String content;

  DiaryGenerationResult({required this.title, required this.content});
}


/// AIサービスのインターフェース
/// 
/// Phase 1.7.1更新: Result<T>パターンと使用量制限統合
abstract class AiServiceInterface {
  /// インターネット接続があるかどうかを確認
  Future<bool> isOnline();

  /// 画像から直接日記を生成（Vision API使用）
  /// Phase 1.7.1: 使用量制限チェック統合
  /// Phase 2.3.2: プロンプト統合対応
  Future<Result<DiaryGenerationResult>> generateDiaryFromImage({
    required Uint8List imageData,
    required DateTime date,
    String? location,
    List<DateTime>? photoTimes,
    String? prompt,
  });

  /// 複数画像から順次日記を生成（Vision API使用）
  /// Phase 1.7.1: 使用量制限チェック統合
  /// Phase 2.3.2: プロンプト統合対応
  Future<Result<DiaryGenerationResult>> generateDiaryFromMultipleImages({
    required List<({Uint8List imageData, DateTime time})> imagesWithTimes,
    String? location,
    String? prompt,
    Function(int current, int total)? onProgress,
  });

  /// 日記の内容からタグを自動生成
  /// Phase 1.7.1: タグ生成は使用量にカウントしない
  Future<Result<List<String>>> generateTagsFromContent({
    required String title,
    required String content,
    required DateTime date,
    required int photoCount,
  });

  // Phase 1.7.3: UI連携準備メソッド追加
  
  /// 残りAI生成回数を取得
  Future<Result<int>> getRemainingGenerations();
  
  /// 使用量リセット日を取得
  Future<Result<DateTime>> getNextResetDate();
  
  /// 制限状態をチェック
  Future<Result<bool>> canUseAiGeneration();
}