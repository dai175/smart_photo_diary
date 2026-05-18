import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/result/result.dart';
import '../../core/service_locator.dart';
import '../../localization/localization_extensions.dart';
import '../../models/writing_prompt.dart';
import '../../services/interfaces/photo_cache_service_interface.dart';
import 'diary_generating_banner.dart';
import 'diary_generating_skeleton_view.dart';

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
              Expanded(child: DiaryGeneratingSkeletonView(date: photoDateTime)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: DiaryGeneratingBanner(
                  photoCount: selectedAssets.length,
                  selectedPrompt: selectedPrompt,
                  statusText: statusText,
                ),
              ),
              SizedBox(height: padding.bottom),
            ],
          ),
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
  const _HeroPhoto({required this.asset, this.cacheService});

  final AssetEntity asset;
  final IPhotoCacheService? cacheService;

  @override
  State<_HeroPhoto> createState() => _HeroPhotoState();
}

class _HeroPhotoState extends State<_HeroPhoto> {
  late Future<Result<Uint8List>> _future;

  @override
  void initState() {
    super.initState();
    final cacheService =
        widget.cacheService ?? serviceLocator.get<IPhotoCacheService>();
    _future = cacheService.getThumbnail(
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
