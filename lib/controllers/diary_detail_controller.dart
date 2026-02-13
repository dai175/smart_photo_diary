import 'package:photo_manager/photo_manager.dart';

import '../core/result/result.dart';
import '../core/service_locator.dart';
import '../core/service_registration.dart';
import '../models/diary_entry.dart';
import '../services/interfaces/diary_service_interface.dart';
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
  DiaryDetailErrorType? _errorType;
  String _rawErrorDetail = '';

  /// 現在の日記エントリー
  DiaryEntry? get diaryEntry => _diaryEntry;

  /// 写真アセット
  List<AssetEntity> get photoAssets => _photoAssets;

  /// 編集モードか
  bool get isEditing => _isEditing;

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
    try {
      _clearErrorState();
      setLoading(true);

      final diaryService = await ServiceRegistration.getAsync<IDiaryService>();
      final result = await diaryService.getDiaryEntry(diaryId);

      switch (result) {
        case Success(data: final entry):
          if (entry == null) {
            _setErrorState(DiaryDetailErrorType.notFound);
            return;
          }

          final photoService =
              await ServiceRegistration.getAsync<IPhotoService>();
          final assetsResult = await photoService.getAssetsByIds(
            entry.photoIds,
          );

          if (assetsResult.isFailure) {
            try {
              serviceLocator.get<ILoggingService>().warning(
                'Failed to load photo assets for diary entry',
                context: 'DiaryDetailController.loadDiaryEntry',
                data:
                    'diaryId: ${entry.id}, error: ${assetsResult.error.message}',
              );
            } catch (_) {}
          }

          _diaryEntry = entry;
          _photoAssets = assetsResult.getOrDefault([]);
          setLoading(false);

        case Failure(exception: final e):
          _setErrorState(DiaryDetailErrorType.loadFailed, e.message);
      }
    } catch (e) {
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

    try {
      setLoading(true);
      _clearErrorState();

      final diaryService = await ServiceRegistration.getAsync<IDiaryService>();

      final updatedEntry = _diaryEntry!.copyWith(
        title: title,
        content: content,
        updatedAt: DateTime.now(),
      );
      final updateResult = await diaryService.updateDiaryEntry(updatedEntry);

      switch (updateResult) {
        case Success():
          _isEditing = false;
          // リロードして最新データを取得
          await loadDiaryEntry(diaryId);
          return true;
        case Failure(exception: final e):
          _setErrorState(DiaryDetailErrorType.updateFailed, e.message);
          return false;
      }
    } catch (e) {
      _setErrorState(DiaryDetailErrorType.updateFailed, '$e');
      return false;
    }
  }

  /// 日記を削除する。成功時 true を返す。
  Future<bool> deleteDiary(String diaryId) async {
    if (_diaryEntry == null) return false;

    try {
      setLoading(true);
      _clearErrorState();

      final diaryService = await ServiceRegistration.getAsync<IDiaryService>();
      final deleteResult = await diaryService.deleteDiaryEntry(diaryId);

      switch (deleteResult) {
        case Success():
          setLoading(false);
          return true;
        case Failure(exception: final e):
          _setErrorState(DiaryDetailErrorType.deleteFailed, e.message);
          return false;
      }
    } catch (e) {
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
