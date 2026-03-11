import 'package:photo_manager/photo_manager.dart';

import '../core/result/result.dart';
import '../core/service_locator.dart';
import '../core/service_registration.dart';
import '../models/diary_entry.dart';
import '../services/interfaces/diary_crud_service_interface.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../services/interfaces/photo_service_interface.dart';
import 'base_error_controller.dart';

/// DiaryDetailScreen のエラー種別
enum DiaryDetailErrorType { notFound, loadFailed, updateFailed, deleteFailed }

/// DiaryDetailScreen の状態管理・ビジネスロジック
class DiaryDetailController extends BaseErrorController {
  DiaryEntry? _diaryEntry;
  List<AssetEntity> _photoAssets = [];
  bool _isEditing = false;
  bool _wasModified = false;
  int _requestVersion = 0;
  DiaryDetailErrorType? _errorType;
  String _rawErrorDetail = '';

  /// 現在の日記エントリー
  DiaryEntry? get diaryEntry => _diaryEntry;

  /// 写真アセット
  List<AssetEntity> get photoAssets => _photoAssets;

  /// 編集モードか
  bool get isEditing => _isEditing;

  /// 日記が更新されたか（詳細画面から戻る際の判定用）
  bool get wasModified => _wasModified;

  /// エラー種別
  DiaryDetailErrorType? get errorType => _errorType;

  /// エラー詳細（技術的な情報）
  String get rawErrorDetail => _rawErrorDetail;

  /// エラー状態か（BaseErrorController の hasError をオーバーライド）
  @override
  bool get hasError => _errorType != null;

  void _setErrorState(DiaryDetailErrorType type, [String detail = '']) {
    _errorType = type;
    _rawErrorDetail = detail;
    setLoading(false);
    notifyListeners();
  }

  void _clearErrorState() {
    _errorType = null;
    _rawErrorDetail = '';
  }

  /// 日記エントリーを読み込む
  Future<void> loadDiaryEntry(String diaryId) async {
    final localVersion = ++_requestVersion;
    try {
      _clearErrorState();
      setLoading(true);

      final diaryService =
          await ServiceRegistration.getAsync<IDiaryCrudService>();
      if (localVersion != _requestVersion) return;
      final result = await diaryService.getDiaryEntry(diaryId);

      switch (result) {
        case Success(data: final entry):
          if (entry == null) {
            if (localVersion != _requestVersion) return;
            _setErrorState(DiaryDetailErrorType.notFound);
            return;
          }

          final photoService =
              await ServiceRegistration.getAsync<IPhotoService>();
          if (localVersion != _requestVersion) return;
          final assetsResult = await photoService.getAssetsByIds(
            entry.photoIds,
          );

          if (localVersion != _requestVersion) return;

          if (assetsResult.isFailure) {
            try {
              serviceLocator.get<ILoggingService>().warning(
                'Failed to load photo assets for diary entry',
                context: 'DiaryDetailController.loadDiaryEntry',
                data:
                    'diaryId: ${entry.id}, error: ${assetsResult.error.message}',
              );
            } catch (_) {
              // LoggingService unavailable — non-critical, photo loading continues with fallback
            }
          }

          _diaryEntry = entry;
          _photoAssets = assetsResult.getOrDefault([]);
          setLoading(false);

        case Failure(exception: final e):
          if (localVersion != _requestVersion) return;
          _setErrorState(DiaryDetailErrorType.loadFailed, e.message);
      }
    } catch (e) {
      if (localVersion != _requestVersion) return;
      _setErrorState(DiaryDetailErrorType.loadFailed, '$e');
    }
  }

  /// 日記を更新する。成功時 true を返す。
  Future<bool> updateDiary(
    String diaryId, {
    required String title,
    required String content,
  }) async {
    if (_diaryEntry == null) return false;

    final localVersion = ++_requestVersion;
    try {
      setLoading(true);
      _clearErrorState();

      final diaryService =
          await ServiceRegistration.getAsync<IDiaryCrudService>();
      if (localVersion != _requestVersion) return false;

      final updatedEntry = _diaryEntry!.copyWith(
        title: title,
        content: content,
        updatedAt: DateTime.now(),
      );
      final updateResult = await diaryService.updateDiaryEntry(updatedEntry);
      if (localVersion != _requestVersion) return updateResult.isSuccess;

      switch (updateResult) {
        case Success():
          _isEditing = false;
          _wasModified = true;
          // リロードして最新データを取得
          await loadDiaryEntry(diaryId);
          return true;
        case Failure(exception: final e):
          _setErrorState(DiaryDetailErrorType.updateFailed, e.message);
          return false;
      }
    } catch (e) {
      if (localVersion != _requestVersion) return false;
      _setErrorState(DiaryDetailErrorType.updateFailed, '$e');
      return false;
    }
  }

  /// 日記を削除する。成功時 true を返す。
  Future<bool> deleteDiary(String diaryId) async {
    if (_diaryEntry == null) return false;

    final localVersion = ++_requestVersion;
    try {
      setLoading(true);
      _clearErrorState();

      final diaryService =
          await ServiceRegistration.getAsync<IDiaryCrudService>();
      if (localVersion != _requestVersion) return false;
      final deleteResult = await diaryService.deleteDiaryEntry(diaryId);
      if (localVersion != _requestVersion) return deleteResult.isSuccess;

      switch (deleteResult) {
        case Success():
          setLoading(false);
          return true;
        case Failure(exception: final e):
          _setErrorState(DiaryDetailErrorType.deleteFailed, e.message);
          return false;
      }
    } catch (e) {
      if (localVersion != _requestVersion) return false;
      _setErrorState(DiaryDetailErrorType.deleteFailed, '$e');
      return false;
    }
  }

  /// 編集モードを開始する
  void startEditing() {
    _isEditing = true;
    notifyListeners();
  }

  /// 編集モードをキャンセルする
  void cancelEditing() {
    _isEditing = false;
    notifyListeners();
  }
}
