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
/// 日記・タグ生成。月間使用量制限は内部で [ISubscriptionService] を参照する。
/// 残回数・使用可否の公開 API は [ISubscriptionService] のみ。
abstract class IAiService {
  /// インターネット接続があるかどうかを確認
  Future<bool> isOnline();

  /// 画像から直接日記を生成（Vision API使用）
  ///
  /// 生成前に月間使用量制限チェックを行う。使用量の記録は行わない。
  /// 呼び出し側は日記の保存成功後に [recordGenerationUsage] を呼ぶこと。
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
    String? contextText,
    Locale? locale,
    DiaryLength? diaryLength,
  });

  /// 複数画像から順次日記を生成（Vision API使用）
  ///
  /// 生成前に月間使用量制限チェックを行う。使用量の記録は行わない。
  /// 呼び出し側は日記の保存成功後に [recordGenerationUsage] を呼ぶこと。
  ///
  /// Returns:
  /// - Success: 生成された [DiaryGenerationResult]（title + content）
  /// - Failure: [AiProcessingException] API呼び出し失敗時
  /// - Failure: [AiProcessingException] 月間使用量制限超過時（isUsageLimitError: true）
  Future<Result<DiaryGenerationResult>> generateDiaryFromMultipleImages({
    required List<({Uint8List imageData, DateTime time})> imagesWithTimes,
    String? location,
    String? prompt,
    String? contextText,
    Function(int current, int total)? onProgress,
    Locale? locale,
    DiaryLength? diaryLength,
  });

  /// 破棄された生成結果では呼ばないこと。
  Future<Result<void>> recordGenerationUsage();

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
}
