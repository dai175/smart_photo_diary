import 'dart:typed_data';
import 'dart:ui';

import '../../core/result/result.dart';
import '../../models/diary_length.dart';

/// 日記生成結果を保持するクラス
class DiaryGenerationResult {
  final String title;
  final String content;

  DiaryGenerationResult({required this.title, required this.content});
}

/// AIサービスのインターフェース
///
/// AI日記生成・タグ生成および使用量管理を提供する。
/// 内部的にSubscriptionServiceと連携し、月間使用量制限を適用する。
abstract class IAiService {
  /// インターネット接続があるかどうかを確認
  Future<bool> isOnline();

  /// 画像から直接日記を生成（Vision API使用）
  ///
  /// 生成前に月間使用量制限チェックを行い、成功後に使用量を記録する。
  ///
  /// Returns:
  /// - Success: 生成された [DiaryGenerationResult]（title + content）
  /// - Failure: [AiProcessingException] API呼び出し失敗時
  /// - Failure: [AiProcessingException] 月間使用量制限超過時（isUsageLimitError: true）
  Future<Result<DiaryGenerationResult>> generateDiaryFromImage({
    required Uint8List imageData,
    required DateTime date,
    String? location,
    List<DateTime>? photoTimes,
    String? prompt,
    Locale? locale,
    DiaryLength? diaryLength,
  });

  /// 複数画像から順次日記を生成（Vision API使用）
  ///
  /// 生成前に月間使用量制限チェックを行い、成功後に使用量を記録する。
  ///
  /// Returns:
  /// - Success: 生成された [DiaryGenerationResult]（title + content）
  /// - Failure: [AiProcessingException] API呼び出し失敗時
  /// - Failure: [AiProcessingException] 月間使用量制限超過時（isUsageLimitError: true）
  Future<Result<DiaryGenerationResult>> generateDiaryFromMultipleImages({
    required List<({Uint8List imageData, DateTime time})> imagesWithTimes,
    String? location,
    String? prompt,
    Function(int current, int total)? onProgress,
    Locale? locale,
    DiaryLength? diaryLength,
  });

  /// 日記の内容からタグを自動生成
  ///
  /// タグ生成は使用量にカウントしない。
  ///
  /// Returns:
  /// - Success: 生成されたタグ文字列リスト
  /// - Failure: [AiProcessingException] タグ生成処理失敗時
  Future<Result<List<String>>> generateTagsFromContent({
    required String title,
    required String content,
    required DateTime date,
    required int photoCount,
    Locale? locale,
  });

  /// 残りAI生成回数を取得
  ///
  /// Returns:
  /// - Success: 今月の残りAI生成可能回数
  /// - Failure: [ServiceException] SubscriptionServiceが利用不可の場合
  Future<Result<int>> getRemainingGenerations();

  /// 使用量リセット日を取得
  ///
  /// Returns:
  /// - Success: 次の月次リセット日時
  /// - Failure: [ServiceException] SubscriptionServiceが利用不可の場合
  Future<Result<DateTime>> getNextResetDate();

  /// AI生成が使用可能かチェック
  ///
  /// 月次リセット処理を実行した上で使用可否を判定する。
  ///
  /// Returns:
  /// - Success: 使用可能な場合 true、制限超過時 false
  /// - Failure: [ServiceException] SubscriptionServiceが利用不可の場合
  Future<Result<bool>> canUseAiGeneration();
}
