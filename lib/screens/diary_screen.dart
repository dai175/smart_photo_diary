import 'package:flutter/material.dart';
import '../controllers/diary_screen_controller.dart';
import '../widgets/diary_card_widget.dart';
import '../shared/filter_bottom_sheet.dart';
import '../shared/active_filters_display.dart';
import 'diary_detail_screen.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/gradient_app_bar.dart';
import '../ui/components/animated_button.dart';
import '../ui/components/loading_shimmer.dart';
import '../ui/animations/list_animations.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late final DiaryScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DiaryScreenController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        debugPrint('日記が削除されました');
      }
    });
  }

  // フィルタボトムシートを表示
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
          appBar: _buildAppBar(),
          body: Column(
            children: [
              // アクティブフィルタ表示
              Container(
                padding: EdgeInsets.symmetric(
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
              
              // 日記一覧
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return GradientAppBar(
      title: _controller.isSearching 
        ? TextField(
            controller: _controller.searchController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'タイトルや本文を検索...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
              ),
              border: InputBorder.none,
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.white,
              ),
            ),
            onChanged: _controller.performSearch,
          )
        : const Text('日記一覧'),
      gradient: AppColors.primaryGradient,
      leading: _controller.isSearching 
        ? IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
            ),
            onPressed: _controller.stopSearch,
          )
        : null,
      actions: _controller.isSearching 
        ? [
            if (_controller.searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(
                  Icons.clear_rounded,
                  color: Colors.white,
                ),
                onPressed: _controller.clearSearch,
              ),
          ]
        : [
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
              ),
              onPressed: _controller.refresh,
            ),
            IconButton(
              icon: const Icon(
                Icons.search_rounded,
                color: Colors.white,
              ), 
              onPressed: _controller.startSearch,
            ),
            Container(
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              child: IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  color: _controller.currentFilter.isActive 
                    ? AppColors.accent 
                    : Colors.white,
                ),
                onPressed: _showFilterBottomSheet,
              ),
            ),
          ],
    );
  }

  Widget _buildContent() {
    if (_controller.isLoading) {
      return ListView.builder(
        padding: AppSpacing.screenPadding,
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(
            bottom: index < 5 ? AppSpacing.md : 0,
          ),
          child: const DiaryCardShimmer(),
        ),
      );
    }

    if (_controller.diaryEntries.isNotEmpty) {
      return ListView.builder(
        padding: AppSpacing.screenPadding,
        itemCount: _controller.diaryEntries.length,
        itemBuilder: (context, index) {
          final entry = _controller.diaryEntries[index];
          return SlideInWidget(
            delay: Duration(milliseconds: 50 * index),
            begin: const Offset(0.0, 0.2),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: index < _controller.diaryEntries.length - 1 ? AppSpacing.lg : 0,
              ),
              child: DiaryCardWidget(
                entry: entry,
                onTap: () => _navigateToDiaryDetail(entry.id),
              ),
            ),
          );
        },
      );
    }

    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: AppSpacing.cardPaddingLarge,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.3),
                borderRadius: AppSpacing.cardRadiusLarge,
              ),
              child: Icon(
                _controller.getEmptyStateIcon(),
                size: AppSpacing.iconXl,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              _controller.getEmptyStateMessage(),
              style: AppTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _controller.getEmptyStateSubMessage(),
              style: AppTypography.withColor(
                AppTypography.bodyMedium,
                AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (_controller.currentFilter.isActive && !_controller.isSearching) ...[
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                onPressed: _controller.clearAllFilters,
                text: 'フィルタをクリア',
                icon: Icons.clear_all_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}