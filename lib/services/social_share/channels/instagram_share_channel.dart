import 'dart:io';
import 'dart:ui';

import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/result/result.dart';
import '../../../core/service_locator.dart';
import '../../../core/service_registration.dart';
import '../../../models/diary_entry.dart';
import '../../logging_service.dart';
import '../../diary_image_generator.dart';
import '../../interfaces/social_share_service_interface.dart';
import '../../settings_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../localization/localization_utils.dart';

/// Instagram系（埋め込み画像を生成して共有）チャネル実装
class InstagramShareChannel {
  static const int _shareTimeoutSeconds = 60;
  static const Rect _defaultShareOrigin = Rect.fromLTWH(0, 0, 1, 1);

  LoggingService get _logger => serviceLocator.get<LoggingService>();
  DiaryImageGenerator get _imageGenerator => DiaryImageGenerator.getInstance();

  Future<Result<void>> share({
    required DiaryEntry diary,
    required ShareFormat format,
    List<AssetEntity>? photos,
    Rect? shareOrigin,
  }) async {
    try {
      _logger.info(
        'Instagram共有開始: ${format.displayName}',
        context: 'InstagramShareChannel.share',
        data: 'diary_id: ${diary.id}',
      );

      final imageResult = await _imageGenerator.generateImage(
        diary: diary,
        format: format,
        photos: photos,
      );
      if (imageResult.isFailure) {
        return Failure<void>(imageResult.error);
      }

      final File imageFile = imageResult.value;

      await Share.shareXFiles(
        [XFile(imageFile.path)],
        text: '${diary.title}\n\n#SmartPhotoDiary で生成',
        sharePositionOrigin: shareOrigin ?? _defaultShareOrigin,
      ).timeout(
        const Duration(seconds: _shareTimeoutSeconds),
        onTimeout: () {
          // Get current locale for error message
          Locale? locale;
          try {
            final settingsService = ServiceRegistration.get<SettingsService>();
            locale = settingsService.locale;
          } catch (_) {
            locale = null;
          }
          final resolvedLocale = locale ?? PlatformDispatcher.instance.locale;
          final timeoutMessage = _getLocalizedMessage(
            resolvedLocale,
            (l10n) => l10n.commonShareTimeout,
            'Sharing timed out',
          );
          throw Exception(timeoutMessage);
        },
      );

      _logger.info('Instagram共有成功', context: 'InstagramShareChannel.share');
      return const Success<void>(null);
    } catch (e, st) {
      _logger.error(
        'Instagram共有エラー',
        context: 'InstagramShareChannel.share',
        error: e,
        stackTrace: st,
      );
      // Get current locale for error message
      Locale? locale;
      try {
        final settingsService = ServiceRegistration.get<SettingsService>();
        locale = settingsService.locale;
      } catch (_) {
        locale = null;
      }
      final resolvedLocale = locale ?? PlatformDispatcher.instance.locale;
      final errorMessage = _getLocalizedMessage(
        resolvedLocale,
        (l10n) => l10n.commonShareFailedWithReason('Image sharing failed'),
        'Image sharing failed',
      );
      return Failure<void>(
        InstagramShareException(errorMessage, originalError: e, stackTrace: st),
      );
    }
  }

  String _getLocalizedMessage(
    Locale locale,
    String Function(AppLocalizations) getMessage,
    String fallback,
  ) {
    try {
      final l10n = LocalizationUtils.resolveFor(locale);
      return getMessage(l10n);
    } catch (_) {
      return fallback;
    }
  }
}

class InstagramShareException extends AppException {
  const InstagramShareException(
    super.message, {
    super.details,
    super.originalError,
    super.stackTrace,
  });
}
