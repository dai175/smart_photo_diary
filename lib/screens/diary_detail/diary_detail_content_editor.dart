import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../constants/app_constants.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../localization/localization_extensions.dart';
import '../../models/diary_entry.dart';
import '../../ui/animations/list_animations.dart';
import '../../ui/components/custom_card.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';

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
          _buildHeader(context),
          const SizedBox(height: AppSpacing.lg),
          if (isEditing)
            _buildEditableTitle(context)
          else
            _buildReadOnlyTitle(context),
          const SizedBox(height: AppSpacing.lg),
          if (isEditing)
            _buildEditableContent(context)
          else
            _buildReadOnlyContent(context),
        ],
      ),
    );

    return SlideInWidget(
      delay: Duration(milliseconds: photoAssets.isNotEmpty ? 200 : 100),
      child: isEditing
          ? card
          : GestureDetector(
              onLongPress: () => _copyDiaryToClipboard(context),
              child: card,
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
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
    );
  }

  Widget _buildEditableTitle(BuildContext context) {
    return _buildInputContainer(
      context: context,
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
    return _buildReadOnlyField(
      context: context,
      label: l10n.commonTitleLabel,
      text: diaryEntry.title.isNotEmpty
          ? diaryEntry.title
          : context.l10n.diaryCardUntitled,
      textStyle: AppTypography.titleMedium,
    );
  }

  Widget _buildEditableContent(BuildContext context) {
    return _buildInputContainer(
      context: context,
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
    return _buildReadOnlyField(
      context: context,
      label: l10n.commonBodyLabel,
      text: diaryEntry.content,
      textStyle: AppTypography.bodyLarge,
    );
  }

  /// 編集用入力フィールドの共通コンテナ
  Widget _buildInputContainer({
    required BuildContext context,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        borderRadius: AppSpacing.inputRadius,
        color: colorScheme.surface,
      ),
      child: child,
    );
  }

  /// 読み取り専用フィールドの共通ウィジェット
  Widget _buildReadOnlyField({
    required BuildContext context,
    required String label,
    required String text,
    required TextStyle textStyle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(text, style: textStyle.copyWith(color: colorScheme.onSurface)),
      ],
    );
  }

  /// 日記内容をクリップボードにコピーする
  void _copyDiaryToClipboard(BuildContext context) {
    final title = diaryEntry.title.isNotEmpty ? '${diaryEntry.title}\n\n' : '';
    final text = '$title${diaryEntry.content}\n\n${AppConstants.shareHashtag}';
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.diaryDetailCopiedToClipboard)));
  }
}
