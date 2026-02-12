import 'package:flutter/material.dart';
import '../controllers/diary_screen_controller.dart';
import '../localization/localization_extensions.dart';
import '../widgets/diary_card_widget.dart';
import '../shared/filter_bottom_sheet.dart';
import '../core/service_locator.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../shared/active_filters_display.dart';
import 'diary_detail_screen.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/components/animated_button.dart';
import '../ui/components/loading_shimmer.dart';
import '../ui/animations/list_animations.dart';
import '../ui/animations/micro_interactions.dart';
import '../constants/app_icons.dart';
import '../constants/app_constants.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/interfaces/photo_cache_service_interface.dart';
import '../controllers/scroll_signal.dart';

class DiaryScreen extends StatefulWidget {
  final ScrollSignal? scrollSignal;

  const DiaryScreen({super.key, this.scrollSignal});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late final ILoggingService _logger;
  late final DiaryScreenController _controller;
  late final ScrollController _scrollController;
  int _lastPrefetchIndex = 0;
  bool _isPrefetching = false;

  @override
  void initState() {
    super.initState();
    _logger = serviceLocator.get<ILoggingService>();
    _controller = DiaryScreenController();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _controller.addListener(_onControllerChanged);
    widget.scrollSignal?.addListener(_onScrollToTop);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    widget.scrollSignal?.removeListener(_onScrollToTop);
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // 下端の一定割合手前で次ページをプリロード
    if (position.pixels >=
        position.maxScrollExtent *
            AppConstants.diaryListLoadMoreThresholdRatio) {
      _controller.loadMore();
    }
  }

