import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../controllers/photo_selection_controller.dart';
import '../services/interfaces/photo_cache_service_interface.dart';
import '../services/photo_cache_service.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/animated_button.dart';
import '../ui/components/loading_shimmer.dart';
import '../utils/performance_monitor.dart';
import '../services/logging_service.dart';

/// 最適化された写真グリッド表示ウィジェット
class OptimizedPhotoGridWidget extends StatefulWidget {
  final PhotoSelectionController controller;
  final VoidCallback? onSelectionLimitReached;
  final VoidCallback? onUsedPhotoSelected;
  final VoidCallback? onRequestPermission;
  final VoidCallback? onDifferentDateSelected;

  const OptimizedPhotoGridWidget({
    super.key,
    required this.controller,
    this.onSelectionLimitReached,
    this.onUsedPhotoSelected,
    this.onRequestPermission,
    this.onDifferentDateSelected,
  });

  @override
  State<OptimizedPhotoGridWidget> createState() =>
      _OptimizedPhotoGridWidgetState();
}

class _OptimizedPhotoGridWidgetState extends State<OptimizedPhotoGridWidget> {
  late final PhotoCacheServiceInterface _cacheService;
  final ScrollController _scrollController = ScrollController();

  // 遅延読み込み用の変数
  static const int _itemsPerPage = 30;
  int _visibleItemCount = 0; // 初期値を0に変更
  bool _isLoadingMore = false;
  int _lastPhotoCount = 0; // 写真リストの長さを追跡

  // パフォーマンス最適化用の変数
  bool _isScrolling = false;
  DateTime? _lastScrollTime;
  static const Duration _scrollDebounce = Duration(milliseconds: 100);

  // サムネイルプリロード重複実行防止フラグ
  bool _isPreloadingThumbnails = false;

