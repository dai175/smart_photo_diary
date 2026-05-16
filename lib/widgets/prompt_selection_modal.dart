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
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/animated_button.dart';
import '../ui/components/custom_dialog.dart';
import '../localization/localization_extensions.dart';
import 'prompt_selection_items.dart';

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
      final services = await Future.wait([
        ServiceRegistration.getAsync<IPromptService>(),
        ServiceRegistration.getAsync<ISubscriptionService>(),
      ]);
      _promptService = services[0] as IPromptService;
      _subscriptionService = services[1] as ISubscriptionService;

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
      maxWidth: 420,
      contentPadding: EdgeInsets.zero,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: _isLoading ? _buildLoadingContent() : _buildContent(context),
      ),
      actions: _buildActions(),
    );
  }

  String? _getContextText() {
    final text = _contextController.text.trim();
    return text.isEmpty ? null : text;
  }

  List<Widget> _buildActions() {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accentColor = theme.brightness == Brightness.dark
        ? AppColors.accentLight
        : AppColors.accent;
    final String primaryText;
    if (_isRandomSelected) {
      primaryText = l10n.promptCreateRandom;
    } else if (_selectedPrompt != null) {
      primaryText = l10n.promptCreateWithSelected;
    } else {
      primaryText = l10n.promptCreateWithout;
    }

    return [
      AnimatedButton(
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
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        shadowColor: accentColor.withValues(alpha: 0.3),
        child: Center(child: Text(primaryText)),
      ),
    ];
  }

  Widget _buildCloseButton(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.of(context).pop(),
      tooltip: context.l10n.commonCancel,
      icon: Icon(
        Icons.close,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 20,
      ),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
          ),
          child: _buildCloseButton(context),
        ),
        const SizedBox(
          height: AppSpacing.xxl * 5,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accentMutedColor = isDark
        ? AppColors.accentLight
        : AppColors.accentMuted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
            0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _headerDate,
                      style: AppTypography.sectionLabel.copyWith(
                        color: accentMutedColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.promptSelectionTitle,
                      style: AppTypography.cardTitle.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.promptSelectionSubtitle,
                      style: AppTypography.cardBody.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCloseButton(context),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
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
                    children: [
                      AnimatedRotation(
                        turns: _showContextInput ? 0.25 : 0,
                        duration: AppConstants.quickAnimationDuration,
                        child: Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: accentMutedColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.promptContextToggle,
                        style: AppTypography.bodySmall.copyWith(
                          color: accentMutedColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          l10n.promptContextInputHelper,
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
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

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.promptSectionQuickOptions,
                style: AppTypography.sectionLabel.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickOptionCell(
                      isSelected: _selectedPrompt == null && !_isRandomSelected,
                      icon: Icons.edit_off_rounded,
                      title: l10n.promptOptionNone,
                      desc: l10n.promptOptionNoneDescription,
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
                      desc: l10n.promptRandomDescription,
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
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Text(
                l10n.promptSectionBrowse,
                style: AppTypography.sectionLabel.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (!_isLoading)
                Text(
                  l10n.promptBrowseCount(_availablePrompts.length),
                  style: AppTypography.cardBody.copyWith(
                    fontSize: 11.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

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
    required String desc,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardBgColor = isDark
        ? AppColors.surfaceContainerDark
        : AppColors.cardBg;
    final glyphBgColor = colorScheme.surfaceContainerHighest;

    return InkWell(
      borderRadius: AppSpacing.cardRadiusLarge,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.selectedBg : cardBgColor,
          borderRadius: AppSpacing.cardRadiusLarge,
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : (isDark ? AppColors.outlineDark : AppColors.divider),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : glyphBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: AppColors.accent,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
                height: 1.2,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              desc,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                height: 1.45,
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptList() {
    final dividerColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.outlineDark
        : AppColors.divider;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.lg,
      ),
      itemCount: _availablePrompts.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: dividerColor, indent: 14, endIndent: 14),
      itemBuilder: (context, index) {
        final prompt = _availablePrompts[index];
        return PromptSelectionItems.buildPromptCard(
          context,
          prompt: prompt,
          isSelected: _selectedPrompt?.id == prompt.id && !_isRandomSelected,
          isPremium: _isPremium,
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
