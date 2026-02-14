import 'dart:typed_data';
import 'dart:ui';

import 'package:photo_manager/photo_manager.dart';

import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../core/errors/error_handler.dart';
import '../core/service_locator.dart';
import '../core/service_registration.dart';
import '../models/writing_prompt.dart';
import '../services/ai/ai_service_interface.dart';
import '../services/interfaces/diary_crud_service_interface.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../services/interfaces/prompt_service_interface.dart';
import 'base_error_controller.dart';

/// DiaryPreviewScreen のエラー種別
enum DiaryPreviewErrorType { noPhotos, generationFailed, saveFailed }

/// DiaryPreviewScreen の状態管理・ビジネスロジック
class DiaryPreviewController extends BaseErrorController {
  late final ILoggingService _logger;
  late final IPhotoService _photoService;

  bool _isInitializing = true;
  bool _isSaving = false;
  bool _isAnalyzingPhotos = false;
  int _currentPhotoIndex = 0;
  int _totalPhotos = 0;
  DateTime _photoDateTime = DateTime.now();
  WritingPrompt? _selectedPrompt;
  String _generatedTitle = '';
  String _generatedContent = '';
  DiaryPreviewErrorType? _errorType;
  String? _savedDiaryId;
  bool _usageLimitReached = false;

  /// 初期化中か
  bool get isInitializing => _isInitializing;

  /// 保存中か
  bool get isSaving => _isSaving;

  /// 写真分析中か
  bool get isAnalyzingPhotos => _isAnalyzingPhotos;

  /// 現在分析中の写真インデックス
  int get currentPhotoIndex => _currentPhotoIndex;

  /// 合計写真数
  int get totalPhotos => _totalPhotos;

  /// 写真の撮影日時
  DateTime get photoDateTime => _photoDateTime;

  /// 選択中のプロンプト
  WritingPrompt? get selectedPrompt => _selectedPrompt;

  /// 生成されたタイトル
  String get generatedTitle => _generatedTitle;

  /// 生成された本文
  String get generatedContent => _generatedContent;

  /// エラー種別
  DiaryPreviewErrorType? get errorType => _errorType;

  /// エラー状態か
  @override
  bool get hasError => _errorType != null;

  /// 保存された日記ID（自動保存後のナビゲーション用）
  String? get savedDiaryId => _savedDiaryId;

  /// 使用量制限に到達したか
  bool get usageLimitReached => _usageLimitReached;

  DiaryPreviewController() {
    _logger = serviceLocator.get<ILoggingService>();
    _photoService = ServiceRegistration.get<IPhotoService>();
  }

  void _setErrorState(DiaryPreviewErrorType type) {
    _errorType = type;
    setLoading(false);
    _isSaving = false;
    notifyListeners();
  }

  void _clearErrorState() {
    _errorType = null;
    _usageLimitReached = false;
  }

  /// 初期化して日記を生成する
  Future<void> initializeAndGenerate({
    required List<AssetEntity> assets,
    WritingPrompt? prompt,
    required Locale locale,
  }) async {
    _selectedPrompt = prompt;

    await Future.delayed(const Duration(milliseconds: 100));

    _isInitializing = false;
    notifyListeners();

    await _loadModelAndGenerateDiary(assets: assets, locale: locale);
  }

  /// モデルをロードして日記を生成
  Future<void> _loadModelAndGenerateDiary({
    required List<AssetEntity> assets,
    required Locale locale,
  }) async {
    if (assets.isEmpty) {
      _setErrorState(DiaryPreviewErrorType.noPhotos);
      return;
    }

    _clearErrorState();
    setLoading(true);

    try {
      final aiService = await ServiceRegistration.getAsync<IAiService>();
      _photoDateTime = _resolvePhotoDateTime(assets);

      final aiResult = assets.length == 1
          ? await _generateFromSinglePhoto(aiService, assets.first, locale)
          : await _generateFromMultiplePhotos(aiService, assets, locale);

      if (aiResult == null) return; // error already handled

      _generatedTitle = aiResult.title;
      _generatedContent = aiResult.content;
      _isSaving = true;
      setLoading(false);

      await _recordPromptUsage();
      await _autoSaveDiary(assets: assets);
    } catch (e, stackTrace) {
      _logger.error(
        'Diary generation failed',
        error: e,
        context: 'DiaryPreviewController._loadModelAndGenerateDiary',
        stackTrace: stackTrace,
      );
      _setErrorState(DiaryPreviewErrorType.generationFailed);
    }
  }

