import 'dart:typed_data';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import '../constants/app_constants.dart';
import '../core/result/result.dart';
import '../core/service_locator.dart';
import '../localization/localization_extensions.dart';
import '../models/diary_entry.dart';
import '../services/interfaces/photo_cache_service_interface.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../ui/component_constants.dart';
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
  late final IPhotoCacheService _photoCacheService;
  final _thumbnailFutures = <String, Future<Result<Uint8List>>>{};
  late String _heroDate;

  @override
  void initState() {
    super.initState();
    _photoCacheService = serviceLocator.get<IPhotoCacheService>();
    _initAsyncState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _heroDate = _computeHeroDate();
  }

  @override
  void didUpdateWidget(DiaryCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id ||
        !listEquals(oldWidget.entry.photoIds, widget.entry.photoIds)) {
      _initAsyncState();
    }
    if (oldWidget.entry.date != widget.entry.date) {
      _heroDate = _computeHeroDate();
    }
  }

  void _initAsyncState() {
    _thumbnailFutures.clear();
    _photoAssetsFuture = _fetchPhotoAssets();
  }

  String _computeHeroDate() {
    final locale = Localizations.localeOf(context);
    return DateFormat(
      'MMM d · EEEE',
      locale.toString(),
    ).format(widget.entry.date).toUpperCase();
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = widget.entry.title.isNotEmpty
        ? widget.entry.title
        : l10n.diaryCardUntitled;
    final formattedDate = l10n.formatMonthDay(widget.entry.date);

    return Semantics(
      label: l10n.diaryCardSemanticLabel(title, formattedDate),
      button: true,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(CardConstants.radiusHero),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A231E1A),
              blurRadius: 22,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.card,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(CardConstants.radiusHero),
          color: AppColors.cardBg,
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroPhoto(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    12,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _heroDate,
                        style: AppTypography.dateLabel.copyWith(
                          color: AppColors.accentMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: AppTypography.cardTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.entry.content.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.entry.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.cardBody.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                      if (widget.entry.effectiveTags.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildTagChips(widget.entry.effectiveTags),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroPhoto(BuildContext context) {
    if (widget.entry.photoIds.isEmpty) {
      return _buildPhotoFallback();
    }
    return FutureBuilder<List<AssetEntity>>(
      future: _photoAssetsFuture,
      builder: (context, snapshot) {
        final assets = snapshot.data;
        final firstAsset = (assets != null && assets.isNotEmpty)
            ? assets.first
            : null;

        return AspectRatio(
          aspectRatio: 3 / 2,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (snapshot.connectionState == ConnectionState.waiting)
                const CardShimmer()
              else if (firstAsset != null)
                _buildHeroImage(context, firstAsset)
              else
                _buildPhotoFallback(),
              if (widget.entry.photoIds.length >= 2)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildPhotoBadge(widget.entry.photoIds.length),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroImage(BuildContext context, AssetEntity asset) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final screenWidth = MediaQuery.of(context).size.width;
    final w = (screenWidth * dpr).toInt();
    final h = (screenWidth / 1.5 * dpr).toInt();

    final future = _thumbnailFutures.putIfAbsent(
      asset.id,
      () => _photoCacheService.getThumbnail(
        asset,
        width: w,
        height: h,
        quality: AppConstants.diaryThumbnailQuality,
      ),
    );

    return FutureBuilder<Result<Uint8List>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isFailure) {
          return _buildPhotoFallback();
        }
        return Image.memory(
          snapshot.data!.value,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      },
    );
  }

  Widget _buildPhotoFallback() {
    return AspectRatio(
      aspectRatio: 3 / 2,
      child: Container(
        color: AppColors.glyphBg,
        child: const Icon(
          Icons.photo_camera_outlined,
          color: AppColors.muted,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildPhotoBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.photo_library_outlined,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChips(List<String> tags) {
    final displayTags = tags.take(3).toList();
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (int i = 0; i < displayTags.length; i++)
          ModernChip.tonedTag(displayTags[i], index: i),
      ],
    );
  }
}
