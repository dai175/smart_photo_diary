import 'package:flutter/material.dart';
import '../services/interfaces/prompt_service_interface.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../core/service_locator.dart';
import '../models/writing_prompt.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/custom_card.dart';
import '../ui/animations/list_animations.dart';
import '../ui/animations/micro_interactions.dart';
import '../utils/prompt_category_utils.dart';

/// ライティングプロンプト表示画面
/// 
/// Premium機能として、ユーザーに書くヒントとなるプロンプトを表示します。
/// カテゴリ別フィルタリング、ランダム表示、検索機能を提供します。
class WritingPromptsScreen extends StatefulWidget {
  const WritingPromptsScreen({super.key});

  @override
  State<WritingPromptsScreen> createState() => _WritingPromptsScreenState();
}

class _WritingPromptsScreenState extends State<WritingPromptsScreen> {
  late IPromptService _promptService;
  late ISubscriptionService _subscriptionService;
  
  bool _isLoading = true;
  bool _isPremium = false;
  List<WritingPrompt> _displayedPrompts = [];
  PromptCategory? _selectedCategory;
  String _searchQuery = '';
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      _promptService = await ServiceLocator().getAsync<IPromptService>();
      _subscriptionService = await ServiceLocator().getAsync<ISubscriptionService>();
      
      // Premium状態を取得
      final accessResult = await _subscriptionService.canAccessPremiumFeatures();
      if (accessResult.isSuccess) {
        _isPremium = accessResult.value;
      }
      
      // 初期プロンプトを読み込み
      await _loadPrompts();
    } catch (e) {
      debugPrint('WritingPromptsScreen初期化エラー: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPrompts() async {
    try {
      List<WritingPrompt> prompts;
      
      if (_searchQuery.isNotEmpty) {
        // 検索クエリがある場合
        prompts = _promptService.searchPrompts(_searchQuery, isPremium: _isPremium);
      } else if (_selectedCategory != null) {
        // カテゴリが選択されている場合
        prompts = _promptService.getPromptsByCategory(_selectedCategory!, isPremium: _isPremium);
      } else {
        // 全プロンプトを表示
        prompts = _promptService.getPromptsForPlan(isPremium: _isPremium);
      }
      
      setState(() {
        _displayedPrompts = prompts;
      });
    } catch (e) {
      debugPrint('プロンプト読み込みエラー: $e');
    }
  }

  void _onCategorySelected(PromptCategory? category) {
    setState(() {
      _selectedCategory = category;
      _searchQuery = '';
      _searchController.clear();
    });
    _loadPrompts();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _selectedCategory = null;
    });
    _loadPrompts();
  }

  void _showRandomPrompt() {
    final randomPrompt = _promptService.getRandomPrompt(
      isPremium: _isPremium,
      category: _selectedCategory,
    );
    
    if (randomPrompt != null) {
      _showPromptDetail(randomPrompt);
    }
  }

  void _showPromptDetail(WritingPrompt prompt) {
    showDialog(
      context: context,
      builder: (context) => _buildPromptDetailDialog(prompt),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingView() : _buildMainContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('ライティングプロンプト'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      elevation: 2,
      actions: [
        if (_isPremium)
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            child: IconButton(
              icon: Icon(
                Icons.shuffle_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: _showRandomPrompt,
              tooltip: 'ランダムプロンプト',
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: FadeInWidget(
        child: CustomCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'プロンプトを読み込み中...',
                style: AppTypography.titleLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (!_isPremium) {
      return _buildPremiumUpgradeView();
    }

    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(
          child: _displayedPrompts.isEmpty
              ? _buildEmptyView()
              : _buildPromptsList(),
        ),
      ],
    );
  }

  Widget _buildPremiumUpgradeView() {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: CustomCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                size: 64,
                color: AppColors.warning,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Premium機能',
                style: AppTypography.headlineSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'ライティングプロンプトはPremiumプランの機能です。\n59個の豊富なプロンプトで、日記作成をサポートします。',
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              MicroInteractions.bounceOnTap(
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.upgrade_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Premiumにアップグレード',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          // 検索バー
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'プロンプトを検索...',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // カテゴリフィルター
          _buildCategoryFilter(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryChip('全て', null),
          const SizedBox(width: AppSpacing.sm),
          ...PromptCategory.values.map((category) {
            final prompts = _promptService.getPromptsByCategory(category, isPremium: _isPremium);
            if (prompts.isEmpty) return const SizedBox.shrink();
            
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _buildCategoryChip(
                PromptCategoryUtils.getCategoryDisplayName(category),
                category,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, PromptCategory? category) {
    final isSelected = _selectedCategory == category;
    
    return MicroInteractions.scaleOnTap(
      onTap: () => _onCategorySelected(category),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.lg),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPromptsList() {
    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: _displayedPrompts.length,
      itemBuilder: (context, index) {
        final prompt = _displayedPrompts[index];
        return SlideInWidget(
          delay: Duration(milliseconds: index * 50),
          child: _buildPromptCard(prompt),
        );
      },
    );
  }

  Widget _buildPromptCard(WritingPrompt prompt) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: MicroInteractions.bounceOnTap(
        onTap: () => _showPromptDetail(prompt),
        child: CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: PromptCategoryUtils.getCategoryColor(prompt.category).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                    child: Text(
                      PromptCategoryUtils.getCategoryDisplayName(prompt.category),
                      style: AppTypography.labelSmall.copyWith(
                        color: PromptCategoryUtils.getCategoryColor(prompt.category),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (prompt.isPremiumOnly)
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                prompt.text,
                style: AppTypography.bodyLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (prompt.description != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  prompt.description!,
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (prompt.tags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: prompt.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                      child: Text(
                        tag,
                        style: AppTypography.labelSmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'プロンプトが見つかりません',
              style: AppTypography.titleLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _searchQuery.isNotEmpty
                  ? '検索条件を変更してお試しください'
                  : '別のカテゴリを選択してください',
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptDetailDialog(WritingPrompt prompt) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: MicroInteractions.scaleTransition(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.lg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ヘッダー
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: PromptCategoryUtils.getCategoryColor(prompt.category).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.lg),
                    topRight: Radius.circular(AppSpacing.lg),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: PromptCategoryUtils.getCategoryColor(prompt.category),
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                      child: Text(
                        PromptCategoryUtils.getCategoryDisplayName(prompt.category),
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (prompt.isPremiumOnly)
                      Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: AppColors.warning,
                      ),
                  ],
                ),
              ),
              // コンテンツ
              Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prompt.text,
                      style: AppTypography.titleMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (prompt.description != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        prompt.description!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (prompt.tags.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'タグ',
                        style: AppTypography.labelMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: prompt.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(AppSpacing.sm),
                            ),
                            child: Text(
                              tag,
                              style: AppTypography.labelSmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              // アクション
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MicroInteractions.bounceOnTap(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppSpacing.md),
                        ),
                        child: Text(
                          '閉じる',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}