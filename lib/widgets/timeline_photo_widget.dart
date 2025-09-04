import 'package:flutter/material.dart';
import '../models/timeline_photo_group.dart';
import '../services/timeline_grouping_service.dart';
import '../controllers/photo_selection_controller.dart';
import '../widgets/timeline_date_header.dart';
import '../widgets/optimized_photo_grid_widget.dart';
import '../ui/design_system/app_spacing.dart';
import '../constants/app_constants.dart';

/// タイムライン表示用の写真ウィジェット
class TimelinePhotoWidget extends StatefulWidget {
  /// 写真選択コントローラー
  final PhotoSelectionController controller;

  /// 選択上限到達時のコールバック
  final VoidCallback? onSelectionLimitReached;

  /// 使用済み写真選択時のコールバック
  final VoidCallback? onUsedPhotoSelected;

  /// 権限要求コールバック
  final VoidCallback? onRequestPermission;

  /// 異なる日付選択時のコールバック
  final VoidCallback? onDifferentDateSelected;

  /// カメラ撮影コールバック
  final VoidCallback? onCameraPressed;

  /// スマートFAB表示制御
  final bool showFAB;

  const TimelinePhotoWidget({
    super.key,
    required this.controller,
    this.onSelectionLimitReached,
    this.onUsedPhotoSelected,
    this.onRequestPermission,
    this.onDifferentDateSelected,
    this.onCameraPressed,
    this.showFAB = true,
  });

  @override
  State<TimelinePhotoWidget> createState() => _TimelinePhotoWidgetState();
}

class _TimelinePhotoWidgetState extends State<TimelinePhotoWidget> {
  final TimelineGroupingService _groupingService = TimelineGroupingService();
  List<TimelinePhotoGroup> _photoGroups = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _updatePhotoGroups();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    _updatePhotoGroups();
  }

  void _updatePhotoGroups() {
    final groups = _groupingService.groupPhotosForTimeline(
      widget.controller.photoAssets,
    );

    if (mounted) {
      setState(() {
        _photoGroups = groups;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        if (widget.controller.isLoading) {
          return _buildLoadingState();
        }

        if (!widget.controller.hasPermission) {
          return _buildPermissionDeniedState();
        }

        if (_photoGroups.isEmpty) {
          return _buildEmptyState();
        }

        return _buildTimelineContent();
      },
    );
  }

  /// タイムラインコンテンツを構築
  Widget _buildTimelineContent() {
    final selectedDate = _groupingService.getSelectedDate(
      widget.controller.selectedPhotos,
    );

    return CustomScrollView(
      slivers: [
        // 各グループごとにヘッダーと写真グリッドを表示
        for (final group in _photoGroups) ...[
          // 日付ヘッダー
          SliverPersistentHeader(
            delegate: TimelineDateHeaderDelegate(group: group),
            pinned: true,
          ),

          // 写真グリッド
          _buildPhotoGridSliver(group, selectedDate),

          // グループ間のスペース
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        ],

        // 底部のスペース
        const SliverToBoxAdapter(
          child: SizedBox(height: AppConstants.bottomNavPadding),
        ),
      ],
    );
  }

  /// 写真グリッド用のSliverを構築
  Widget _buildPhotoGridSliver(
    TimelinePhotoGroup group,
    DateTime? selectedDate,
  ) {
    // 日付制限による視覚的フィードバック
    final shouldDimGroup =
        selectedDate != null && !_isSameDateAsGroup(selectedDate, group);

    return SliverToBoxAdapter(
      child: Opacity(
        opacity: shouldDimGroup ? 0.3 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _TimelineGroupPhotoGrid(
            group: group,
            controller: widget.controller,
            onSelectionLimitReached: widget.onSelectionLimitReached,
            onUsedPhotoSelected: widget.onUsedPhotoSelected,
            onDifferentDateSelected: widget.onDifferentDateSelected,
            isDimmed: shouldDimGroup,
          ),
        ),
      ),
    );
  }

  /// ローディング状態を構築
  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  /// 権限拒否状態を構築
  Widget _buildPermissionDeniedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '写真へのアクセス許可が必要です',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (widget.onRequestPermission != null)
            TextButton(
              onPressed: widget.onRequestPermission,
              child: const Text('許可する'),
            ),
        ],
      ),
    );
  }

  /// 空状態を構築
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '写真がありません',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 指定日付がグループと同じ日付かどうかを判定
  bool _isSameDateAsGroup(DateTime date, TimelinePhotoGroup group) {
    final groupFirstPhoto = group.photos.firstOrNull;
    if (groupFirstPhoto == null) return false;

    final photoDate = groupFirstPhoto.createDateTime;
    return date.year == photoDate.year &&
        date.month == photoDate.month &&
        date.day == photoDate.day;
  }
}

/// タイムライングループ専用の最適化された写真グリッドウィジェット
class _TimelineGroupPhotoGrid extends StatefulWidget {
  final TimelinePhotoGroup group;
  final PhotoSelectionController controller;
  final VoidCallback? onSelectionLimitReached;
  final VoidCallback? onUsedPhotoSelected;
  final VoidCallback? onDifferentDateSelected;
  final bool isDimmed;

  const _TimelineGroupPhotoGrid({
    required this.group,
    required this.controller,
    this.onSelectionLimitReached,
    this.onUsedPhotoSelected,
    this.onDifferentDateSelected,
    this.isDimmed = false,
  });

  @override
  State<_TimelineGroupPhotoGrid> createState() =>
      _TimelineGroupPhotoGridState();
}

class _TimelineGroupPhotoGridState extends State<_TimelineGroupPhotoGrid> {
  late PhotoSelectionController _groupController;

  @override
  void initState() {
    super.initState();
    // グループ専用のコントローラーを作成
    _groupController = PhotoSelectionController();
    _groupController.setPhotoAssets(widget.group.photos);
    _groupController.setUsedPhotoIds(widget.controller.usedPhotoIds);
    _groupController.setDateRestrictionEnabled(true);

    // メインコントローラーの選択状態を同期
    _syncSelectionState();

    // メインコントローラーの変更を監視
    widget.controller.addListener(_onMainControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onMainControllerChanged);
    _groupController.dispose();
    super.dispose();
  }

  void _onMainControllerChanged() {
    _syncSelectionState();
  }

  void _syncSelectionState() {
    // メインコントローラーの選択状態をグループコントローラーに同期
    for (int i = 0; i < widget.group.photos.length; i++) {
      final photo = widget.group.photos[i];
      final mainIndex = widget.controller.photoAssets.indexOf(photo);
      if (mainIndex >= 0 && mainIndex < widget.controller.selected.length) {
        if (i < _groupController.selected.length) {
          _groupController.selected[i] = widget.controller.selected[mainIndex];
        }
      }
    }
    // 選択状態の変更を通知
    if (mounted) {
      setState(() {
        // UI更新をトリガー
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OptimizedPhotoGridWidget(
      controller: _groupController,
      onSelectionLimitReached: widget.onSelectionLimitReached,
      onUsedPhotoSelected: widget.onUsedPhotoSelected,
      onRequestPermission: null, // グループ内では不要
      onDifferentDateSelected: widget.isDimmed
          ? widget.onDifferentDateSelected
          : null,
    );
  }
}
