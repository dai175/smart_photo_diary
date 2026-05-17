import 'dart:math';
import 'dart:ui';

import '../models/writing_prompt.dart';
import 'prompt_cache_service.dart';

/// プロンプトのフィルタリング・検索・ランダム選択・ローカライゼーション
///
/// キャッシュデータへのアクセスは PromptCacheService 越しに行う。
final class PromptFilterService {
  final PromptCacheService _cache;
  final Random _random;

  PromptFilterService({required PromptCacheService cache, Random? random})
    : _cache = cache,
      _random = random ?? Random();

  /// プラン別フィルタ済みプロンプトを返す
  List<WritingPrompt> getPromptsForPlan({
    required bool isPremium,
    Locale? locale,
  }) {
    return localizePrompts(_cache.getPlanCache(isPremium), locale);
  }

  /// カテゴリ別 + プラン制限済みプロンプトを返す
  List<WritingPrompt> getPromptsByCategory(
    PromptCategory category, {
    required bool isPremium,
    Locale? locale,
  }) {
    final filtered = _cache
        .getCategoryCache(category)
        .where((p) => p.isAvailableForPlan(isPremium: isPremium))
        .toList();
    return localizePrompts(filtered, locale);
  }

  /// IDでプロンプトを返す（存在しない場合は null）
  WritingPrompt? getById(String id, {Locale? locale}) =>
      _localizePrompt(_cache.getById(id), locale);

  /// キーワード全文検索（空クエリは全件返す）
  List<WritingPrompt> searchPrompts(
    String query, {
    required bool isPremium,
    Locale? locale,
  }) {
    if (query.trim().isEmpty) {
      return getPromptsForPlan(isPremium: isPremium, locale: locale);
    }
    final lowerQuery = query.toLowerCase();
    final results = getPromptsForPlan(
      isPremium: isPremium,
    ).where((p) => p.matchesKeyword(lowerQuery)).toList();
    return localizePrompts(results, locale);
  }

  /// カテゴリ別プロンプト数統計を返す
  Map<PromptCategory, int> getPromptStatistics({required bool isPremium}) {
    return {
      for (final cat in PromptCategory.values)
        cat: getPromptsByCategory(cat, isPremium: isPremium).length,
    };
  }

  /// 優先度加重ランダム選択（候補なしの場合 null）
  WritingPrompt? getRandomPrompt({
    required bool isPremium,
    PromptCategory? category,
    List<String>? excludeIds,
    Locale? locale,
  }) {
    final candidates = _buildCandidates(
      isPremium: isPremium,
      category: category,
      excludeIds: excludeIds,
    );
    if (candidates.isEmpty) return null;
    return _localizePrompt(_selectWeightedRandom(candidates), locale);
  }

  /// 重複回避ランダムシーケンス（count が候補数を超えた場合は候補数分返す）
  ///
  /// 候補プールを一度だけ構築し、Set による O(1) 除外で N+1 再構築を回避する。
  List<WritingPrompt> getRandomPromptSequence({
    required int count,
    required bool isPremium,
    PromptCategory? category,
    Locale? locale,
  }) {
    if (count <= 0) return [];

    final pool = _buildCandidates(isPremium: isPremium, category: category);
    if (pool.isEmpty) return [];

    final actualCount = count > pool.length ? pool.length : count;
    final selected = <WritingPrompt>[];
    final excluded = <String>{};

    for (int i = 0; i < actualCount; i++) {
      final candidates = excluded.isEmpty
          ? pool
          : pool.where((p) => !excluded.contains(p.id)).toList();
      if (candidates.isEmpty) break;
      final prompt = _selectWeightedRandom(candidates);
      selected.add(prompt);
      excluded.add(prompt.id);
    }

    return localizePrompts(selected, locale);
  }

  /// ローカライゼーション（locale が null の場合は元リストをそのまま返す）
  List<WritingPrompt> localizePrompts(
    List<WritingPrompt> prompts,
    Locale? locale,
  ) {
    if (locale == null) return List.unmodifiable(prompts);
    return List.unmodifiable(
      prompts.map((p) => p.localizedCopy(locale)).toList(growable: false),
    );
  }

  List<WritingPrompt> _buildCandidates({
    required bool isPremium,
    PromptCategory? category,
    List<String>? excludeIds,
  }) {
    final base = category != null
        ? getPromptsByCategory(category, isPremium: isPremium)
        : getPromptsForPlan(isPremium: isPremium);

    if (excludeIds == null || excludeIds.isEmpty) return base;
    final excludeSet = excludeIds.toSet();
    return base.where((p) => !excludeSet.contains(p.id)).toList();
  }

  WritingPrompt _selectWeightedRandom(List<WritingPrompt> prompts) {
    if (prompts.length == 1) return prompts.first;
    final totalWeight = prompts.fold<int>(0, (sum, p) => sum + p.priority);
    final randomWeight = _random.nextInt(totalWeight);
    int currentWeight = 0;
    for (final prompt in prompts) {
      currentWeight += prompt.priority;
      if (randomWeight < currentWeight) return prompt;
    }
    return prompts.last;
  }

  WritingPrompt? _localizePrompt(WritingPrompt? prompt, Locale? locale) {
    if (prompt == null || locale == null) return prompt;
    return prompt.localizedCopy(locale);
  }
}
