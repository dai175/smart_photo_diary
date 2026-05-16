import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../controllers/diary_detail_controller.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../localization/localization_extensions.dart';
import '../../ui/components/animated_button.dart';
import '../../ui/components/custom_card.dart';
import '../../ui/components/loading_state_card.dart';
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
      final errorMsg = _getErrorMessage(l10n);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.commonErrorWithMessage(errorMsg))),
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
      final errorMsg = _getErrorMessage(l10n);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.commonErrorWithMessage(errorMsg))),
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
          final isEditing = _controller.isEditing;
          return Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: isEditing ? _buildAppBar(l10n) : null,
            body: isEditing
                ? _buildBody(l10n)
                : Stack(
                    children: [
                      _buildBody(l10n),
                      _buildFloatingControls(context, l10n),
                    ],
                  ),
            bottomNavigationBar: _buildBottomBar(l10n),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(title: Text(l10n.diaryDetailEditTitle));
  }

  Widget _buildFloatingControls(BuildContext context, AppLocalizations l10n) {
    final canShowActions =
        !_controller.isLoading &&
        !_controller.hasError &&
        _controller.diaryEntry != null;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 20,
      right: 20,
      child: Row(
        children: [
          _buildFloatingButton(
            Icons.arrow_back_ios_new_rounded,
            () => Navigator.of(
              context,
            ).pop(_controller.wasModified ? 'updated' : null),
          ),
          const Spacer(),
          if (canShowActions) ...[
            _buildFloatingButton(
              Icons.share_rounded,
              () => DiaryDetailShareHelper.showShareDialog(
                context: context,
                diaryEntry: _controller.diaryEntry!,
                photoAssets: _controller.photoAssets,
              ),
            ),
            const SizedBox(width: 8),
            _buildFloatingButton(
              Icons.edit_rounded,
              () => _controller.startEditing(),
            ),
            const SizedBox(width: 8),
            _buildFloatingButton(
              Icons.more_horiz_rounded,
              () => _showMoreMenu(context, l10n),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingButton(IconData icon, VoidCallback onTap) {
    return CircularIconButton(
      onPressed: onTap,
      icon: icon,
      backgroundColor: Colors.black.withValues(alpha: 0.45),
      foregroundColor: Colors.white,
      size: 36,
    );
  }

  Future<void> _showMoreMenu(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.delete_rounded,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                l10n.commonDelete,
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                MicroInteractions.hapticTap(
                  intensity: VibrationIntensity.medium,
                );
                _deleteDiary();
              },
            ),
          ],
        ),
      ),
    );
  }

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
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? AppSpacing.bottomBarShadowDark
              : AppSpacing.bottomBarShadow,
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

  Widget _buildLoadingState(AppLocalizations l10n) {
    return Center(
      child: FadeInWidget(
        child: LoadingStateCard(
          title: l10n.diaryDetailLoadingTitle,
          subtitle: l10n.diaryDetailLoadingSubtitle,
          indicatorColor: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return _buildInfoCard(
      iconData: Icons.error_outline_rounded,
      iconColor: cs.error,
      iconBgColor: cs.errorContainer.withValues(alpha: 0.3),
      title: l10n.commonErrorOccurred,
      subtitle: _getErrorMessage(l10n),
      subtitleColor: cs.error,
    );
  }

  Widget _buildNotFoundState(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return _buildInfoCard(
      iconData: Icons.search_off_rounded,
      iconColor: cs.secondary,
      iconBgColor: cs.secondaryContainer.withValues(alpha: 0.3),
      title: l10n.diaryNotFoundMessage,
      subtitle: l10n.diaryNotFoundSubtitle,
      subtitleColor: cs.onSurfaceVariant,
    );
  }

  Widget _buildInfoCard({
    required IconData iconData,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required Color subtitleColor,
  }) {
    return Center(
      child: FadeInWidget(
        child: CustomCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: AppSpacing.iconLg,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(title, style: AppTypography.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                style: AppTypography.bodyMedium.copyWith(color: subtitleColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                onPressed: () => Navigator.pop(context),
                text: context.l10n.commonBack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
