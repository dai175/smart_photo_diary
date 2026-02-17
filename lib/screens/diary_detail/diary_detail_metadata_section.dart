import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/diary_entry.dart';
import '../../ui/components/custom_card.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../ui/animations/list_animations.dart';
import '../../localization/localization_extensions.dart';

/// 日記詳細のメタデータセクション（作成日、更新日、タグ）
class DiaryDetailMetadataSection extends StatelessWidget {
  const DiaryDetailMetadataSection({
    super.key,
    required this.diaryEntry,
    required this.photoAssets,
    required this.l10n,
  });

  final DiaryEntry diaryEntry;
  final List<AssetEntity> photoAssets;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
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
              l10n.formatFullDateTime(diaryEntry.createdAt),
              Icons.access_time_rounded,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildMetadataRow(
              context,
              l10n.commonUpdatedAtLabel,
              l10n.formatFullDateTime(diaryEntry.updatedAt),
              Icons.update_rounded,
            ),
            if (diaryEntry.effectiveTags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildTagsRow(context),
            ],
          ],
        ),
      ),
    );
  }

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

  Widget _buildTagsRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tagForeground = isDark ? AppColors.primaryLight : AppColors.primary;
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
            children: diaryEntry.effectiveTags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.chipRadius,
                ),
                child: Text(
                  tag,
                  style: AppTypography.withColor(
                    AppTypography.labelSmall,
                    tagForeground,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
