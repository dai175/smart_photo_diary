import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import '../models/timeline_photo_group.dart';
import '../services/timeline_grouping_service.dart';
import '../controllers/photo_selection_controller.dart';
import '../ui/design_system/app_spacing.dart';
import '../constants/app_constants.dart';

/// タイムライン表示用の写真ウィジェット
///
/// ホーム画面タブ統合後のメインコンポーネント。
/// - 日付別グルーピング（今日/昨日/月単位）
/// - スティッキーヘッダー付きスクロール表示
/// - 写真選択・薄化表示機能
/// - パフォーマンス最適化（インデックスキャッシュ・薄化判定キャッシュ）
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

  // パフォーマンス最適化用の定数
  static const double _crossAxisSpacing = 2.0;
  static const double _mainAxisSpacing = 2.0;
  static const int _crossAxisCount = 4;
  static const double _childAspectRatio = 1.0;

  // インデックスキャッシュ（メインインデックス検索の最適化）
  final Map<String, int> _photoIndexCache = {};

  // 薄化計算結果のキャッシュ
  final Map<String, bool> _dimPhotoCache = {};
  DateTime? _lastSelectedDate;
  int _lastSelectedCount = 0;

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
    // 薄化キャッシュをクリア（選択状態変更時）
    final currentSelectedDate = _groupingService.getSelectedDate(
      widget.controller.selectedPhotos,
    );
    final currentSelectedCount = widget.controller.selectedCount;

    if (_lastSelectedDate != currentSelectedDate ||
        _lastSelectedCount != currentSelectedCount) {
      _dimPhotoCache.clear();
      _lastSelectedDate = currentSelectedDate;
      _lastSelectedCount = currentSelectedCount;
    }

    _updatePhotoGroups();
  }

  void _updatePhotoGroups() {
    final groups = _groupingService.groupPhotosForTimeline(
      widget.controller.photoAssets,
    );

    // インデックスキャッシュを更新
    _rebuildPhotoIndexCache();

    if (mounted) {
      setState(() {
        _photoGroups = groups;
      });
    }
  }

  /// 写真インデックスキャッシュを再構築（パフォーマンス最適化）
  void _rebuildPhotoIndexCache() {
    _photoIndexCache.clear();
    final assets = widget.controller.photoAssets;
    for (int i = 0; i < assets.length; i++) {
      _photoIndexCache[assets[i].id] = i;
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

    // flutter_sticky_headerを使ったシンプルな実装
    return CustomScrollView(
      slivers: _photoGroups.map((group) {
        return SliverStickyHeader(
          header: _buildStickyHeader(group),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildPhotoGridForGroup(group, selectedDate),
              const SizedBox(height: AppSpacing.md),
            ]),
          ),
        );
      }).toList(),
    );
  }

  /// スティッキーヘッダーを構築
  Widget _buildStickyHeader(TimelinePhotoGroup group) {
    return Container(
      height: 48.0,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          group.displayName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }

  /// グループ用の写真グリッドを構築
  Widget _buildPhotoGridForGroup(
    TimelinePhotoGroup group,
    DateTime? selectedDate,
  ) {
    if (group.photos.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text('写真がありません', style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _crossAxisCount,
            crossAxisSpacing: _crossAxisSpacing,
            mainAxisSpacing: _mainAxisSpacing,
            childAspectRatio: _childAspectRatio,
          ),
          itemCount: group.photos.length,
          itemBuilder: (context, index) {
            final photo = group.photos[index];

            // キャッシュを使用してメインインデックスを高速取得
            final mainIndex = _photoIndexCache[photo.id] ?? -1;
            final isSelected =
                mainIndex >= 0 && mainIndex < widget.controller.selected.length
                ? widget.controller.selected[mainIndex]
                : false;
            final isUsed = mainIndex >= 0
                ? widget.controller.isPhotoUsed(mainIndex)
                : false;

            // キャッシュを使用した薄化判定（パフォーマンス最適化）
            final shouldDimPhoto = _shouldDimPhotoWithCache(
              photo: photo,
              selectedDate: selectedDate,
              isSelected: isSelected,
            );

            return GestureDetector(
              onTap: () => _handlePhotoTap(mainIndex),
              child: Stack(
                children: [
                  // アニメーション最適化: AnimatedOpacityでスムーズな薄化切替
                  AnimatedOpacity(
                    opacity: shouldDimPhoto ? 0.6 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeInOut,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0E0E0), // 固定値でパフォーマンス最適化
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(4),
                        ),
                        child: _OptimizedPhotoThumbnail(
                          photo: photo,
                          key: ValueKey(photo.id), // キーでWidgetの再利用を促進
                        ),
                      ),
                    ),
                  ),
                  // パフォーマンス最適化された選択インジケーター
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _OptimizedSelectionIndicator(
                      isSelected: isSelected,
                      isUsed: isUsed,
                      shouldDimPhoto: shouldDimPhoto,
                      primaryColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  // パフォーマンス最適化された使用済みラベル
                  if (isUsed) const _OptimizedUsedLabel(),
                ],
              ),
            );
          },
        );
      },
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

  /// 写真タップ時の処理
  void _handlePhotoTap(int mainIndex) {
    if (mainIndex < 0) return;

    if (widget.controller.isPhotoUsed(mainIndex)) {
      // 使用済み写真はタップしても何もしない（視覚的なラベルで十分）
      return;
    }

    // 現在の選択状態を保存
    final wasSelected = widget.controller.selected[mainIndex];

    // 選択解除の場合は制限チェック不要
    if (wasSelected) {
      widget.controller.toggleSelect(mainIndex);
      return;
    }

    // 選択可能かチェック
    if (!widget.controller.canSelectPhoto(mainIndex)) {
      // 選択上限に達している場合はダイアログを表示せず、何もしない
      if (widget.controller.selectedCount >= AppConstants.maxPhotosSelection) {
        return;
      }

      // 日付が異なる場合のチェック
      if (widget.onDifferentDateSelected != null) {
        widget.onDifferentDateSelected!();
      }
      return;
    }

    widget.controller.toggleSelect(mainIndex);
  }

  /// 指定日付が写真と同じ日付かどうかを判定
  bool _isSameDateAsPhoto(DateTime date, AssetEntity photo) {
    final photoDate = photo.createDateTime;
    return date.year == photoDate.year &&
        date.month == photoDate.month &&
        date.day == photoDate.day;
  }

  /// キャッシュ機能付きの薄化判定（パフォーマンス最適化）
  bool _shouldDimPhotoWithCache({
    required AssetEntity photo,
    required DateTime? selectedDate,
    required bool isSelected,
  }) {
    // 選択済みの写真は薄くしない
    if (isSelected) return false;

    // キャッシュから取得を試行
    final cacheKey =
        '${photo.id}_${selectedDate?.millisecondsSinceEpoch}_${widget.controller.selectedCount}';
    if (_dimPhotoCache.containsKey(cacheKey)) {
      return _dimPhotoCache[cacheKey]!;
    }

    // 計算して結果をキャッシュ
    final result = _calculateShouldDimPhoto(
      photo: photo,
      selectedDate: selectedDate,
      isSelected: isSelected,
    );
    _dimPhotoCache[cacheKey] = result;

    return result;
  }

  /// 写真を薄く表示するかどうかを判定（実際の計算ロジック）
  bool _calculateShouldDimPhoto({
    required AssetEntity photo,
    required DateTime? selectedDate,
    required bool isSelected,
  }) {
    // 選択済みの写真は薄くしない
    if (isSelected) return false;

    // 選択がない場合は薄くしない
    if (selectedDate == null) return false;

    // 3枚選択済みの場合は、未選択の写真をすべて薄くする
    if (widget.controller.selectedCount >= 3) return true;

    // そうでなければ、異なる日付の写真のみ薄くする
    return !_isSameDateAsPhoto(selectedDate, photo);
  }
}

