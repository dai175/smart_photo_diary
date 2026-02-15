import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../controllers/diary_preview_controller.dart';
import '../../core/service_registration.dart';
import '../../localization/localization_extensions.dart';
import '../../models/diary_length.dart';
import '../../models/writing_prompt.dart';
import '../../services/interfaces/logging_service_interface.dart';
import '../../services/interfaces/settings_service_interface.dart';
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
  late final DiaryPreviewController _controller;
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _controller = DiaryPreviewController();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _controller.addListener(_onControllerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Load default diary length from settings (async-safe)
      var defaultLength = DiaryLength.standard;
      try {
        final settingsService =
            await ServiceRegistration.getAsync<ISettingsService>();
        defaultLength = settingsService.diaryLength;
      } catch (e) {
        // Fall back to standard if settings service is unavailable
        try {
          final logger = await ServiceRegistration.getAsync<ILoggingService>();
          logger.warning(
            'Failed to load diary length from settings, using standard',
            context: 'DiaryPreviewScreen.initState',
            data: e,
          );
        } catch (_) {
          // LoggingService also unavailable — silent fallback acceptable
        }
      }
      _controller.setDiaryLength(defaultLength);

      if (mounted) {
        _controller.initializeAndGenerate(
          assets: widget.selectedAssets,
          prompt: widget.selectedPrompt,
          locale: Localizations.localeOf(context),
          diaryLength: defaultLength,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    // 生成完了時にテキストコントローラーを同期
    if (_controller.generatedTitle.isNotEmpty &&
        _titleController.text != _controller.generatedTitle) {
      _titleController.text = _controller.generatedTitle;
    }
    if (_controller.generatedContent.isNotEmpty &&
        _contentController.text != _controller.generatedContent) {
      _contentController.text = _controller.generatedContent;
    }

    // 使用量制限に到達した場合はダイアログ表示（consumeで1回限り）
    if (_controller.consumeUsageLimitReached() && mounted) {
      DiaryPreviewDialogHelper.showUsageLimitDialog(context);
    }

    // 自動保存完了後のナビゲーション（consumeで1回限り）
    final savedId = _controller.consumeSavedDiaryId();
    if (savedId != null && mounted) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(context.l10n.diaryPreviewSaveSuccess)),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DiaryDetailScreen(diaryId: savedId),
        ),
        result: true,
      );
    }
  }

  /// 日記を手動保存する
  Future<void> _saveDiary() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await _controller.manualSave(
      assets: widget.selectedAssets,
      title: _titleController.text,
      content: _contentController.text,
    );

    if (success && mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(context.l10n.diaryPreviewSaveSuccess)),
      );
      navigator.pop(true);
    } else if (!success && mounted && _controller.hasError) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.commonErrorWithMessage(
              context.l10n.diaryPreviewSaveError,
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            if (!_controller.isLoading &&
                !_controller.hasError &&
                _titleController.text.isNotEmpty) {
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
                photoDateTime: _controller.photoDateTime,
                selectedPrompt: _controller.selectedPrompt,
                isInitializing: _controller.isInitializing,
                isLoading: _controller.isLoading,
                isSaving: _controller.isSaving,
                hasError: _controller.hasError,
                errorMessage: _controller.hasError ? _getErrorMessage() : '',
                isAnalyzingPhotos: _controller.isAnalyzingPhotos,
                currentPhotoIndex: _controller.currentPhotoIndex,
                totalPhotos: _controller.totalPhotos,
                titleController: _titleController,
                contentController: _contentController,
              ),
            ),
            bottomNavigationBar: _buildBottomBar(),
          ),
        );
      },
    );
  }

  String _getErrorMessage() {
    return switch (_controller.errorType) {
      DiaryPreviewErrorType.noPhotos => context.l10n.diaryPreviewNoPhotosError,
      DiaryPreviewErrorType.generationFailed =>
        context.l10n.diaryPreviewGenerationError,
      DiaryPreviewErrorType.saveFailed => context.l10n.diaryPreviewSaveError,
      null => '',
    };
  }

  /// AppBarを構築
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(context.l10n.diaryPreviewAppBarTitle),
      centerTitle: false,
      actions: [
        // 再生成ボタン（プロンプトをスキップ）
        if (!_controller.isInitializing &&
            !_controller.isLoading &&
            !_controller.hasError &&
            _controller.selectedPrompt != null)
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.xs),
            child: IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () {
                _controller.clearPrompt();
                _controller.initializeAndGenerate(
                  assets: widget.selectedAssets,
                  locale: Localizations.localeOf(context),
                );
              },
              tooltip: context.l10n.diaryPreviewRegenerateWithoutPromptTooltip,
            ),
          ),
        // 手動保存ボタン
        if (!_controller.isInitializing &&
            !_controller.isLoading &&
            !_controller.isSaving &&
            !_controller.hasError)
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            child: IconButton(
              icon: Icon(
                Icons.save_rounded,
                color: Theme.of(context).colorScheme.onSurface,
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
    if (_controller.isLoading || _controller.isSaving || _controller.hasError) {
      return null;
    }

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
