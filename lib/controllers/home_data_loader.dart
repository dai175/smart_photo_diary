import 'dart:async';

import 'package:photo_manager/photo_manager.dart';

import '../constants/app_constants.dart';
import '../core/result/result.dart';
import '../core/service_registration.dart';
import '../models/diary_change.dart';
import '../models/diary_entry.dart';
import '../models/photo_type_filter.dart';
import '../services/interfaces/diary_service_interface.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../services/photo_filter_service.dart';
import 'home_controller.dart';
import 'photo_selection_controller.dart';

/// Home timeline load / refresh / plan-access-day sync.
///
/// Extracted from HomeScreen State so the IO paths can be unit-tested
/// without the tab/navigation god object.
class HomeDataLoader {
  /// Timeline load window (locked photos stay in the list, blurred).
  static const loadDays = 365;

  static const _photosPerPage = AppConstants.timelinePageSize;

  final IPhotoService _photoService;
  final ISubscriptionService _subscriptionService;
  final ILoggingService _logger;
  final PhotoSelectionController _photoController;
  final HomeController _homeController;
  final bool Function() _isMounted;
  final Future<void> Function() _onPermissionDenied;
  final Future<void> Function() _onLimitedAccess;
  final Future<IDiaryService> Function() _resolveDiaryService;

  IDiaryService? _diaryService;
  PhotoTypeFilter photoTypeFilter;
  Set<String> _screenshotAssetIds = {};
  int _currentPhotoOffset = 0;
  bool _isRequestingPermission = false;
  bool _isPreloading = false;
  StreamSubscription<DiaryChange>? _diarySub;

  HomeDataLoader({
    required IPhotoService photoService,
    required ISubscriptionService subscriptionService,
    required ILoggingService logger,
    required PhotoSelectionController photoController,
    required HomeController homeController,
    required bool Function() isMounted,
    required this.photoTypeFilter,
    required Future<void> Function() onPermissionDenied,
    required Future<void> Function() onLimitedAccess,
    IDiaryService? diaryService,
    Future<IDiaryService> Function()? resolveDiaryService,
  }) : _photoService = photoService,
       _subscriptionService = subscriptionService,
       _logger = logger,
       _photoController = photoController,
       _homeController = homeController,
       _isMounted = isMounted,
       _onPermissionDenied = onPermissionDenied,
       _onLimitedAccess = onLimitedAccess,
       _diaryService = diaryService,
       _resolveDiaryService =
           resolveDiaryService ??
           (() => ServiceRegistration.getAsync<IDiaryService>());

  Future<void> loadTodayPhotos() async {
    if (!_isMounted()) return;

    if (_isRequestingPermission) {
      return;
    }

    _isRequestingPermission = true;
    _photoController.setLoading(true);

    try {
      final permissionResult = await _photoService.requestPermission();
      final hasPermission = permissionResult.getOrDefault(false);

      if (!_isMounted()) return;

      _photoController.setPermission(hasPermission);

      if (!hasPermission) {
        _photoController.setLoading(false);
        await _onPermissionDenied();
        return;
      }

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      await syncAccessibleDays();

      if (photoTypeFilter == PhotoTypeFilter.photosOnly) {
        final idsResult = await PhotoFilterService.getScreenshotAssetIds(
          _logger,
        );
        _screenshotAssetIds = idsResult.getOrDefault({});
      } else {
        _screenshotAssetIds = {};
      }

      final photosResult = await _photoService.getPhotosInDateRange(
        startDate: todayStart.subtract(const Duration(days: loadDays)),
        endDate: todayStart.add(const Duration(days: 1)),
        limit: _photosPerPage,
      );
      final dateFilteredPhotos = photosResult.getOrDefault([]);
      final photos = PhotoFilterService.filterByPhotoType(
        dateFilteredPhotos,
        photoTypeFilter,
        _screenshotAssetIds,
      );

      if (!_isMounted()) return;

      if (photos.isEmpty) {
        final isLimited = (await _photoService.isLimitedAccess()).getOrDefault(
          false,
        );
        if (isLimited) {
          await _onLimitedAccess();
        }
      }

      _photoController.setPhotoAssets(photos);
      _currentPhotoOffset = dateFilteredPhotos.length;
      // dateFilteredPhotos is post-date-filter (not truly raw from album).
      // On Android, DateTimeCond may include photos outside the range
      // (e.g. DATE_ADDED vs DATE_TAKEN mismatch), which the service then
      // removes. Using `< pageSize` would prematurely stop pagination
      // if even 1 photo is filtered out. Use isEmpty instead.
      if (dateFilteredPhotos.isEmpty) {
        _photoController.setHasMorePhotos(false);
      } else {
        _photoController.setHasMorePhotos(true);
      }
      _photoController.setLoading(false);

      if (_isMounted() && _photoController.hasMorePhotos) {
        Future.microtask(() => preloadMorePhotos(showLoading: false));
      }
    } catch (e) {
      if (_isMounted()) {
        _photoController.setPhotoAssets([]);
        _photoController.setLoading(false);
      }
    } finally {
      _isRequestingPermission = false;
    }
  }

  Future<void> loadMorePhotos() async {
    await preloadMorePhotos(showLoading: true);
  }

