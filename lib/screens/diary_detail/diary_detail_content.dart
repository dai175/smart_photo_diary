import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../constants/app_constants.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../localization/localization_extensions.dart';
import '../../models/diary_entry.dart';
import '../../ui/components/custom_card.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../ui/animations/list_animations.dart';
import '../../ui/animations/micro_interactions.dart';

/// 日記詳細のコンテンツ表示ウィジェット
///
/// 日付ヘッダー、写真セクション、本文セクション、メタデータセクションの
/// 表示を担当する。編集モード時のTextField表示もここで管理。
class DiaryDetailContent extends StatelessWidget {
  const DiaryDetailContent({
    super.key,
    required this.diaryEntry,
    required this.photoAssets,
    required this.isEditing,
    required this.titleController,
    required this.contentController,
  });

  /// 表示対象の日記エントリー
  final DiaryEntry diaryEntry;

  /// 写真アセットリスト
  final List<AssetEntity> photoAssets;

  /// 編集モードかどうか
  final bool isEditing;

  /// タイトル編集用コントローラー
  final TextEditingController titleController;

  /// 本文編集用コントローラー
  final TextEditingController contentController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日付ヘッダーカード
          _buildDateHeader(context, l10n),
          const SizedBox(height: AppSpacing.lg),

          // 写真セクション
          if (photoAssets.isNotEmpty) ...[
            _buildPhotoSection(context, l10n),
            const SizedBox(height: AppSpacing.lg),
          ],

          // コンテンツセクション
          _buildContentSection(context, l10n),

          const SizedBox(height: AppSpacing.lg),

          // メタデータセクション
          _buildMetadataSection(context, l10n),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  /// 日付ヘッダーカードを構築
  Widget _buildDateHeader(BuildContext context, AppLocalizations l10n) {
    return FadeInWidget(
      child: Container(
        width: double.infinity,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.diaryDetailDateLabel,
                    style: AppTypography.withColor(
                      AppTypography.labelMedium,
                      Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    context.l10n.formatFullDate(diaryEntry.date),
                    style: AppTypography.withColor(
                      AppTypography.titleLarge,
                      Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            if (diaryEntry.effectiveTags.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: AppSpacing.chipRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tag_rounded,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: AppSpacing.iconXs,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      l10n.diaryDetailTagCount(diaryEntry.effectiveTags.length),
                      style: AppTypography.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 写真セクションを構築
  Widget _buildPhotoSection(BuildContext context, AppLocalizations l10n) {
    return SlideInWidget(
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
                  l10n.diaryDetailPhotosSectionTitle(photoAssets.length),
                  style: AppTypography.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photoAssets.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == photoAssets.length - 1
                          ? 0
                          : AppSpacing.md,
                    ),
                    child: _buildPhotoItem(context, index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// コンテンツセクション（タイトル + 本文）を構築
  Widget _buildContentSection(BuildContext context, AppLocalizations l10n) {
    return SlideInWidget(
      delay: Duration(milliseconds: photoAssets.isNotEmpty ? 200 : 100),
      child: CustomCard(
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
                ? _buildEditableTitle(context, l10n)
                : _buildReadOnlyTitle(context, l10n),

            const SizedBox(height: AppSpacing.lg),

            // 本文セクション
            isEditing
                ? _buildEditableContent(context, l10n)
                : _buildReadOnlyContent(context, l10n),
          ],
        ),
      ),
    );
  }

  /// 編集可能タイトル
  Widget _buildEditableTitle(BuildContext context, AppLocalizations l10n) {
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

  /// 読み取り専用タイトル
  Widget _buildReadOnlyTitle(BuildContext context, AppLocalizations l10n) {
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
              : l10n.diaryCardUntitled,
          style: AppTypography.titleMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// 編集可能本文
  Widget _buildEditableContent(BuildContext context, AppLocalizations l10n) {
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

  /// 読み取り専用本文
  Widget _buildReadOnlyContent(BuildContext context, AppLocalizations l10n) {
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

  /// メタデータセクションを構築
  Widget _buildMetadataSection(BuildContext context, AppLocalizations l10n) {
    return SlideInWidget(
      delay: Duration(milliseconds: photoAssets.isNotEmpty ? 300 : 200),
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: AppSpacing.iconSm,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.diaryDetailMetadataTitle,
                  style: AppTypography.titleMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildMetadataRow(
              context,
              l10n.commonCreatedAtLabel,
              context.l10n.formatFullDateTime(diaryEntry.createdAt),
              Icons.access_time_rounded,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildMetadataRow(
              context,
              l10n.commonUpdatedAtLabel,
              context.l10n.formatFullDateTime(diaryEntry.updatedAt),
              Icons.update_rounded,
            ),
            if (diaryEntry.effectiveTags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildTagsRow(context, l10n),
            ],
          ],
        ),
      ),
    );
  }

  /// 写真アイテムを構築
  Widget _buildPhotoItem(BuildContext context, int index) {
    return FutureBuilder<Uint8List?>(
      future: photoAssets[index].thumbnailDataWithSize(
        ThumbnailSize(
          (AppConstants.largeImageSize * 1.2).toInt(),
          (AppConstants.largeImageSize * 1.2).toInt(),
        ),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: AppSpacing.photoRadius,
            ),
            child: Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          );
        }

        return MicroInteractions.bounceOnTap(
          onTap: () {
            MicroInteractions.hapticTap();
            _showPhotoDialog(context, snapshot.data!, index);
          },
          child: Container(
            width: 200,
            constraints: const BoxConstraints(minHeight: 150, maxHeight: 300),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppSpacing.photoRadius,
            ),
            child: ClipRRect(
              borderRadius: AppSpacing.photoRadius,
              child: RepaintBoundary(
                child: Image.memory(
                  snapshot.data!,
                  width: 200,
                  fit: BoxFit.contain,
                  cacheWidth: (200 * MediaQuery.of(context).devicePixelRatio)
                      .round(),
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// メタデータ行を構築
  Widget _buildMetadataRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: AppSpacing.iconXs,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: AppTypography.labelMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  /// タグ行を構築
  Widget _buildTagsRow(BuildContext context, AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.tag_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: AppSpacing.iconXs,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          l10n.commonTagsLabel,
          style: AppTypography.labelMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: diaryEntry.effectiveTags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: AppSpacing.chipRadius,
                    ),
                    child: Text(
                      tag,
                      style: AppTypography.withColor(
                        AppTypography.labelSmall,
                        Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  /// 写真拡大ダイアログを表示
  void _showPhotoDialog(BuildContext context, Uint8List imageData, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 600,
                ),
                decoration: BoxDecoration(
                  borderRadius: AppSpacing.cardRadiusLarge,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: AppSpacing.cardRadiusLarge,
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: Image.memory(imageData, fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                top: -10,
                right: -10,
                child: MicroInteractions.bounceOnTap(
                  onTap: () {
                    MicroInteractions.hapticTap();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
