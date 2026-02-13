import '../storage_service.dart';
import '../../models/import_result.dart';
import '../../core/result/result.dart';

/// ストレージサービスのインターフェース
///
/// データのバックアップ（エクスポート）、リストア（インポート）、
/// ストレージ使用量の取得、データベース最適化を提供する。
abstract class IStorageService {
  /// ストレージ使用量を取得する
  ///
  /// Throws: ファイルシステムエラー時に例外をスローする可能性あり。
  /// Result版の [getStorageInfoResult] の使用を推奨。
  Future<StorageInfo> getStorageInfo();

  /// データのエクスポート（保存先選択可能）
  ///
  /// [startDate] / [endDate] で期間フィルター可能。
  ///
  /// 戻り値: 保存先パス。キャンセル時は null。
  ///
  /// Throws: [StorageException] 日記データ取得失敗時。
  /// Result版の [exportDataResult] の使用を推奨。
  Future<String?> exportData({DateTime? startDate, DateTime? endDate});

  /// データのインポート（リストア機能）
  ///
  /// ファイル選択ダイアログを表示し、JSONバックアップファイルを読み込む。
  ///
  /// Returns:
  /// - Success: [ImportResult]（成功/スキップ/失敗件数、エラー詳細）
  /// - Failure: [ServiceException] ファイル未選択、ファイル不存在、
  ///   JSON解析エラー、バックアップ形式不正、バージョン非互換時
  /// - Failure: [StorageException] 既存データ取得失敗、エントリー保存失敗時
  Future<Result<ImportResult>> importData();

  /// データベースの最適化
  ///
  /// Hiveデータベースのコンパクトと一時ファイルの削除を実行。
  ///
  /// 戻り値: 常に true。
  /// Result版の [optimizeDatabaseResult] の使用を推奨。
  Future<bool> optimizeDatabase();

  // ========================================
  // Result<T>パターン版のメソッド
  // ========================================

  /// ストレージ使用量を取得する（Result版）
  ///
  /// Returns:
  /// - Success: [StorageInfo]（総サイズ、日記データサイズ）
  /// - Failure: [ServiceException] ファイルシステムエラー時
  Future<Result<StorageInfo>> getStorageInfoResult();

  /// データのエクスポート（Result版）
  ///
  /// Returns:
  /// - Success: 保存先パス。キャンセル時は null
  /// - Failure: [ServiceException] エクスポート処理失敗時
  Future<Result<String?>> exportDataResult({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// データベースの最適化（Result版）
  ///
  /// Returns:
  /// - Success: 最適化結果（true）
  /// - Failure: [ServiceException] 最適化処理失敗時
  Future<Result<bool>> optimizeDatabaseResult();
}
