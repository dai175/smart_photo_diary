import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/diary_entry.dart';
import '../../ui/components/custom_card.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../ui/animations/list_animations.dart';
import '../../localization/localization_extensions.dart';

/// 日記詳細のコンテンツ編集・表示セクション（タイトル + 本文）
class DiaryDetailContentEditor extends StatelessWidget {
  const DiaryDetailContentEditor({
    super.key,
    required this.diaryEntry,
    required this.photoAssets,
    required this.isEditing,
    required this.titleController,
    required this.contentController,
    required this.l10n,
  });

  final DiaryEntry diaryEntry;
  final List<AssetEntity> photoAssets;
  final bool isEditing;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final card = CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isEditing ? Icons.edit_rounded : Icons.article_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: AppSpacing.iconMd,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isEditing
                    ? l10n.diaryDetailEditTitle
                    : l10n.diaryDetailContentHeading,
                style: AppTypography.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // タイトルセクション
          isEditing
              ? _buildEditableTitle(context)
              : _buildReadOnlyTitle(context),

          const SizedBox(height: AppSpacing.lg),

          // 本文セクション
          isEditing
              ? _buildEditableContent(context)
              : _buildReadOnlyContent(context),
        ],
      ),
    );

    return SlideInWidget(
      delay: Duration(milliseconds: photoAssets.isNotEmpty ? 200 : 100),
      child: isEditing
          ? card
          : GestureDetector(
              onLongPress: () {
                final title = diaryEntry.title.isNotEmpty
                    ? '${diaryEntry.title}\n\n'
                    : '';
                final text = '$title${diaryEntry.content}\n\n#SmartPhotoDiary';
                Clipboard.setData(ClipboardData(text: text));
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.diaryDetailCopiedToClipboard)),
                );
              },
              child: card,
            ),
    );
  }

  Widget _buildEditableTitle(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: AppSpacing.inputRadius,
        color: Theme.of(context).colorScheme.surface,
      ),
      child: TextField(
        controller: titleController,
        style: AppTypography.titleMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: l10n.commonTitleLabel,
          border: InputBorder.none,
          hintText: l10n.diaryDetailTitleHint,
          contentPadding: AppSpacing.inputPadding,
          labelStyle: AppTypography.labelMedium,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.commonTitleLabel,
          style: AppTypography.labelMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          diaryEntry.title.isNotEmpty
              ? diaryEntry.title
              : context.l10n.diaryCardUntitled,
          style: AppTypography.titleMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: AppSpacing.inputRadius,
        color: Theme.of(context).colorScheme.surface,
      ),
      child: TextField(
        controller: contentController,
        maxLines: null,
        minLines: 8,
        textAlignVertical: TextAlignVertical.top,
        style: AppTypography.bodyLarge.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: l10n.commonBodyLabel,
          border: InputBorder.none,
          hintText: l10n.diaryDetailContentHint,
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

  Widget _buildReadOnlyContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.commonBodyLabel,
          style: AppTypography.labelMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          diaryEntry.content,
          style: AppTypography.bodyLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
