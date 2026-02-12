import 'package:flutter/material.dart';

import '../../localization/localization_extensions.dart';
import '../../models/writing_prompt.dart';
import '../../ui/components/custom_card.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../ui/animations/list_animations.dart';
import '../../utils/prompt_category_utils.dart';

/// 日記プレビューのローディング状態ウィジェット群
class DiaryPreviewLoadingStates extends StatelessWidget {
  const DiaryPreviewLoadingStates({
    super.key,
    required this.isInitializing,
    required this.isSaving,
    required this.isAnalyzingPhotos,
    required this.currentPhotoIndex,
    required this.totalPhotos,
    required this.selectedPrompt,
  });

  final bool isInitializing;
  final bool isSaving;
  final bool isAnalyzingPhotos;
  final int currentPhotoIndex;
  final int totalPhotos;
  final WritingPrompt? selectedPrompt;

  @override
  Widget build(BuildContext context) {
    return FadeInWidget(
      child: CustomCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
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
              if (isAnalyzingPhotos && totalPhotos > 1)
                _buildAnalyzingProgress(context)
              else if (isInitializing)
                _buildInitializingText(context)
              else if (isSaving)
                _buildSavingText(context)
              else
                _buildGeneratingText(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzingProgress(BuildContext context) {
    return Column(
      children: [
        Text(
          context.l10n.diaryPreviewAnalyzingPhotos,
          style: AppTypography.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.diaryPreviewAnalyzingProgress(
            currentPhotoIndex,
            totalPhotos,
          ),
          style: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: totalPhotos > 0 ? currentPhotoIndex / totalPhotos : 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitializingText(BuildContext context) {
    return Column(
      children: [
        Text(
          context.l10n.diaryPreviewInitializingPromptsTitle,
          style: AppTypography.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.diaryPreviewInitializingPromptsDescription,
          style: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSavingText(BuildContext context) {
    return Column(
      children: [
        Text(
          context.l10n.diaryPreviewSavingDiaryTitle,
          style: AppTypography.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.diaryPreviewSavingDiaryDescription,
          style: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGeneratingText(BuildContext context) {
    return Column(
      children: [
        Text(
          context.l10n.diaryPreviewGeneratingDiaryTitle,
          style: AppTypography.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.diaryPreviewGeneratingDiaryDescription,
          style: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (selectedPrompt != null) ...[
          const SizedBox(height: AppSpacing.md),
          _buildPromptIndicator(context),
        ],
      ],
    );
  }

  Widget _buildPromptIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: PromptCategoryUtils.getCategoryColor(
          selectedPrompt!.category,
        ).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(
          color: PromptCategoryUtils.getCategoryColor(
            selectedPrompt!.category,
          ).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.edit_note_rounded,
            size: 16,
            color: PromptCategoryUtils.getCategoryColor(
              selectedPrompt!.category,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              selectedPrompt!.text.length > 30
                  ? '${selectedPrompt!.text.substring(0, 30)}...'
                  : selectedPrompt!.text,
              style: AppTypography.bodySmall.copyWith(
                color: PromptCategoryUtils.getCategoryColor(
                  selectedPrompt!.category,
                ),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
