import 'package:flutter/material.dart';
import '../../localization/localization_extensions.dart';
import '../../models/diary_entry.dart';
import '../../ui/components/custom_card.dart';
import '../../ui/components/modern_chip.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../ui/animations/list_animations.dart';

/// 日記詳細のタグセクション
class DiaryDetailMetadataSection extends StatelessWidget {
  const DiaryDetailMetadataSection({
    super.key,
    required this.diaryEntry,
    this.hasPhotos = false,
  });

  final DiaryEntry diaryEntry;
  final bool hasPhotos;

  @override
  Widget build(BuildContext context) {
    if (diaryEntry.effectiveTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return SlideInWidget(
      delay: Duration(milliseconds: hasPhotos ? 300 : 200),
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tag_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: AppSpacing.iconMd,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  context.l10n.diaryDetailTagsSectionTitle,
                  style: AppTypography.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: diaryEntry.effectiveTags
                  .map((tag) => ModernChip.tag(label: tag))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
