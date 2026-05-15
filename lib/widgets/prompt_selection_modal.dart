import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/ai_constants.dart';
import '../constants/app_constants.dart';
import '../models/writing_prompt.dart';
import '../services/interfaces/prompt_service_interface.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../core/service_registration.dart';
import '../core/service_locator.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../ui/component_constants.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/custom_dialog.dart';
import '../localization/localization_extensions.dart';
import 'prompt_selection_items.dart';

/// プロンプト選択モーダル
class PromptSelectionModal extends StatefulWidget {
  final void Function(WritingPrompt?, String?) onPromptSelected;
  final void Function(String?) onSkip;
  final DateTime? date;

  const PromptSelectionModal({
    super.key,
    required this.onPromptSelected,
    required this.onSkip,
    this.date,
  });

  @override
  State<PromptSelectionModal> createState() => _PromptSelectionModalState();
}

class _PromptSelectionModalState extends State<PromptSelectionModal>
    with SingleTickerProviderStateMixin {
  late final ILoggingService _logger;
  late final IPromptService _promptService;
  late final ISubscriptionService _subscriptionService;

  bool _isLoading = true;
  bool _isPremium = false;
  List<WritingPrompt> _availablePrompts = [];
  WritingPrompt? _selectedPrompt;
  bool _isRandomSelected = false;
  bool _showContextInput = false;
  late final TextEditingController _contextController;
  late final AnimationController _contextAnimationController;
  late final Animation<double> _contextAnimation;
  late String _headerDate;

  @override
  void initState() {
    super.initState();
    _logger = serviceLocator.get<ILoggingService>();
    _contextController = TextEditingController();
    _contextAnimationController = AnimationController(
      duration: AppConstants.quickAnimationDuration,
      vsync: this,
    );
    _contextAnimation = CurvedAnimation(
      parent: _contextAnimationController,
      curve: Curves.easeInOut,
    );
    _initializeServices();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final date = widget.date ?? DateTime.now();
    final locale = Localizations.localeOf(context);
    _headerDate = DateFormat(
      'MMM d',
      locale.toString(),
    ).format(date).toUpperCase();
  }

  @override
  void dispose() {
    _contextAnimationController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      _promptService = await ServiceRegistration.getAsync<IPromptService>();
      _subscriptionService =
          await ServiceRegistration.getAsync<ISubscriptionService>();

      final accessResult = await _subscriptionService
          .canAccessPremiumFeatures();
      if (accessResult.isSuccess) {
        _isPremium = accessResult.value;
      }

      if (!mounted) return;

      final locale = Localizations.localeOf(context);
      _availablePrompts = _promptService.getPromptsForPlan(
        isPremium: _isPremium,
        locale: locale,
      );
      _logger.info(
        'Prompt initialization completed: ${_availablePrompts.length} prompts, isPremium: $_isPremium',
        context: 'PromptSelectionModal',
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _logger.error(
        'Prompt service initialization error',
        error: e,
        context: 'PromptSelectionModal',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: context.l10n.promptSelectionTitle,
      icon: Icons.edit_note_rounded,
      iconColor: Theme.of(context).colorScheme.primary,
      maxWidth: 420,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 480),
        child: _isLoading ? _buildLoadingContent() : _buildContent(context),
      ),
      actions: _buildActions(),
    );
  }

  String? _getContextText() {
    final text = _contextController.text.trim();
    return text.isEmpty ? null : text;
  }

  List<CustomDialogAction> _buildActions() {
    final l10n = context.l10n;
    final String primaryText;
    if (_isRandomSelected) {
      primaryText = l10n.promptCreateRandom;
    } else if (_selectedPrompt != null) {
      primaryText = l10n.promptCreateWithSelected;
    } else {
      primaryText = l10n.promptCreateWithout;
    }

    return [
      CustomDialogAction(
        text: l10n.commonCancel,
        onPressed: () => Navigator.of(context).pop(),
      ),
      CustomDialogAction(
        text: primaryText,
        isPrimary: true,
        onPressed: () {
          final contextText = _getContextText();
          if (_isRandomSelected) {
            final randomPrompt = _promptService.getRandomPrompt(
              isPremium: _isPremium,
              locale: Localizations.localeOf(context),
            );
            widget.onPromptSelected(randomPrompt, contextText);
          } else if (_selectedPrompt != null) {
            widget.onPromptSelected(_selectedPrompt, contextText);
          } else {
            widget.onSkip(contextText);
          }
        },
      ),
    ];
  }

  Widget _buildLoadingContent() {
    return Container(
      height: 200,
      padding: AppSpacing.cardPadding,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日付ラベル
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            0,
          ),
          child: Text(
            _headerDate,
            style: AppTypography.dateLabel.copyWith(
              color: AppColors.accentMuted,
            ),
          ),
        ),

        // コンテキスト入力トグル
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    _showContextInput = !_showContextInput;
                  });
                  if (_showContextInput) {
                    _contextAnimationController.forward();
                  } else {
                    _contextAnimationController.reverse();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showContextInput
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.promptContextToggle,
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizeTransition(
                sizeFactor: _contextAnimation,
                axisAlignment: -1.0,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: TextField(
                    controller: _contextController,
                    maxLines: 2,
                    maxLength: AiConstants.contextTextMaxLength,
                    decoration: InputDecoration(
                      labelText: l10n.promptContextInputLabel,
                      hintText: l10n.promptContextInputHint,
                      helperText: l10n.promptContextInputHelper,
                      helperMaxLines: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // クイックオプション 2列グリッド
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: _buildQuickOptionCell(
                  isSelected: _selectedPrompt == null && !_isRandomSelected,
                  icon: Icons.edit_off_rounded,
                  title: l10n.promptOptionNone,
                  onTap: () => setState(() {
                    _selectedPrompt = null;
                    _isRandomSelected = false;
                  }),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildQuickOptionCell(
                  isSelected: _isRandomSelected,
                  icon: Icons.shuffle_rounded,
                  title: l10n.promptOptionRandom,
                  onTap: _isLoading
                      ? null
                      : () => setState(() {
                          _selectedPrompt = null;
                          _isRandomSelected = true;
                        }),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // プロンプトリスト
        Flexible(
          child: _availablePrompts.isEmpty
              ? _buildEmptyState()
              : _buildPromptList(),
        ),
      ],
    );
  }

  Widget _buildQuickOptionCell({
    required bool isSelected,
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(ModalConstants.radius - 4),
      onTap: onTap,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.selectedBg : AppColors.glyphBg,
          borderRadius: BorderRadius.circular(ModalConstants.radius - 4),
          border: Border.all(
            color: isSelected ? AppColors.accentMuted : AppColors.divider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.accentMuted : AppColors.muted,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTypography.cardBody.copyWith(
                color: isSelected
                    ? AppColors.accentMuted
                    : AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptList() {
    return ListView.separated(
      padding: AppSpacing.cardPadding,
      itemCount: _availablePrompts.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final prompt = _availablePrompts[index];
        return PromptSelectionItems.buildPromptCard(
          context,
          prompt: prompt,
          isSelected: _selectedPrompt?.id == prompt.id && !_isRandomSelected,
          onTap: () => _selectPrompt(prompt),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_note_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.promptEmptyTitle, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.promptEmptyDescription,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _selectPrompt(WritingPrompt prompt) {
    setState(() {
      _selectedPrompt = prompt;
      _isRandomSelected = false;
    });
  }
}
