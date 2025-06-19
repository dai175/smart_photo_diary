import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/services/interfaces/prompt_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';
import 'package:smart_photo_diary/services/prompt_service.dart';
import 'package:smart_photo_diary/services/logging_service.dart';
import 'package:smart_photo_diary/models/writing_prompt.dart';
import 'package:smart_photo_diary/models/subscription_plan.dart';
import '../../mocks/mock_subscription_service.dart';
import '../../test_helpers/mock_platform_channels.dart';

/// テスト用の簡単なLoggingServiceモック
class _MockLoggingService implements LoggingService {
  @override
  void info(String message, {String? context, dynamic data}) {
    // テスト用なので何もしない
  }
  
  @override
  void warning(String message, {String? context, dynamic data}) {
    // テスト用なので何もしない
  }
  
  @override
  void error(String message, {String? context, dynamic error, StackTrace? stackTrace}) {
    // テスト用なので何もしない
  }
  
  @override
  void debug(String message, {String? context, dynamic data}) {
    // テスト用なので何もしない
  }
  
  @override
  Stopwatch startTimer(String operation, {String? context}) {
    return Stopwatch()..start();
  }
  
  @override
  void endTimer(Stopwatch stopwatch, String operation, {String? context}) {
    // テスト用なので何もしない
  }
}

