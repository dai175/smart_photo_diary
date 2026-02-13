import 'dart:typed_data';
import 'dart:ui';

import 'package:photo_manager/photo_manager.dart';

import '../core/errors/app_exceptions.dart';
import '../core/errors/error_handler.dart';
import '../core/service_locator.dart';
import '../core/service_registration.dart';
import '../models/writing_prompt.dart';
import '../services/ai/ai_service_interface.dart';
import '../services/interfaces/diary_service_interface.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../services/interfaces/prompt_service_interface.dart';
import 'base_error_controller.dart';

/// DiaryPreviewScreen のエラー種別
enum DiaryPreviewErrorType { noPhotos, generationFailed, saveFailed }

/// DiaryPreviewScreen の状態管理・ビジネスロジック
class DiaryPreviewController extends BaseErrorController {
  late final ILoggingService _logger;
  late final IAiService _aiService;
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
    _aiService = ServiceRegistration.get<IAiService>();
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
      // 写真の撮影日時を取得
      List<DateTime> photoTimes = [];
      for (final asset in assets) {
        photoTimes.add(asset.createDateTime);
      }

      DateTime photoDateTime;
      if (photoTimes.length == 1) {
        photoDateTime = photoTimes.first;
      } else {
        photoTimes.sort();
        final middleIndex = photoTimes.length ~/ 2;
        photoDateTime = photoTimes[middleIndex];
      }

      DiaryGenerationResult result;

      if (assets.length == 1) {
        // 単一写真の場合
        final firstAsset = assets.first;
        final imageData = await _photoService.getOriginalFile(firstAsset);

        if (imageData == null) {
          _setErrorState(DiaryPreviewErrorType.generationFailed);
          return;
        }

        final resultFromAi = await _aiService.generateDiaryFromImage(
          imageData: imageData,
          date: photoDateTime,
          prompt: _selectedPrompt?.text,
          locale: locale,
        );

        if (resultFromAi.isFailure) {
          if (resultFromAi.error is AiProcessingException &&
              resultFromAi.error.message.contains('月間制限に達しました')) {
            _usageLimitReached = true;
            setLoading(false);
            notifyListeners();
            return;
          }
          throw Exception(resultFromAi.error.message);
        }

        result = resultFromAi.value;
      } else {
        // 複数写真の場合
        _logger.info('複数写真の順次分析を開始', context: 'DiaryPreviewController');

        final List<({Uint8List imageData, DateTime time})> imagesWithTimes = [];

        for (final asset in assets) {
          final imageData = await _photoService.getOriginalFile(asset);
          if (imageData != null) {
            imagesWithTimes.add((
              imageData: imageData,
              time: asset.createDateTime,
            ));
          }
        }

        if (imagesWithTimes.isEmpty) {
          _setErrorState(DiaryPreviewErrorType.generationFailed);
          return;
        }

        _isAnalyzingPhotos = true;
        _totalPhotos = imagesWithTimes.length;
        _currentPhotoIndex = 0;
        notifyListeners();

        final resultFromAi = await _aiService.generateDiaryFromMultipleImages(
          imagesWithTimes: imagesWithTimes,
          prompt: _selectedPrompt?.text,
          onProgress: (current, total) {
            _logger.info(
              '画像分析進捗: $current/$total',
              context: 'DiaryPreviewController',
            );
            _currentPhotoIndex = current;
            _totalPhotos = total;
            notifyListeners();
          },
          locale: locale,
        );

        if (resultFromAi.isFailure) {
          if (resultFromAi.error is AiProcessingException &&
              resultFromAi.error.message.contains('月間制限に達しました')) {
            _usageLimitReached = true;
            _isAnalyzingPhotos = false;
            setLoading(false);
            notifyListeners();
            return;
          }
          throw Exception(resultFromAi.error.message);
        }

        result = resultFromAi.value;

        _isAnalyzingPhotos = false;
      }

      _generatedTitle = result.title;
      _generatedContent = result.content;
      _isSaving = true;
      _photoDateTime = photoDateTime;
      setLoading(false);

      // プロンプト使用履歴を記録
      if (_selectedPrompt != null) {
        try {
          final promptService =
              await ServiceRegistration.getAsync<IPromptService>();
          await promptService.recordPromptUsage(promptId: _selectedPrompt!.id);
        } catch (e) {
          _logger.error(
            'プロンプト使用履歴記録エラー',
            error: e,
            context: 'DiaryPreviewController',
          );
        }
      }

      await _autoSaveDiary(assets: assets);
    } catch (e) {
      _setErrorState(DiaryPreviewErrorType.generationFailed);
    }
  }

  /// 自動保存を実行する
  Future<void> _autoSaveDiary({required List<AssetEntity> assets}) async {
    try {
      _logger.info(
        '自動保存開始: 写真数=${assets.length}',
        context: 'DiaryPreviewController',
      );

      final diaryService = await ServiceRegistration.getAsync<IDiaryService>();

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
      _logger.info('自動保存成功', context: 'DiaryPreviewController');

      _savedDiaryId = savedDiary.id;
      _isSaving = false;
      notifyListeners();
    } catch (e, stackTrace) {
      final loggingService = serviceLocator.get<ILoggingService>();
      final appError = ErrorHandler.handleError(e, context: '自動保存');
      loggingService.error(
        '日記の自動保存に失敗しました',
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
        '日記保存開始: 写真数=${assets.length}',
        context: 'DiaryPreviewController',
      );

      final diaryService = await ServiceRegistration.getAsync<IDiaryService>();

      final manualSaveResult = await diaryService.saveDiaryEntryWithPhotos(
        date: _photoDateTime,
        title: title,
        content: content,
        photos: assets,
      );

      if (manualSaveResult.isFailure) {
        throw manualSaveResult.error;
      }

      _logger.info('日記保存成功', context: 'DiaryPreviewController');
      setLoading(false);
      return true;
    } catch (e, stackTrace) {
      final loggingService = serviceLocator.get<ILoggingService>();
      final appError = ErrorHandler.handleError(e, context: '日記保存');
      loggingService.error(
        '日記の保存に失敗しました',
        context: 'DiaryPreviewController._saveDiaryEntry',
        error: appError,
        stackTrace: stackTrace,
      );

      _setErrorState(DiaryPreviewErrorType.saveFailed);
      return false;
    }
  }

  /// プロンプトをクリア
  void clearPrompt() {
    _selectedPrompt = null;
    notifyListeners();
  }
}
