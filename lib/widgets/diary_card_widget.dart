import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import '../models/diary_entry.dart';
import '../services/diary_service.dart';
import '../constants/app_constants.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/custom_card.dart';
import '../ui/components/modern_chip.dart';
import '../ui/components/loading_shimmer.dart';

class DiaryCardWidget extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback onTap;

  const DiaryCardWidget({
    super.key,
    required this.entry,
    required this.onTap,
  });

  // タグを取得（永続化キャッシュ優先）
  Future<List<String>> _generateTags() async {
    try {
      final diaryService = await DiaryService.getInstance();
      return await diaryService.getTagsForEntry(entry);
    } catch (e) {
      // エラー時はフォールバックタグを返す（時間帯のみ）
      final fallbackTags = <String>[];
      
      final hour = entry.date.hour;
      if (hour >= 5 && hour < 12) {
        fallbackTags.add('朝');
      } else if (hour >= 12 && hour < 18) {
        fallbackTags.add('昼');
      } else if (hour >= 18 && hour < 22) {
        fallbackTags.add('夕方');
      } else {
        fallbackTags.add('夜');
      }
      
      return fallbackTags;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = entry.title.isNotEmpty ? entry.title : '無題';

    return CustomCard(
      onTap: onTap,
      elevation: AppSpacing.elevationSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー（日付とアイコン）
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: AppSpacing.chipRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: AppSpacing.iconXs,
                      color: AppColors.onPrimaryContainer,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      DateFormat('MM/dd').format(entry.date),
                      style: AppTypography.withColor(
                        AppTypography.labelSmall,
                        AppColors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant,
                size: AppSpacing.iconSm,
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),

          // タイトル
          Text(
            title,
            style: AppTypography.titleLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppSpacing.sm),

          // 本文（一部）
          Text(
            entry.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.withColor(
              AppTypography.bodyMedium,
              AppColors.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // 写真があれば表示
          _buildPhotoThumbnails(),

          // タグ（動的生成）
          _buildTags(context),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnails() {
    return FutureBuilder<List<AssetEntity>>(
      future: entry.getPhotoAssets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: AppConstants.diaryThumbnailSize + AppSpacing.sm,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(
                  right: index < 2 ? AppSpacing.sm : 0,
                  bottom: AppSpacing.sm,
                ),
                child: const CardShimmer(),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox();
        }

        final assets = snapshot.data!;
        return SizedBox(
          height: AppConstants.diaryThumbnailSize + AppSpacing.sm,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: assets.length,
            itemBuilder: (context, imgIndex) {
              return Padding(
                padding: EdgeInsets.only(
                  right: imgIndex < assets.length - 1 ? AppSpacing.sm : 0,
                  bottom: AppSpacing.sm,
                ),
                child: _buildThumbnail(assets[imgIndex]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildThumbnail(AssetEntity asset) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailData,
      builder: (context, thumbnailSnapshot) {
        if (!thumbnailSnapshot.hasData) {
          return Container(
            width: AppConstants.diaryThumbnailSize,
            height: AppConstants.diaryThumbnailSize,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppSpacing.photoRadius,
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: AppSpacing.photoRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppSpacing.photoRadius,
            child: Image.memory(
              thumbnailSnapshot.data!,
              height: AppConstants.diaryThumbnailSize,
              width: AppConstants.diaryThumbnailSize,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTags(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _generateTags(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'タグを生成中...',
                style: AppTypography.withColor(
                  AppTypography.labelSmall,
                  AppColors.onSurfaceVariant,
                ),
              ),
            ],
          );
        }
        
        final tags = snapshot.data ?? [];
        if (tags.isEmpty) return const SizedBox();
        
        return Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: tags
              .take(4) // 最大4つまで表示
              .map(
                (tag) => CategoryChip(
                  label: tag,
                  selected: false,
                  category: _getCategoryForTag(tag),
                ),
              )
              .toList(),
        );
      },
    );
  }

  ChipCategory _getCategoryForTag(String tag) {
    // タグの内容に基づいてカテゴリを判定
    if (tag.contains('朝') || tag.contains('昼') || tag.contains('夕') || tag.contains('夜')) {
      return ChipCategory.general;
    } else if (tag.contains('楽し') || tag.contains('嬉し') || tag.contains('悲し') || tag.contains('怒り')) {
      return ChipCategory.emotion;
    } else if (tag.contains('料理') || tag.contains('食事') || tag.contains('食べ') || tag.contains('グルメ')) {
      return ChipCategory.food;
    } else if (tag.contains('公園') || tag.contains('家') || tag.contains('店') || tag.contains('場所')) {
      return ChipCategory.location;
    } else if (tag.contains('運動') || tag.contains('散歩') || tag.contains('スポーツ') || tag.contains('旅行')) {
      return ChipCategory.activity;
    }
    return ChipCategory.general;
  }
}