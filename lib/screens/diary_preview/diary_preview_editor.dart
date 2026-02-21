import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../localization/localization_extensions.dart';
import '../../models/writing_prompt.dart';
import '../../ui/components/custom_card.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../ui/animations/list_animations.dart';
import '../../utils/prompt_category_utils.dart';

/// 日記プレビューのエディタ状態ウィジェット
class DiaryPreviewEditor extends StatelessWidget {
  const DiaryPreviewEditor({
    super.key,
    required this.titleController,
    required this.contentController,
    required this.selectedPrompt,
  });

  final TextEditingController titleController;
  final TextEditingController contentController;
  final WritingPrompt? selectedPrompt;

  @override
  Widget build(BuildContext context) {
    return SlideInWidget(
      delay: AppConstants.quickAnimationDuration,
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEditorHeader(context),
            const SizedBox(height: AppSpacing.md),
            _buildTitleField(context),
            const SizedBox(height: AppSpacing.sm),
            _buildContentField(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.edit_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: AppSpacing.iconMd,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            context.l10n.diaryPreviewContentSectionTitle,
            style: AppTypography.titleLarge,
          ),
        ),
        if (selectedPrompt != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: PromptCategoryUtils.getCategoryColor(
                selectedPrompt!.category,
              ).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  size: 12,
                  color: PromptCategoryUtils.getCategoryColor(
                    selectedPrompt!.category,
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  context.l10n.diaryPreviewPromptTag,
                  style: AppTypography.labelSmall.copyWith(
                    color: PromptCategoryUtils.getCategoryColor(
                      selectedPrompt!.category,
                    ),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTitleField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
        borderRadius: AppSpacing.inputRadius,
        color: Theme.of(context).colorScheme.surface,
      ),
      child: TextField(
        controller: titleController,
        style: AppTypography.titleMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: context.l10n.diaryPreviewTitleLabel,
          border: InputBorder.none,
          hintText: context.l10n.diaryPreviewTitleHint,
          contentPadding: AppSpacing.inputPadding,
          labelStyle: AppTypography.labelMedium,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildContentField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
        borderRadius: AppSpacing.inputRadius,
        color: Theme.of(context).colorScheme.surface,
      ),
      child: TextField(
        controller: contentController,
        maxLines: null,
        minLines: 12,
        textAlignVertical: TextAlignVertical.top,
        style: AppTypography.bodyLarge.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: context.l10n.diaryPreviewContentLabel,
          hintText: context.l10n.diaryPreviewContentHint,
          border: InputBorder.none,
          contentPadding: AppSpacing.inputPadding,
          labelStyle: AppTypography.labelMedium,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          alignLabelWithHint: true,
        ),
      ),
    );
  }
}
