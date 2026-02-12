import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/errors/error_handler.dart';
import '../../core/service_locator.dart';
import '../../core/service_registration.dart';
import '../../localization/localization_extensions.dart';
import '../../models/writing_prompt.dart';
import '../../services/ai/ai_service_interface.dart';
import '../../services/interfaces/diary_service_interface.dart';
import '../../services/interfaces/logging_service_interface.dart';
import '../../services/interfaces/photo_service_interface.dart';
import '../../services/interfaces/prompt_service_interface.dart';
import '../../ui/components/animated_button.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/animations/list_animations.dart';
import '../diary_detail_screen.dart';
import 'diary_preview_body.dart';
import 'diary_preview_dialogs.dart';

/// 生成された日記のプレビュー画面
class DiaryPreviewScreen extends StatefulWidget {
  /// 選択された写真アセット
  final List<AssetEntity> selectedAssets;

  /// 選択されたプロンプト（オプション）
  final WritingPrompt? selectedPrompt;

  const DiaryPreviewScreen({
    super.key,
    required this.selectedAssets,
    this.selectedPrompt,
  });

  @override
  State<DiaryPreviewScreen> createState() => _DiaryPreviewScreenState();
}

class _DiaryPreviewScreenState extends State<DiaryPreviewScreen> {
  late final ILoggingService _logger;
  late final IAiService _aiService;
  late final IPhotoService _photoService;

  bool _isInitializing = true;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasError = false;
  String _errorMessage = '';
  DateTime _photoDateTime = DateTime.now();

  int _currentPhotoIndex = 0;
  int _totalPhotos = 0;
  bool _isAnalyzingPhotos = false;

  late TextEditingController _titleController;
  late TextEditingController _contentController;

  WritingPrompt? _selectedPrompt;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();

    _logger = serviceLocator.get<ILoggingService>();
    _aiService = ServiceRegistration.get<IAiService>();
    _photoService = ServiceRegistration.get<IPhotoService>();

    _selectedPrompt = widget.selectedPrompt;