/// パフォーマンス最適化された写真サムネイルウィジェット
class _OptimizedPhotoThumbnail extends StatelessWidget {
  const _OptimizedPhotoThumbnail({super.key, required this.photo});

  final AssetEntity photo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: photo.thumbnailData,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            // メモリ使用量最適化のためキャッシュを有効化
            isAntiAlias: false,
            filterQuality: FilterQuality.low,
          );
        } else {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFBDBDBD),
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF9E9E9E),
              ),
            ),
          );
        }
      },
    );
  }
}

/// パフォーマンス最適化された選択インジケーター
class _OptimizedSelectionIndicator extends StatelessWidget {
  const _OptimizedSelectionIndicator({
    required this.isSelected,
    required this.isUsed,
    required this.shouldDimPhoto,
    required this.primaryColor,
  });

  final bool isSelected;
  final bool isUsed;
  final bool shouldDimPhoto;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isSelected || isUsed ? Colors.white : Colors.transparent,
        shape: BoxShape.circle,
        border: !isSelected && !isUsed && !shouldDimPhoto
            ? Border.all(
                color: const Color(0xB3FFFFFF), // 固定値でパフォーマンス最適化
                width: 2,
              )
            : null,
        boxShadow: shouldDimPhoto
            ? null
            : const [
                BoxShadow(
                  color: Color(0x33000000), // 固定値でパフォーマンス最適化
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: (isSelected || isUsed)
          ? Icon(
              isUsed ? Icons.done : Icons.check_circle,
              size: 19,
              color: isUsed ? Colors.orange : primaryColor,
            )
          : null,
    );
  }
}

/// パフォーマンス最適化された使用済みラベル
class _OptimizedUsedLabel extends StatelessWidget {
  const _OptimizedUsedLabel();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 4,
      left: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xE6FF9800), // 固定値でパフォーマンス最適化
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          '使用済み',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
