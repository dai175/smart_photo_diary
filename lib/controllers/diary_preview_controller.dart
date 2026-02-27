import 'dart:ui';

import 'package:photo_manager/photo_manager.dart';

import '../constants/app_constants.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../core/service_locator.dart';
import '../core/service_registration.dart';
import '../models/diary_length.dart';
import '../models/writing_prompt.dart';
import '../services/interfaces/ai_service_interface.dart';
import '../services/interfaces/diary_crud_service_interface.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../services/interfaces/prompt_service_interface.dart';
import '../utils/photo_date_resolver.dart';
import 'base_error_controller.dart';
import 'diary_preview_generation_delegate.dart';
import 'diary_preview_save_delegate.dart';

/// DiaryPreviewScreen のエラー種別
enum DiaryPreviewErrorType { noPhotos, generationFailed, saveFailed }

/// DiaryPreviewScreen の状態管理・ビジネスロジック
///
/// AI生成は [DiaryPreviewGenerationDelegate]、保存は [DiaryPreviewSaveDelegate]、
/// 日時解決は [PhotoDateResolver] にそれぞれ委譲する。
class DiaryPreviewController extends BaseErrorController {
  late final ILoggingService _logger;
  late final DiaryPreviewGenerationDelegate _generationDelegate;
  late final DiaryPreviewSaveDelegate _saveDelegate;

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
  String? _contextText;
  DiaryLength _diaryLength = DiaryLength.standard;

  /// 現在の日記の長さ設定
  DiaryLength get diaryLength => _diaryLength;

  /// 日記の長さを設定
  void setDiaryLength(DiaryLength length) {
    _diaryLength = length;
    notifyListeners();
  }

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
    final photoService = ServiceRegistration.get<IPhotoService>();

    _generationDelegate = DiaryPreviewGenerationDelegate(
      photoService: photoService,
      logger: _logger,
    );
    _saveDelegate = DiaryPreviewSaveDelegate(
      getDiaryService: () => ServiceRegistration.getAsync<IDiaryCrudService>(),
      getPromptService: () => ServiceRegistration.getAsync<IPromptService>(),
      logger: _logger,
    );
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
    String? contextText,
    required Locale locale,
    DiaryLength? diaryLength,
  }) async {
    if (diaryLength != null) {
      _diaryLength = diaryLength;
    }
    _contextText = contextText;
    _selectedPrompt = prompt;

    await Future.delayed(AppConstants.microStaggerUnit);

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
      _photoDateTime = PhotoDateResolver.resolveMedianDateTime(assets);

      final Result<GenerationOutput> genResult;
      if (assets.length == 1) {
        genResult = await _generationDelegate.generateFromSinglePhoto(
          aiService: aiService,
          asset: assets.first,
          photoDateTime: _photoDateTime,
          locale: locale,
          prompt: _selectedPrompt?.text,
          contextText: _contextText,
          diaryLength: _diaryLength,
        );
      } else {
        _isAnalyzingPhotos = true;
        _totalPhotos = assets.length;
        _currentPhotoIndex = 0;
        notifyListeners();

        genResult = await _generationDelegate.generateFromMultiplePhotos(
          aiService: aiService,
          assets: assets,
          locale: locale,
          prompt: _selectedPrompt?.text,
          contextText: _contextText,
          diaryLength: _diaryLength,
          onProgress: (current, total) {
            _logger.info(
              'Image analysis progress: $current/$total',
              context: 'DiaryPreviewController',
            );
            _currentPhotoIndex = current;
            _totalPhotos = total;
            notifyListeners();
          },
        );

        _isAnalyzingPhotos = false;
      }

      if (_handleUsageLimitIfNeeded(genResult)) return;

      if (genResult.isFailure) throw genResult.error;

      final output = genResult.value;
      _generatedTitle = output.title;
      _generatedContent = output.content;
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

  /// AI生成結果のusage limitチェック。制限到達時は true を返す。
  bool _handleUsageLimitIfNeeded(Result<GenerationOutput> result) {
    if (result case Failure<GenerationOutput>(
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

  /// プロンプト使用履歴を記録（非クリティカル）
  Future<void> _recordPromptUsage() async {
    if (_selectedPrompt == null) return;
    await _saveDelegate.recordPromptUsage(promptId: _selectedPrompt!.id);
  }

  /// 自動保存を実行する
  Future<void> _autoSaveDiary({required List<AssetEntity> assets}) async {
    final result = await _saveDelegate.saveDiary(
      photoDateTime: _photoDateTime,
      title: _generatedTitle,
      content: _generatedContent,
      assets: assets,
    );

    if (result.isSuccess) {
      _savedDiaryId = result.value;
      _isSaving = false;
      notifyListeners();
    } else {
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
    setLoading(true);
    _clearErrorState();

    final result = await _saveDelegate.saveDiary(
      photoDateTime: _photoDateTime,
      title: title,
      content: content,
      assets: assets,
    );

    if (result.isSuccess) {
      setLoading(false);
      return true;
    } else {
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
