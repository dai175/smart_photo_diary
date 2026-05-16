import 'package:flutter/material.dart';

import '../../localization/localization_extensions.dart';
import '../../models/diary_entry.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';

/// 日記詳細のメタデータセクション（作成日・更新日・写真枚数）
class DiaryDetailMetadataSection extends StatelessWidget {
  const DiaryDetailMetadataSection({super.key, required this.diaryEntry});

  final DiaryEntry diaryEntry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final photoCount = diaryEntry.photoIds.length;
    final showUpdated =
        diaryEntry.updatedAt.difference(diaryEntry.createdAt).inMinutes > 1;
    final colorScheme = Theme.of(context).colorScheme;

    Widget metaRow(IconData icon, String label) => Row(
      children: [
        Icon(
          icon,
          size: AppSpacing.iconXxs,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.withColor(
            AppTypography.bodySmall,
            colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photoCount > 0) ...[
          metaRow(
            Icons.photo_library_rounded,
            l10n.diaryDetailPhotoCount(photoCount),
          ),
          const SizedBox(height: 6),
        ],
        metaRow(
          Icons.calendar_today_rounded,
          l10n.formatFullDateTime(diaryEntry.createdAt),
        ),
        if (showUpdated) ...[
          const SizedBox(height: 6),
          metaRow(
            Icons.edit_calendar_rounded,
            l10n.formatFullDateTime(diaryEntry.updatedAt),
          ),
        ],
      ],
    );
  }
}
