// MockPromptService実装とテスト
//
// PromptServiceのモック実装とテストユーティリティ
// 他のサービスやUIテスト時の依存関係モックに使用

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/services/interfaces/prompt_service_interface.dart';
import 'package:smart_photo_diary/models/writing_prompt.dart';
import 'package:smart_photo_diary/services/analytics/prompt_usage_analytics.dart';
import 'package:smart_photo_diary/services/analytics/category_popularity_reporter.dart';
import 'package:smart_photo_diary/services/analytics/user_behavior_analyzer.dart';
import 'package:smart_photo_diary/services/analytics/improvement_suggestion_tracker.dart';

/// PromptServiceのモック実装
/// 
/// テスト用の固定データとシンプルなロジックを提供
class MockPromptService implements IPromptService {
  bool _isInitialized = false;
  final List<WritingPrompt> _mockPrompts = [];
  final List<PromptUsageHistory> _mockUsageHistory = [];
  final List<SuggestionImplementationRecord> _mockSuggestionImplementations = [];
  
  /// 初期化時に呼び出される設定用データ
  final List<WritingPrompt>? initialPrompts;
  
  MockPromptService({this.initialPrompts}) {
    if (initialPrompts != null) {
      _mockPrompts.addAll(initialPrompts!);
    } else {
      _setupDefaultMockData();
    }
  }
  
  /// デフォルトのモックデータを設定
  void _setupDefaultMockData() {
    _mockPrompts.addAll([
      // Basic用プロンプト
      WritingPrompt(
        id: 'mock_basic_daily_001',
        text: '今日の気分はいかがですか？',
        category: PromptCategory.emotion,
        isPremiumOnly: false,
        tags: ['日常', '気分', '今日'],
        description: 'テスト用基本日常プロンプト',
        priority: 80,
        isActive: true,
      ),
      WritingPrompt(
        id: 'mock_basic_gratitude_001',
        text: '今日感謝したいことは何ですか？',
        category: PromptCategory.emotion,
        isPremiumOnly: false,
        tags: ['感謝', '今日', 'ありがとう'],
        description: 'テスト用基本感謝プロンプト',
        priority: 85,
        isActive: true,
      ),
      
      // Premium用プロンプト
      WritingPrompt(
        id: 'mock_premium_travel_001',
        text: 'この旅行で一番印象に残った瞬間は？',
        category: PromptCategory.emotionDepth,
        isPremiumOnly: true,
        tags: ['旅行', '印象', '瞬間'],
        description: 'テスト用Premium旅行プロンプト',
        priority: 90,
        isActive: true,
      ),
      WritingPrompt(
        id: 'mock_premium_work_001',
        text: '今日の仕事で成果を感じた瞬間は？',
        category: PromptCategory.emotionGrowth,
        isPremiumOnly: true,
        tags: ['仕事', '成果', '達成感'],
        description: 'テスト用Premium仕事プロンプト',
        priority: 85,
        isActive: true,
      ),
      WritingPrompt(
        id: 'mock_premium_reflection_001',
        text: '最近の自分の成長を振り返ってみてください',
        category: PromptCategory.emotionDiscovery,
        isPremiumOnly: true,
        tags: ['振り返り', '成長', '自己分析'],
        description: 'テスト用Premium振り返りプロンプト',
        priority: 95,
        isActive: true,
      ),
    ]);
  }
  
  @override
  bool get isInitialized => _isInitialized;
  
  @override
  Future<bool> initialize() async {
    _isInitialized = true;
    return true;
  }
  
  @override
  List<WritingPrompt> getAllPrompts() {
    _ensureInitialized();
    return List.unmodifiable(_mockPrompts.where((p) => p.isActive));
  }
  
  @override
  List<WritingPrompt> getPromptsForPlan({required bool isPremium}) {
    _ensureInitialized();
    
    return _mockPrompts
        .where((p) => p.isActive && p.isAvailableForPlan(isPremium: isPremium))
        .toList();
  }
  
