import '../models/writing_prompt.dart';
import '../utils/prompt_category_utils.dart';
import 'interfaces/logging_service_interface.dart';

/// プロンプトデータのキャッシュ構築・管理
///
/// プラン別・カテゴリ別・ID別の3種キャッシュを構築・保持する。
/// フィルタリングロジックは PromptFilterService に委譲する。
final class PromptCacheService {
  final ILoggingService _logger;

  final Map<bool, List<WritingPrompt>> _planFilterCache = {};
  final Map<PromptCategory, List<WritingPrompt>> _categoryCache = {};
  final Map<String, WritingPrompt> _idCache = {};
  bool _isBuilt = false;

  PromptCacheService({required ILoggingService logger}) : _logger = logger;

  bool get isBuilt => _isBuilt;

  /// 全プロンプトリストから3種キャッシュを一括構築する
  void build(List<WritingPrompt> prompts) {
    try {
      _planFilterCache.clear();
      _categoryCache.clear();
      _idCache.clear();

      _planFilterCache[false] = PromptCategoryUtils.filterPromptsByPlan(
        prompts,
        isPremium: false,
      );
      _planFilterCache[true] = PromptCategoryUtils.filterPromptsByPlan(
        prompts,
        isPremium: true,
      );

      for (final category in PromptCategory.values) {
        _categoryCache[category] = prompts
            .where((p) => p.category == category && p.isActive)
            .toList();
      }

      for (final prompt in prompts) {
        _idCache[prompt.id] = prompt;
      }

      _isBuilt = true;
      _logger.info('PromptCacheService: Cache build completed');
    } catch (e) {
      _logger.error('PromptCacheService: Cache build failed', error: e);
      rethrow;
    }
  }

  /// プラン別キャッシュを返す（未構築時は空リスト）
  List<WritingPrompt> getPlanCache(bool isPremium) =>
      _planFilterCache[isPremium] ?? [];

  /// カテゴリ別キャッシュを返す（未構築時は空リスト）
  List<WritingPrompt> getCategoryCache(PromptCategory category) =>
      _categoryCache[category] ?? [];

  /// IDでプロンプトを返す（存在しない場合は null）
  WritingPrompt? getById(String id) => _idCache[id];

  /// キャッシュをクリアして未構築状態に戻す
  void clear() {
    _planFilterCache.clear();
    _categoryCache.clear();
    _idCache.clear();
    _isBuilt = false;
  }
}
