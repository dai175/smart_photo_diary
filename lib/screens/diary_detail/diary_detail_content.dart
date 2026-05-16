import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../constants/app_constants.dart';
import '../../core/result/result.dart';
import '../../core/service_locator.dart';
import '../../localization/localization_extensions.dart';
import '../../models/diary_entry.dart';
import '../../services/interfaces/photo_cache_service_interface.dart';
import '../../ui/animations/micro_interactions.dart';
import '../../ui/components/fullscreen_photo_viewer.dart';
import '../../ui/components/modern_chip.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import 'diary_detail_metadata_section.dart';
import 'diary_detail_photo_section.dart';

/// 日記詳細のコンテンツ表示ウィジェット（エディトリアルレイアウト）
class DiaryDetailContent extends StatefulWidget {
  const DiaryDetailContent({
    super.key,
    required this.diaryEntry,
    required this.photoAssets,
    required this.isEditing,
    required this.titleController,
    required this.contentController,
  });

  final DiaryEntry diaryEntry;
  final List<AssetEntity> photoAssets;
  final bool isEditing;
  final TextEditingController titleController;
  final TextEditingController contentController;

  @override
  State<DiaryDetailContent> createState() => _DiaryDetailContentState();
}

class _DiaryDetailContentState extends State<DiaryDetailContent> {
  static const String _galleryHeroPrefix = 'diary-detail-gallery';

  late final IPhotoCacheService _photoCacheService;
  final _galleryFutures = <String, Future<Result<Uint8List>>>{};
  late String _cachedDateLabel;

  @override
  void initState() {
    super.initState();
    _photoCacheService = serviceLocator.get<IPhotoCacheService>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachedDateLabel = _computeDateLabel();
  }

  @override
  void didUpdateWidget(DiaryDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.diaryEntry.date != widget.diaryEntry.date) {
      _cachedDateLabel = _computeDateLabel();
    }
    if (!listEquals(oldWidget.photoAssets, widget.photoAssets)) {
      _galleryFutures.clear();
    }
  }

  String _computeDateLabel() {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat(
      'MMM d · EEEE',
      locale,
    ).format(widget.diaryEntry.date).toUpperCase();
  }

  Future<Result<Uint8List>> _getGalleryThumbnail(AssetEntity asset) {
    return _galleryFutures.putIfAbsent(
      asset.id,
      () => _photoCacheService.getThumbnail(asset, width: 300, height: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isEditing)
            SizedBox(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
            )
          else if (widget.photoAssets.isNotEmpty)
            DiaryDetailPhotoSection(photoAssets: widget.photoAssets)
          else
            _buildPhotoPlaceholder(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _cachedDateLabel,
                  style: AppTypography.withColor(
                    AppTypography.dateLabel,
                    AppColors.accentMuted,
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.isEditing)
                  _buildEditableTitleInline(context)
                else
                  Text(
                    widget.diaryEntry.title.isNotEmpty
                        ? widget.diaryEntry.title
                        : context.l10n.diaryCardUntitled,
                    style: AppTypography.withColor(
                      AppTypography.detailTitle,
                      colorScheme.onSurface,
                    ),
                  ),
                const SizedBox(height: 12),
                if (widget.diaryEntry.effectiveTags.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.diaryEntry.effectiveTags
                        .asMap()
                        .entries
                        .map((e) => ModernChip.tonedTag(e.value, index: e.key))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ] else
                  const SizedBox(height: 4),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 16),
                if (widget.isEditing)
                  _buildEditableContentInline(context)
                else
                  GestureDetector(
                    onLongPress: () => _copyDiaryToClipboard(context),
                    child: Text(
                      widget.diaryEntry.content,
                      style: AppTypography.withColor(
                        AppTypography.detailBody,
                        colorScheme.onSurface,
                      ),
                    ),
                  ),
                if (widget.photoAssets.length > 1) ...[
                  const SizedBox(height: 20),
                  _buildInlineGallery(context),
                ],
                const SizedBox(height: 20),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 12),
                DiaryDetailMetadataSection(diaryEntry: widget.diaryEntry),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.photo_rounded,
          size: 48,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildEditableTitleInline(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: widget.titleController,
      style: AppTypography.withColor(
        AppTypography.detailTitle,
        colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: l10n.diaryDetailTitleHint,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintStyle: AppTypography.withColor(
          AppTypography.detailTitle,
          colorScheme.onSurfaceVariant,
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildEditableContentInline(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: widget.contentController,
      maxLines: null,
      minLines: 6,
      textAlignVertical: TextAlignVertical.top,
      style: AppTypography.withColor(
        AppTypography.detailBody,
        colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: l10n.diaryDetailContentHint,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintStyle: AppTypography.withColor(
          AppTypography.detailBody,
          colorScheme.onSurfaceVariant,
        ),
        isDense: true,
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildInlineGallery(BuildContext context) {
    final galleryAssets = widget.photoAssets.sublist(1);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: galleryAssets.length,
      itemBuilder: (context, i) {
        final asset = galleryAssets[i];
        return GestureDetector(
          onTap: () => FullscreenPhotoViewer.show(
            context,
            asset: asset,
            heroTag: '$_galleryHeroPrefix-${asset.id}',
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: FutureBuilder<Result<Uint8List>>(
              future: _getGalleryThumbnail(asset),
              builder: (context, snapshot) {
                final colorScheme = Theme.of(context).colorScheme;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(color: colorScheme.surfaceContainerHighest);
                }
                final result = snapshot.data;
                if (result is Success<Uint8List>) {
                  return Image.memory(
                    result.value,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  );
                }
                return Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _copyDiaryToClipboard(BuildContext context) {
    final l10n = context.l10n;
    final title = widget.diaryEntry.title.isNotEmpty
        ? '${widget.diaryEntry.title}\n\n'
        : '';
    final text =
        '$title${widget.diaryEntry.content}\n\n${AppConstants.shareHashtag}';
    Clipboard.setData(ClipboardData(text: text));
    MicroInteractions.hapticSuccess();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.diaryDetailCopiedToClipboard)));
  }
}
