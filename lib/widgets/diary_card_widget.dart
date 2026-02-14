import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../constants/app_constants.dart';
import '../core/result/result.dart';
import '../core/service_locator.dart';
import '../l10n/generated/app_localizations.dart';
import '../localization/localization_extensions.dart';
import '../models/diary_entry.dart';
import '../services/interfaces/diary_service_interface.dart';
import '../services/interfaces/photo_cache_service_interface.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../ui/components/custom_card.dart';
import '../ui/components/loading_shimmer.dart';
import '../ui/components/modern_chip.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';

class DiaryCardWidget extends StatefulWidget {
  final DiaryEntry entry;
  final VoidCallback onTap;

  const DiaryCardWidget({super.key, required this.entry, required this.onTap});

  @override
  State<DiaryCardWidget> createState() => _DiaryCardWidgetState();
}

class _DiaryCardWidgetState extends State<DiaryCardWidget> {
  late Future<List<AssetEntity>> _photoAssetsFuture;
  late Future<List<String>?> _tagsFuture;

  @override
  void initState() {
    super.initState();
    _photoAssetsFuture = _fetchPhotoAssets();
    _tagsFuture = _fetchTags();
  }

  @override
  void didUpdateWidget(DiaryCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id) {
      _photoAssetsFuture = _fetchPhotoAssets();
      _tagsFuture = _fetchTags();
    }
  }

  Future<List<AssetEntity>> _fetchPhotoAssets() {
    final photoService = serviceLocator.get<IPhotoService>();
    return photoService
        .getAssetsByIds(widget.entry.photoIds)
        .then((result) => result.getOrDefault([]));
  }

  // タグを取得（永続化キャッシュ優先）
  // Returns null on failure to signal that l10n-dependent fallback is needed
  Future<List<String>?> _fetchTags() async {
    try {
      final diaryService = await ServiceLocator().getAsync<IDiaryService>();
      final result = await diaryService.getTagsForEntry(widget.entry);
      if (result.isSuccess) {
        return result.value;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // エラー時のフォールバックタグ（時間帯のみ）
  List<String> _fallbackTags(AppLocalizations l10n) {
    final hour = widget.entry.date.hour;
    if (hour >= 5 && hour < 12) return [l10n.tagMorning];
    if (hour >= 12 && hour < 18) return [l10n.tagAfternoon];
    if (hour >= 18 && hour < 22) return [l10n.tagEvening];
    return [l10n.tagNight];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = widget.entry.title.isNotEmpty
        ? widget.entry.title
        : l10n.diaryCardUntitled;

    return CustomCard(
      onTap: widget.onTap,
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
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: AppSpacing.chipRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: AppSpacing.iconXs,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      l10n.formatMonthDay(widget.entry.date),
                      style: AppTypography.withColor(
                        AppTypography.labelSmall,
                        Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            widget.entry.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.withColor(
              AppTypography.bodyMedium,
              Theme.of(context).colorScheme.onSurfaceVariant,
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
      future: _photoAssetsFuture,
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
    final cacheService = serviceLocator.get<IPhotoCacheService>();
    final size = AppConstants.diaryThumbnailSize.toInt();
    return FutureBuilder<Result<Uint8List>>(
      future: cacheService.getThumbnail(
        asset,
        width: size,
        height: size,
        quality: AppConstants.diaryThumbnailQuality,
      ),
      builder: (context, thumbnailSnapshot) {
        if (!thumbnailSnapshot.hasData) {
          return Container(
            width: AppConstants.diaryThumbnailSize,
            height: AppConstants.diaryThumbnailSize,
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppSpacing.photoRadius,
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (thumbnailSnapshot.data!.isFailure) {
          return Container(
            width: AppConstants.diaryThumbnailSize,
            height: AppConstants.diaryThumbnailSize,
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppSpacing.photoRadius,
            ),
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          );
        }

        final thumbnailData = thumbnailSnapshot.data!.value;
        final dpr = MediaQuery.of(context).devicePixelRatio;
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
              thumbnailData,
              height: AppConstants.diaryThumbnailSize,
              width: AppConstants.diaryThumbnailSize,
              fit: BoxFit.cover,
              cacheWidth: (AppConstants.diaryThumbnailSize * dpr).round(),
              cacheHeight: (AppConstants.diaryThumbnailSize * dpr).round(),
              gaplessPlayback: true,
              filterQuality: FilterQuality.low,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTags(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<List<String>?>(
      future: _tagsFuture,
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
                l10n.diaryCardGeneratingTags,
                style: AppTypography.withColor(
                  AppTypography.labelSmall,
                  AppColors.onSurfaceVariant,
                ),
              ),
            ],
          );
        }

        final tags = snapshot.data ?? _fallbackTags(l10n);
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
    if (tag.contains('朝') ||
        tag.contains('昼') ||
        tag.contains('夕') ||
        tag.contains('夜')) {
      return ChipCategory.general;
    } else if (tag.contains('楽し') ||
        tag.contains('嬉し') ||
        tag.contains('悲し') ||
        tag.contains('怒り')) {
      return ChipCategory.emotion;
    } else if (tag.contains('料理') ||
        tag.contains('食事') ||
        tag.contains('食べ') ||
        tag.contains('グルメ')) {
      return ChipCategory.food;
    } else if (tag.contains('公園') ||
        tag.contains('家') ||
        tag.contains('店') ||
        tag.contains('場所')) {
      return ChipCategory.location;
    } else if (tag.contains('運動') ||
        tag.contains('散歩') ||
        tag.contains('スポーツ') ||
        tag.contains('旅行')) {
      return ChipCategory.activity;
    }
    return ChipCategory.general;
  }
}
