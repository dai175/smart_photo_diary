import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../localization/localization_extensions.dart';
import '../../models/writing_prompt.dart';
import '../../ui/components/animated_button.dart';
import '../../ui/components/custom_card.dart';
import '../../ui/components/photo_gallery.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../ui/animations/list_animations.dart';
import 'diary_preview_prompt_display.dart';
import 'diary_preview_loading_states.dart';
import 'diary_preview_editor.dart';

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
            DiaryPreviewLoadingStates(
              isInitializing: isInitializing,
              isSaving: isSaving,
              isAnalyzingPhotos: isAnalyzingPhotos,
              currentPhotoIndex: currentPhotoIndex,
              totalPhotos: totalPhotos,
              selectedPrompt: selectedPrompt,
            )
          // エラー表示（初期化完了後のみ）
          else if (!isInitializing && hasError)
            _buildErrorState(context)
          // 日記編集フィールド（初期化完了後、日記生成完了後、自動保存前）
          else if (!isInitializing && !isLoading && !isSaving && !hasError)
            DiaryPreviewEditor(
              titleController: titleController,
              contentController: contentController,
              selectedPrompt: selectedPrompt,
            ),

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
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: AppSpacing.cardRadius,
          boxShadow: AppSpacing.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  context.l10n.formatFullDate(photoDateTime),
                  style: AppTypography.withColor(
                    AppTypography.titleLarge,
                    Theme.of(context).colorScheme.onSurface,
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
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            PhotoGallery(assets: selectedAssets, multiplePhotoSize: 120),
          ],
        ),
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
                child: const Icon(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
