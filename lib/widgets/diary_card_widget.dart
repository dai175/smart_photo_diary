import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import '../models/diary_entry.dart';
import '../services/diary_service.dart';
import '../constants/app_constants.dart';

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
      debugPrint('タグ取得エラー: $e');
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
    // タイトルを取得
    final title = entry.title.isNotEmpty ? entry.title : '無題';

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日付
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                DateFormat('yyyy年MM月dd日').format(entry.date),
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // タイトル
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            // 本文（一部）
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                entry.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),

            // 写真があれば表示
            _buildPhotoThumbnails(),

            // タグ（動的生成）
            _buildTags(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnails() {
    return FutureBuilder<List<AssetEntity>>(
      future: entry.getPhotoAssets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox();
        }

        final assets = snapshot.data!;
        return SizedBox(
          height: AppConstants.diaryThumbnailSize,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: assets.length,
            itemBuilder: (context, imgIndex) {
              return Padding(
                padding: EdgeInsets.only(
                  left: imgIndex == 0 ? 16 : 8,
                  right: imgIndex == assets.length - 1 ? 16 : 0,
                  bottom: 8,
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
          return SizedBox(
            width: AppConstants.diaryThumbnailSize,
            height: AppConstants.diaryThumbnailSize,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(ThemeConstants.mediumBorderRadius),
          child: Image.memory(
            thumbnailSnapshot.data!,
            height: AppConstants.diaryThumbnailSize,
            width: AppConstants.diaryThumbnailSize,
            fit: BoxFit.cover,
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
          return const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('タグを生成中...', style: TextStyle(fontSize: 12)),
              ],
            ),
          );
        }
        
        final tags = snapshot.data ?? [];
        if (tags.isEmpty) return const SizedBox();
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            spacing: 8,
            children: [
              for (final tag in tags)
                Chip(
                  label: Text(
                    '#$tag',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  padding: const EdgeInsets.all(0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        );
      },
    );
  }
}