  @override
  List<WritingPrompt> getPromptsByCategory(
    PromptCategory category, {
    required bool isPremium,
  }) {
    _ensureInitialized();
    
    return _mockPrompts
        .where((p) => 
            p.isActive && 
            p.category == category && 
            p.isAvailableForPlan(isPremium: isPremium)
        )
        .toList();
  }
  
  @override
  WritingPrompt? getRandomPrompt({
    required bool isPremium,
    PromptCategory? category,
    List<String>? excludeIds,
  }) {
    _ensureInitialized();
    
    List<WritingPrompt> candidates = category != null
        ? getPromptsByCategory(category, isPremium: isPremium)
        : getPromptsForPlan(isPremium: isPremium);
    
    // 除外IDを適用
    if (excludeIds != null && excludeIds.isNotEmpty) {
      candidates = candidates.where((prompt) => !excludeIds.contains(prompt.id)).toList();
    }
    
    if (candidates.isEmpty) return null;
    
    // テスト用シンプルな選択：最初の要素を返す
    return candidates.first;
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
      return prompt.text.toLowerCase().contains(lowerQuery) ||
          prompt.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
          (prompt.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
  
  @override
  WritingPrompt? getPromptById(String id) {
    _ensureInitialized();
    
    try {
      return _mockPrompts.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
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
    // モック実装では特に何もしない
  }
  
  @override
  void reset() {
    _isInitialized = false;
    // プロンプトデータはリセットしない（テスト間で一貫性を保つため）
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
    
    List<WritingPrompt> candidates = category != null
        ? getPromptsByCategory(category, isPremium: isPremium)
        : getPromptsForPlan(isPremium: isPremium);
    
    if (candidates.isEmpty) {
      return [];
    }
    
    // テスト用シンプルな実装：要求数か利用可能数の小さい方を返す
    final actualCount = count > candidates.length ? candidates.length : count;
    return candidates.take(actualCount).toList();
  }
  
  @override
  Future<bool> recordPromptUsage({
    required String promptId,
    String? diaryEntryId,
    bool wasHelpful = true,
  }) async {
    _ensureInitialized();
    
    final usage = PromptUsageHistory(
      promptId: promptId,
      diaryEntryId: diaryEntryId,
      wasHelpful: wasHelpful,
    );
    
    _mockUsageHistory.add(usage);
    return true;
  }
  
  @override
  List<PromptUsageHistory> getUsageHistory({
    int? limit,
    String? promptId,
  }) {
    _ensureInitialized();
    
    var histories = _mockUsageHistory.where((h) => true).toList();
    
    if (promptId != null) {
      histories = histories.where((h) => h.promptId == promptId).toList();
    }
    
    histories.sort((a, b) => b.usedAt.compareTo(a.usedAt));
    
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
    
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final recentIds = <String>[];
    
    final sortedHistory = _mockUsageHistory
        .where((h) => h.usedAt.isAfter(cutoffDate))
        .toList();
    
    sortedHistory.sort((a, b) => b.usedAt.compareTo(a.usedAt));
    
    for (final history in sortedHistory) {
      if (!recentIds.contains(history.promptId)) {
        recentIds.add(history.promptId);
        if (recentIds.length >= limit) break;
      }
    }
    
    return recentIds;
  }
  
  @override
  Future<bool> clearUsageHistory({int? olderThanDays}) async {
    _ensureInitialized();
    
    if (olderThanDays == null) {
      _mockUsageHistory.clear();
    } else {
      final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));
      _mockUsageHistory.removeWhere((h) => h.usedAt.isBefore(cutoffDate));
    }
    
    return true;
  }
  
  @override
  Map<String, int> getUsageFrequencyStats({int days = 30}) {
    _ensureInitialized();
    
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final stats = <String, int>{};
    
    for (final history in _mockUsageHistory) {
      if (history.usedAt.isAfter(cutoffDate)) {
        stats[history.promptId] = (stats[history.promptId] ?? 0) + 1;
      }
    }
    
    return stats;
  }
  
  @override
  PromptFrequencyAnalysis analyzePromptFrequency({int days = 30}) {
    _ensureInitialized();
    
    final usageData = getUsageFrequencyStats(days: days);
    
    return PromptUsageAnalytics.analyzePromptFrequency(
      usageData: usageData,
      periodDays: days,
      allPrompts: _mockPrompts,
    );
  }
  
  @override
  CategoryPopularityAnalysis analyzeCategoryPopularity({
    int days = 30,
    bool isPremium = false,
    bool comparePreviousPeriod = true,
  }) {
    _ensureInitialized();
    
    final usageData = getUsageFrequencyStats(days: days);
    final availablePrompts = getPromptsForPlan(isPremium: isPremium);
    
    // モック用の前期間データ（空）
    Map<String, int>? previousPeriodData;
    if (comparePreviousPeriod) {
      previousPeriodData = <String, int>{};
    }
    
    return PromptUsageAnalytics.analyzeCategoryPopularity(
      usageData: usageData,
      allPrompts: availablePrompts,
      previousPeriodData: previousPeriodData,
    );
  }
  
  @override
  UserBehaviorAnalysis analyzeUserBehavior({int days = 30}) {
    _ensureInitialized();
    
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final recentHistory = _mockUsageHistory
        .where((history) => history.usedAt.isAfter(cutoffDate))
        .toList();
    
    return PromptUsageAnalytics.analyzeUserBehavior(
      usageHistory: recentHistory,
    );
  }
  
  @override
  List<PromptImprovementSuggestion> generateImprovementSuggestions({
    int days = 30,
    bool isPremium = false,
  }) {
    _ensureInitialized();
    
    final frequencyAnalysis = analyzePromptFrequency(days: days);
    final categoryAnalysis = analyzeCategoryPopularity(
      days: days,
      isPremium: isPremium,
    );
    final behaviorAnalysis = analyzeUserBehavior(days: days);
    final availablePrompts = getPromptsForPlan(isPremium: isPremium);
    
    return PromptUsageAnalytics.generateImprovementSuggestions(
      frequencyAnalysis: frequencyAnalysis,
      categoryAnalysis: categoryAnalysis,
      behaviorAnalysis: behaviorAnalysis,
      allPrompts: availablePrompts,
    );
  }
  
  @override
  CategoryPopularityReport generateCategoryReport({
    int days = 30,
    bool isPremium = false,
  }) {
    _ensureInitialized();
    
    final analysis = analyzeCategoryPopularity(
      days: days,
      isPremium: isPremium,
      comparePreviousPeriod: true,
    );
    
    return CategoryPopularityReporter.generateDetailedReport(
      analysis: analysis,
      periodDays: days,
    );
  }
  
  @override
  String getCategoryUsageSummary({
    int days = 30,
    bool isPremium = false,
  }) {
    _ensureInitialized();
    
    final analysis = analyzeCategoryPopularity(
      days: days,
      isPremium: isPremium,
      comparePreviousPeriod: false,
    );
    
    return CategoryPopularityReporter.generateQuickSummary(analysis);
  }
  
  @override
  List<CategoryRankingItem> getCategoryRanking({
    int days = 30,
    bool isPremium = false,
    int topN = 5,
  }) {
    _ensureInitialized();
    
    final analysis = analyzeCategoryPopularity(
      days: days,
      isPremium: isPremium,
      comparePreviousPeriod: false,
    );
    
    return CategoryPopularityReporter.getCategoryRanking(
      analysis: analysis,
      topN: topN,
    );
  }

  @override
  DetailedBehaviorAnalysis analyzeDetailedUserBehavior({
    int days = 30,
    bool isPremium = false,
  }) {
    _ensureInitialized();
    
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final recentHistory = _mockUsageHistory
        .where((history) => history.usedAt.isAfter(cutoffDate))
        .toList();
    
    final availablePrompts = getPromptsForPlan(isPremium: isPremium);
    
    return UserBehaviorAnalyzer.analyzeDetailedBehavior(
      usageHistory: recentHistory,
      availablePrompts: availablePrompts,
    );
  }

  @override
  Future<bool> saveSuggestionImplementation(SuggestionImplementationRecord record) async {
    _ensureInitialized();
    
    _mockSuggestionImplementations.add(record);
    return true;
  }

  @override
  List<SuggestionImplementationRecord> getSuggestionImplementations({
    int? limit,
    PersonalizationType? suggestionType,
  }) {
    _ensureInitialized();
    
    var implementations = _mockSuggestionImplementations.where((impl) => true).toList();
    
    // 特定提案タイプでフィルタ
    if (suggestionType != null) {
      implementations = implementations.where((impl) => impl.suggestionType == suggestionType).toList();
    }
    
    // 新しい順でソート
    implementations.sort((a, b) => b.implementedAt.compareTo(a.implementedAt));
    
    // 件数制限
    if (limit != null && limit > 0) {
      implementations = implementations.take(limit).toList();
    }
    
    return implementations;
  }

  @override
  SuggestionEffectivenessAnalysis analyzeSuggestionEffectiveness({int days = 90}) {
    _ensureInitialized();
    
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final recentImplementations = _mockSuggestionImplementations
        .where((impl) => impl.implementedAt.isAfter(cutoffDate))
        .toList();
    
    return ImprovementSuggestionTracker.analyzeEffectiveness(
      implementations: recentImplementations,
    );
  }

  @override
  UserFeedbackAnalysis analyzeUserFeedback({int days = 90}) {
    _ensureInitialized();
    
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final recentImplementations = _mockSuggestionImplementations
        .where((impl) => impl.implementedAt.isAfter(cutoffDate))
        .toList();
    
    return ImprovementSuggestionTracker.analyzeFeedback(
      implementations: recentImplementations,
    );
  }

  @override
  ContinuousImprovementData generateContinuousImprovementData({int days = 90}) {
    _ensureInitialized();
    
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final recentImplementations = _mockSuggestionImplementations
        .where((impl) => impl.implementedAt.isAfter(cutoffDate))
        .toList();
    
    final effectivenessAnalysis = ImprovementSuggestionTracker.analyzeEffectiveness(
      implementations: recentImplementations,
    );
    
    final feedbackAnalysis = ImprovementSuggestionTracker.analyzeFeedback(
      implementations: recentImplementations,
    );
    
    return ImprovementSuggestionTracker.generateContinuousImprovementData(
      effectivenessAnalysis: effectivenessAnalysis,
      feedbackAnalysis: feedbackAnalysis,
      implementations: recentImplementations,
    );
  }
  
  /// テスト用のヘルパーメソッド
  void addMockPrompt(WritingPrompt prompt) {
    _mockPrompts.add(prompt);
  }
  
  void clearMockPrompts() {
    _mockPrompts.clear();
  }
  
  void addMockUsageHistory(PromptUsageHistory history) {
    _mockUsageHistory.add(history);
  }
  
  void clearMockUsageHistory() {
    _mockUsageHistory.clear();
  }
  
  void addMockSuggestionImplementation(SuggestionImplementationRecord implementation) {
    _mockSuggestionImplementations.add(implementation);
  }
  
  void clearMockSuggestionImplementations() {
    _mockSuggestionImplementations.clear();
  }
  
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('MockPromptService が初期化されていません');
    }
  }
}

