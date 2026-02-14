import 'dart:ui';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/diary_entry.dart';
import 'interfaces/diary_tag_service_interface.dart';
import 'interfaces/ai_service_interface.dart';
import 'interfaces/logging_service_interface.dart';
import 'interfaces/settings_service_interface.dart';
import '../core/service_registration.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';

/// 日記タグ管理サービス
///
/// タグの取得（AI生成/キャッシュ）、全タグ集計、人気タグ集計、
/// バックグラウンドタグ生成を担当。
class DiaryTagService implements IDiaryTagService {
  static const String _boxName = 'diary_entries';

  final IAiService _aiService;
  final ILoggingService _logger;

  DiaryTagService({
    required IAiService aiService,
    required ILoggingService logger,
  }) : _aiService = aiService,
       _logger = logger;

  /// Hiveボックスを遅延取得（DiaryServiceが先にオープン済みを前提）
  Box<DiaryEntry>? get _diaryBox {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        return Hive.box<DiaryEntry>(_boxName);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Result<List<String>>> getTagsForEntry(DiaryEntry entry) async {
    try {
      // 有効なキャッシュがあればそれを返す
      if (entry.hasValidTags) {
        return Success(entry.cachedTags!);
      }

      // キャッシュが無効または存在しない場合は新しく生成
      _logger.debug('Generating new tags: ${entry.id}');
      final tagsResult = await _aiService.generateTagsFromContent(
        title: entry.title,
        content: entry.content,
        date: entry.date,
        photoCount: entry.photoIds.length,
        locale: _getCurrentLocale(),
      );

      if (tagsResult.isSuccess) {
        // Hiveボックスから最新のエントリーを取得して更新
        final box = _diaryBox;
        if (box != null && box.isOpen) {
          final latestEntry = box.get(entry.id);
          if (latestEntry != null) {
            latestEntry.updateTags(tagsResult.value);
            await box.put(latestEntry.id, latestEntry);
          }
        }
        return Success(tagsResult.value);
      } else {
        _logger.error('Tag generation error', error: tagsResult.error);
        // エラー時はフォールバックタグを返す
        return Success(_generateFallbackTags(entry));
      }
    } catch (e) {
      _logger.error('Tag generation error', error: e);
      // エラー時はフォールバックタグを返す
      return Success(_generateFallbackTags(entry));
    }
  }

  @override
  Future<Result<Set<String>>> getAllTags() async {
    try {
      final box = _diaryBox;
      if (box == null) {
        return const Success(<String>{});
      }
      final allTags = <String>{};

      for (final entry in box.values) {
        allTags.addAll(entry.effectiveTags);
      }

      return Success(allTags);
    } catch (e) {
      _logger.error('Tag list retrieval error', error: e);
      return Failure(
        ServiceException('Failed to retrieve tag list', originalError: e),
      );
    }
  }

  @override
  Future<Result<List<String>>> getPopularTags({int limit = 10}) async {
    try {
      final box = _diaryBox;
      if (box == null) {
        return const Success(<String>[]);
      }
      final tagCounts = <String, int>{};

      for (final entry in box.values) {
        for (final tag in entry.effectiveTags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }

      final sortedTags = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return Success(sortedTags.take(limit).map((e) => e.key).toList());
    } catch (e) {
      _logger.error('Popular tag retrieval error', error: e);
      return Failure(
        ServiceException('Failed to retrieve popular tags', originalError: e),
      );
    }
  }

  @override
  void generateTagsInBackground(
    DiaryEntry entry, {
    void Function(String id, String searchableText)? onSearchIndexUpdate,
  }) {
    _generateTagsInBackgroundCore(
      entry: entry,
      content: entry.content,
      logLabel: 'background',
      onTagsGenerated: (latestEntry, tags) {
        latestEntry.updateTags(tags);
        onSearchIndexUpdate?.call(
          latestEntry.id,
          _buildSearchableText(latestEntry),
        );
      },
    );
  }

  @override
  void generateTagsInBackgroundForPastPhoto(
    DiaryEntry entry, {
    void Function(String id, String searchableText)? onSearchIndexUpdate,
  }) {
    // 過去の日付であることを示すコンテキストを生成
    final daysDifference = DateTime.now().difference(entry.date).inDays;
    final locale = _getCurrentLocale();
    final isEnglish = locale.languageCode == 'en';
    String pastContext;

    if (daysDifference <= 0) {
      pastContext = isEnglish ? "Today's memory" : '今日の思い出';
    } else if (daysDifference == 1) {
      pastContext = isEnglish ? "Yesterday's memory" : '昨日の思い出';
    } else if (daysDifference <= 7) {
      pastContext = isEnglish
          ? 'Memory from $daysDifference days ago'
          : '$daysDifference日前の思い出';
    } else if (daysDifference <= 30) {
      final weeks = (daysDifference / 7).round();
      pastContext = isEnglish
          ? 'Memory from about $weeks weeks ago'
          : '約$weeks週間前の思い出';
    } else if (daysDifference <= 365) {
      final months = (daysDifference / 30).round();
      pastContext = isEnglish
          ? 'Memory from about $months months ago'
          : '約$monthsヶ月前の思い出';
    } else {
      final years = (daysDifference / 365).round();
      pastContext = isEnglish
          ? 'Memory from about $years years ago'
          : '約$years年前の思い出';
    }

    _generateTagsInBackgroundCore(
      entry: entry,
      content: '$pastContext: ${entry.content}',
      logLabel: 'past-photo-diary',
      onTagsGenerated: (latestEntry, tags) {
        latestEntry.updateTags(tags);
        onSearchIndexUpdate?.call(
          latestEntry.id,
          _buildSearchableText(latestEntry),
        );
      },
    );
  }

  /// バックグラウンドタグ生成の共通処理
  void _generateTagsInBackgroundCore({
    required DiaryEntry entry,
    required String content,
    required String logLabel,
    required void Function(DiaryEntry latestEntry, List<String> tags)
    onTagsGenerated,
  }) {
    Future.delayed(Duration.zero, () async {
      try {
        _logger.debug('Starting $logLabel tag generation: ${entry.id}');
        final tagsResult = await _aiService.generateTagsFromContent(
          title: entry.title,
          content: content,
          date: entry.date,
          photoCount: entry.photoIds.length,
          locale: _getCurrentLocale(),
        );

        if (tagsResult.isSuccess) {
          final box = _diaryBox;
          if (box != null && box.isOpen) {
            final latestEntry = box.get(entry.id);
            if (latestEntry != null) {
              onTagsGenerated(latestEntry, tagsResult.value);
              await box.put(latestEntry.id, latestEntry);
              _logger.debug(
                '$logLabel tag generation completed: ${entry.id} -> ${tagsResult.value}',
              );
            } else {
              _logger.warning(
                '$logLabel tag generation: Entry not found: ${entry.id}',
              );
            }
          } else {
            _logger.warning(
              '$logLabel tag generation: Hive box is unavailable',
            );
          }
        } else {
          _logger.error(
            '$logLabel tag generation error',
            error: tagsResult.error,
          );
        }
      } catch (e) {
        _logger.error('$logLabel tag generation error', error: e);
      }
    });
  }

  /// フォールバックタグを生成（ロケール対応）
  List<String> _generateFallbackTags(DiaryEntry entry) {
    final tags = <String>[];
    final locale = _getCurrentLocale();
    final isEnglish = locale.languageCode == 'en';

    // 時間帯タグのみ
    final hour = entry.date.hour;
    if (hour >= 5 && hour < 12) {
      tags.add(isEnglish ? 'Morning' : '朝');
    } else if (hour >= 12 && hour < 18) {
      tags.add(isEnglish ? 'Afternoon' : '昼');
    } else if (hour >= 18 && hour < 22) {
      tags.add(isEnglish ? 'Evening' : '夕方');
    } else {
      tags.add(isEnglish ? 'Night' : '夜');
    }

    return tags;
  }

  /// 検索用テキストを作成
  String _buildSearchableText(DiaryEntry entry) {
    final tags = entry.effectiveTags.join(' ');
    final location = entry.location ?? '';
    final text = '${entry.title} ${entry.content} $tags $location';
    return text.toLowerCase();
  }

  /// 現在のロケールを取得
  Locale _getCurrentLocale() {
    try {
      final settingsService = ServiceRegistration.get<ISettingsService>();
      final locale = settingsService.locale;
      if (locale != null) {
        return locale;
      }
    } catch (e) {
      _logger.warning('Locale retrieval error: $e');
    }

    // フォールバック: システムロケール
    try {
      final currentLocale = Intl.getCurrentLocale();
      if (currentLocale.isNotEmpty) {
        final parts = currentLocale.split('_');
        if (parts.length >= 2) {
          return Locale(parts[0], parts[1]);
        } else {
          return Locale(parts[0]);
        }
      }
    } catch (e2) {
      _logger.warning('System locale retrieval error: $e2');
    }

    // 最終的なフォールバック: 日本語
    return const Locale('ja');
  }
}
