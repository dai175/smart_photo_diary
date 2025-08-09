import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/writing_prompt.dart';
import '../services/interfaces/prompt_service_interface.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../core/service_registration.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/custom_dialog.dart';
import '../utils/prompt_category_utils.dart';
import '../services/logging_service.dart';

/// プロンプト選択モーダル
class PromptSelectionModal extends StatefulWidget {
  final Function(WritingPrompt?) onPromptSelected;
  final VoidCallback onSkip;

  const PromptSelectionModal({
    super.key,
    required this.onPromptSelected,
    required this.onSkip,
  });

  @override
  State<PromptSelectionModal> createState() => _PromptSelectionModalState();
}

class _PromptSelectionModalState extends State<PromptSelectionModal> {
  late final IPromptService _promptService;
  late final ISubscriptionService _subscriptionService;

  bool _isLoading = true;
  bool _isPremium = false;
  List<WritingPrompt> _availablePrompts = [];
  WritingPrompt? _selectedPrompt;
  bool _isRandomSelected = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
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

      // 利用可能なプロンプトを読み込み
      _availablePrompts = _promptService.getPromptsForPlan(
        isPremium: _isPremium,
      );
      if (kDebugMode) {
        LoggingService.instance.info(
          'プロンプト初期化完了',
          context: 'PromptSelectionModal._loadPrompts',
          data: {
            'promptCount': _availablePrompts.length,
            'isPremium': _isPremium,
          },
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        LoggingService.instance.error(
          'プロンプトサービス初期化エラー',
          context: 'PromptSelectionModal._loadPrompts',
          error: e,
        );
      }
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
      title: 'プロンプト選択',
      icon: Icons.edit_note_rounded,
      iconColor: Theme.of(context).colorScheme.primary,
      maxWidth: 420,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400),
        child: _isLoading ? _buildLoadingContent() : _buildContent(context),
      ),
      actions: _buildActions(),
    );
  }

  List<CustomDialogAction> _buildActions() {
    return [
      CustomDialogAction(
        text: 'キャンセル',
        onPressed: () => Navigator.of(context).pop(),
      ),
      CustomDialogAction(
        text: _isRandomSelected
            ? 'ランダムで作成'
            : (_selectedPrompt != null ? 'プロンプトで作成' : 'そのまま作成'),
        icon: _isRandomSelected
            ? Icons.shuffle_rounded
            : (_selectedPrompt != null
                  ? Icons.auto_awesome_rounded
                  : Icons.photo_camera_rounded),
        isPrimary: true,
        onPressed: () {
          if (_isRandomSelected) {
            // ランダム選択の場合は実際のプロンプトを取得して渡す
            final randomPrompt = _promptService.getRandomPrompt(
              isPremium: _isPremium,
            );
            widget.onPromptSelected(randomPrompt);
          } else if (_selectedPrompt != null) {
            widget.onPromptSelected(_selectedPrompt);
          } else {
            widget.onSkip();
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
    return _availablePrompts.isEmpty ? _buildEmptyState() : _buildPromptList();
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
          // プロンプトなしオプション
          return _buildNoPromptOption();
        } else if (index == 1) {
          // ランダム選択ボタン
          return _buildRandomButton();
        }

        final prompt = _availablePrompts[index - 2];
        return _buildPromptCard(prompt);
      },
    );
  }

  Widget _buildNoPromptOption() {
    final isSelected = _selectedPrompt == null && !_isRandomSelected;

    return InkWell(
      onTap: () => setState(() {
        _selectedPrompt = null;
        _isRandomSelected = false;
      }),
      borderRadius: AppSpacing.cardRadius,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
              : null,
          borderRadius: AppSpacing.cardRadius,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_off_rounded,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'プロンプトなし',
                    style: AppTypography.titleSmall.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '写真のみから日記を生成',
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRandomButton() {
    final isSelected = _isRandomSelected;

    return InkWell(
      onTap: _isLoading
          ? null
          : () => setState(() {
              _selectedPrompt = null;
              _isRandomSelected = true;
            }),
      borderRadius: AppSpacing.cardRadius,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: AppSpacing.cardRadius,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shuffle_rounded,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ランダム選択',
                    style: AppTypography.titleSmall.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _isLoading ? 'プロンプトを読み込み中...' : 'おすすめのプロンプトを自動選択',
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              )
            else
              Icon(
                Icons.auto_awesome_rounded,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.7),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptCard(WritingPrompt prompt) {
    final isSelected = _selectedPrompt?.id == prompt.id && !_isRandomSelected;

    return InkWell(
      onTap: () => _selectPrompt(prompt),
      borderRadius: AppSpacing.cardRadius,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: isSelected
              ? PromptCategoryUtils.getCategoryColor(
                  prompt.category,
                ).withValues(alpha: 0.15)
              : null,
          borderRadius: AppSpacing.cardRadius,
          border: Border.all(
            color: isSelected
                ? PromptCategoryUtils.getCategoryColor(
                    prompt.category,
                  ).withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? PromptCategoryUtils.getCategoryColor(prompt.category)
                        : PromptCategoryUtils.getCategoryColor(
                            prompt.category,
                          ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                  ),
                  child: Text(
                    PromptCategoryUtils.getCategoryDisplayName(prompt.category),
                    style: AppTypography.labelSmall.copyWith(
                      color: isSelected
                          ? Colors.white
                          : PromptCategoryUtils.getCategoryColor(
                              prompt.category,
                            ),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: PromptCategoryUtils.getCategoryColor(
                      prompt.category,
                    ),
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              prompt.text,
              style: isSelected
                  ? AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    )
                  : AppTypography.bodyMedium,
            ),
            if (prompt.description != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                prompt.description!,
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            Text('プロンプトが見つかりません', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'プロンプトデータの読み込みに失敗しました',
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
