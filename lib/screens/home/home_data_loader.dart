part of '../home_screen.dart';

// ---------------------------------------------------------------------------
// _HomeScreenState データ読み込み系メソッド (mixin)
// ---------------------------------------------------------------------------

mixin _HomeDataLoaderMixin on State<HomeScreen> {
  _HomeScreenState get _self => this as _HomeScreenState;

  Future<void> _loadTodayPhotos() async {
    if (!mounted) return;

    if (_self._isRequestingPermission) {
      return;
    }

    _self._isRequestingPermission = true;
    _self._photoController.setLoading(true);

    try {
      final photoService = ServiceRegistration.get<IPhotoService>();
      final permissionResult = await photoService.requestPermission();
      final hasPermission = permissionResult.getOrDefault(false);

      if (!mounted) return;

      _self._photoController.setPermission(hasPermission);

      if (!hasPermission) {
        _self._photoController.setLoading(false);
        await _self._showPermissionDeniedDialog();
        return;
      }

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      // Always load 365 days of photos (locked photos shown as blurred)
      const loadDays = 365;

      // Determine actual plan access days for lock state
      final planAccessDays = await _getPlanAccessDays();
      _self._photoController.setAccessibleDays(planAccessDays);

      final photosResult = await photoService.getPhotosInDateRange(
        startDate: todayStart.subtract(const Duration(days: loadDays)),
        endDate: todayStart.add(const Duration(days: 1)),
        limit: _HomeScreenState._photosPerPage,
      );
      final photos = photosResult.getOrDefault([]);

      if (!mounted) return;

      if (photos.isEmpty) {
        final isLimited = (await photoService.isLimitedAccess()).getOrDefault(
          false,
        );
        if (isLimited) {
          await _self._showLimitedAccessDialog();
        }
      }

      _self._photoController.setPhotoAssets(photos);
      _self._currentPhotoOffset = photos.length;
      if (photos.length < _HomeScreenState._photosPerPage) {
        _self._photoController.setHasMorePhotos(false);
      } else {
        _self._photoController.setHasMorePhotos(true);
      }
      _self._photoController.setLoading(false);

      if (mounted && _self._photoController.hasMorePhotos) {
        Future.microtask(() => _preloadMorePhotos(showLoading: false));
      }
    } catch (e) {
      if (mounted) {
        _self._photoController.setPhotoAssets([]);
        _self._photoController.setLoading(false);
      }
    } finally {
      _self._isRequestingPermission = false;
    }
  }

  Future<void> _loadMorePhotos() async {
    await _preloadMorePhotos(showLoading: true);
  }

  Future<void> _preloadMorePhotos({bool showLoading = false}) async {
    if (!mounted ||
        _self._isRequestingPermission ||
        !_self._photoController.hasMorePhotos) {
      if (!showLoading) {
        _self._logger.info(
          'Preload skipped: mounted=$mounted, requesting=${_self._isRequestingPermission}, hasMore=${_self._photoController.hasMorePhotos}',
          context: 'HomeScreen._preloadMorePhotos',
        );
      }
      return;
    }

    if (_self._isPreloading) {
      if (!showLoading) {
        _self._logger.info(
          'Preload skipped: already preloading',
          context: 'HomeScreen._preloadMorePhotos',
        );
      }
      return;
    }

    _self._isPreloading = true;

    if (!showLoading) {
      _self._logger.info(
        'Starting preload',
        context: 'HomeScreen._preloadMorePhotos',
      );
    }

    if (showLoading) {
      _self._photoController.setLoading(true);
    }

    try {
      final photoService = ServiceRegistration.get<IPhotoService>();
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      // Always load 365 days of photos (locked photos shown as blurred)
      const loadDays = 365;

      final preloadPages = showLoading ? 1 : AppConstants.timelinePreloadPages;
      final requested = _HomeScreenState._photosPerPage * preloadPages;

      final newPhotosResult = await photoService.getPhotosEfficient(
        startDate: todayStart.subtract(const Duration(days: loadDays)),
        endDate: todayStart.add(const Duration(days: 1)),
        offset: _self._currentPhotoOffset,
        limit: requested,
      );
      final newPhotos = newPhotosResult.getOrDefault([]);

      if (!mounted) return;

      final currentCount = _self._photoController.photoAssets.length;

      if (!showLoading) {
        _self._logger.info(
          'Preload result: current=$currentCount, new=${newPhotos.length}, offset=${_self._currentPhotoOffset}, req=$requested',
          context: 'HomeScreen._preloadMorePhotos',
        );
      }

      if (newPhotos.isNotEmpty) {
        final combined = <AssetEntity>[
          ..._self._photoController.photoAssets,
          ...newPhotos,
        ];
        _self._photoController.setPhotoAssetsPreservingSelection(combined);
        _self._currentPhotoOffset += newPhotos.length;
        final reachedEnd = newPhotos.length < requested;
        _self._photoController.setHasMorePhotos(!reachedEnd);
      } else {
        _self._photoController.setHasMorePhotos(false);

        if (!showLoading) {
          _self._logger.info(
            'Preload finished: no more photos',
            context: 'HomeScreen._preloadMorePhotos',
          );
        }
      }
    } catch (e) {
      _self._logger.error(
        'Preload photo loading error',
        context: 'HomeScreen._preloadMorePhotos',
        error: e,
      );
    } finally {
      _self._isPreloading = false;
      if (showLoading) {
        _self._photoController.setLoading(false);
      }
    }
  }

  Future<void> _loadUsedPhotoIds() async {
    try {
      final diaryService = await ServiceRegistration.getAsync<IDiaryService>();
      final result = await diaryService.getSortedDiaryEntries();
      switch (result) {
        case Success(data: final entries):
          _collectUsedPhotoIds(entries);
        case Failure(exception: final e):
          _self._logger.error(
            'Error loading used photo IDs',
            error: e,
            context: 'HomeScreen',
          );
      }
    } catch (e) {
      _self._logger.error(
        'Error loading used photo IDs',
        error: e,
        context: 'HomeScreen',
      );
    }
  }

  void _collectUsedPhotoIds(List<DiaryEntry> allEntries) {
    final usedIds = <String>{};
    for (final entry in allEntries) {
      usedIds.addAll(entry.photoIds);
    }
    _self._photoController.setUsedPhotoIds(usedIds);
  }

  Future<void> _subscribeDiaryChanges() async {
    try {
      final diaryService = await ServiceRegistration.getAsync<IDiaryService>();
      _self._diarySub = diaryService.changes.listen((change) {
        switch (change.type) {
          case DiaryChangeType.created:
            _self._photoController.addUsedPhotoIds(change.addedPhotoIds);
            break;
          case DiaryChangeType.updated:
            if (change.removedPhotoIds.isNotEmpty) {
              _self._photoController.removeUsedPhotoIds(change.removedPhotoIds);
            }
            if (change.addedPhotoIds.isNotEmpty) {
              _self._photoController.addUsedPhotoIds(change.addedPhotoIds);
            }
            break;
          case DiaryChangeType.deleted:
            _self._photoController.removeUsedPhotoIds(change.removedPhotoIds);
            break;
        }
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _onDiaryCreated() async {
    _self._homeController.refreshDiaryAndStats();
    await _loadUsedPhotoIds();
  }

  Future<int> _getPlanAccessDays() async {
    int accessDays = 1;
    try {
      final subscriptionService =
          await ServiceRegistration.getAsync<ISubscriptionService>();
      final planResult = await subscriptionService.getCurrentPlanClass();
      if (planResult.isSuccess) {
        final plan = planResult.value;
        accessDays = plan.isPremium ? 365 : 1;
      }
    } catch (e) {
      _self._logger.error(
        'Failed to get plan info',
        error: e,
        context: 'HomeScreen._getPlanAccessDays',
      );
    }

    return accessDays;
  }
}
