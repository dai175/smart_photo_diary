import 'package:flutter/material.dart';
import '../models/writing_prompt.dart';
import '../services/interfaces/prompt_service_interface.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../core/service_registration.dart';
import '../core/service_locator.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/custom_dialog.dart';
import '../localization/localization_extensions.dart';
import 'prompt_selection_items.dart';

/// プロンプト選択モーダル
class PromptSelectionModal extends StatefulWidget {
  final void Function(WritingPrompt?, String?) onPromptSelected;
  final void Function(String?) onSkip;

  const PromptSelectionModal({
    super.key,
    required this.onPromptSelected,
    required this.onSkip,
  });

  @override
  State<PromptSelectionModal> createState() => _PromptSelectionModalState();
}

class _PromptSelectionModalState extends State<PromptSelectionModal> {
  late final ILoggingService _logger;
  late final IPromptService _promptService;
  late final ISubscriptionService _subscriptionService;

  bool _isLoading = true;
  bool _isPremium = false;
  List<WritingPrompt> _availablePrompts = [];
  WritingPrompt? _selectedPrompt;
  bool _isRandomSelected = false;
  late final TextEditingController _contextController;

  @override
  void initState() {
    super.initState();
    _logger = serviceLocator.get<ILoggingService>();
    _contextController = TextEditingController();
    _initializeServices();
  }

  @override
  void dispose() {
    _contextController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      _promptService = await ServiceRegistration.getAsync<IPromptService>();
      _subscriptionService =
          await ServiceRegistration.getAsync<ISubscriptionService>();

      // Premium状態を取得
      final accessResult = await _subscriptionService
          .canAccessPremiumFeatures();
      if (accessResult.isSuccess) {
        _isPremium = accessResult.value;
      }

      if (!mounted) {
        return;
      }

      final locale = Localizations.localeOf(context);

      // 利用可能なプロンプトを読み込み
      _availablePrompts = _promptService.getPromptsForPlan(
        isPremium: _isPremium,
        locale: locale,
      );
      _logger.info(
        'Prompt initialization completed: ${_availablePrompts.length} prompts, isPremium: $_isPremium',
        context: 'PromptSelectionModal',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
            // ランダム選択の場合は実際のプロンプトを取得して渡す
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
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: TextField(
            controller: _contextController,
            maxLines: 2,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: l10n.promptContextInputLabel,
              hintText: l10n.promptContextInputHint,
              helperText: l10n.promptContextInputHelper,
            ),
          ),
        ),
        Flexible(
          child: _availablePrompts.isEmpty
              ? _buildEmptyState()
              : _buildPromptList(),
        ),
      ],
    );
  }

  Widget _buildPromptList() {
    return ListView.separated(
      padding: AppSpacing.cardPadding,
      itemCount:
          _availablePrompts.length +
          2, // +1 for no prompt, +1 for random selection
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index == 0) {
          return PromptSelectionItems.buildNoPromptOption(
            context,
            isSelected: _selectedPrompt == null && !_isRandomSelected,
            onTap: () => setState(() {
              _selectedPrompt = null;
              _isRandomSelected = false;
            }),
          );
        } else if (index == 1) {
          return PromptSelectionItems.buildRandomButton(
            context,
            isSelected: _isRandomSelected,
            isLoading: _isLoading,
            onTap: _isLoading
                ? null
                : () => setState(() {
                    _selectedPrompt = null;
                    _isRandomSelected = true;
                  }),
          );
        }

        final prompt = _availablePrompts[index - 2];
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

    // 使用履歴記録は実際に日記生成が完了した時点で行う
    // ここでは選択のみ行い、履歴記録はしない
  }
}