void main() {
  group('MockPromptService', () {
    late MockPromptService mockService;
    
    setUp(() {
      mockService = MockPromptService();
    });
    
    test('初期化が正常に動作する', () async {
      expect(mockService.isInitialized, false);
      
      final result = await mockService.initialize();
      
      expect(result, true);
      expect(mockService.isInitialized, true);
    });
    
    test('デフォルトモックデータが設定される', () async {
      await mockService.initialize();
      
      final allPrompts = mockService.getAllPrompts();
      expect(allPrompts, isNotEmpty);
      expect(allPrompts.length, 5); // デフォルトで5個のプロンプト
    });
    
    test('Basicプラン用プロンプトが正しくフィルタリングされる', () async {
      await mockService.initialize();
      
      final basicPrompts = mockService.getPromptsForPlan(isPremium: false);
      
      expect(basicPrompts.length, 2); // Basic用は2個
      expect(basicPrompts.every((p) => !p.isPremiumOnly), true);
    });
    
    test('Premiumプラン用プロンプトが正しくフィルタリングされる', () async {
      await mockService.initialize();
      
      final premiumPrompts = mockService.getPromptsForPlan(isPremium: true);
      
      expect(premiumPrompts.length, 5); // 全て利用可能
    });
    
    test('カテゴリ別フィルタリングが動作する', () async {
      await mockService.initialize();
      
      final emotionPrompts = mockService.getPromptsByCategory(
        PromptCategory.emotion,
        isPremium: false,
      );
      
      expect(emotionPrompts.length, 2);
      expect(emotionPrompts.first.category, PromptCategory.emotion);
    });
    
    test('ランダム選択が動作する', () async {
      await mockService.initialize();
      
      final randomPrompt = mockService.getRandomPrompt(isPremium: true);
      
      expect(randomPrompt, isNotNull);
    });
    
    test('検索機能が動作する', () async {
      await mockService.initialize();
      
      final searchResults = mockService.searchPrompts(
        '今日',
        isPremium: true,
      );
      
      expect(searchResults, isNotEmpty);
      expect(searchResults.every((p) => p.text.contains('今日')), true);
    });
    
    test('ID検索が動作する', () async {
      await mockService.initialize();
      
      final prompt = mockService.getPromptById('mock_basic_daily_001');
      
      expect(prompt, isNotNull);
      expect(prompt!.id, 'mock_basic_daily_001');
    });
    
    test('統計情報が取得できる', () async {
      await mockService.initialize();
      
      final stats = mockService.getPromptStatistics(isPremium: true);
      
      expect(stats, isNotEmpty);
      expect(stats[PromptCategory.emotion], 2);
      expect(stats[PromptCategory.emotionDepth], 1);
      expect(stats[PromptCategory.emotionGrowth], 1);
    });
    
    test('カスタムプロンプトデータで初期化できる', () async {
      final customPrompts = [
        WritingPrompt(
          id: 'custom_001',
          text: 'カスタムプロンプト',
          category: PromptCategory.emotion,
          isPremiumOnly: false,
          tags: ['カスタム'],
          description: 'カスタムテスト',
          priority: 50,
          isActive: true,
        ),
      ];
      
      final customMockService = MockPromptService(initialPrompts: customPrompts);
      await customMockService.initialize();
      
      final prompts = customMockService.getAllPrompts();
      expect(prompts.length, 1);
      expect(prompts.first.text, 'カスタムプロンプト');
    });
    
    test('初期化前のメソッド呼び出しでエラーが発生', () {
      expect(() => mockService.getAllPrompts(), throwsStateError);
      expect(() => mockService.getPromptsForPlan(isPremium: true), throwsStateError);
    });
    
    test('除外IDを指定した重複回避が動作する', () async {
      // 初期化
      await mockService.initialize();
      
      // 最初のプロンプトを取得
      final firstPrompt = mockService.getRandomPrompt(isPremium: true);
      expect(firstPrompt, isNotNull);
      
      // 最初のプロンプトを除外して次を取得
      final secondPrompt = mockService.getRandomPrompt(
        isPremium: true,
        excludeIds: [firstPrompt!.id],
      );
      
      if (secondPrompt != null) {
        expect(secondPrompt.id, isNot(equals(firstPrompt.id)));
      }
    });
    
    test('ランダムプロンプトシーケンスが動作する', () async {
      // 初期化
      await mockService.initialize();
      
      final prompts = mockService.getRandomPromptSequence(
        count: 2,
        isPremium: true,
      );
      
      expect(prompts.length, lessThanOrEqualTo(2));
      
      // 重複チェック
      final ids = prompts.map((p) => p.id).toSet();
      expect(ids.length, equals(prompts.length));
    });
    
    test('空のシーケンス要求が正しく処理される', () async {
      // 初期化
      await mockService.initialize();
      
      final prompts = mockService.getRandomPromptSequence(
        count: 0,
        isPremium: true,
      );
      
      expect(prompts, isEmpty);
    });
    
    group('使用履歴管理', () {
      test('プロンプト使用履歴を記録できる', () async {
        await mockService.initialize();
        
        final result = await mockService.recordPromptUsage(
          promptId: 'test_prompt_001',
          diaryEntryId: 'diary_001',
          wasHelpful: true,
        );
        
        expect(result, true);
        
        final history = mockService.getUsageHistory();
        expect(history.length, 1);
        expect(history.first.promptId, 'test_prompt_001');
        expect(history.first.diaryEntryId, 'diary_001');
        expect(history.first.wasHelpful, true);
      });
      
      test('使用履歴を取得できる', () async {
        await mockService.initialize();
        
        // 複数の履歴を追加
        await mockService.recordPromptUsage(promptId: 'prompt_001');
        await mockService.recordPromptUsage(promptId: 'prompt_002');
        await mockService.recordPromptUsage(promptId: 'prompt_001');
        
        final allHistory = mockService.getUsageHistory();
        expect(allHistory.length, 3);
        
        // 特定プロンプトの履歴
        final prompt001History = mockService.getUsageHistory(promptId: 'prompt_001');
        expect(prompt001History.length, 2);
        
        // 件数制限
        final limitedHistory = mockService.getUsageHistory(limit: 2);
        expect(limitedHistory.length, 2);
      });
      
      test('最近使用したプロンプトIDを取得できる', () async {
        await mockService.initialize();
        
        // テスト用履歴を追加
        final now = DateTime.now();
        mockService.addMockUsageHistory(PromptUsageHistory(
          promptId: 'recent_001',
          usedAt: now.subtract(Duration(hours: 1)),
        ));
        mockService.addMockUsageHistory(PromptUsageHistory(
          promptId: 'recent_002',
          usedAt: now.subtract(Duration(hours: 2)),
        ));
        mockService.addMockUsageHistory(PromptUsageHistory(
          promptId: 'old_001',
          usedAt: now.subtract(Duration(days: 10)),
        ));
        
        final recentIds = mockService.getRecentlyUsedPromptIds(days: 7);
        expect(recentIds.length, 2);
        expect(recentIds, contains('recent_001'));
        expect(recentIds, contains('recent_002'));
        expect(recentIds, isNot(contains('old_001')));
      });
      
      test('使用履歴をクリアできる', () async {
        await mockService.initialize();
        
        await mockService.recordPromptUsage(promptId: 'test_prompt');
        expect(mockService.getUsageHistory().length, 1);
        
        final result = await mockService.clearUsageHistory();
        expect(result, true);
        expect(mockService.getUsageHistory(), isEmpty);
      });
      
      test('使用頻度統計を取得できる', () async {
        await mockService.initialize();
        
        // テスト用履歴を追加
        final now = DateTime.now();
        mockService.addMockUsageHistory(PromptUsageHistory(
          promptId: 'frequent_001',
          usedAt: now.subtract(Duration(days: 1)),
        ));
        mockService.addMockUsageHistory(PromptUsageHistory(
          promptId: 'frequent_001',
          usedAt: now.subtract(Duration(days: 2)),
        ));
        mockService.addMockUsageHistory(PromptUsageHistory(
          promptId: 'frequent_002',
          usedAt: now.subtract(Duration(days: 3)),
        ));
        
        final stats = mockService.getUsageFrequencyStats(days: 30);
        expect(stats['frequent_001'], 2);
        expect(stats['frequent_002'], 1);
      });
    });
  });
}