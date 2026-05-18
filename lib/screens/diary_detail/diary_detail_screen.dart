import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../controllers/diary_detail_controller.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../localization/localization_extensions.dart';
import '../../ui/animations/micro_interactions.dart';
import '../../utils/dialog_utils.dart';
import 'diary_detail_action_bar.dart';
import 'diary_detail_content.dart';
import 'diary_detail_edit_bottom_bar.dart';
import 'diary_detail_share.dart';
import 'diary_detail_status_views.dart';

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
      if (mounted) _controller.loadDiaryEntry(widget.diaryId);
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
    final entry = _controller.diaryEntry;
    if (entry != null && !_controller.isEditing) {
      _titleController.text = entry.title;
      _contentController.text = entry.content;
    }
  }

  Future<void> _updateDiary() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final success = await _controller.updateDiary(
      widget.diaryId,
      title: _titleController.text,
      content: _contentController.text,
    );
    if (success && mounted) {
      MicroInteractions.hapticSuccess();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.diaryUpdateSuccessMessage)),
      );
    } else if (!success && mounted && _controller.hasError) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.commonErrorWithMessage(_getErrorMessage(l10n))),
        ),
      );
    }
  }

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
      MicroInteractions.hapticSuccess();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.diaryDeleteSuccessMessage)),
      );
      navigator.pop(true);
    } else if (!success && mounted && _controller.hasError) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.commonErrorWithMessage(_getErrorMessage(l10n))),
        ),
      );
    }
  }

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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_controller.wasModified ? 'updated' : null);
      },
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          final isEditing = _controller.isEditing;
          final canAct =
              !_controller.isLoading &&
              !_controller.hasError &&
              _controller.diaryEntry != null;
          return Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: isEditing
                ? AppBar(title: Text(context.l10n.diaryDetailEditTitle))
                : null,
            body: isEditing
                ? _buildBody()
                : Stack(
                    children: [
                      _buildBody(),
                      DiaryDetailActionBar(
                        canShowActions: canAct,
                        onBack: () => Navigator.of(
                          context,
                        ).pop(_controller.wasModified ? 'updated' : null),
                        onShare: () => DiaryDetailShareHelper.showShareDialog(
                          context: context,
                          diaryEntry: _controller.diaryEntry!,
                          photoAssets: _controller.photoAssets,
                        ),
                        onEdit: _controller.startEditing,
                        onDelete: _deleteDiary,
                      ),
                    ],
                  ),
            bottomNavigationBar: (isEditing && canAct)
                ? DiaryDetailEditBottomBar(
                    onCancel: () {
                      _controller.cancelEditing();
                      _titleController.text = _controller.diaryEntry!.title;
                      _contentController.text = _controller.diaryEntry!.content;
                    },
                    onSave: _updateDiary,
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    final l10n = context.l10n;
    if (_controller.isLoading) return const DiaryDetailLoadingView();
    if (_controller.errorType == DiaryDetailErrorType.notFound) {
      return DiaryDetailNotFoundView(onBack: () => Navigator.pop(context));
    }
    if (_controller.hasError) {
      return DiaryDetailErrorView(
        errorMessage: _getErrorMessage(l10n),
        onBack: () => Navigator.pop(context),
      );
    }
    if (_controller.diaryEntry == null) {
      return DiaryDetailNotFoundView(onBack: () => Navigator.pop(context));
    }
    return DiaryDetailContent(
      diaryEntry: _controller.diaryEntry!,
      photoAssets: _controller.photoAssets,
      isEditing: _controller.isEditing,
      titleController: _titleController,
      contentController: _contentController,
    );
  }
}
