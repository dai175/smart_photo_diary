import 'package:flutter/foundation.dart';

typedef PhotoDetailCallback = void Function(String photoId);

/// タイムライン関連のコールバックをグループ化するパラメータオブジェクト
///
/// HomeScreen → HomeContentWidget → TimelineFABIntegration → TimelinePhotoWidget の
/// 3段パススルーで重複していたコールバック群を統合する。
class TimelineCallbacks {
  final VoidCallback? onSelectionLimitReached;
  final VoidCallback? onUsedPhotoSelected;
  final PhotoDetailCallback? onUsedPhotoDetail;
  final VoidCallback? onRequestPermission;
  final VoidCallback? onDifferentDateSelected;
  final VoidCallback? onLockedPhotoTapped;
  final VoidCallback? onCameraPressed;
  final VoidCallback? onDiaryCreated;
  final VoidCallback? onLoadMorePhotos;
  final VoidCallback? onPreloadMorePhotos;

  const TimelineCallbacks({
    this.onSelectionLimitReached,
    this.onUsedPhotoSelected,
    this.onUsedPhotoDetail,
    this.onRequestPermission,
    this.onDifferentDateSelected,
    this.onLockedPhotoTapped,
    this.onCameraPressed,
    this.onDiaryCreated,
    this.onLoadMorePhotos,
    this.onPreloadMorePhotos,
  });
}
