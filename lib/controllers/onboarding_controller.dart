import 'package:flutter/material.dart';

import '../core/service_locator.dart';
import '../core/service_registration.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../services/interfaces/settings_service_interface.dart';

/// OnboardingScreen の状態管理コントローラー
class OnboardingController extends ChangeNotifier {
  static const int _lastPageIndex = 4;

  int _currentPage = 0;
  bool _isProcessing = false;
  bool _disposed = false;

  ILoggingService get _logger => serviceLocator.get<ILoggingService>();

  int get currentPage => _currentPage;
  bool get isProcessing => _isProcessing;
  bool get isLastPage => _currentPage == _lastPageIndex;
  bool get isFirstPage => _currentPage == 0;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void setCurrentPage(int page) {
    if (_currentPage != page) {
      _currentPage = page;
      _safeNotifyListeners();
    }
  }

  void nextPage(PageController controller) {
    if (_currentPage < _lastPageIndex) {
      controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousPage(PageController controller) {
    if (_currentPage > 0) {
      controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// オンボーディング完了処理を実行し、成功したかどうかを返す
  Future<bool> completeOnboarding() async {
    _isProcessing = true;
    _safeNotifyListeners();

    try {
      final settingsService =
          await ServiceRegistration.getAsync<ISettingsService>();
      await settingsService.setFirstLaunchCompleted();

      final photoService = ServiceRegistration.get<IPhotoService>();
      await photoService.requestPermission();

      _logger.info('Onboarding completed', context: 'OnboardingScreen');
      return true;
    } catch (e) {
      _logger.error(
        'Onboarding completion error',
        error: e,
        context: 'OnboardingScreen',
      );
      return true; // エラーでもホーム画面に遷移する
    } finally {
      _isProcessing = false;
      _safeNotifyListeners();
    }
  }
}
