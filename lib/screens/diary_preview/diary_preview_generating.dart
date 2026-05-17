import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/result/result.dart';
import '../../core/service_locator.dart';
import '../../localization/localization_extensions.dart';
import '../../models/writing_prompt.dart';
import '../../services/interfaces/photo_cache_service_interface.dart';
import '../../ui/components/loading_shimmer.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_typography.dart';
import '../../utils/prompt_category_utils.dart';

/// AI生成中に表示するスケルトンプレビュー画面（Variant C: Skeleton preview）。
///
/// 詳細画面と同じレイアウト（ヒーロー写真 + コンテンツエリア）を
/// シマープレースホルダーで先取り表示し、生成完了後のクロスフェードを
/// 自然にする。
class DiaryPreviewGeneratingScreen extends StatelessWidget {
  const DiaryPreviewGeneratingScreen({
    super.key,
    required this.selectedAssets,
    required this.photoDateTime,
    required this.selectedPrompt,
    required this.statusText,
    required this.onBack,
  });

  final List<AssetEntity> selectedAssets;
  final DateTime photoDateTime;
  final WritingPrompt? selectedPrompt;
  final String statusText;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          Column(
            children: [
              // Hero photo (4:3) — extends to y=0, overlaps status bar
              if (selectedAssets.isNotEmpty)
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _HeroPhoto(asset: selectedAssets.first),
                      const _TopScrim(),
                      if (selectedAssets.length > 1)
                        Positioned(
                          right: 14,
                          bottom: 14,
                          child: _PhotoCountBadge(
                            current: 1,
                            total: selectedAssets.length,
                          ),
                        ),
                    ],
                  ),
                ),

              // Skeleton content (mirrors detail screen layout)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DateLine(date: photoDateTime),
                      const SizedBox(height: 12),
                      const LoadingShimmer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SkeletonBar(
                              widthFactor: 0.85,
                              height: 22,
                              radius: 6,
                            ),
                            SizedBox(height: 10),
                            _SkeletonBar(
                              widthFactor: 0.55,
                              height: 22,
                              radius: 6,
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                _SkeletonBar(
                                  fixedWidth: 70,
                                  height: 22,
                                  radius: 6,
                                ),
                                SizedBox(width: 6),
                                _SkeletonBar(
                                  fixedWidth: 86,
                                  height: 22,
                                  radius: 6,
                                ),
                                SizedBox(width: 6),
                                _SkeletonBar(
                                  fixedWidth: 58,
                                  height: 22,
                                  radius: 6,
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            _Hairline(),
                            SizedBox(height: 20),
                            _SkeletonBar(height: 12, radius: 4),
                            SizedBox(height: 10),
                            _SkeletonBar(
                              widthFactor: 0.96,
                              height: 12,
                              radius: 4,
                            ),
                            SizedBox(height: 10),
                            _SkeletonBar(height: 12, radius: 4),
                            SizedBox(height: 10),
                            _SkeletonBar(
                              widthFactor: 0.78,
                              height: 12,
                              radius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Generating banner pinned above home indicator
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    _GeneratingBanner(
                      photoCount: selectedAssets.length,
                      selectedPrompt: selectedPrompt,
                      statusText: statusText,
                    ),
                    const SizedBox(height: 10),
                    const _IndeterminateBar(),
                  ],
                ),
              ),
              SizedBox(height: padding.bottom),
            ],
          ),

          // Floating back button over the scrim
          Positioned(
            top: padding.top + 4,
            left: 8,
            child: _FloatingBackButton(onTap: onBack),
          ),
        ],
      ),
    );
  }
}

class _HeroPhoto extends StatefulWidget {
  const _HeroPhoto({required this.asset});

  final AssetEntity asset;

  @override
  State<_HeroPhoto> createState() => _HeroPhotoState();
}

class _HeroPhotoState extends State<_HeroPhoto> {
  late Future<Result<Uint8List>> _future;

  @override
  void initState() {
    super.initState();
    _future = serviceLocator.get<IPhotoCacheService>().getThumbnail(
      widget.asset,
      width: 800,
      height: 600,
      quality: 85,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<Result<Uint8List>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.data is Success<Uint8List>) {
          return Image.memory(
            (snapshot.data! as Success<Uint8List>).value,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
        }
        return Container(color: cs.surfaceContainerHighest);
      },
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({
    this.widthFactor,
    this.fixedWidth,
    required this.height,
    required this.radius,
  });

  final double? widthFactor;
  final double? fixedWidth;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final shape = Container(
      height: height,
      width: fixedWidth,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    if (fixedWidth != null) return shape;
    return FractionallySizedBox(
      widthFactor: widthFactor ?? 1.0,
      alignment: Alignment.centerLeft,
      child: shape,
    );
  }
}

class _GeneratingBanner extends StatelessWidget {
  const _GeneratingBanner({
    required this.photoCount,
    required this.selectedPrompt,
    required this.statusText,
  });

  final int photoCount;
  final WritingPrompt? selectedPrompt;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final accent = isDark ? AppColors.accentLight : AppColors.accentDark;
    final bg = isDark
        ? AppColors.accentLight.withValues(alpha: 0.14)
        : AppColors.accent.withValues(alpha: 0.10);
    final border = isDark
        ? AppColors.accentLight.withValues(alpha: 0.22)
        : AppColors.accent.withValues(alpha: 0.20);

    final l10n = context.l10n;
    final caption = selectedPrompt == null
        ? l10n.diaryGenerationCaptionNoPrompt(photoCount)
        : l10n.diaryGenerationCaptionWithPrompt(
            photoCount,
            PromptCategoryUtils.getCategoryDisplayName(
              selectedPrompt!.category,
              locale: Localizations.localeOf(context),
            ).toLowerCase(),
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Row(
        children: [
          _PulsingDisc(color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    height: 1.25,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: TextStyle(
                    fontSize: 11.5,
                    letterSpacing: 0.2,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDisc extends StatefulWidget {
  const _PulsingDisc({required this.color});

  final Color color;

  @override
  State<_PulsingDisc> createState() => _PulsingDiscState();
}

class _PulsingDiscState extends State<_PulsingDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.6,
    end: 1.0,
  ).animate(_ac);

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
        child: const Icon(
          Icons.auto_awesome_rounded,
          size: 14,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _IndeterminateBar extends StatelessWidget {
  const _IndeterminateBar();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accentLight : AppColors.accentDark;
    return LinearProgressIndicator(
      minHeight: 4,
      borderRadius: BorderRadius.circular(999),
      backgroundColor: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06),
      valueColor: AlwaysStoppedAnimation<Color>(accent),
    );
  }
}

class _TopScrim extends StatelessWidget {
  const _TopScrim();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        alignment: Alignment.topCenter,
        height: 140,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x73141210), Color(0x00141210)],
          ),
        ),
      ),
    );
  }
}

class _FloatingBackButton extends StatelessWidget {
  const _FloatingBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.commonBack,
      child: Material(
        color: Colors.black.withValues(alpha: 0.42),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              Icons.chevron_left_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoCountBadge extends StatelessWidget {
  const _PhotoCountBadge({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.photo_library_rounded,
            size: 11,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            context.l10n.photoCountIndicator(current, total),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateLine extends StatelessWidget {
  const _DateLine({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.formatMonthDayWithDayName(date),
      style: AppTypography.withColor(
        AppTypography.dateLabel,
        AppColors.accentMuted,
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