    _initializePromptServices();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// 初期化完了後の処理
  Future<void> _initializePromptServices() async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });

      _loadModelAndGenerateDiary();
    }
  }

  /// モデルをロードして日記を生成
  Future<void> _loadModelAndGenerateDiary() async {
    if (widget.selectedAssets.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = context.l10n.diaryPreviewNoPhotosError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // 写真の撮影日時を取得
      List<DateTime> photoTimes = [];
      for (final asset in widget.selectedAssets) {
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

      // async gap 前に context 依存の値をキャプチャ
      final locale = Localizations.localeOf(context);
      final photoDataErrorMsg = context.l10n.diaryPreviewPhotoDataError;

      if (widget.selectedAssets.length == 1) {
        // 単一写真の場合
        final firstAsset = widget.selectedAssets.first;
        final imageData = await _photoService.getOriginalFile(firstAsset);

        if (imageData == null) {
          throw Exception(photoDataErrorMsg);
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
            if (!mounted) return;
            await DiaryPreviewDialogHelper.showUsageLimitDialog(context);
            return;
          }
          throw Exception(resultFromAi.error.message);
        }

        result = resultFromAi.value;
      } else {
        // 複数写真の場合
        _logger.info('複数写真の順次分析を開始', context: 'DiaryPreviewScreen');

        final List<({Uint8List imageData, DateTime time})> imagesWithTimes = [];

        for (final asset in widget.selectedAssets) {
          final imageData = await _photoService.getOriginalFile(asset);
          if (imageData != null) {
            imagesWithTimes.add((
              imageData: imageData,
              time: asset.createDateTime,
            ));
          }
        }

        if (imagesWithTimes.isEmpty) {
          throw Exception(photoDataErrorMsg);
        }

        setState(() {
          _isAnalyzingPhotos = true;
          _totalPhotos = imagesWithTimes.length;
          _currentPhotoIndex = 0;
        });

        final resultFromAi = await _aiService.generateDiaryFromMultipleImages(
          imagesWithTimes: imagesWithTimes,
          prompt: _selectedPrompt?.text,
          onProgress: (current, total) {
            _logger.info(
              '画像分析進捗: $current/$total',
              context: 'DiaryPreviewScreen',
            );
            setState(() {
              _currentPhotoIndex = current;
              _totalPhotos = total;
            });
          },
          locale: locale,
        );

        if (resultFromAi.isFailure) {
          if (resultFromAi.error is AiProcessingException &&
              resultFromAi.error.message.contains('月間制限に達しました')) {
            if (!mounted) return;
            await DiaryPreviewDialogHelper.showUsageLimitDialog(context);
            return;
          }
          throw Exception(resultFromAi.error.message);
        }

        result = resultFromAi.value;

        setState(() {
          _isAnalyzingPhotos = false;
        });
      }

      setState(() {
        _titleController.text = result.title;
        _contentController.text = result.content;
        _isLoading = false;
        _isSaving = true;
        _photoDateTime = photoDateTime;
      });

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
            context: 'DiaryPreviewScreen',
          );
        }
      }

      await _autoSaveDiary();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = context.l10n.diaryPreviewGenerationError;
      });
    }
  }

  /// 自動保存を実行し、日記詳細画面に遷移する
  Future<void> _autoSaveDiary() async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      _logger.info(
        '自動保存開始: 写真数=${widget.selectedAssets.length}',
        context: 'DiaryPreviewScreen',
      );

      final diaryService = await ServiceRegistration.getAsync<IDiaryService>();

      final saveResult = await diaryService.saveDiaryEntryWithPhotos(
        date: _photoDateTime,
        title: _titleController.text,
        content: _contentController.text,
        photos: widget.selectedAssets,
      );

      if (saveResult.isFailure) {
        throw saveResult.error;
      }

      final savedDiary = saveResult.value;
      _logger.info('自動保存成功', context: 'DiaryPreviewScreen');

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(context.l10n.diaryPreviewSaveSuccess)),
        );

        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => DiaryDetailScreen(diaryId: savedDiary.id),
          ),
          result: true,
        );
      }
    } catch (e, stackTrace) {
      final loggingService = serviceLocator.get<ILoggingService>();
      final appError = ErrorHandler.handleError(e, context: '自動保存');
      loggingService.error(
        '日記の自動保存に失敗しました',
        context: 'DiaryPreviewScreen._autoSaveDiary',
        error: appError,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasError = true;
          _errorMessage = context.l10n.diaryPreviewSaveError;
        });

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(context.l10n.commonErrorWithMessage(_errorMessage)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// 日記を保存する（手動保存用）
  Future<void> _saveDiary() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      setState(() {
        _isLoading = true;
      });

      _logger.info(
        '日記保存開始: 写真数=${widget.selectedAssets.length}',
        context: 'DiaryPreviewScreen',
      );

      final diaryService = await ServiceRegistration.getAsync<IDiaryService>();

      final manualSaveResult = await diaryService.saveDiaryEntryWithPhotos(
        date: _photoDateTime,
        title: _titleController.text,
        content: _contentController.text,
        photos: widget.selectedAssets,
      );

      if (manualSaveResult.isFailure) {
        throw manualSaveResult.error;
      }

      _logger.info('日記保存成功', context: 'DiaryPreviewScreen');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(context.l10n.diaryPreviewSaveSuccess)),
        );

        navigator.pop(true);
      }
    } catch (e, stackTrace) {
      final loggingService = serviceLocator.get<ILoggingService>();
      final appError = ErrorHandler.handleError(e, context: '日記保存');
      loggingService.error(
        '日記の保存に失敗しました',
        context: 'DiaryPreviewScreen._saveDiaryEntry',
        error: appError,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = context.l10n.diaryPreviewSaveError;
        });

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(context.l10n.commonErrorWithMessage(_errorMessage)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// プロンプトをクリア（再生成時に使用）
  void _clearPrompt() {
    setState(() {
      _selectedPrompt = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (!_isLoading && !_hasError && _titleController.text.isNotEmpty) {
          final shouldPop =
              await DiaryPreviewDialogHelper.showDiscardConfirmationDialog(
                context,
              );
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: SafeArea(
          child: DiaryPreviewBody(
            selectedAssets: widget.selectedAssets,
            photoDateTime: _photoDateTime,
            selectedPrompt: _selectedPrompt,
            isInitializing: _isInitializing,
            isLoading: _isLoading,
            isSaving: _isSaving,
            hasError: _hasError,
            errorMessage: _errorMessage,
            isAnalyzingPhotos: _isAnalyzingPhotos,
            currentPhotoIndex: _currentPhotoIndex,
            totalPhotos: _totalPhotos,
            titleController: _titleController,
            contentController: _contentController,
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  /// AppBarを構築
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(context.l10n.diaryPreviewAppBarTitle),
      centerTitle: false,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: Theme.of(context).colorScheme.onPrimary,
      ),
      iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
      elevation: 2,
      actions: [
        // 再生成ボタン（プロンプトをスキップ）
        if (!_isInitializing &&
            !_isLoading &&
            !_hasError &&
            _selectedPrompt != null)
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.xs),
            child: IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                _clearPrompt();
                _loadModelAndGenerateDiary();
              },
              tooltip: context.l10n.diaryPreviewRegenerateWithoutPromptTooltip,
            ),
          ),
        // 手動保存ボタン
        if (!_isInitializing && !_isLoading && !_isSaving && !_hasError)
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            child: IconButton(
              icon: Icon(
                Icons.save_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: _saveDiary,
              tooltip: context.l10n.diaryPreviewSaveButton,
            ),
          ),
      ],
    );
  }

  /// BottomBarを構築
  Widget? _buildBottomBar() {
    if (_isLoading || _isSaving || _hasError) return null;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SlideInWidget(
          delay: const Duration(milliseconds: 400),
          begin: const Offset(0, 1),
          child: PrimaryButton(
            onPressed: _saveDiary,
            text: context.l10n.diaryPreviewSaveButton,
            icon: Icons.save_rounded,
            width: double.infinity,
          ),
        ),
      ),
    );
  }
}
