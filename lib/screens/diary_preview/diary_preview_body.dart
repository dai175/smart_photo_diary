import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../constants/app_constants.dart';
import '../../localization/localization_extensions.dart';
import '../../models/writing_prompt.dart';
import '../../ui/components/animated_button.dart';
import '../../ui/components/custom_card.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../ui/animations/list_animations.dart';
import '../../utils/prompt_category_utils.dart';

/// 日記プレビュー画面のボディコンテンツ
///
/// 日付カード、写真プレビュー、ローディング/エラー/エディタ表示を担当する。
class DiaryPreviewBody extends StatelessWidget {
  const DiaryPreviewBody({
    super.key,
    required this.selectedAssets,
    required this.photoDateTime,
    required this.selectedPrompt,
    required this.isInitializing,
    required this.isLoading,
    required this.isSaving,
    required this.hasError,
    required this.errorMessage,
    required this.isAnalyzingPhotos,
    required this.currentPhotoIndex,
    required this.totalPhotos,
    required this.titleController,
    required this.contentController,
  });

  final List<AssetEntity> selectedAssets;
  final DateTime photoDateTime;
  final WritingPrompt? selectedPrompt;
  final bool isInitializing;
  final bool isLoading;
  final bool isSaving;
  final bool hasError;
  final String errorMessage;
  final bool isAnalyzingPhotos;
  final int currentPhotoIndex;
  final int totalPhotos;
  final TextEditingController titleController;
  final TextEditingController contentController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 日付表示カード
          _buildDateCard(context),
          const SizedBox(height: AppSpacing.lg),

          // プロンプトが選択されている場合のみ表示
          if (!isInitializing && selectedPrompt != null)
            DiaryPreviewPromptDisplay(prompt: selectedPrompt!),
          if (!isInitializing && selectedPrompt != null)
            const SizedBox(height: AppSpacing.lg),

          // 選択された写真のプレビュー
          if (selectedAssets.isNotEmpty) _buildPhotoPreview(context),
          const SizedBox(height: AppSpacing.lg),

          // ローディング表示（初期化中、日記生成中、または自動保存中）
          if (isInitializing || isLoading || isSaving)
            _buildLoadingState(context)
          // エラー表示（初期化完了後のみ）
          else if (!isInitializing && hasError)
            _buildErrorState(context)
          // 日記編集フィールド（初期化完了後、日記生成完了後、自動保存前）
          else if (!isInitializing && !isLoading && !isSaving && !hasError)
            _buildEditorState(context),

          // 底部パディング
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  /// 日付カードを構築
  Widget _buildDateCard(BuildContext context) {
    return FadeInWidget(
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: AppSpacing.cardRadius,
          boxShadow: AppSpacing.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                size: AppSpacing.iconMd,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.diaryPreviewDateLabel,
                  style: AppTypography.withColor(
                    AppTypography.labelMedium,
                    Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  context.l10n.formatFullDate(photoDateTime),
                  style: AppTypography.withColor(
                    AppTypography.titleLarge,
                    Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 写真プレビューセクションを構築
  Widget _buildPhotoPreview(BuildContext context) {
    return FadeInWidget(
      delay: const Duration(milliseconds: 100),
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.photo_library_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: AppSpacing.iconMd,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  context.l10n.diaryPreviewSelectedPhotos(
                    selectedAssets.length,
                  ),
                  style: AppTypography.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedAssets.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < selectedAssets.length - 1
                          ? AppSpacing.sm
                          : 0,
                    ),
                    child: _buildPhotoThumbnail(context, index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 写真サムネイルを構築
  Widget _buildPhotoThumbnail(BuildContext context, int index) {
    return Container(
      decoration: BoxDecoration(borderRadius: AppSpacing.photoRadius),
      child: ClipRRect(
        borderRadius: AppSpacing.photoRadius,
        child: FutureBuilder<Uint8List?>(
          future: selectedAssets[index].thumbnailDataWithSize(
            ThumbnailSize(
              (AppConstants.previewImageSize * 1.2).toInt(),
              (AppConstants.previewImageSize * 1.2).toInt(),
            ),
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data != null) {
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: AppSpacing.photoRadius,
                ),
                child: ClipRRect(
                  borderRadius: AppSpacing.photoRadius,
                  child: Image.memory(
                    snapshot.data!,
                    fit: BoxFit.contain,
                    width: 120,
                    height: 120,
                  ),
                ),
              );
            }
            return Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppSpacing.photoRadius,
              ),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  /// ローディング状態を構築
  Widget _buildLoadingState(BuildContext context) {
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

  /// 写真分析進捗を構築
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

  /// 初期化中テキストを構築
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

  /// 保存中テキストを構築
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

  /// 生成中テキストを構築
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

  /// 生成中のプロンプトインジケーターを構築
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

  /// エラー状態を構築
  Widget _buildErrorState(BuildContext context) {
    return SizedBox(
      height: 400,
      child: FadeInWidget(
        child: CustomCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: AppSpacing.iconLg,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                context.l10n.commonErrorOccurred,
                style: AppTypography.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                errorMessage,
                textAlign: TextAlign.left,
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                onPressed: () => Navigator.pop(context),
                text: context.l10n.commonBack,
                icon: Icons.arrow_back_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// エディタ状態を構築
  Widget _buildEditorState(BuildContext context) {
    return SlideInWidget(
      delay: const Duration(milliseconds: 200),
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

  /// エディタヘッダーを構築
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
              vertical: 2,
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
                const SizedBox(width: 2),
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

  /// タイトル入力フィールドを構築
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

  /// 本文入力フィールドを構築
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

/// 選択されたプロンプトの表示ウィジェット
class DiaryPreviewPromptDisplay extends StatelessWidget {
  const DiaryPreviewPromptDisplay({super.key, required this.prompt});

  final WritingPrompt prompt;

  @override
  Widget build(BuildContext context) {
    return FadeInWidget(
      delay: const Duration(milliseconds: 50),
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  color: PromptCategoryUtils.getCategoryColor(prompt.category),
                  size: AppSpacing.iconMd,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    context.l10n.diaryPreviewCurrentPromptTitle,
                    style: AppTypography.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: PromptCategoryUtils.getCategoryColor(
                      prompt.category,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Text(
                    PromptCategoryUtils.getCategoryDisplayName(
                      prompt.category,
                      locale: Localizations.localeOf(context),
                    ),
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              prompt.text,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
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
}
