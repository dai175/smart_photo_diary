import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';

import '../core/errors/app_exceptions.dart';
import '../core/result/result.dart';
import '../models/writing_prompt.dart';
import '../services/interfaces/logging_service_interface.dart';
import 'interfaces/prompt_service_interface.dart';
import 'interfaces/prompt_usage_service_interface.dart';
import 'prompt_cache_service.dart';
import 'prompt_filter_service.dart';

/// ライティングプロンプト管理サービス（薄いオーケストレーター）
///
/// JSON 読み込みと初期化シーケンスを担当し、
/// キャッシュ管理を PromptCacheService、フィルタ/検索を PromptFilterService に委譲する。
/// 使用履歴管理は IPromptUsageService に委譲（Facade パターン）。
class PromptService implements IPromptService {
  static const String _promptsAssetPath = 'assets/data/writing_prompts.json';

  List<WritingPrompt> _allPrompts = [];
  bool _isInitialized = false;

  final ILoggingService _logger;
  IPromptUsageService? _usageService;
  late final PromptCacheService _cacheService;
  late final PromptFilterService _filterService;

  PromptService({
    required ILoggingService logger,
    IPromptUsageService? usageService,
  }) : _logger = logger,
       _usageService = usageService {
    _cacheService = PromptCacheService(logger: logger);
    _filterService = PromptFilterService(cache: _cacheService);
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<bool> initialize() async {
    try {
      _logger.info('PromptService: Initialization started');
      if (_isInitialized) {
        _logger.info('PromptService: Already initialized');
        return true;
      }
      await _loadPromptsFromAsset();
      if (_cacheService.build(_allPrompts).isFailure) {
        return false;
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

  Future<void> _loadPromptsFromAsset() async {
    try {
      final String jsonString = await rootBundle.loadString(_promptsAssetPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> promptsList = jsonData['prompts'] ?? [];
      _allPrompts = promptsList
          .map((j) => WritingPrompt.fromJson(j as Map<String, dynamic>))
          .toList();
      _logger.info(
        'PromptService: JSON loading completed (${_allPrompts.length} prompts)',
      );
      _validatePromptData(jsonData);
    } catch (e) {
      _logger.error('PromptService: JSON loading failed', error: e);
      rethrow;
    }
  }

  void _validatePromptData(Map<String, dynamic> jsonData) {
    final int expectedTotal = jsonData['totalPrompts'] ?? 0;
    final int expectedBasic = jsonData['basicPrompts'] ?? 0;
    final int expectedPremium = jsonData['premiumPrompts'] ?? 0;
    final int actualTotal = _allPrompts.length;
    final int actualBasic = _allPrompts.where((p) => !p.isPremiumOnly).length;
    final int actualPremium = _allPrompts.where((p) => p.isPremiumOnly).length;

    if (actualTotal != expectedTotal ||
        actualBasic != expectedBasic ||
        actualPremium != expectedPremium) {
      _logger.warning(
        'PromptService: Prompt data mismatch: '
        'expected(total:$expectedTotal, basic:$expectedBasic, premium:$expectedPremium) '
        'actual(total:$actualTotal, basic:$actualBasic, premium:$actualPremium)',
      );
    }

    final seen = <String>{};
    if (!_allPrompts.every((p) => seen.add(p.id))) {
      _logger.warning('PromptService: Duplicate prompt IDs found');
    }
  }

  @override
  List<WritingPrompt> getAllPrompts({Locale? locale}) {
    _ensureInitialized();
    final active = _allPrompts.where((p) => p.isActive).toList();
    return _filterService.localizePrompts(active, locale);
  }

  @override
  List<WritingPrompt> getPromptsForPlan({
    required bool isPremium,
    Locale? locale,
  }) {
    _ensureInitialized();
    return _filterService.getPromptsForPlan(
      isPremium: isPremium,
      locale: locale,
    );
  }

  @override
  List<WritingPrompt> getPromptsByCategory(
    PromptCategory category, {
    required bool isPremium,
    Locale? locale,
  }) {
    _ensureInitialized();
    return _filterService.getPromptsByCategory(
      category,
      isPremium: isPremium,
      locale: locale,
    );
  }

  @override
  WritingPrompt? getRandomPrompt({
    required bool isPremium,
    PromptCategory? category,
    List<String>? excludeIds,
    Locale? locale,
  }) {
    _ensureInitialized();
    return _filterService.getRandomPrompt(
      isPremium: isPremium,
      category: category,
      excludeIds: excludeIds,
      locale: locale,
    );
  }

  @override
  List<WritingPrompt> getRandomPromptSequence({
    required int count,
    required bool isPremium,
    PromptCategory? category,
    Locale? locale,
  }) {
    _ensureInitialized();
    return _filterService.getRandomPromptSequence(
      count: count,
      isPremium: isPremium,
      category: category,
      locale: locale,
    );
  }

  @override
  List<WritingPrompt> searchPrompts(
    String query, {
    required bool isPremium,
    Locale? locale,
  }) {
    _ensureInitialized();
    return _filterService.searchPrompts(
      query,
      isPremium: isPremium,
      locale: locale,
    );
  }

  @override
  WritingPrompt? getPromptById(String id, {Locale? locale}) {
    _ensureInitialized();
    return _filterService.getById(id, locale: locale);
  }

  @override
  Map<PromptCategory, int> getPromptStatistics({required bool isPremium}) {
    _ensureInitialized();
    return _filterService.getPromptStatistics(isPremium: isPremium);
  }

  @override
  void clearCache() {
    if (_isInitialized) {
      if (_cacheService.build(_allPrompts).isFailure) {
        _isInitialized = false;
      }
    } else {
      _cacheService.clear();
    }
  }

  @override
  void reset() {
    _isInitialized = false;
    _allPrompts.clear();
    _cacheService.clear();
    _usageService = null;
  }

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

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'PromptService is not initialized. Call initialize() first.',
      );
    }
  }
}