  void _onScrollToTop() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      0,
      duration: AppConstants.defaultAnimationDuration,
      curve: Curves.easeOut,
    );
  }

  void _onControllerChanged() {
    // エントリー数が増えたら先読みを試行
    if (_controller.diaryEntries.length > _lastPrefetchIndex &&
        !_controller.isLoading) {
      _prefetchUpcomingThumbnails();
    }
  }

  Future<void> _prefetchUpcomingThumbnails() async {
    if (_isPrefetching) return;
    _isPrefetching = true;
    // すでに先読み済みのインデックス以降から一定件数を先読み
    final start = _lastPrefetchIndex;
    final endExclusive =
        (_lastPrefetchIndex + AppConstants.diaryPrefetchAheadCount).clamp(
          0,
          _controller.diaryEntries.length,
        );

    if (start >= endExclusive) return;

    final slice = _controller.diaryEntries.sublist(start, endExclusive);
    final assets = <AssetEntity>[];
    for (final entry in slice) {
      if (entry.photoIds.isEmpty) continue;
      try {
        final asset = await AssetEntity.fromId(entry.photoIds.first);
        if (asset != null) assets.add(asset);
      } catch (_) {
        // ignore individual failures
      }
    }
    if (assets.isEmpty) {
      _lastPrefetchIndex = endExclusive;
      _isPrefetching = false;
      return;
    }

    final cache = serviceLocator.get<IPhotoCacheService>();
    final size = AppConstants.diaryThumbnailSize.toInt();
    await cache.preloadThumbnails(
      assets,
      width: size,
      height: size,
      quality: AppConstants.diaryThumbnailQuality,
    );
    _lastPrefetchIndex = endExclusive;
    _isPrefetching = false;
  }

  // 日記エントリーをタップしたときに詳細画面に遷移
  void _navigateToDiaryDetail(String diaryId) {
    Navigator.push(
      context,
      DiaryDetailScreen(diaryId: diaryId).customRoute(),
    ).then((result) {
      // 詳細画面から戻ってきたときに日記一覧を再読み込み
      _controller.loadDiaryEntries();

      // 削除された場合の追加処理（必要に応じて）
      if (result == true) {
        _logger.info('日記が削除されました', context: 'DiaryScreen');
      }
    });
  }

  // フィルタボトムシートを表示
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.borderRadiusXl),
        ),
      ),
      builder: (context) => FilterBottomSheet(
        initialFilter: _controller.currentFilter,
        onApply: _controller.applyFilter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: _buildAppBar(context),
          body: MicroInteractions.pullToRefresh(
            onRefresh: _controller.refresh,
            color: AppColors.primary,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // アクティブフィルタ表示（AppBar直下に固定されないようスリバーとして配置）
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: ActiveFiltersDisplay(
                      filter: _controller.currentFilter,
                      onClear: _controller.clearAllFilters,
                      onRemoveTag: _controller.removeTagFilter,
                      onRemoveTimeOfDay: _controller.removeTimeOfDayFilter,
                      onRemoveDateRange: _controller.removeDateRangeFilter,
                      onRemoveSearch: _controller.removeSearchFilter,
                    ),
                  ),
                ),

                ..._buildSliverContent(),
                // フッター：追加読み込みインジケータ
                SliverToBoxAdapter(
                  child: _controller.isLoadingMore
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: Center(
                            child: SizedBox(
                              width: AppConstants.diaryListFooterSpinnerSize,
                              height: AppConstants.diaryListFooterSpinnerSize,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      title: _controller.isSearching
          ? TextField(
              controller: _controller.searchController,
              autofocus: true,
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              decoration: InputDecoration(
                hintText: context.l10n.diarySearchHint,
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withValues(alpha: 0.7),
                ),
                border: InputBorder.none,
                prefixIcon: Icon(
                  AppIcons.search,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              onChanged: _controller.performSearch,
            )
          : Text(context.l10n.diaryListTitle),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      titleTextStyle: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary),
      iconTheme: IconThemeData(color: colorScheme.onPrimary),
      elevation: 2,
      leading: _controller.isSearching
          ? IconButton(
              icon: Icon(AppIcons.actionBack, color: colorScheme.onPrimary),
              onPressed: _controller.stopSearch,
            )
          : null,
      actions: _controller.isSearching
          ? [
              if (_controller.searchQuery.isNotEmpty)
                IconButton(
                  icon: Icon(
                    AppIcons.searchClear,
                    color: colorScheme.onPrimary,
                  ),
                  onPressed: _controller.clearSearch,
                ),
            ]
          : [
              IconButton(
                icon: Icon(
                  AppIcons.search,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: _controller.startSearch,
              ),
              Container(
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                child: IconButton(
                  icon: Icon(
                    _controller.currentFilter.isActive
                        ? AppIcons.filterActive
                        : AppIcons.filter,
                    color: _controller.currentFilter.isActive
                        ? Theme.of(context).colorScheme.inversePrimary
                        : colorScheme.onPrimary,
                  ),
                  onPressed: _showFilterBottomSheet,
                ),
              ),
            ],
    );
  }

  List<Widget> _buildSliverContent() {
    if (_controller.isLoading) {
      return [
        SliverPadding(
          padding: AppSpacing.screenPadding,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index < AppConstants.diaryListInitialShimmerCount - 1
                      ? AppSpacing.md
                      : 0,
                ),
                child: const DiaryCardShimmer(),
              ),
              childCount: AppConstants.diaryListInitialShimmerCount,
            ),
          ),
        ),
      ];
    }

    if (_controller.diaryEntries.isNotEmpty) {
      return [
        SliverPadding(
          padding: AppSpacing.screenPadding,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final entry = _controller.diaryEntries[index];
              return SlideInWidget(
                // 大量件数でのオーバーヘッドを避けるため先頭数件のみ遅延を付与
                delay: Duration(
                  milliseconds:
                      AppConstants.diaryListAnimationStaggerMs *
                      (index < AppConstants.diaryListAnimationStaggerLimit
                          ? index
                          : 0),
                ),
                begin: const Offset(0.0, 0.2),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: index < _controller.diaryEntries.length - 1
                        ? AppSpacing.lg
                        : 0,
                  ),
                  child: DiaryCardWidget(
                    entry: entry,
                    onTap: () => _navigateToDiaryDetail(entry.id),
                  ),
                ),
              );
            }, childCount: _controller.diaryEntries.length),
          ),
        ),
      ];
    }

    // 空状態（画面全体中央配置 + 常にスクロール可能）
    return [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.book_outlined,
                size: AppConstants.emptyStateIconSize,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _controller.getLocalizedEmptyStateMessage(
                  noDiariesMessage: () => context.l10n.diaryNoEntriesMessage,
                  noSearchResultsMessage: (query) =>
                      context.l10n.diaryNoSearchResults(query),
                  noFilterResultsMessage: () =>
                      context.l10n.diaryNoFilterResults,
                ),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (_controller.currentFilter.isActive &&
                  !_controller.isSearching) ...[
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  onPressed: _controller.clearAllFilters,
                  text: context.l10n.commonClearFilters,
                  icon: Icons.clear_all_rounded,
                ),
              ],
            ],
          ),
        ),
      ),
    ];
  }
}
