import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../constants/app_constants.dart';
import '../core/result/result.dart';
import '../core/service_locator.dart';
import '../l10n/generated/app_localizations.dart';
import '../localization/localization_extensions.dart';
import '../models/diary_entry.dart';
import '../services/interfaces/diary_tag_service_interface.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../services/interfaces/photo_cache_service_interface.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../ui/components/custom_card.dart';
import '../ui/components/loading_shimmer.dart';
import '../ui/components/modern_chip.dart';
import '../ui/components/photo_placeholder.dart';
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
    _tagsFuture = widget.entry.hasValidTags
        ? Future.value(widget.entry.tags)
        : _fetchTags();
  }

  @override
  void didUpdateWidget(DiaryCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id) {
      _photoAssetsFuture = _fetchPhotoAssets();
      _tagsFuture = widget.entry.hasValidTags
          ? Future.value(widget.entry.tags)
          : _fetchTags();
    }
  }

  Future<List<AssetEntity>> _fetchPhotoAssets() {
    if (widget.entry.photoIds.isEmpty) {
      return Future.value([]);
    }
    final photoService = serviceLocator.get<IPhotoService>();
    return photoService
        .getAssetsByIds(widget.entry.photoIds)
        .then((result) => result.getOrDefault([]));
  }

  // タグを取得（永続化キャッシュ優先）
  // Returns null on failure to signal that l10n-dependent fallback is needed
  Future<List<String>?> _fetchTags() async {
    try {
      final tagService = await serviceLocator.getAsync<IDiaryTagService>();
      final result = await tagService.getTagsForEntry(widget.entry);
      if (result.isSuccess) {
        return result.value;
      }
      return null;
    } catch (e) {
      serviceLocator.get<ILoggingService>().error(
        'Failed to fetch tags',
        context: 'DiaryCardWidget._fetchTags',
        error: e,
      );
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
      elevation: AppSpacing.elevationXs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー（日付とアイコン）
          Row(
            children: [
              Text(
                l10n.formatMonthDay(widget.entry.date),
                style: AppTypography.withColor(
                  AppTypography.labelSmall,
                  Theme.of(context).colorScheme.onSurfaceVariant,
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
    // photoIdsが空なら即座に返す（FutureBuilderの状態遷移による高さ変動を防止）
    if (widget.entry.photoIds.isEmpty) {
      return const SizedBox();
    }
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
        if (thumbnailSnapshot.hasError ||
            (thumbnailSnapshot.hasData && thumbnailSnapshot.data!.isFailure)) {
          return const PhotoPlaceholder(
            size: AppConstants.diaryThumbnailSize,
            isError: true,
          );
        }
        if (!thumbnailSnapshot.hasData) {
          return const PhotoPlaceholder(size: AppConstants.diaryThumbnailSize);
        }

        final thumbnailData = thumbnailSnapshot.data!.value;
        final dpr = MediaQuery.of(context).devicePixelRatio;
        return ClipRRect(
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
        );
      },
    );
  }

  Widget _buildTags(BuildContext context) {
    final l10n = context.l10n;

    // キャッシュ済みタグは同期的に即表示（FutureBuilder不要）
    if (widget.entry.hasValidTags) {
      return _buildTagChips(widget.entry.tags!);
    }

    // キャッシュなしの場合のみ非同期取得
    return FutureBuilder<List<String>?>(
      future: _tagsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: AppConstants.progressIndicatorStrokeWidth,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.diaryCardGeneratingTags,
                style: AppTypography.withColor(
                  AppTypography.labelSmall,
                  Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        }

        final tags = snapshot.data ?? _fallbackTags(l10n);
        return _buildTagChips(tags);
      },
    );
  }

  Widget _buildTagChips(List<String> tags) {
    if (tags.isEmpty) return const SizedBox();
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: tags
          .take(4) // 最大4つまで表示
          .map((tag) => ModernChip.tag(label: tag))
          .toList(),
    );
  }
}
