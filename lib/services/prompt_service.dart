// PromptService実装
//
// ライティングプロンプトの管理を担当するサービス
// JSONデータの読み込み、キャッシュ、フィルタリング機能を提供
//
// 使用履歴管理はPromptUsageServiceに委譲（Facadeパターン）

import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../core/errors/app_exceptions.dart';
import '../core/result/result.dart';
import '../core/service_locator.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../models/writing_prompt.dart';
import '../utils/prompt_category_utils.dart';
import 'interfaces/prompt_service_interface.dart';
import 'interfaces/prompt_usage_service_interface.dart';

/// ライティングプロンプト管理サービス
///
/// プロンプトデータの読み込み、キャッシュ管理、
/// プラン別フィルタリング機能を提供。
/// 使用履歴管理はIPromptUsageServiceに委譲。
class PromptService implements IPromptService {
  static const String _promptsAssetPath = 'assets/data/writing_prompts.json';

  // プロンプトデータとキャッシュ
  List<WritingPrompt> _allPrompts = [];
  final Map<bool, List<WritingPrompt>> _planFilterCache = {};
  final Map<PromptCategory, List<WritingPrompt>> _categoryCache = {};
  final Map<String, WritingPrompt> _idCache = {};

  // 依存サービス
  final ILoggingService _logger;
  IPromptUsageService? _usageService;

  // 初期化状態管理
  bool _isInitialized = false;

  // 乱数生成器（テスト可能性のため分離）
  final Random _random = Random();

