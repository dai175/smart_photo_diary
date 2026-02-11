import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../constants/app_constants.dart';
import '../../core/result/result.dart';
import '../../core/service_registration.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../localization/localization_extensions.dart';
import '../../models/diary_entry.dart';
import '../../services/interfaces/diary_service_interface.dart';
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
  DiaryEntry? _diaryEntry;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _hasError = false;
  String _errorMessage = '';
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  List<AssetEntity> _photoAssets = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    // ローカライズへの依存をinitState完了後に解決するため初回ロードはフレーム後に実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDiaryEntry();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// 日記エントリーを読み込む
  Future<void> _loadDiaryEntry() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final diaryService = await ServiceRegistration.getAsync<IDiaryService>();
      final result = await diaryService.getDiaryEntry(widget.diaryId);

      if (!mounted) return;

      switch (result) {
        case Success(data: final entry):
          if (entry == null) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = context.l10n.diaryNotFoundMessage;
            });
            return;
          }

          final assets = await entry.getPhotoAssets();

          if (!mounted) return;

          setState(() {
            _diaryEntry = entry;
            _titleController.text = entry.title;
            _contentController.text = entry.content;
            _photoAssets = assets;
            _isLoading = false;
          });
        case Failure(exception: final e):
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage =
                '${context.l10n.diaryLoadErrorMessage}: ${e.message}';
          });
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = context.l10n;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '${l10n.diaryLoadErrorMessage}: $e';
      });
    }
  }

  /// 日記を更新する
  Future<void> _updateDiary() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (_diaryEntry == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final diaryService = await ServiceRegistration.getAsync<IDiaryService>();

      final updatedEntry = _diaryEntry!.copyWith(
        title: _titleController.text,
        content: _contentController.text,
        updatedAt: DateTime.now(),
      );
      final updateResult = await diaryService.updateDiaryEntry(updatedEntry);

      switch (updateResult) {
        case Success():
          await _loadDiaryEntry();

          if (mounted) {
            setState(() {
              _isEditing = false;
            });

            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text(context.l10n.diaryUpdateSuccessMessage)),
            );
          }
        case Failure(exception: final e):
          if (mounted) {
            final l10n = context.l10n;
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = l10n.diaryDetailUpdateError(e.message);
            });

            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(l10n.commonErrorWithMessage(_errorMessage)),
              ),
            );
          }
      }
    } catch (e) {
      if (mounted) {
        final l10n = context.l10n;
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = l10n.diaryDetailUpdateError('$e');
        });

        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.commonErrorWithMessage(_errorMessage))),
        );
      }
    }
  }

  /// 日記を削除する
  Future<void> _deleteDiary() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = context.l10n;

    if (_diaryEntry == null) return;

    final confirmed = await DialogUtils.showConfirmationDialog(
      context,
      l10n.diaryDetailDeleteDialogTitle,
      l10n.diaryDetailDeleteDialogMessage,
      confirmText: l10n.commonDelete,
      isDestructive: true,
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final diaryService = await ServiceRegistration.getAsync<IDiaryService>();
      final deleteResult = await diaryService.deleteDiaryEntry(_diaryEntry!.id);

      switch (deleteResult) {
        case Success():
          if (mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text(context.l10n.diaryDeleteSuccessMessage)),
            );
            navigator.pop(true);
          }
        case Failure(exception: final e):
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = l10n.diaryDetailDeleteError(e.message);
            });

            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(l10n.commonErrorWithMessage(_errorMessage)),
              ),
            );
          }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = l10n.diaryDetailDeleteError('$e');
        });

        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.commonErrorWithMessage(_errorMessage))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(l10n),
      body: _buildBody(l10n),
      bottomNavigationBar: _buildBottomBar(l10n),
    );
  }

  /// AppBarを構築
  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      title: Text(
        _isEditing ? l10n.diaryDetailEditTitle : l10n.diaryDetailViewTitle,
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: Theme.of(context).colorScheme.onPrimary,
      ),
      iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
      elevation: 2,
      actions: [
        // 共有ボタン
        if (!_isLoading && !_hasError && _diaryEntry != null && !_isEditing)
          IconButton(
            onPressed: () {
              MicroInteractions.hapticTap();
              DiaryDetailShareHelper.showShareDialog(
                context: context,
                diaryEntry: _diaryEntry!,
                photoAssets: _photoAssets,
              );
            },
            icon: Icon(
              Icons.share_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            tooltip: l10n.commonShare,
          ),
        // 編集モード切替ボタン
        if (!_isLoading && !_hasError && _diaryEntry != null)
          IconButton(
            onPressed: () {
              MicroInteractions.hapticTap();
              if (_isEditing) {
                _updateDiary();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
            icon: Icon(
              _isEditing ? Icons.check_rounded : Icons.edit_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            tooltip: _isEditing ? l10n.commonSave : l10n.commonEdit,
          ),
        // 削除ボタン
        if (!_isLoading && !_hasError && _diaryEntry != null)
          IconButton(
            onPressed: () {
              MicroInteractions.hapticTap(intensity: VibrationIntensity.medium);
              _deleteDiary();
            },
            icon: Icon(
              Icons.delete_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            tooltip: l10n.commonDelete,
          ),
      ],
    );
  }

  /// Bodyを構築
  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return _buildLoadingState(l10n);
    }
    if (_hasError) {
      return _buildErrorState(l10n);
    }
    if (_diaryEntry == null) {
      return _buildNotFoundState(l10n);
    }
    return DiaryDetailContent(
      diaryEntry: _diaryEntry!,
      photoAssets: _photoAssets,
      isEditing: _isEditing,
      titleController: _titleController,
      contentController: _contentController,
    );
  }

  /// BottomBarを構築
  Widget? _buildBottomBar(AppLocalizations l10n) {
    if (!_isEditing || _isLoading || _hasError || _diaryEntry == null) {
      return null;
    }
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(
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
                  setState(() {
                    _isEditing = false;
                    _titleController.text = _diaryEntry!.title;
                    _contentController.text = _diaryEntry!.content;
                  });
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
                icon: Icons.save_rounded,
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
                _errorMessage,
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                onPressed: () => Navigator.pop(context),
                text: l10n.commonBack,
                icon: Icons.arrow_back_rounded,
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
                icon: Icons.arrow_back_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