  @override
  void initState() {
    super.initState();
    _cacheService = PhotoCacheService.getInstance();
    _scrollController.addListener(_onScroll);

    // 初期プリロード
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadInitialThumbnails();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OptimizedPhotoGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 写真リストが変更された場合、表示数をリセット
    if (oldWidget.controller.photoAssets.length !=
        widget.controller.photoAssets.length) {
      setState(() {
        _visibleItemCount = widget.controller.photoAssets.length.clamp(
          0,
          _itemsPerPage,
        );
      });

      // 新しい写真リストの初期バッチをプリロード
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _preloadInitialThumbnails();
      });
    }
  }

  /// スクロール時の処理
  void _onScroll() {
    // スクロール状態を追跡
    if (!_isScrolling) {
      setState(() {
        _isScrolling = true;
      });
    }

    _lastScrollTime = DateTime.now();

    // デバウンス処理でスクロール停止を検出
    Future.delayed(_scrollDebounce, () {
      if (_lastScrollTime != null &&
          DateTime.now().difference(_lastScrollTime!) >= _scrollDebounce) {
        if (mounted && _isScrolling) {
          setState(() {
            _isScrolling = false;
          });
        }
      }
    });

    // 追加読み込みの判定
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  /// 追加アイテムの読み込み
  void _loadMoreItems() {
    if (_isLoadingMore ||
        _visibleItemCount >= widget.controller.photoAssets.length) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    // 次のバッチをプリロード
    final nextBatch = widget.controller.photoAssets
        .skip(_visibleItemCount)
        .take(_itemsPerPage)
        .toList();
    _cacheService
        .preloadThumbnails(
          nextBatch,
          width: AppConstants.photoThumbnailSize.toInt(),
          height: AppConstants.photoThumbnailSize.toInt(),
        )
        .then((_) {
          if (mounted) {
            setState(() {
              _visibleItemCount = (_visibleItemCount + _itemsPerPage).clamp(
                0,
                widget.controller.photoAssets.length,
              );
              _isLoadingMore = false;
            });
          }
        });
  }

  /// 初期サムネイルのプリロード
  Future<void> _preloadInitialThumbnails() async {
    if (widget.controller.photoAssets.isEmpty) return;

    // 重複実行防止チェック
    if (_isPreloadingThumbnails) return;

    _isPreloadingThumbnails = true;

    try {
      PerformanceMonitor.startMeasurement('initial_thumbnail_preload');

      final initialBatch = widget.controller.photoAssets
          .take(_itemsPerPage)
          .toList();
      await _cacheService.preloadThumbnails(
        initialBatch,
        width: AppConstants.photoThumbnailSize.toInt(),
        height: AppConstants.photoThumbnailSize.toInt(),
      );

      await PerformanceMonitor.endMeasurement(
        'initial_thumbnail_preload',
        context: 'OptimizedPhotoGridWidget',
      );
    } finally {
      _isPreloadingThumbnails = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        // 写真リストが変更された場合の処理
        if (_lastPhotoCount != widget.controller.photoAssets.length) {
          _lastPhotoCount = widget.controller.photoAssets.length;

          // 表示数をリセット
          _visibleItemCount = widget.controller.photoAssets.length.clamp(
            0,
            _itemsPerPage,
          );

          // 初期プリロードを実行
          if (widget.controller.photoAssets.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _preloadInitialThumbnails();
            });
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildPhotoGrid(context),
            const SizedBox(height: AppSpacing.sm),
            Center(child: _buildSelectionCounter(context)),
          ],
        );
      },
    );
  }

  Widget _buildPhotoGrid(BuildContext context) {
    final crossAxisCount = _getCrossAxisCount(context);
    final gridHeight = _getGridHeight(context, crossAxisCount);

    if (widget.controller.isLoading) {
      return SizedBox(
        height: gridHeight,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.0,
          ),
          itemCount: 9,
          itemBuilder: (context, index) => const CardShimmer(),
        ),
      );
    }

    if (!widget.controller.hasPermission) {
      return SizedBox(height: gridHeight, child: _buildPermissionRequest());
    }

    if (widget.controller.photoAssets.isEmpty) {
      return SizedBox(height: gridHeight, child: _buildEmptyState(context));
    }

    return SizedBox(height: gridHeight, child: _buildGrid(context));
  }

  Widget _buildGrid(BuildContext context) {
    final crossAxisCount = _getCrossAxisCount(context);
    final itemCount = _visibleItemCount;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _getMaxGridWidth(context)),
        child: GridView.builder(
          controller: _scrollController,
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.0,
          ),
          itemCount: itemCount + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= itemCount) {
              // ローディングインジケーター
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            return _buildPhotoItem(index);
          },
        ),
      ),
    );
  }

  Widget _buildPhotoItem(int index) {
    final isSelected = widget.controller.selected[index];
    final isUsed = widget.controller.isPhotoUsed(index);

    // アクセシビリティ用のラベル作成
    String semanticLabel = '写真 ${index + 1}';
    if (isUsed) {
      semanticLabel += '、使用済み';
    }
    if (isSelected) {
      semanticLabel += '、選択中';
    } else {
      semanticLabel += '、未選択';
    }

    return RepaintBoundary(
      child: Semantics(
        label: semanticLabel,
        button: true,
        selected: isSelected,
        enabled: !isUsed,
        onTap: isUsed ? null : () => _handlePhotoTap(index),
        child: GestureDetector(
          onTap: () => _handlePhotoTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: AppSpacing.photoRadius,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildPhotoThumbnail(index),
                _buildSelectionIndicator(index),
                if (isUsed) _buildUsedLabel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(int index) {
    final asset = widget.controller.photoAssets[index];

    // スクロール中は低品質、停止後は高品質
    final quality = _isScrolling ? 50 : 80;
    final filterQuality = _isScrolling
        ? FilterQuality.low
        : FilterQuality.medium;

    return ClipRRect(
      borderRadius: AppSpacing.photoRadius,
      child: FutureBuilder<Uint8List?>(
        future: _loadThumbnailResult(
          asset,
          width: AppConstants.photoThumbnailSize.toInt(),
          height: AppConstants.photoThumbnailSize.toInt(),
          quality: quality,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return RepaintBoundary(
              child: Image.memory(
                snapshot.data!,
                height: AppConstants.photoThumbnailSize,
                width: AppConstants.photoThumbnailSize,
                fit: BoxFit.cover,
                cacheHeight:
                    (AppConstants.photoThumbnailSize *
                            MediaQuery.of(context).devicePixelRatio)
                        .round(),
                cacheWidth:
                    (AppConstants.photoThumbnailSize *
                            MediaQuery.of(context).devicePixelRatio)
                        .round(),
                gaplessPlayback: true,
                filterQuality: filterQuality,
                // スクロール中はフレーム優先
                frameBuilder: _isScrolling
                    ? null
                    : (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded) {
                          return child;
                        }
                        return AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: child,
                        );
                      },
              ),
            );
          } else {
            return Container(
              height: AppConstants.photoThumbnailSize,
              width: AppConstants.photoThumbnailSize,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppSpacing.photoRadius,
              ),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSelectionIndicator(int index) {
    return Positioned(
      top: AppSpacing.xs,
      right: AppSpacing.xs,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: _getSelectionIcon(index),
      ),
    );
  }

  Widget _getSelectionIcon(int index) {
    if (widget.controller.isPhotoUsed(index)) {
      return Icon(Icons.done_rounded, color: AppColors.warning, size: 18);
    } else {
      return Icon(
        widget.controller.selected[index]
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: widget.controller.selected[index]
            ? AppColors.success
            : AppColors.onSurfaceVariant,
        size: 18,
      );
    }
  }

  Widget _buildUsedLabel() {
    return Positioned(
      bottom: AppSpacing.xs,
      left: AppSpacing.xs,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppSpacing.xs),
        ),
        child: Text(
          AppConstants.usedPhotoLabel,
          style: AppTypography.withColor(
            AppTypography.labelSmall,
            Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: AppSpacing.cardRadius,
          ),
          child: Icon(
            Icons.photo_camera_outlined,
            size: AppSpacing.iconLg,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppConstants.permissionMessage,
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          onPressed: widget.onRequestPermission,
          text: AppConstants.requestPermissionButton,
          icon: Icons.camera_alt,
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: AppSpacing.cardRadius,
            ),
            child: Icon(
              Icons.photo_library_outlined,
              size: AppSpacing.iconLg,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppConstants.noPhotosMessage,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCounter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: widget.controller.selectedCount > 0
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: AppSpacing.chipRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_library_rounded,
            size: AppSpacing.iconSm,
            color: widget.controller.selectedCount > 0
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '選択された写真: ${widget.controller.selectedCount}/${AppConstants.maxPhotosSelection}枚',
            style: AppTypography.withColor(
              AppTypography.labelMedium,
              widget.controller.selectedCount > 0
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _handlePhotoTap(int index) {
    if (widget.controller.isPhotoUsed(index)) {
      widget.onUsedPhotoSelected?.call();
      return;
    }

    // 現在の選択状態を保存
    final wasSelected = widget.controller.selected[index];

    // 選択解除の場合は制限チェック不要
    if (wasSelected) {
      widget.controller.toggleSelect(index);
      return;
    }

    // 選択可能かチェック
    if (!widget.controller.canSelectPhoto(index)) {
      // 選択上限に達している場合
      if (widget.controller.selectedCount >= AppConstants.maxPhotosSelection) {
        widget.onSelectionLimitReached?.call();
        return;
      }

      // 使用済み写真の場合（念のため再度チェック）
      if (widget.controller.isPhotoUsed(index)) {
        widget.onUsedPhotoSelected?.call();
        return;
      }

      // 日付が異なる場合のチェック（上限に達しておらず、使用済みでもない場合）
      if (widget.onDifferentDateSelected != null) {
        widget.onDifferentDateSelected!();
      }
      return;
    }

    widget.controller.toggleSelect(index);
  }

  /// グリッドの最大幅を計算（縦向きと同じ配置を維持）
  double _getMaxGridWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;

    // 横向き時は縦向きの幅に相当するサイズに制限
    if (orientation == Orientation.landscape) {
      return screenHeight * 0.9; // 少し余裕を持たせる
    }

    return screenWidth;
  }

  /// 画面の向きに関係なく3カラムで統一
  int _getCrossAxisCount(BuildContext context) {
    // 縦向き・横向き問わず3カラムで統一して、写真の位置関係を保持
    return AppConstants.photoGridCrossAxisCount;
  }

  /// グリッドの高さを動的に計算（縦横で同じアイテムサイズを維持）
  double _getGridHeight(BuildContext context, int crossAxisCount) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;

    final padding =
        AppSpacing.screenPadding.horizontal + AppSpacing.cardPadding.horizontal;

    // 縦向きと横向きで同じアイテムサイズを維持するために、
    // より小さい画面幅を基準にアイテムサイズを計算
    final baseWidth = orientation == Orientation.landscape
        ? screenHeight // 横向き時は縦向きの幅（screenHeight）を基準に
        : screenWidth; // 縦向き時はそのまま

    final availableWidth = baseWidth - padding;
    final spacing = AppSpacing.sm * (crossAxisCount - 1);
    final itemWidth = (availableWidth - spacing) / crossAxisCount;

    // アイテムのアスペクト比を1:1として、3行分の高さを計算
    final rowHeight = itemWidth;
    final totalHeight = rowHeight * 2 + AppSpacing.sm * 2; // 2行 + 間のスペース

    return totalHeight;
  }

  /// サムネイル読み込み（Result<T>版）
  Future<Uint8List?> _loadThumbnailResult(
    dynamic asset, {
    int width = 200,
    int height = 200,
    int quality = 80,
  }) async {
    final thumbnailResult = await _cacheService.getThumbnailResult(
      asset,
      width: width,
      height: height,
      quality: quality,
    );

    if (thumbnailResult.isSuccess) {
      return thumbnailResult.value;
    } else {
      // エラーハンドリング
      await _handleThumbnailError(thumbnailResult.error, 'サムネイル読み込み');
      return null; // エラー時はnullを返してプレースホルダーを表示
    }
  }

  /// サムネイルエラーの統一ハンドリング
  Future<void> _handleThumbnailError(Exception error, String context) async {
    final loggingService = await LoggingService.getInstance();
    loggingService.error(
      'サムネイル読み込みエラー',
      context: 'OptimizedPhotoGridWidget.$context',
      error: error,
    );
    // UI処理は継続（プレースホルダー表示）
  }
}
