import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../controllers/photo_selection_controller.dart';
import '../core/result/result.dart';
import '../core/service_locator.dart';
import '../services/interfaces/photo_cache_service_interface.dart';
import '../ui/design_system/app_spacing.dart';
import '../utils/performance_monitor.dart';
import 'photo_grid_components.dart';

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
  late final IPhotoCacheService _cacheService;
  final ScrollController _scrollController = ScrollController();

  // 遅延読み込み用の変数
  static const int _itemsPerPage = 30;
  int _visibleItemCount = _itemsPerPage;
  bool _isLoadingMore = false;
  int _lastPhotoCount = 0;

  // パフォーマンス最適化用の変数
  bool _isScrolling = false;
  DateTime? _lastScrollTime;
  static const Duration _scrollDebounce = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    _cacheService = serviceLocator.get<IPhotoCacheService>();
    _scrollController.addListener(_onScroll);

    _visibleItemCount = widget.controller.photoAssets.length.clamp(
      0,
      _itemsPerPage,
    );

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
    if (oldWidget.controller.photoAssets.length !=
        widget.controller.photoAssets.length) {
      setState(() {
        _visibleItemCount = widget.controller.photoAssets.length.clamp(
          0,
          _itemsPerPage,
        );
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _preloadInitialThumbnails();
      });
    }
  }

  /// スクロール時の処理
  void _onScroll() {
    if (!_isScrolling) {
      setState(() {
        _isScrolling = true;
      });
    }

    _lastScrollTime = DateTime.now();

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
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        // 写真リストが変更された場合の処理
        if (_lastPhotoCount != widget.controller.photoAssets.length) {
          _lastPhotoCount = widget.controller.photoAssets.length;

          _visibleItemCount = widget.controller.photoAssets.length.clamp(
            0,
            _itemsPerPage,
          );

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
            Center(
              child: PhotoGridSelectionCounter(
                selectedCount: widget.controller.selectedCount,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhotoGrid(BuildContext context) {
    final crossAxisCount = PhotoGridLayout.getCrossAxisCount();
    final gridHeight = PhotoGridLayout.getGridHeight(
      context,
      crossAxisCount: crossAxisCount,
      rowCount: 2,
    );

    if (widget.controller.isLoading) {
      return PhotoGridShimmer(
        crossAxisCount: crossAxisCount,
        height: gridHeight,
      );
    }

    if (!widget.controller.hasPermission) {
      return SizedBox(
        height: gridHeight,
        child: PhotoGridPermissionRequest(
          onRequestPermission: widget.onRequestPermission,
        ),
      );
    }

    if (widget.controller.photoAssets.isEmpty) {
      return SizedBox(height: gridHeight, child: const PhotoGridEmptyState());
    }

    return SizedBox(height: gridHeight, child: _buildGrid(context));
  }

  Widget _buildGrid(BuildContext context) {
    final crossAxisCount = PhotoGridLayout.getCrossAxisCount();
    final itemCount = _visibleItemCount;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: PhotoGridLayout.getMaxGridWidth(context),
        ),
        child: GridView.builder(
          controller: _scrollController,
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: PhotoGridLayout.gridDelegate(
            crossAxisCount: crossAxisCount,
          ),
          itemCount: itemCount + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= itemCount) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: AppConstants.progressIndicatorStrokeWidth,
                ),
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

    return PhotoGridItemWrapper(
      index: index,
      isSelected: isSelected,
      isUsed: isUsed,
      onTap: () => _handlePhotoTap(index),
      thumbnail: _buildPhotoThumbnail(index),
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
      child: FutureBuilder<Result<Uint8List>>(
        future: _cacheService.getThumbnail(
          asset,
          width: AppConstants.photoThumbnailSize.toInt(),
          height: AppConstants.photoThumbnailSize.toInt(),
          quality: quality,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData &&
              snapshot.data!.isSuccess) {
            return RepaintBoundary(
              child: Image.memory(
                snapshot.data!.value,
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
                          duration: AppConstants.quickAnimationDuration,
                          curve: Curves.easeOut,
                          child: child,
                        );
                      },
              ),
            );
          }
          return const PhotoThumbnailPlaceholder();
        },
      ),
    );
  }

  void _handlePhotoTap(int index) {
    handlePhotoTap(
      index: index,
      controller: widget.controller,
      onUsedPhotoSelected: widget.onUsedPhotoSelected,
      onSelectionLimitReached: widget.onSelectionLimitReached,
      onDifferentDateSelected: widget.onDifferentDateSelected,
    );
  }
}
