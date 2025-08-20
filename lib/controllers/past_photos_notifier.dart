import 'package:flutter/material.dart';
import '../models/states/past_photos_state.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../services/interfaces/photo_access_control_service_interface.dart';
import '../models/plans/plan.dart';
import '../core/service_registration.dart';
import '../core/errors/error_handler.dart';
import '../services/logging_service.dart';

/// 過去の写真機能の状態を管理するNotifier
class PastPhotosNotifier extends ChangeNotifier {
  final IPhotoService _photoService;
  final IPhotoAccessControlService _accessControlService;

  PastPhotosState _state = PastPhotosState.initial();
  PastPhotosState get state => _state;

  /// 選択された写真のIDセット（PhotoSelectionControllerと連携）
  final Set<String> _selectedPhotoIds = {};
  Set<String> get selectedPhotoIds => Set.unmodifiable(_selectedPhotoIds);

  /// 使用済み写真のIDセット
  Set<String> _usedPhotoIds = {};
  Set<String> get usedPhotoIds => Set.unmodifiable(_usedPhotoIds);

  PastPhotosNotifier({
    required IPhotoService photoService,
    required IPhotoAccessControlService accessControlService,
  }) : _photoService = photoService,
       _accessControlService = accessControlService;

  /// 工場メソッドでサービスを自動注入
  factory PastPhotosNotifier.create() {
    return PastPhotosNotifier(
      photoService: ServiceRegistration.get<IPhotoService>(),
      accessControlService:
          ServiceRegistration.get<IPhotoAccessControlService>(),
    );
  }

