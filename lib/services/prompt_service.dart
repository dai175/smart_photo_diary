// PromptService実装
// 
// ライティングプロンプトの管理を担当するサービス
// シングルトンパターンでJSONデータの読み込み、キャッシュ、
// フィルタリング機能を提供

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/service_locator.dart';
import '../services/logging_service.dart';
import '../models/writing_prompt.dart';
import '../utils/prompt_category_utils.dart';
import 'interfaces/prompt_service_interface.dart';

/// ライティングプロンプト管理サービス
/// 
/// シングルトンパターンでプロンプトデータの読み込み、
/// キャッシュ管理、プラン別フィルタリング機能を提供
class PromptService implements IPromptService {
  static PromptService? _instance;
  static const String _promptsAssetPath = 'assets/data/writing_prompts.json';
  static const String _usageHistoryBoxName = 'prompt_usage_history';
  
  // プロンプトデータとキャッシュ
  List<WritingPrompt> _allPrompts = [];
  final Map<bool, List<WritingPrompt>> _planFilterCache = {};
  final Map<PromptCategory, List<WritingPrompt>> _categoryCache = {};
  final Map<String, WritingPrompt> _idCache = {};
  
  // 使用履歴管理
  Box<PromptUsageHistory>? _usageHistoryBox;
  
  // 初期化状態管理
  bool _isInitialized = false;
  
  // 乱数生成器（テスト可能性のため分離）
  final Random _random = Random();
  
  // 内部コンストラクタ（シングルトン用）
  PromptService._internal();
  
  /// シングルトンインスタンス取得
  static PromptService get instance {
    _instance ??= PromptService._internal();
    return _instance!;
  }
  
