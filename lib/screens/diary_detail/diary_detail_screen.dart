import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../controllers/diary_detail_controller.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../localization/localization_extensions.dart';
import '../../ui/components/animated_button.dart';
import '../../ui/components/custom_card.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../ui/animations/list_animations.dart';
import '../../ui/animations/micro_interactions.dart';
import '../../utils/dialog_utils.dart';
import 'diary_detail_content.dart';
import 'diary_detail_share.dart';

class DiaryDetailScreen extends StatefulWidget {
  final String diaryId;

  const DiaryDetailScreen({super.key, required this.diaryId});

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();

  /// カスタムページ遷移を提供
  Route<T> customRoute<T>() {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => this,
      transitionDuration: AppConstants.defaultAnimationDuration,
      reverseTransitionDuration: AppConstants.shortAnimationDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  late final DiaryDetailController _controller;
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _controller = DiaryDetailController();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _controller.addListener(_onControllerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.loadDiaryEntry(widget.diaryId);
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
    // Controller の diaryEntry が変わったらテキストコントローラーを同期
    final entry = _controller.diaryEntry;
    if (entry != null && !_controller.isEditing) {
      _titleController.text = entry.title;
      _contentController.text = entry.content;
    }
    // ListenableBuilder がUIを再構築するため setState は不要
  }

  /// 日記を更新する
  Future<void> _updateDiary() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    final success = await _controller.updateDiary(
      widget.diaryId,
      title: _titleController.text,
      content: _contentController.text,
    );

    if (success && mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.diaryUpdateSuccessMessage)),
      );
    } else if (!success && mounted && _controller.hasError) {
      final errorMsg = _getErrorMessage(l10n);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.commonErrorWithMessage(errorMsg))),
      );
    }
  }

  /// 日記を削除する
  Future<void> _deleteDiary() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = context.l10n;

    final confirmed = await DialogUtils.showConfirmationDialog(
      context,
      l10n.diaryDetailDeleteDialogTitle,
      l10n.diaryDetailDeleteDialogMessage,
      confirmText: l10n.commonDelete,
      isDestructive: true,
    );

    if (confirmed != true) return;

    final success = await _controller.deleteDiary(widget.diaryId);

    if (success && mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.diaryDeleteSuccessMessage)),
      );
      navigator.pop(true);
    } else if (!success && mounted && _controller.hasError) {
      final errorMsg = _getErrorMessage(l10n);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.commonErrorWithMessage(errorMsg))),
      );
    }
  }

  /// エラー種別からローカライズされたメッセージを取得
  String _getErrorMessage(AppLocalizations l10n) {
    final detail = _controller.rawErrorDetail;
    return switch (_controller.errorType) {
      DiaryDetailErrorType.notFound => l10n.diaryNotFoundMessage,
      DiaryDetailErrorType.loadFailed => l10n.diaryDetailLoadError(detail),
      DiaryDetailErrorType.updateFailed => l10n.diaryDetailUpdateError(detail),
      DiaryDetailErrorType.deleteFailed => l10n.diaryDetailDeleteError(detail),
      null => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_controller.wasModified ? 'updated' : null);
      },
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: _buildAppBar(l10n),
            body: _buildBody(l10n),
            bottomNavigationBar: _buildBottomBar(l10n),
          );
        },
      ),
    );
  }

  /// AppBarを構築
  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      title: Text(
        _controller.isEditing
            ? l10n.diaryDetailEditTitle
            : l10n.diaryDetailViewTitle,
      ),
      actions: [
        // 共有ボタン
        if (!_controller.isLoading &&
            !_controller.hasError &&
            _controller.diaryEntry != null &&
            !_controller.isEditing)
          IconButton(
            onPressed: () {
              DiaryDetailShareHelper.showShareDialog(
                context: context,
                diaryEntry: _controller.diaryEntry!,
                photoAssets: _controller.photoAssets,
              );
            },
            icon: const Icon(Icons.share_rounded),
            tooltip: l10n.commonShare,
          ),
        // 編集モード切替ボタン
        if (!_controller.isLoading &&
            !_controller.hasError &&
            _controller.diaryEntry != null)
          IconButton(
            onPressed: () {
              if (_controller.isEditing) {
                _updateDiary();
              } else {
                _controller.startEditing();
              }
            },
            icon: Icon(
              _controller.isEditing ? Icons.check_rounded : Icons.edit_rounded,
            ),
            tooltip: _controller.isEditing ? l10n.commonSave : l10n.commonEdit,
          ),
        // 削除ボタン
        if (!_controller.isLoading &&
            !_controller.hasError &&
            _controller.diaryEntry != null)
          IconButton(
            onPressed: () {
              MicroInteractions.hapticTap(intensity: VibrationIntensity.medium);
              _deleteDiary();
            },
            icon: const Icon(Icons.delete_rounded),
            tooltip: l10n.commonDelete,
          ),
      ],
    );
  }

  /// Bodyを構築
  Widget _buildBody(AppLocalizations l10n) {
    if (_controller.isLoading) {
      return _buildLoadingState(l10n);
    }
    if (_controller.errorType == DiaryDetailErrorType.notFound) {
      return _buildNotFoundState(l10n);
    }
    if (_controller.hasError) {
      return _buildErrorState(l10n);
    }
    if (_controller.diaryEntry == null) {
      return _buildNotFoundState(l10n);
    }
    return DiaryDetailContent(
      diaryEntry: _controller.diaryEntry!,
      photoAssets: _controller.photoAssets,
      isEditing: _controller.isEditing,
      titleController: _titleController,
      contentController: _contentController,
    );
  }

  /// BottomBarを構築
  Widget? _buildBottomBar(AppLocalizations l10n) {
    if (!_controller.isEditing ||
        _controller.isLoading ||
        _controller.hasError ||
        _controller.diaryEntry == null) {
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
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: SecondaryButton(
                onPressed: () {
                  _controller.cancelEditing();
                  _titleController.text = _controller.diaryEntry!.title;
                  _contentController.text = _controller.diaryEntry!.content;
                },
                text: l10n.commonCancel,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 1,
              child: PrimaryButton(
                onPressed: _updateDiary,
                text: l10n.commonSave,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ローディング状態を構築
  Widget _buildLoadingState(AppLocalizations l10n) {
    return Center(
      child: FadeInWidget(
        child: CustomCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.diaryDetailLoadingTitle,
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.diaryDetailLoadingSubtitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// エラー状態を構築
  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: FadeInWidget(
        child: CustomCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.errorContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: AppSpacing.iconLg,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(l10n.commonErrorOccurred, style: AppTypography.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _getErrorMessage(l10n),
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                onPressed: () => Navigator.pop(context),
                text: l10n.commonBack,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 未検出状態を構築
  Widget _buildNotFoundState(AppLocalizations l10n) {
    return Center(
      child: FadeInWidget(
        child: CustomCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                  size: AppSpacing.iconLg,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(l10n.diaryNotFoundMessage, style: AppTypography.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.diaryNotFoundSubtitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                onPressed: () => Navigator.pop(context),
                text: l10n.commonBack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
