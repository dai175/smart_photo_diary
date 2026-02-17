import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../localization/localization_extensions.dart';
import '../../models/diary_entry.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../ui/animations/list_animations.dart';
import 'diary_detail_photo_section.dart';
import 'diary_detail_content_editor.dart';
import 'diary_detail_metadata_section.dart';

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
          _buildDateHeader(context),
          const SizedBox(height: AppSpacing.lg),

          // 写真セクション
          if (photoAssets.isNotEmpty) ...[
            DiaryDetailPhotoSection(photoAssets: photoAssets, l10n: l10n),
            const SizedBox(height: AppSpacing.lg),
          ],

          // コンテンツセクション
          DiaryDetailContentEditor(
            diaryEntry: diaryEntry,
            photoAssets: photoAssets,
            isEditing: isEditing,
            titleController: titleController,
            contentController: contentController,
            l10n: l10n,
          ),

          const SizedBox(height: AppSpacing.lg),

          // メタデータセクション
          DiaryDetailMetadataSection(
            diaryEntry: diaryEntry,
            photoAssets: photoAssets,
            l10n: l10n,
          ),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  /// 日付ヘッダーカードを構築
  Widget _buildDateHeader(BuildContext context) {
    final l10n = context.l10n;
    return FadeInWidget(
      child: Container(
        width: double.infinity,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.diaryDetailDateLabel,
                    style: AppTypography.withColor(
                      AppTypography.labelMedium,
                      Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    context.l10n.formatFullDate(diaryEntry.date),
                    style: AppTypography.withColor(
                      AppTypography.titleLarge,
                      Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            if (diaryEntry.effectiveTags.isNotEmpty) ...[
              Builder(
                builder: (context) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final foreground = isDark
                      ? AppColors.primaryLight
                      : AppColors.primary;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: AppSpacing.chipRadius,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tag_rounded,
                          color: foreground,
                          size: AppSpacing.iconXs,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          l10n.diaryDetailTagCount(
                            diaryEntry.effectiveTags.length,
                          ),
                          style: AppTypography.labelSmall.copyWith(
                            color: foreground,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
