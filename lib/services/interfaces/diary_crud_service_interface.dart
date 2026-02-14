import 'package:photo_manager/photo_manager.dart';
import '../../models/diary_entry.dart';
import '../../core/result/result.dart';

/// 日記のCRUD操作を担当するインターフェース
abstract class IDiaryCrudService {
  /// 日記エントリーを保存
  ///
  /// Returns:
  /// - Success: 保存された [DiaryEntry]（IDが自動生成される）
  /// - Failure: [ServiceException] データベース書き込み失敗時
  Future<Result<DiaryEntry>> saveDiaryEntry({
    required DateTime date,
    required String title,
    required String content,
    required List<String> photoIds,
    String? location,
    List<String>? tags,
  });

  /// 指定されたIDの日記エントリーを取得
  ///
  /// Returns:
  /// - Success: 該当する [DiaryEntry]。IDが存在しない場合は null
  /// - Failure: [ServiceException] データベース読み取り失敗時
  Future<Result<DiaryEntry?>> getDiaryEntry(String id);

  /// 日記エントリーを更新
  ///
  /// Returns:
  /// - Success: void（更新完了）
  /// - Failure: [ServiceException] データベース書き込み失敗時
  Future<Result<void>> updateDiaryEntry(DiaryEntry entry);

  /// 日記エントリーを削除
  ///
  /// Returns:
  /// - Success: void（削除完了）
  /// - Failure: [ServiceException] データベース書き込み失敗時
  Future<Result<void>> deleteDiaryEntry(String id);

  /// 写真付きで日記エントリーを保存（後方互換性）
  ///
  /// Returns:
  /// - Success: 保存された [DiaryEntry]
  /// - Failure: [ServiceException] データベース書き込み失敗時
  Future<Result<DiaryEntry>> saveDiaryEntryWithPhotos({
    required DateTime date,
    required String title,
    required String content,
    required List<AssetEntity> photos,
  });

  /// 過去の写真から日記エントリーを作成
  ///
  /// Returns:
  /// - Success: 作成された [DiaryEntry]
  /// - Failure: [ServiceException] データベース書き込み失敗時
  Future<Result<DiaryEntry>> createDiaryForPastPhoto({
    required DateTime photoDate,
    required String title,
    required String content,
    required List<String> photoIds,
    String? location,
    List<String>? tags,
  });
}
