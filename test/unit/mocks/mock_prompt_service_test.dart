// MockPromptService実装とテスト
//
// PromptServiceのモック実装とテストユーティリティ
// 他のサービスやUIテスト時の依存関係モックに使用

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/services/interfaces/prompt_service_interface.dart';
import 'package:smart_photo_diary/models/writing_prompt.dart';

/// PromptServiceのモック実装
/// 
/// テスト用の固定データとシンプルなロジックを提供
class MockPromptService implements IPromptService {
  bool _isInitialized = false;
  final List<WritingPrompt> _mockPrompts = [];
  
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
        category: PromptCategory.daily,
        isPremiumOnly: false,
        tags: ['日常', '気分', '今日'],
        description: 'テスト用基本日常プロンプト',
        priority: 80,
        isActive: true,
      ),
      WritingPrompt(
        id: 'mock_basic_gratitude_001',
        text: '今日感謝したいことは何ですか？',
        category: PromptCategory.gratitude,
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
        category: PromptCategory.travel,
        isPremiumOnly: true,
        tags: ['旅行', '印象', '瞬間'],
        description: 'テスト用Premium旅行プロンプト',
        priority: 90,
        isActive: true,
      ),
      WritingPrompt(
        id: 'mock_premium_work_001',
        text: '今日の仕事で成果を感じた瞬間は？',
        category: PromptCategory.work,
        isPremiumOnly: true,
        tags: ['仕事', '成果', '達成感'],
        description: 'テスト用Premium仕事プロンプト',
        priority: 85,
        isActive: true,
      ),
      WritingPrompt(
        id: 'mock_premium_reflection_001',
        text: '最近の自分の成長を振り返ってみてください',
        category: PromptCategory.reflection,
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
  }) {
    _ensureInitialized();
    
    final candidates = category != null
        ? getPromptsByCategory(category, isPremium: isPremium)
        : getPromptsForPlan(isPremium: isPremium);
    
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
  
  /// テスト用のヘルパーメソッド
  void addMockPrompt(WritingPrompt prompt) {
    _mockPrompts.add(prompt);
  }
  
  void clearMockPrompts() {
    _mockPrompts.clear();
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
      
      final dailyPrompts = mockService.getPromptsByCategory(
        PromptCategory.daily,
        isPremium: false,
      );
      
      expect(dailyPrompts.length, 1);
      expect(dailyPrompts.first.category, PromptCategory.daily);
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
      expect(stats[PromptCategory.daily], 1);
      expect(stats[PromptCategory.gratitude], 1);
      expect(stats[PromptCategory.travel], 1);
    });
    
    test('カスタムプロンプトデータで初期化できる', () async {
      final customPrompts = [
        WritingPrompt(
          id: 'custom_001',
          text: 'カスタムプロンプト',
          category: PromptCategory.daily,
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
  });
}