  static final _epoch = DateTime(1970);

  /// アセットから有効な日時を取得する。
  ///
  /// [AssetEntity.createDateTime] がエポック（1970年以前）の場合は
  /// [AssetEntity.modifiedDateTime] をフォールバックとして使用する。
  static DateTime _resolveAssetDateTime(AssetEntity asset) {
    final createDate = asset.createDateTime;
    return createDate.isAfter(_epoch) ? createDate : asset.modifiedDateTime;
  }

  /// 写真リストの代表日時を算出（中央値）
  DateTime _resolvePhotoDateTime(List<AssetEntity> assets) {
    final photoTimes =
        assets
            .map(_resolveAssetDateTime)
            .where((dt) => dt.isAfter(_epoch))
            .toList()
          ..sort();

    if (photoTimes.isEmpty) return DateTime.now();

    return photoTimes.length == 1
        ? photoTimes.first
        : photoTimes[photoTimes.length ~/ 2];
  }

  /// AI生成結果のusage limitチェック。制限到達時は true を返す。
  bool _handleUsageLimitIfNeeded(Result<DiaryGenerationResult> resultFromAi) {
    if (resultFromAi case Failure<DiaryGenerationResult>(
      exception: AiProcessingException(isUsageLimitError: true),
    )) {
      _usageLimitReached = true;
      _isAnalyzingPhotos = false;
      setLoading(false);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 単一写真からAI日記を生成
  Future<DiaryGenerationResult?> _generateFromSinglePhoto(
    IAiService aiService,
    AssetEntity asset,
    Locale locale,
  ) async {
    final imageResult = await _photoService.getOriginalFile(asset);
    if (imageResult.isFailure) {
      _setErrorState(DiaryPreviewErrorType.generationFailed);
      return null;
    }

    final resultFromAi = await aiService.generateDiaryFromImage(
      imageData: imageResult.value,
      date: _photoDateTime,
      prompt: _selectedPrompt?.text,
      locale: locale,
    );

    if (_handleUsageLimitIfNeeded(resultFromAi)) return null;
    if (resultFromAi.isFailure) throw resultFromAi.error;

    return resultFromAi.value;
  }

  /// 複数写真からAI日記を生成
  Future<DiaryGenerationResult?> _generateFromMultiplePhotos(
    IAiService aiService,
    List<AssetEntity> assets,
    Locale locale,
  ) async {
    _logger.info(
      'Starting sequential analysis of multiple photos',
      context: 'DiaryPreviewController',
    );

    final imagesWithTimes = <({Uint8List imageData, DateTime time})>[];
    for (final asset in assets) {
      final imageResult = await _photoService.getOriginalFile(asset);
      if (imageResult.isSuccess) {
        imagesWithTimes.add((
          imageData: imageResult.value,
          time: _resolveAssetDateTime(asset),
        ));
      } else {
        _logger.warning(
          'Failed to load image, skipping asset: ${asset.id}',
          context: 'DiaryPreviewController._generateFromMultiplePhotos',
        );
      }
    }

    if (imagesWithTimes.isEmpty) {
      _setErrorState(DiaryPreviewErrorType.generationFailed);
      return null;
    }

    _isAnalyzingPhotos = true;
    _totalPhotos = imagesWithTimes.length;
    _currentPhotoIndex = 0;
    notifyListeners();

    final resultFromAi = await aiService.generateDiaryFromMultipleImages(
      imagesWithTimes: imagesWithTimes,
      prompt: _selectedPrompt?.text,
      onProgress: (current, total) {
        _logger.info(
          'Image analysis progress: $current/$total',
          context: 'DiaryPreviewController',
        );
        _currentPhotoIndex = current;
        _totalPhotos = total;
        notifyListeners();
      },
      locale: locale,
    );

    _isAnalyzingPhotos = false;

    if (_handleUsageLimitIfNeeded(resultFromAi)) return null;
    if (resultFromAi.isFailure) throw resultFromAi.error;

    return resultFromAi.value;
  }

  /// プロンプト使用履歴を記録（非クリティカル）
  Future<void> _recordPromptUsage() async {
    if (_selectedPrompt == null) return;
    try {
      final promptService =
          await ServiceRegistration.getAsync<IPromptService>();
      final result = await promptService.recordPromptUsage(
        promptId: _selectedPrompt!.id,
      );
      if (result case Failure(:final exception)) {
        _logger.error(
          'Prompt usage history recording failed',
          error: exception,
          context: 'DiaryPreviewController',
        );
      }
    } catch (e) {
      _logger.error(
        'Prompt usage history recording error',
        error: e,
        context: 'DiaryPreviewController',
      );
    }
  }

  /// 自動保存を実行する
  Future<void> _autoSaveDiary({required List<AssetEntity> assets}) async {
    try {
      _logger.info(
        'Starting auto-save: photoCount=${assets.length}',
        context: 'DiaryPreviewController',
      );

      final diaryService =
          await ServiceRegistration.getAsync<IDiaryCrudService>();

      final saveResult = await diaryService.saveDiaryEntryWithPhotos(
        date: _photoDateTime,
        title: _generatedTitle,
        content: _generatedContent,
        photos: assets,
      );

      if (saveResult.isFailure) {
        throw saveResult.error;
      }

      final savedDiary = saveResult.value;
      _logger.info('Auto-save succeeded', context: 'DiaryPreviewController');

      _savedDiaryId = savedDiary.id;
      _isSaving = false;
      notifyListeners();
    } catch (e, stackTrace) {
      final appError = ErrorHandler.handleError(e, context: 'auto-save');
      _logger.error(
        'Diary auto-save failed',
        context: 'DiaryPreviewController._autoSaveDiary',
        error: appError,
        stackTrace: stackTrace,
      );

      _isSaving = false;
      _setErrorState(DiaryPreviewErrorType.saveFailed);
    }
  }

  /// 日記を手動保存する。成功時は保存済みフラグを設定。
  Future<bool> manualSave({
    required List<AssetEntity> assets,
    required String title,
    required String content,
  }) async {
    try {
      setLoading(true);
      _clearErrorState();

      _logger.info(
        'Starting diary save: photoCount=${assets.length}',
        context: 'DiaryPreviewController',
      );

      final diaryService =
          await ServiceRegistration.getAsync<IDiaryCrudService>();

      final manualSaveResult = await diaryService.saveDiaryEntryWithPhotos(
        date: _photoDateTime,
        title: title,
        content: content,
        photos: assets,
      );

      if (manualSaveResult.isFailure) {
        throw manualSaveResult.error;
      }

      _logger.info('Diary save succeeded', context: 'DiaryPreviewController');
      setLoading(false);
      return true;
    } catch (e, stackTrace) {
      final appError = ErrorHandler.handleError(e, context: 'diary-save');
      _logger.error(
        'Diary save failed',
        context: 'DiaryPreviewController._saveDiaryEntry',
        error: appError,
        stackTrace: stackTrace,
      );

      _setErrorState(DiaryPreviewErrorType.saveFailed);
      return false;
    }
  }

  /// 使用量制限フラグを消費する（1回限りのイベント処理用）
  bool consumeUsageLimitReached() {
    if (_usageLimitReached) {
      _usageLimitReached = false;
      return true;
    }
    return false;
  }

  /// 保存済み日記IDを消費する（1回限りのナビゲーション処理用）
  String? consumeSavedDiaryId() {
    final id = _savedDiaryId;
    _savedDiaryId = null;
    return id;
  }

  /// プロンプトをクリア
  void clearPrompt() {
    _selectedPrompt = null;
    notifyListeners();
  }
}
