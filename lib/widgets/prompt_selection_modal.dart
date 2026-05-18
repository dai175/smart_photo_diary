import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../models/writing_prompt.dart';
import '../services/interfaces/prompt_service_interface.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../core/service_registration.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/animated_button.dart';
import '../ui/components/custom_dialog.dart';
import '../localization/localization_extensions.dart';
import 'prompt_list_item.dart';
import 'prompt_search_bar.dart';

class PromptSelectionModal extends StatefulWidget {
  final void Function(WritingPrompt?, String?) onPromptSelected;
  final void Function(String?) onSkip;
  final DateTime? date;
  final ILoggingService? logger;
  final IPromptService? promptService;
  final ISubscriptionService? subscriptionService;

  const PromptSelectionModal({
    super.key,
    required this.onPromptSelected,
    required this.onSkip,
    this.date,
    this.logger,
    this.promptService,
    this.subscriptionService,
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
  bool _initSucceeded = false;
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
    _logger = widget.logger ?? ServiceRegistration.get<ILoggingService>();
    _promptService =
        widget.promptService ?? ServiceRegistration.get<IPromptService>();
    _subscriptionService =
        widget.subscriptionService ??
        ServiceRegistration.get<ISubscriptionService>();
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
        _initSucceeded = true;
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
      PrimaryButton(
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
        width: double.infinity,
        text: primaryText,
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

        PromptSearchBar(
          controller: _contextController,
          contextAnimation: _contextAnimation,
          isExpanded: _showContextInput,
          onToggle: () {
            setState(() {
              _showContextInput = !_showContextInput;
            });
            if (_showContextInput) {
              _contextAnimationController.forward();
            } else {
              _contextAnimationController.reverse();
            }
          },
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
                    child: _QuickOptionCell(
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
                    child: _QuickOptionCell(
                      isSelected: _isRandomSelected,
                      icon: Icons.shuffle_rounded,
                      title: l10n.promptOptionRandom,
                      desc: l10n.promptRandomDescription,
                      onTap: (_isLoading || !_initSucceeded)
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
        return PromptListItem(
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
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note_rounded, color: onSurfaceVariant, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.promptEmptyTitle, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.promptEmptyDescription,
              style: AppTypography.bodySmall.copyWith(color: onSurfaceVariant),
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

class _QuickOptionCell extends StatelessWidget {
  const _QuickOptionCell({
    required this.isSelected,
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  final bool isSelected;
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardBgColor = isDark
        ? AppColors.surfaceContainerDark
        : AppColors.cardBg;
    final glyphBgColor = colorScheme.surfaceContainerHighest;

    return Ink(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.selectedBg : cardBgColor,
        borderRadius: AppSpacing.cardRadiusLarge,
        border: Border.all(
          color: isSelected
              ? AppColors.accent
              : (isDark ? AppColors.outlineDark : AppColors.divider),
        ),
      ),
      child: InkWell(
        borderRadius: AppSpacing.cardRadiusLarge,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
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
      ),
    );
  }
}