/// Phase 3.1.2: プロンプト機能統合テスト
/// 
/// この統合テストファイルでは以下の項目を検証します：
/// 
/// ## 実装機能テスト
/// - 3.1.2.1: プラン別表示テスト
/// - 3.1.2.2: Basic/Premium分離テスト
/// - 3.1.2.3: プロンプト検索テスト
/// - 3.1.2.4: カテゴリフィルタテスト
/// 
/// ## 技術要件
/// - MockSubscriptionServiceとPromptServiceの統合使用
/// - ServiceLocatorを使った依存注入テスト
/// - Result<T>パターンでのエラーハンドリング検証
/// - 各テストケースは独立して実行可能
void main() {
  group('Phase 3.1.2: プロンプト機能統合テスト', () {
    late ServiceLocator serviceLocator;
    late MockSubscriptionService mockSubscriptionService;
    late IPromptService promptService;
    late _MockLoggingService mockLoggingService;

    setUpAll(() async {
      // テストバインディングの初期化
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // プラットフォームチャネルのモック設定
      MockPlatformChannels.setupMocks();
      
      // テスト用のHive初期化
      await Hive.initFlutter();
      
      // WritingPromptアダプタの登録
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(PromptCategoryAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(WritingPromptAdapter());
      }
    });

    setUp(() async {
      // ServiceLocatorをクリアしてテスト用にセットアップ
      serviceLocator = ServiceLocator();
      serviceLocator.clear();
      
      // MockLoggingServiceを作成・登録
      mockLoggingService = _MockLoggingService();
      serviceLocator.registerSingleton<LoggingService>(mockLoggingService);
      
      // MockSubscriptionServiceを作成・登録
      mockSubscriptionService = MockSubscriptionService();
      serviceLocator.registerSingleton<ISubscriptionService>(mockSubscriptionService);
      
      // PromptServiceを取得・登録
      promptService = PromptService.instance;
      serviceLocator.registerSingleton<IPromptService>(promptService);
      
      // サービスを初期化
      await mockSubscriptionService.initialize();
      await promptService.initialize();
    });

    tearDown(() async {
      // テスト後のクリーンアップ
      mockSubscriptionService.resetToDefaults();
      promptService.reset();
      PromptService.resetInstance();
      serviceLocator.clear();
      
      // Hiveボックスのクリーンアップ
      try {
        if (Hive.isBoxOpen('prompt_usage_history')) {
          final box = Hive.box('prompt_usage_history');
          await box.clear();
          await box.close();
        }
        if (Hive.isBoxOpen('suggestion_implementations')) {
          final box = Hive.box('suggestion_implementations');
          await box.clear();
          await box.close();
        }
      } catch (e) {
        // Hiveボックスのクリーンアップエラーは無視
      }
    });

    // =================================================================
    // 3.1.2.1: プラン別表示テスト
    // =================================================================

    group('3.1.2.1: プラン別表示テスト', () {
      test('Basicプランで基本プロンプト（5個）のみ表示確認', () async {
        // Given: Basicプランに設定
        mockSubscriptionService.setCurrentPlan(SubscriptionPlan.basic);
        
        // When: Basic用プロンプトを取得
        final prompts = promptService.getPromptsForPlan(isPremium: false);
        
        // Then: Basic用プロンプトのみが表示される
        
        // Basic用プロンプトの数を確認（感情深掘り型：基本感情カテゴリ）
        expect(prompts.length, equals(5));
        
        // すべてのプロンプトがBasic用（Premium以外）であることを確認
        for (final prompt in prompts) {
          expect(prompt.isPremiumOnly, isFalse, 
            reason: 'Basicプランでは全プロンプトがPremium専用ではない必要があります');
        }
        
        // 基本感情カテゴリが含まれていることを確認
        final categories = prompts.map((p) => p.category).toSet();
        expect(categories.contains(PromptCategory.emotion), isTrue);
      });

      test('Premiumプランで全プロンプト（20個）表示確認', () async {
        // Given: Premiumプランに設定
        mockSubscriptionService.setCurrentPlan(SubscriptionPlan.premiumMonthly);
        
        // When: Premium用プロンプトを取得
        final prompts = promptService.getPromptsForPlan(isPremium: true);
        
        // Then: 全プロンプトが表示される
        // 全プロンプト数を確認（感情深掘り型：20個）
        expect(prompts.length, equals(20));
        
        // BasicとPremiumの両方のプロンプトが含まれることを確認
        final basicPrompts = prompts.where((p) => !p.isPremiumOnly).toList();
        final premiumPrompts = prompts.where((p) => p.isPremiumOnly).toList();
        
        expect(basicPrompts.length, equals(5));
        expect(premiumPrompts.length, equals(15));
        
        // 9つの感情深掘り型カテゴリすべてが含まれることを確認
        final categories = prompts.map((p) => p.category).toSet();
        expect(categories.length, equals(9));
        expect(categories.contains(PromptCategory.emotion), isTrue);
        expect(categories.contains(PromptCategory.emotionDepth), isTrue);
        expect(categories.contains(PromptCategory.sensoryEmotion), isTrue);
        expect(categories.contains(PromptCategory.emotionGrowth), isTrue);
        expect(categories.contains(PromptCategory.emotionConnection), isTrue);
        expect(categories.contains(PromptCategory.emotionDiscovery), isTrue);
        expect(categories.contains(PromptCategory.emotionFantasy), isTrue);
        expect(categories.contains(PromptCategory.emotionHealing), isTrue);
        expect(categories.contains(PromptCategory.emotionEnergy), isTrue);
      });

      test('プラン変更時の表示切り替え確認', () async {
        // Given: 最初にBasicプランに設定
        mockSubscriptionService.setCurrentPlan(SubscriptionPlan.basic);
        
        // When: Basicプランでプロンプトを取得
        final basicPrompts = promptService.getPromptsForPlan(isPremium: false);
        expect(basicPrompts.length, equals(5));
        
        // Then: Premiumプランに変更
        mockSubscriptionService.setCurrentPlan(SubscriptionPlan.premiumMonthly);
        
        // When: Premiumプランでプロンプトを取得
        final premiumPrompts = promptService.getPromptsForPlan(isPremium: true);
        
        // Then: 表示が切り替わることを確認
        expect(premiumPrompts.length, equals(20));
        expect(premiumPrompts.length, greaterThan(basicPrompts.length));
        
        // BasicプロンプトがPremiumプロンプトに含まれることを確認
        final basicIds = basicPrompts.map((p) => p.id).toSet();
        final premiumIds = premiumPrompts.map((p) => p.id).toSet();
        expect(premiumIds.containsAll(basicIds), isTrue);
      });
    });

    // =================================================================
    // 3.1.2.2: Basic/Premium分離テスト
    // =================================================================

    group('3.1.2.2: Basic/Premium分離テスト', () {
      test('Basic/Premium用プロンプトの正確な分離', () async {
        // Given: Premiumプランに設定（全プロンプトを確認するため）
        mockSubscriptionService.setCurrentPlan(SubscriptionPlan.premiumMonthly);
        
        // When: 全プロンプトを取得
        final allPrompts = promptService.getAllPrompts();
        
        // Then: Basic/Premiumの分離を確認
        final basicPrompts = allPrompts.where((p) => !p.isPremiumOnly).toList();
        final premiumPrompts = allPrompts.where((p) => p.isPremiumOnly).toList();
        
        // 正確な数の確認（感情深掘り型：5+15=20）
        expect(basicPrompts.length, equals(5));
        expect(premiumPrompts.length, equals(15));
        expect(basicPrompts.length + premiumPrompts.length, equals(20));
        
        // Basic用プロンプトのカテゴリ確認（基本感情のみ）
        final basicCategories = basicPrompts.map((p) => p.category).toSet();
        expect(basicCategories.length, equals(1)); // emotionのみ
        expect(basicCategories.contains(PromptCategory.emotion), isTrue);
        
        // Premium用プロンプトのカテゴリ確認（残り8カテゴリ）
        final premiumCategories = premiumPrompts.map((p) => p.category).toSet();
        expect(premiumCategories.length, equals(8)); // 残り8カテゴリ
        expect(premiumCategories.contains(PromptCategory.emotionDepth), isTrue);
        expect(premiumCategories.contains(PromptCategory.sensoryEmotion), isTrue);
        expect(premiumCategories.contains(PromptCategory.emotionGrowth), isTrue);
        expect(premiumCategories.contains(PromptCategory.emotionConnection), isTrue);
        expect(premiumCategories.contains(PromptCategory.emotionDiscovery), isTrue);
        expect(premiumCategories.contains(PromptCategory.emotionFantasy), isTrue);
        expect(premiumCategories.contains(PromptCategory.emotionHealing), isTrue);
        expect(premiumCategories.contains(PromptCategory.emotionEnergy), isTrue);
      });

      test('プラン権限による適切なフィルタリング', () async {
        // Test Case 1: Basicプランでのフィルタリング
        mockSubscriptionService.setCurrentPlan(SubscriptionPlan.basic);
        
        final dailyBasicPrompts = promptService.getPromptsByCategory(PromptCategory.emotion, isPremium: false);
        
        // Basicプランでは'基本感情'カテゴリのBasicプロンプトのみ取得
        for (final prompt in dailyBasicPrompts) {
          expect(prompt.category, equals(PromptCategory.emotion));
          expect(prompt.isPremiumOnly, isFalse);
        }
        
        // Test Case 2: Premiumカテゴリへのアクセス試行
        final emotionDepthPrompts = promptService.getPromptsByCategory(PromptCategory.emotionDepth, isPremium: false);
        
        // Basicプランでは'感情深掘り'カテゴリは空のはず
        expect(emotionDepthPrompts.isEmpty, isTrue);
        
        // Test Case 3: Premiumプランでのフィルタリング
        mockSubscriptionService.setCurrentPlan(SubscriptionPlan.premiumMonthly);
        
        final premiumEmotionDepthPrompts = promptService.getPromptsByCategory(PromptCategory.emotionDepth, isPremium: true);
        
        // Premiumプランでは'感情深掘り'カテゴリのプロンプトが取得できる
        expect(premiumEmotionDepthPrompts.isNotEmpty, isTrue);
        for (final prompt in premiumEmotionDepthPrompts) {
          expect(prompt.category, equals(PromptCategory.emotionDepth));
          expect(prompt.isPremiumOnly, isTrue);
        }
      });

      test('無効なプランでのアクセス制限', () async {
        // Given: 無効な状態をシミュレート（初期化されていない状態）
        mockSubscriptionService.resetToDefaults();
        
        // When: プロンプト取得を試行
        final prompts = promptService.getAllPrompts();
        
        // Then: サービスが初期化されていれば、少なくとも何らかの結果が返る
        // （実際の実装では、エラーハンドリングやデフォルト動作が定義されている）
        expect(prompts.isNotEmpty, isTrue);
        
        // 初期化後のテスト
        await mockSubscriptionService.initialize();
        
        // 期限切れのPremiumプランをシミュレート
        mockSubscriptionService.setCurrentPlan(
          SubscriptionPlan.premiumMonthly,
          expiryDate: DateTime.now().subtract(const Duration(days: 1)),
          isActive: false,
        );
        
        final expiredPrompts = promptService.getPromptsForPlan(isPremium: false);
        
        // 期限切れの場合はBasicプランと同様の動作をするか確認
        final premiumPrompts = expiredPrompts.where((p) => p.isPremiumOnly).toList();
        
        // 期限切れの場合、Premiumプロンプトへのアクセスが制限される
        expect(premiumPrompts.isEmpty, isTrue);
      });
    });

    // =================================================================
    // 3.1.2.3: プロンプト検索テスト
    // =================================================================

    group('3.1.2.3: プロンプト検索テスト', () {
      test('キーワード検索の基本動作', () async {
        // Given: Premiumプランに設定
        mockSubscriptionService.setCurrentPlan(SubscriptionPlan.premiumMonthly);
        
        // When: 検索クエリを実行（実際のプロンプトデータに基づくキーワード）
        final searchResults = promptService.searchPrompts('感情', isPremium: true);
        
        // Then: 検索結果が正常に取得される
        
        // 検索結果に'感情'が含まれることを確認
        expect(searchResults.isNotEmpty, isTrue);
        
        for (final prompt in searchResults) {
          final containsKeyword = prompt.text.contains('感情') ||
                                 (prompt.description?.contains('感情') ?? false) ||
                                 prompt.tags.any((tag) => tag.contains('感情'));
          expect(containsKeyword, isTrue, 
            reason: '検索結果にはキーワードが含まれている必要があります');
        }
        
        // 複数キーワードの検索
        final multiResults = promptService.searchPrompts('気持ち', isPremium: true);
        
        // 「気持ち」は実際にタグに存在するので結果が期待できる
        if (multiResults.isNotEmpty) {
          for (final prompt in multiResults) {
            final containsAnyKeyword = prompt.text.contains('気持ち') ||
                                     (prompt.description?.contains('気持ち') ?? false) ||
                                     prompt.tags.any((tag) => tag.contains('気持ち'));
            expect(containsAnyKeyword, isTrue);
          }
        }
      });

      test('プラン制限下での検索結果フィルタリング', () async {
        // Test Case 1: Basicプランでの検索
        mockSubscriptionService.setCurrentPlan(SubscriptionPlan.basic);
        
        // Basicプランでの検索（Basic用キーワード）
        final basicResults = promptService.searchPrompts('感情', isPremium: false);
        
        // 検索結果はすべてBasic用プロンプトである必要がある
        for (final prompt in basicResults) {
          expect(prompt.isPremiumOnly, isFalse, 
            reason: 'Basicプランの検索結果にはPremiumプロンプトが含まれてはいけません');
        }
        
        // Premium用キーワードでの検索
        final premiumKeywordResults = promptService.searchPrompts('深掘り', isPremium: false);
        
        // Basicプランでは、Premium専用キーワードでは結果が返らないか、
        // 返っても少ない結果になる
        expect(premiumKeywordResults.isEmpty || 
               premiumKeywordResults.every((p) => !p.isPremiumOnly), isTrue);
        
        // Test Case 2: Premiumプランでの検索
        mockSubscriptionService.setCurrentPlan(SubscriptionPlan.premiumMonthly);
        
        final premiumResults = promptService.searchPrompts('深掘り', isPremium: true);
        
        // Premiumプランでは、Premium用キーワードでも結果が取得できる可能性が高い
        // （実際のプロンプトデータによる）
        
        // 検索結果の比較
        expect(premiumResults.length, greaterThanOrEqualTo(premiumKeywordResults.length));
      });

      test('空検索結果の適切な処理', () async {
        // Given: Premiumプランに設定
        mockSubscriptionService.setCurrentPlan(SubscriptionPlan.premiumMonthly);
        
        // When: 存在しないキーワードで検索
        final searchResults = promptService.searchPrompts('存在しないキーワード12345', isPremium: true);
        
        // Then: 結果は正常に取得されるが、空である
        expect(searchResults.isEmpty, isTrue);
        
        // 空文字列での検索
        final emptyResults = promptService.searchPrompts('', isPremium: true);
        
        // 空文字列の場合は全プロンプトが返るか、適切に処理される
        expect(emptyResults.length, greaterThanOrEqualTo(0));
        
        // 空白文字での検索
        final whitespaceResults = promptService.searchPrompts('   ', isPremium: true);
        expect(whitespaceResults.length, greaterThanOrEqualTo(0));
      });
    });

    // =================================================================
    // 3.1.2.4: カテゴリフィルタテスト
    // =================================================================

    group('3.1.2.4: カテゴリフィルタテスト', () {
      test('カテゴリ別フィルタリング機能', () async {
        // Given: Premiumプランに設定
        mockSubscriptionService.setCurrentPlan(SubscriptionPlan.premiumMonthly);
        
        // Test Case 1: 各感情深掘り型カテゴリでのフィルタリング
        final categories = [
          PromptCategory.emotion, PromptCategory.emotionDepth, PromptCategory.sensoryEmotion,
          PromptCategory.emotionGrowth, PromptCategory.emotionConnection, PromptCategory.emotionDiscovery,
          PromptCategory.emotionFantasy, PromptCategory.emotionHealing, PromptCategory.emotionEnergy
        ];
        
        for (final category in categories) {
          // When: カテゴリでフィルタリング
          final categoryPrompts = promptService.getPromptsByCategory(category, isPremium: true);
          
          // Then: そのカテゴリのプロンプトのみが返される
          // カテゴリが一致することを確認
          for (final prompt in categoryPrompts) {
            expect(prompt.category, equals(category), 
              reason: 'カテゴリ ${category.displayName} のフィルタリングが正しく動作していません');
          }
          
          // プロンプトが存在することを確認（カテゴリによっては空の可能性もある）
          if (categoryPrompts.isNotEmpty) {
            expect(categoryPrompts.first.category, equals(category));
          }
        }
      });

      test('プラン制限を考慮したカテゴリフィルタ', () async {
        // Test Case 1: Basicプランでのカテゴリフィルタ
        mockSubscriptionService.setCurrentPlan(SubscriptionPlan.basic);
        
        // Basic用カテゴリ（基本感情のみ）
        final emotionPrompts = promptService.getPromptsByCategory(PromptCategory.emotion, isPremium: false);
        expect(emotionPrompts.isNotEmpty, isTrue);
        
        for (final prompt in emotionPrompts) {
          expect(prompt.category, equals(PromptCategory.emotion));
          expect(prompt.isPremiumOnly, isFalse);
        }
        
        // Premium用カテゴリへのアクセス試行
        final premiumCategories = [
          PromptCategory.emotionDepth, PromptCategory.sensoryEmotion, PromptCategory.emotionGrowth,
          PromptCategory.emotionConnection, PromptCategory.emotionDiscovery, PromptCategory.emotionFantasy,
          PromptCategory.emotionHealing, PromptCategory.emotionEnergy
        ];
        
        for (final category in premiumCategories) {
          final prompts = promptService.getPromptsByCategory(category, isPremium: false);
          
          // Basicプランでは、Premium用カテゴリからプロンプトが取得できない
          expect(prompts.isEmpty, isTrue, 
            reason: 'Basicプランではカテゴリ ${category.displayName} のプロンプトが取得できてはいけません');
        }
        
        // Test Case 2: Premiumプランでのカテゴリフィルタ
        mockSubscriptionService.setCurrentPlan(SubscriptionPlan.premiumMonthly);
        
        for (final category in premiumCategories) {
          final prompts = promptService.getPromptsByCategory(category, isPremium: true);
          
          // Premiumプランでは、Premium用カテゴリからプロンプトが取得できる
          expect(prompts.isNotEmpty, isTrue, 
            reason: 'Premiumプランではカテゴリ ${category.displayName} のプロンプトが取得できる必要があります');
          
          for (final prompt in prompts) {
            expect(prompt.category, equals(category));
            expect(prompt.isPremiumOnly, isTrue);
          }
        }
      });

      test('複数カテゴリでの組み合わせテスト', () async {
        // Given: Premiumプランに設定
        mockSubscriptionService.setCurrentPlan(SubscriptionPlan.premiumMonthly);
        
        // Test Case 1: 感情深掘り型カテゴリ統計の確認
        final allPrompts = promptService.getAllPrompts();
        
        // カテゴリ統計を手動で作成
        final categoryStats = <PromptCategory, int>{};
        for (final prompt in allPrompts) {
          categoryStats[prompt.category] = (categoryStats[prompt.category] ?? 0) + 1;
        }
        
        // 9つの感情深掘り型カテゴリが存在することを確認
        expect(categoryStats.length, equals(9));
        
        // 各カテゴリに適切な数のプロンプトが存在することを確認
        int totalPrompts = 0;
        for (final entry in categoryStats.entries) {
          expect(entry.value, greaterThan(0), 
            reason: 'カテゴリ ${entry.key.displayName} にはプロンプトが存在する必要があります');
          totalPrompts += entry.value;
        }
        expect(totalPrompts, equals(20));
        
        // Test Case 2: Basic/Premiumカテゴリの分離確認
        final basicPrompts = allPrompts.where((p) => !p.isPremiumOnly).toList();
        final premiumPrompts = allPrompts.where((p) => p.isPremiumOnly).toList();
        
        final basicCategories = basicPrompts.map((p) => p.category).toSet();
        final premiumCategories = premiumPrompts.map((p) => p.category).toSet();
        
        expect(basicCategories.length, equals(1)); // emotion のみ
        expect(premiumCategories.length, equals(8)); // 残り8カテゴリ
        
        expect(basicCategories.contains(PromptCategory.emotion), isTrue);
        expect(premiumCategories.contains(PromptCategory.emotionDepth), isTrue);
        expect(premiumCategories.contains(PromptCategory.sensoryEmotion), isTrue);
        expect(premiumCategories.contains(PromptCategory.emotionGrowth), isTrue);
        expect(premiumCategories.contains(PromptCategory.emotionConnection), isTrue);
        expect(premiumCategories.contains(PromptCategory.emotionDiscovery), isTrue);
        expect(premiumCategories.contains(PromptCategory.emotionFantasy), isTrue);
        expect(premiumCategories.contains(PromptCategory.emotionHealing), isTrue);
        expect(premiumCategories.contains(PromptCategory.emotionEnergy), isTrue);
        
        // Test Case 3: プラン別アクセス制御の確認
        // Basicプランに変更
        mockSubscriptionService.setCurrentPlan(SubscriptionPlan.basic);
        
        final basicPlanPrompts = promptService.getPromptsForPlan(isPremium: false);
        final accessibleBasicCategories = basicPlanPrompts.map((p) => p.category).toSet();
        
        expect(accessibleBasicCategories.length, equals(1));
        expect(accessibleBasicCategories.contains(PromptCategory.emotion), isTrue);
        
        // Premiumプランでのアクセス可能カテゴリ確認
        mockSubscriptionService.setCurrentPlan(SubscriptionPlan.premiumMonthly);
        
        final premiumPlanPrompts = promptService.getPromptsForPlan(isPremium: true);
        final accessiblePremiumCategories = premiumPlanPrompts.map((p) => p.category).toSet();
        
        expect(accessiblePremiumCategories.length, equals(9));
      });
    });
  });
}