  /// 初期データの読み込み
  Future<void> loadInitialPhotos(Plan currentPlan) async {
    if (_state.isLoading) return;

    _updateState(
      _state.copyWith(
        isLoading: true,
        isInitialLoading: true,
        clearError: true,
      ),
    );

    try {
      final loggingService = await LoggingService.getInstance();

      // アクセス可能な日付範囲を取得
      final accessibleDate = _accessControlService.getAccessibleDateForPlan(
        currentPlan,
      );
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 日付範囲を計算
      final startDate = accessibleDate;
      final endDate = today; // 今日は除外

      loggingService.debug(
        '過去の写真を読み込み中',
        context: 'PastPhotosNotifier.loadInitialPhotos',
        data: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'plan': currentPlan.displayName,
        }.toString(),
      );

      // 写真を取得（Result版）
      final photosResult = await _photoService.getPhotosEfficientResult(
        startDate: startDate,
        endDate: endDate,
        limit: _state.photosPerPage,
      );

      if (!photosResult.isSuccess) {
        throw photosResult.error;
      }

      final photos = photosResult.value;

      // 月別にグループ化
      final photosByMonth = _state.groupPhotosByMonth(photos);

      _updateState(
        _state.copyWith(
          photos: photos,
          photosByMonth: photosByMonth,
          currentPage: 0,
          hasMore: photos.length >= _state.photosPerPage,
          isLoading: false,
          isInitialLoading: false,
        ),
      );

      loggingService.info(
        '過去の写真読み込み完了',
        context: 'PastPhotosNotifier.loadInitialPhotos',
        data: '写真数: ${photos.length}',
      );
    } catch (e) {
      final loggingService = await LoggingService.getInstance();
      final appError = ErrorHandler.handleError(e, context: '過去の写真読み込み');

      loggingService.error(
        '過去の写真読み込みエラー',
        context: 'PastPhotosNotifier.loadInitialPhotos',
        error: appError,
      );

      _updateState(
        _state.copyWith(
          isLoading: false,
          isInitialLoading: false,
          errorMessage: appError.message,
        ),
      );
    }
  }

  /// 追加の写真を読み込み（ページネーション）
  Future<void> loadMorePhotos(Plan currentPlan) async {
    if (_state.isLoading || !_state.hasMore) return;

    _updateState(_state.copyWith(isLoading: true));

    try {
      final offset = _state.photos.length;

      // アクセス可能な日付範囲を取得
      final accessibleDate = _accessControlService.getAccessibleDateForPlan(
        currentPlan,
      );
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 追加の写真を取得（Result版）
      final morePhotosResult = await _photoService.getPhotosEfficientResult(
        startDate: accessibleDate,
        endDate: today,
        limit: _state.photosPerPage,
        offset: offset,
      );

      if (!morePhotosResult.isSuccess) {
        throw morePhotosResult.error;
      }

      final morePhotos = morePhotosResult.value;

      if (morePhotos.isEmpty) {
        _updateState(_state.copyWith(hasMore: false, isLoading: false));
        return;
      }

      // 既存の写真と結合
      final allPhotos = [..._state.photos, ...morePhotos];

      // 月別にグループ化を更新
      final photosByMonth = _state.groupPhotosByMonth(allPhotos);

      _updateState(
        _state.copyWith(
          photos: allPhotos,
          photosByMonth: photosByMonth,
          currentPage: _state.nextPage,
          hasMore: morePhotos.length >= _state.photosPerPage,
          isLoading: false,
        ),
      );
    } catch (e) {
      final loggingService = await LoggingService.getInstance();
      final appError = ErrorHandler.handleError(e, context: '追加写真読み込み');

      loggingService.error(
        '追加写真読み込みエラー',
        context: 'PastPhotosNotifier.loadMorePhotos',
        error: appError,
      );

      _updateState(
        _state.copyWith(isLoading: false, errorMessage: appError.message),
      );
    }
  }

  /// 特定の日付の写真のみを読み込み
  Future<void> loadPhotosForDate(DateTime date) async {
    if (_state.isLoading) return;

    // 日付移動時に選択をクリア
    clearSelection();

    _updateState(
      _state.copyWith(isLoading: true, selectedDate: date, clearError: true),
    );

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
        999,
      );

      final photosResult = await _photoService.getPhotosEfficientResult(
        startDate: startOfDay,
        endDate: endOfDay,
        limit: 200, // 1日分なので多めに取得
      );

      if (!photosResult.isSuccess) {
        throw photosResult.error;
      }

      final photos = photosResult.value;

      // 選択された日付の写真のみでグループ化
      final photosByMonth = _state.groupPhotosByMonth(photos);

      _updateState(
        _state.copyWith(
          photos: photos,
          photosByMonth: photosByMonth,
          currentPage: 0,
          hasMore: false, // 特定日付の場合はページネーション不要
          isLoading: false,
          isInitialLoading: false,
        ),
      );
    } catch (e) {
      final loggingService = await LoggingService.getInstance();
      final appError = ErrorHandler.handleError(e, context: '日付指定写真読み込み');

      loggingService.error(
        '日付指定写真読み込みエラー',
        context: 'PastPhotosNotifier.loadPhotosForDate',
        error: appError,
      );

      _updateState(
        _state.copyWith(isLoading: false, errorMessage: appError.message),
      );
    }
  }

  /// 日付選択をクリア
  void clearDateSelection(Plan currentPlan) {
    // 日付選択クリア時に選択もクリア
    clearSelection();

    _updateState(
      _state.copyWith(clearSelectedDate: true, isCalendarView: false),
    );

    // 全期間の写真を再読み込み
    loadInitialPhotos(currentPlan);
  }

  /// カレンダー表示モードの切り替え
  void toggleCalendarView() {
    _updateState(_state.copyWith(isCalendarView: !_state.isCalendarView));
  }

  /// 写真の選択状態を切り替え
  void togglePhotoSelection(String photoId) {
    if (_selectedPhotoIds.contains(photoId)) {
      _selectedPhotoIds.remove(photoId);
    } else {
      _selectedPhotoIds.add(photoId);
    }
    notifyListeners();
  }

  /// 選択をクリア
  void clearSelection() {
    _selectedPhotoIds.clear();
    notifyListeners();
  }

  /// 使用済み写真IDを設定
  void setUsedPhotoIds(Set<String> usedIds) {
    _usedPhotoIds = Set.from(usedIds);
    notifyListeners();
  }

  /// 写真が使用済みかどうかをチェック
  bool isPhotoUsed(String photoId) {
    return _usedPhotoIds.contains(photoId);
  }

  /// エラーをクリア
  void clearError() {
    if (_state.errorMessage != null) {
      _updateState(_state.copyWith(clearError: true));
    }
  }

  /// 状態を更新
  void _updateState(PastPhotosState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _selectedPhotoIds.clear();
    _usedPhotoIds.clear();
    super.dispose();
  }
}