  Future<void> preloadMorePhotos({bool showLoading = false}) async {
    if (!_isMounted() ||
        _isRequestingPermission ||
        !_photoController.hasMorePhotos) {
      if (!showLoading) {
        _logger.info(
          'Preload skipped: mounted=${_isMounted()}, requesting=$_isRequestingPermission, hasMore=${_photoController.hasMorePhotos}',
          context: 'HomeDataLoader.preloadMorePhotos',
        );
      }
      return;
    }

    if (_isPreloading) {
      if (!showLoading) {
        _logger.info(
          'Preload skipped: already preloading',
          context: 'HomeDataLoader.preloadMorePhotos',
        );
      }
      return;
    }

    _isPreloading = true;

    if (!showLoading) {
      _logger.info(
        'Starting preload',
        context: 'HomeDataLoader.preloadMorePhotos',
      );
    }

    if (showLoading) {
      _photoController.setLoading(true);
    }

    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      final preloadPages = showLoading ? 1 : AppConstants.timelinePreloadPages;
      final requested = _photosPerPage * preloadPages;

      final newPhotosResult = await _photoService.getPhotosEfficient(
        startDate: todayStart.subtract(const Duration(days: loadDays)),
        endDate: todayStart.add(const Duration(days: 1)),
        offset: _currentPhotoOffset,
        limit: requested,
      );
      final dateFilteredNewPhotos = newPhotosResult.getOrDefault([]);
      final newPhotos = PhotoFilterService.filterByPhotoType(
        dateFilteredNewPhotos,
        photoTypeFilter,
        _screenshotAssetIds,
      );

      if (!_isMounted()) return;

      final currentCount = _photoController.photoAssets.length;

      if (!showLoading) {
        _logger.info(
          'Preload result: current=$currentCount, new=${newPhotos.length}, offset=$_currentPhotoOffset, req=$requested',
          context: 'HomeDataLoader.preloadMorePhotos',
        );
      }

      _currentPhotoOffset += dateFilteredNewPhotos.length;
      _photoController.setHasMorePhotos(dateFilteredNewPhotos.isNotEmpty);

      if (newPhotos.isNotEmpty) {
        final combined = <AssetEntity>[
          ..._photoController.photoAssets,
          ...newPhotos,
        ];
        _photoController.setPhotoAssetsPreservingSelection(combined);
      }

      if (dateFilteredNewPhotos.isEmpty && !showLoading) {
        _logger.info(
          'Preload finished: no more photos',
          context: 'HomeDataLoader.preloadMorePhotos',
        );
      }
    } catch (e) {
      _logger.error(
        'Preload photo loading error',
        context: 'HomeDataLoader.preloadMorePhotos',
        error: e,
      );
    } finally {
      _isPreloading = false;
      if (showLoading) {
        _photoController.setLoading(false);
      }
    }
  }

  Future<void> loadUsedPhotoIds() async {
    try {
      _diaryService ??= await _resolveDiaryService();
      final result = await _diaryService!.getSortedDiaryEntries();
      switch (result) {
        case Success(data: final entries):
          _collectUsedPhotoIds(entries);
        case Failure(exception: final e):
          _logger.error(
            'Error loading used photo IDs',
            error: e,
            context: 'HomeDataLoader',
          );
      }
    } catch (e) {
      _logger.error(
        'Error loading used photo IDs',
        error: e,
        context: 'HomeDataLoader',
      );
    }
  }

  void _collectUsedPhotoIds(List<DiaryEntry> allEntries) {
    final usedIds = <String>{};
    for (final entry in allEntries) {
      usedIds.addAll(entry.photoIds);
    }
    _photoController.setUsedPhotoIds(usedIds);
  }

  Future<void> subscribeDiaryChanges() async {
    try {
      _diaryService ??= await _resolveDiaryService();
      _diarySub = _diaryService!.changes.listen((change) {
        switch (change.type) {
          case DiaryChangeType.created:
            _photoController.addUsedPhotoIds(change.addedPhotoIds);
            break;
          case DiaryChangeType.updated:
            if (change.removedPhotoIds.isNotEmpty) {
              _photoController.removeUsedPhotoIds(change.removedPhotoIds);
            }
            if (change.addedPhotoIds.isNotEmpty) {
              _photoController.addUsedPhotoIds(change.addedPhotoIds);
            }
            break;
          case DiaryChangeType.deleted:
            _photoController.removeUsedPhotoIds(change.removedPhotoIds);
            break;
        }
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> onDiaryCreated() async {
    _homeController.refreshDiaryAndStats();
    await loadUsedPhotoIds();
  }

  Future<void> syncAccessibleDays() async {
    final planAccessDays = await _getPlanAccessDays();
    if (!_isMounted()) return;
    _photoController.setAccessibleDays(planAccessDays);
  }

  Future<int> _getPlanAccessDays() async {
    int accessDays = 1;
    try {
      final planResult = await _subscriptionService.getCurrentPlanClass();
      if (planResult.isSuccess) {
        accessDays = planResult.value.pastPhotoAccessDays;
      }
    } catch (e) {
      _logger.error(
        'Failed to get plan info',
        error: e,
        context: 'HomeDataLoader._getPlanAccessDays',
      );
    }

    return accessDays;
  }

  Future<void> refreshHome() async {
    _currentPhotoOffset = 0;
    _isPreloading = false;
    _photoController.setHasMorePhotos(true);
    await loadTodayPhotos();
    await loadUsedPhotoIds();
  }

  IDiaryService? get diaryService => _diaryService;

  Future<IDiaryService> ensureDiaryService() async {
    return _diaryService ??= await _resolveDiaryService();
  }

  void dispose() {
    _diarySub?.cancel();
    _diarySub = null;
  }
}