  PromptService({
    required ILoggingService logger,
    IPromptUsageService? usageService,
  }) : _logger = logger,
       _usageService = usageService;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<bool> initialize() async {
    try {
      _logger.info('PromptService: Initialization started');

      // 既に初期化済みの場合はスキップ
      if (_isInitialized) {
        _logger.info('PromptService: Already initialized');
        return true;
      }

      // JSONファイルを読み込み
      await _loadPromptsFromAsset();

      // キャッシュを生成
      _buildCaches();

      // 使用履歴サービスを取得（コンストラクタ未注入かつServiceLocator経由でも失敗時はnull）
      if (_usageService == null) {
        try {
          _usageService = await serviceLocator.getAsync<IPromptUsageService>();
        } catch (e) {
          _logger.warning(
            'PromptService: Usage history feature disabled (${e.toString()})',
          );
          _usageService = null;
        }
      }

      _isInitialized = true;
      _logger.info(
        'PromptService: Initialization completed (prompt count: ${_allPrompts.length})',
      );

      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'PromptService: Initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// JSONアセットからプロンプトデータを読み込み
  Future<void> _loadPromptsFromAsset() async {
    try {
      // JSONファイルを読み込み
      final String jsonString = await rootBundle.loadString(_promptsAssetPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // プロンプト配列を抽出
      final List<dynamic> promptsList = jsonData['prompts'] ?? [];

      // WritingPromptオブジェクトに変換
      _allPrompts = promptsList
          .map((json) => WritingPrompt.fromJson(json as Map<String, dynamic>))
          .toList();

      _logger.info(
        'PromptService: JSON loading completed (${_allPrompts.length} prompts)',
      );

      // データ整合性チェック
      _validatePromptData(jsonData);
    } catch (e) {
      _logger.error('PromptService: JSON loading failed', error: e);
      rethrow;
    }
  }

  /// プロンプトデータの整合性をチェック
  void _validatePromptData(Map<String, dynamic> jsonData) {
    // メタデータと実際のデータ数の整合性確認
    final int expectedTotal = jsonData['totalPrompts'] ?? 0;
    final int expectedBasic = jsonData['basicPrompts'] ?? 0;
    final int expectedPremium = jsonData['premiumPrompts'] ?? 0;

    final int actualTotal = _allPrompts.length;
    final int actualBasic = _allPrompts.where((p) => !p.isPremiumOnly).length;
    final int actualPremium = _allPrompts.where((p) => p.isPremiumOnly).length;

    if (actualTotal != expectedTotal ||
        actualBasic != expectedBasic ||
        actualPremium != expectedPremium) {
      final error =
          'Prompt data mismatch: '
          'expected(total:$expectedTotal, basic:$expectedBasic, premium:$expectedPremium) '
          'actual(total:$actualTotal, basic:$actualBasic, premium:$actualPremium)';
      _logger.warning('PromptService: $error');
    }

    // ID重複チェック
    final ids = _allPrompts.map((p) => p.id).toList();
    final uniqueIds = ids.toSet();
    if (ids.length != uniqueIds.length) {
      _logger.warning('PromptService: Duplicate prompt IDs found');
    }
  }

  /// 各種キャッシュを構築
  void _buildCaches() {
    try {
      // プラン別キャッシュ
      _planFilterCache[false] = PromptCategoryUtils.filterPromptsByPlan(
        _allPrompts,
        isPremium: false,
      );
      _planFilterCache[true] = PromptCategoryUtils.filterPromptsByPlan(
        _allPrompts,
        isPremium: true,
      );

      // カテゴリ別キャッシュ
      for (final category in PromptCategory.values) {
        _categoryCache[category] = _allPrompts
            .where((p) => p.category == category && p.isActive)
            .toList();
      }

      // ID別キャッシュ
      for (final prompt in _allPrompts) {
        _idCache[prompt.id] = prompt;
      }

      _logger.info('PromptService: Cache build completed');
    } catch (e) {
      _logger.error('PromptService: Cache build failed', error: e);
      rethrow;
    }
  }

  @override
  List<WritingPrompt> getAllPrompts({Locale? locale}) {
    _ensureInitialized();
    final activePrompts = _allPrompts.where((p) => p.isActive).toList();
    return _localizePrompts(activePrompts, locale);
  }

  @override
  List<WritingPrompt> getPromptsForPlan({
    required bool isPremium,
    Locale? locale,
  }) {
    _ensureInitialized();

    if (!_planFilterCache.containsKey(isPremium)) {
      _planFilterCache[isPremium] = PromptCategoryUtils.filterPromptsByPlan(
        _allPrompts,
        isPremium: isPremium,
      );
    }

    final cached = _planFilterCache[isPremium] ?? [];
    return _localizePrompts(cached, locale);
  }

  @override
  List<WritingPrompt> getPromptsByCategory(
    PromptCategory category, {
    required bool isPremium,
    Locale? locale,
  }) {
    _ensureInitialized();

    // カテゴリのプロンプトを取得
    final categoryPrompts = _categoryCache[category] ?? [];

    // プラン制限を適用
    final filtered = categoryPrompts
        .where((prompt) => prompt.isAvailableForPlan(isPremium: isPremium))
        .toList();
    return _localizePrompts(filtered, locale);
  }

  @override
  WritingPrompt? getRandomPrompt({
    required bool isPremium,
    PromptCategory? category,
    List<String>? excludeIds,
    Locale? locale,
  }) {
    _ensureInitialized();

    List<WritingPrompt> candidates;

    if (category != null) {
      // 特定カテゴリから選択
      candidates = getPromptsByCategory(
        category,
        isPremium: isPremium,
        locale: null,
      );
    } else {
      // 全プロンプトから選択
      candidates = getPromptsForPlan(isPremium: isPremium, locale: null);
    }

    // 手動除外IDを適用
    if (excludeIds != null && excludeIds.isNotEmpty) {
      candidates = candidates
          .where((prompt) => !excludeIds.contains(prompt.id))
          .toList();
    }

    // 履歴ベースの重複回避は無効化（ユーザー要望により）
    // final recentlyUsedIds = getRecentlyUsedPromptIds();
    // if (recentlyUsedIds.isNotEmpty) {
    //   candidates = candidates.where((prompt) => !recentlyUsedIds.contains(prompt.id)).toList();
    // }

    if (candidates.isEmpty) {
      return null;
    }

    // 優先度による重み付けランダム選択
    final selected = _selectWeightedRandom(candidates);
    return _localizePrompt(selected, locale);
  }

  /// 優先度による重み付けランダム選択
  WritingPrompt _selectWeightedRandom(List<WritingPrompt> prompts) {
    if (prompts.length == 1) {
      return prompts.first;
    }

    // 優先度の合計を計算
    final totalWeight = prompts.fold<int>(0, (sum, p) => sum + p.priority);

    // ランダムな重みを選択
    final randomWeight = _random.nextInt(totalWeight);

    // 重みに基づいてプロンプトを選択
    int currentWeight = 0;
    for (final prompt in prompts) {
      currentWeight += prompt.priority;
      if (randomWeight < currentWeight) {
        return prompt;
      }
    }

    // フォールバック（通常は到達しない）
    return prompts.last;
  }

  List<WritingPrompt> _localizePrompts(
    List<WritingPrompt> prompts,
    Locale? locale,
  ) {
    if (locale == null) {
      return List.unmodifiable(prompts);
    }

    final localized = prompts
        .map((prompt) => prompt.localizedCopy(locale))
        .toList(growable: false);
    return List.unmodifiable(localized);
  }

  WritingPrompt? _localizePrompt(WritingPrompt? prompt, Locale? locale) {
    if (prompt == null) {
      return null;
    }
    if (locale == null) {
      return prompt;
    }
    return prompt.localizedCopy(locale);
  }

  @override
  List<WritingPrompt> searchPrompts(
    String query, {
    required bool isPremium,
    Locale? locale,
  }) {
    _ensureInitialized();

    if (query.trim().isEmpty) {
      return getPromptsForPlan(isPremium: isPremium, locale: locale);
    }

    final lowerQuery = query.toLowerCase();
    final availablePrompts = getPromptsForPlan(
      isPremium: isPremium,
      locale: null,
    );

    final results = availablePrompts
        .where((prompt) => prompt.matchesKeyword(lowerQuery))
        .toList();

    return _localizePrompts(results, locale);
  }

  @override
  WritingPrompt? getPromptById(String id, {Locale? locale}) {
    _ensureInitialized();
    final prompt = _idCache[id];
    return _localizePrompt(prompt, locale);
  }

  @override
  Map<PromptCategory, int> getPromptStatistics({required bool isPremium}) {
    _ensureInitialized();

    final stats = <PromptCategory, int>{};

    for (final category in PromptCategory.values) {
      final categoryPrompts = getPromptsByCategory(
        category,
        isPremium: isPremium,
      );
      stats[category] = categoryPrompts.length;
    }

    return stats;
  }

  @override
  void clearCache() {
    _planFilterCache.clear();
    _categoryCache.clear();
    _idCache.clear();
  }

  @override
  void reset() {
    _isInitialized = false;
    _allPrompts.clear();
    clearCache();
    _usageService = null;
  }

  @override
  List<WritingPrompt> getRandomPromptSequence({
    required int count,
    required bool isPremium,
    PromptCategory? category,
    Locale? locale,
  }) {
    _ensureInitialized();

    if (count <= 0) {
      return [];
    }

    List<WritingPrompt> candidates;

    if (category != null) {
      // 特定カテゴリから選択
      candidates = getPromptsByCategory(
        category,
        isPremium: isPremium,
        locale: null,
      );
    } else {
      // 全プロンプトから選択
      candidates = getPromptsForPlan(isPremium: isPremium, locale: null);
    }

    if (candidates.isEmpty) {
      return [];
    }

    // 要求数がプロンプト総数を超える場合は、利用可能な分だけ返す
    final actualCount = count > candidates.length ? candidates.length : count;

    final selectedPrompts = <WritingPrompt>[];
    final excludeIds = <String>[];

    // 重複回避しながら指定数のプロンプトを選択
    for (int i = 0; i < actualCount; i++) {
      final prompt = getRandomPrompt(
        isPremium: isPremium,
        category: category,
        excludeIds: excludeIds,
        locale: null,
      );

      if (prompt != null) {
        selectedPrompts.add(prompt);
        excludeIds.add(prompt.id);
      } else {
        // これ以上選択できるプロンプトがない場合は終了
        break;
      }
    }

    return _localizePrompts(selectedPrompts, locale);
  }

  // =================================================================
  // 使用履歴メソッド（IPromptUsageServiceへの委譲）
  // =================================================================

  @override
  Future<Result<bool>> recordPromptUsage({
    required String promptId,
    String? diaryEntryId,
    bool wasHelpful = true,
  }) async {
    _ensureInitialized();
    if (_usageService == null) {
      return const Failure(ServiceException('Usage service is not available'));
    }
    return _usageService!.recordPromptUsage(
      promptId: promptId,
      diaryEntryId: diaryEntryId,
      wasHelpful: wasHelpful,
    );
  }

  @override
  List<PromptUsageHistory> getUsageHistory({int? limit, String? promptId}) {
    _ensureInitialized();
    if (_usageService == null) return [];
    return _usageService!.getUsageHistory(limit: limit, promptId: promptId);
  }

  @override
  List<String> getRecentlyUsedPromptIds({int days = 7, int limit = 10}) {
    _ensureInitialized();
    if (_usageService == null) return [];
    return _usageService!.getRecentlyUsedPromptIds(days: days, limit: limit);
  }

  @override
  Future<Result<bool>> clearUsageHistory({int? olderThanDays}) async {
    _ensureInitialized();
    if (_usageService == null) {
      return const Failure(ServiceException('Usage service is not available'));
    }
    return _usageService!.clearUsageHistory(olderThanDays: olderThanDays);
  }

  @override
  Map<String, int> getUsageFrequencyStats({int days = 30}) {
    _ensureInitialized();
    if (_usageService == null) return {};
    return _usageService!.getUsageFrequencyStats(days: days);
  }

  /// 初期化チェック
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'PromptService is not initialized. Call initialize() first.',
      );
    }
  }
}