  /// テスト用インスタンスリセット
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }
  
  @override
  bool get isInitialized => _isInitialized;
  
  @override
  Future<bool> initialize() async {
    final loggingService = await ServiceLocator().getAsync<LoggingService>();
    
    try {
      loggingService.info('PromptService: 初期化開始');
      
      // 既に初期化済みの場合はスキップ
      if (_isInitialized) {
        loggingService.info('PromptService: 既に初期化済み');
        return true;
      }
      
      // JSONファイルを読み込み
      await _loadPromptsFromAsset();
      
      // キャッシュを生成
      await _buildCaches();
      
      // 使用履歴Box初期化（失敗してもPromptService自体は初期化完了とする）
      try {
        await _initializeUsageHistoryBox();
      } catch (e) {
        loggingService.warning('PromptService: 使用履歴機能は無効化されました（${e.toString()}）');
        _usageHistoryBox = null;
      }
      
      _isInitialized = true;
      loggingService.info('PromptService: 初期化完了（プロンプト数: ${_allPrompts.length}）');
      
      return true;
    } catch (e, stackTrace) {
      loggingService.error('PromptService: 初期化失敗', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// JSONアセットからプロンプトデータを読み込み
  Future<void> _loadPromptsFromAsset() async {
    final loggingService = await ServiceLocator().getAsync<LoggingService>();
    
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
      
      loggingService.info('PromptService: JSON読み込み完了（${_allPrompts.length}個のプロンプト）');
      
      // データ整合性チェック
      await _validatePromptData(jsonData);
      
    } catch (e) {
      loggingService.error('PromptService: JSON読み込み失敗', error: e);
      rethrow;
    }
  }
  
  /// プロンプトデータの整合性をチェック
  Future<void> _validatePromptData(Map<String, dynamic> jsonData) async {
    final loggingService = await ServiceLocator().getAsync<LoggingService>();
    
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
      final error = 'プロンプトデータ不整合: '
          '期待値(total:$expectedTotal, basic:$expectedBasic, premium:$expectedPremium) '
          '実際(total:$actualTotal, basic:$actualBasic, premium:$actualPremium)';
      loggingService.warning('PromptService: $error');
    }
    
    // ID重複チェック
    final ids = _allPrompts.map((p) => p.id).toList();
    final uniqueIds = ids.toSet();
    if (ids.length != uniqueIds.length) {
      loggingService.warning('PromptService: プロンプトIDに重複があります');
    }
  }
  
  /// 各種キャッシュを構築
  Future<void> _buildCaches() async {
    final loggingService = await ServiceLocator().getAsync<LoggingService>();
    
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
      
      loggingService.info('PromptService: キャッシュ構築完了');
    } catch (e) {
      loggingService.error('PromptService: キャッシュ構築失敗', error: e);
      rethrow;
    }
  }
  
  /// 使用履歴Box初期化
  Future<void> _initializeUsageHistoryBox() async {
    final loggingService = await ServiceLocator().getAsync<LoggingService>();
    
    // 既存のBoxがあればクローズ
    if (Hive.isBoxOpen(_usageHistoryBoxName)) {
      await Hive.box<PromptUsageHistory>(_usageHistoryBoxName).close();
    }
    
    _usageHistoryBox = await Hive.openBox<PromptUsageHistory>(_usageHistoryBoxName);
    loggingService.info('PromptService: 使用履歴Box初期化完了（履歴数: ${_usageHistoryBox!.length}）');
  }
  
  @override
  List<WritingPrompt> getAllPrompts() {
    _ensureInitialized();
    return List.unmodifiable(_allPrompts.where((p) => p.isActive));
  }
  
  @override
  List<WritingPrompt> getPromptsForPlan({required bool isPremium}) {
    _ensureInitialized();
    return List.unmodifiable(_planFilterCache[isPremium] ?? []);
  }
  
  @override
  List<WritingPrompt> getPromptsByCategory(
    PromptCategory category, {
    required bool isPremium,
  }) {
    _ensureInitialized();
    
    // カテゴリのプロンプトを取得
    final categoryPrompts = _categoryCache[category] ?? [];
    
    // プラン制限を適用
    return categoryPrompts
        .where((prompt) => prompt.isAvailableForPlan(isPremium: isPremium))
        .toList();
  }
  
  @override
  WritingPrompt? getRandomPrompt({
    required bool isPremium,
    PromptCategory? category,
    List<String>? excludeIds,
  }) {
    _ensureInitialized();
    
    List<WritingPrompt> candidates;
    
    if (category != null) {
      // 特定カテゴリから選択
      candidates = getPromptsByCategory(category, isPremium: isPremium);
    } else {
      // 全プロンプトから選択
      candidates = getPromptsForPlan(isPremium: isPremium);
    }
    
    // 手動除外IDを適用
    if (excludeIds != null && excludeIds.isNotEmpty) {
      candidates = candidates.where((prompt) => !excludeIds.contains(prompt.id)).toList();
    }
    
    // 履歴ベースの重複回避（最近使用したプロンプトを除外）
    final recentlyUsedIds = getRecentlyUsedPromptIds();
    if (recentlyUsedIds.isNotEmpty) {
      candidates = candidates.where((prompt) => !recentlyUsedIds.contains(prompt.id)).toList();
    }
    
    if (candidates.isEmpty) {
      return null;
    }
    
    // 優先度による重み付けランダム選択
    return _selectWeightedRandom(candidates);
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
  
  @override
  List<WritingPrompt> searchPrompts(
    String query, {
    required bool isPremium,
  }) {
    _ensureInitialized();
    
    if (query.trim().isEmpty) {
      return getPromptsForPlan(isPremium: isPremium);
    }
    
    final lowerQuery = query.toLowerCase();
    final availablePrompts = getPromptsForPlan(isPremium: isPremium);
    
    return availablePrompts.where((prompt) {
      // テキスト内検索
      if (prompt.text.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      
      // タグ検索
      if (prompt.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))) {
        return true;
      }
      
      // 説明文検索
      if (prompt.description?.toLowerCase().contains(lowerQuery) == true) {
        return true;
      }
      
      return false;
    }).toList();
  }
  
  @override
  WritingPrompt? getPromptById(String id) {
    _ensureInitialized();
    return _idCache[id];
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
    
    // 使用履歴Boxもリセット
    _usageHistoryBox = null;
  }
  
  @override
  List<WritingPrompt> getRandomPromptSequence({
    required int count,
    required bool isPremium,
    PromptCategory? category,
  }) {
    _ensureInitialized();
    
    if (count <= 0) {
      return [];
    }
    
    List<WritingPrompt> candidates;
    
    if (category != null) {
      // 特定カテゴリから選択
      candidates = getPromptsByCategory(category, isPremium: isPremium);
    } else {
      // 全プロンプトから選択
      candidates = getPromptsForPlan(isPremium: isPremium);
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
      );
      
      if (prompt != null) {
        selectedPrompts.add(prompt);
        excludeIds.add(prompt.id);
      } else {
        // これ以上選択できるプロンプトがない場合は終了
        break;
      }
    }
    
    return selectedPrompts;
  }
  
  @override
  Future<bool> recordPromptUsage({
    required String promptId,
    String? diaryEntryId,
    bool wasHelpful = true,
  }) async {
    _ensureInitialized();
    
    if (_usageHistoryBox == null) {
      return false;
    }
    
    try {
      final usage = PromptUsageHistory(
        promptId: promptId,
        diaryEntryId: diaryEntryId,
        wasHelpful: wasHelpful,
      );
      
      await _usageHistoryBox!.add(usage);
      
      final loggingService = await ServiceLocator().getAsync<LoggingService>();
      loggingService.info('PromptService: プロンプト使用履歴記録完了（promptId: $promptId）');
      
      return true;
    } catch (e) {
      final loggingService = await ServiceLocator().getAsync<LoggingService>();
      loggingService.error('PromptService: 使用履歴記録失敗', error: e);
      return false;
    }
  }
  
  @override
  List<PromptUsageHistory> getUsageHistory({
    int? limit,
    String? promptId,
  }) {
    _ensureInitialized();
    
    if (_usageHistoryBox == null) {
      return [];
    }
    
    var histories = _usageHistoryBox!.values.toList();
    
    // 特定プロンプトIDでフィルタ
    if (promptId != null) {
      histories = histories.where((h) => h.promptId == promptId).toList();
    }
    
    // 新しい順でソート
    histories.sort((a, b) => b.usedAt.compareTo(a.usedAt));
    
    // 件数制限
    if (limit != null && limit > 0) {
      histories = histories.take(limit).toList();
    }
    
    return histories;
  }
  
  @override
  List<String> getRecentlyUsedPromptIds({
    int days = 7,
    int limit = 10,
  }) {
    _ensureInitialized();
    
    if (_usageHistoryBox == null) {
      return [];
    }
    
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    final recentHistories = _usageHistoryBox!.values
        .where((h) => h.usedAt.isAfter(cutoffDate))
        .toList();
    
    // 新しい順でソート
    recentHistories.sort((a, b) => b.usedAt.compareTo(a.usedAt));
    
    // プロンプトIDを抽出（重複除去）
    final recentIds = <String>[];
    for (final history in recentHistories) {
      if (!recentIds.contains(history.promptId)) {
        recentIds.add(history.promptId);
        
        if (recentIds.length >= limit) {
          break;
        }
      }
    }
    
    return recentIds;
  }
  
  @override
  Future<bool> clearUsageHistory({int? olderThanDays}) async {
    _ensureInitialized();
    
    if (_usageHistoryBox == null) {
      return false;
    }
    
    try {
      if (olderThanDays == null) {
        // 全削除
        await _usageHistoryBox!.clear();
      } else {
        // 指定日数より古いもののみ削除
        final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));
        final keysToDelete = <int>[];
        
        for (int i = 0; i < _usageHistoryBox!.length; i++) {
          final history = _usageHistoryBox!.getAt(i);
          if (history != null && history.usedAt.isBefore(cutoffDate)) {
            keysToDelete.add(i);
          }
        }
        
        // 後ろから削除（インデックスのずれを防ぐため）
        for (final key in keysToDelete.reversed) {
          await _usageHistoryBox!.deleteAt(key);
        }
      }
      
      final loggingService = await ServiceLocator().getAsync<LoggingService>();
      loggingService.info('PromptService: 使用履歴クリア完了');
      
      return true;
    } catch (e) {
      final loggingService = await ServiceLocator().getAsync<LoggingService>();
      loggingService.error('PromptService: 使用履歴クリア失敗', error: e);
      return false;
    }
  }
  
  @override
  Map<String, int> getUsageFrequencyStats({int days = 30}) {
    _ensureInitialized();
    
    if (_usageHistoryBox == null) {
      return {};
    }
    
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final stats = <String, int>{};
    
    for (final history in _usageHistoryBox!.values) {
      if (history.usedAt.isAfter(cutoffDate)) {
        stats[history.promptId] = (stats[history.promptId] ?? 0) + 1;
      }
    }
    
    return stats;
  }
  
  /// 初期化チェック
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('PromptService が初期化されていません。initialize() を呼び出してください。');
    }
  }
}