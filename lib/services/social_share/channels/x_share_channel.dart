import 'dart:ui';

import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/result/result.dart';
import '../../../core/service_locator.dart';
import '../../../core/service_registration.dart';
import '../../../localization/localization_utils.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../constants/app_constants.dart';
import '../../../models/diary_entry.dart';
import '../../logging_service.dart';
import '../../settings_service.dart';

/// テキスト共有チャネル実装（各プラットフォームで利用可能）
class XShareChannel {
  static const int _shareTimeoutSeconds = 60;
  static const Rect _defaultShareOrigin = Rect.fromLTWH(0, 0, 1, 1);

  LoggingService get _logger => serviceLocator.get<LoggingService>();

  Future<Result<void>> share({
    required DiaryEntry diary,
    List<AssetEntity>? photos,
    Rect? shareOrigin,
  }) async {
    try {
      _logger.info(
        'テキスト共有開始',
        context: 'XShareChannel.share',
        data: 'diary_id: ${diary.id}',
      );

      // 画像の準備（最大3枚）
      final assets = photos ?? await diary.getPhotoAssets();
      final limited = assets.take(AppConstants.maxPhotosSelection).toList();
      final files = <XFile>[];
      for (final a in limited) {
        final f = await a.file;
        if (f != null && f.existsSync()) {
          files.add(XFile(f.path));
        }
      }

      // テキスト生成
      Locale? locale;
      try {
        final settingsService =
            await ServiceRegistration.getAsync<SettingsService>();
        locale = settingsService.locale;
      } catch (_) {
        locale = null;
      }

      final resolvedLocale = locale ?? PlatformDispatcher.instance.locale;
      final appName = LocalizationUtils.appTitleFor(resolvedLocale);

      // シンプルなテキスト生成（文字数制限なし）
      final parts = <String>[];
      if (diary.title.isNotEmpty) {
        parts.add(diary.title);
      }
      if (diary.content.isNotEmpty) {
        parts.add(diary.content);
      }
      parts.add(appName);

      final text = parts.join('\n\n');

      await Share.shareXFiles(
        files,
        text: text,
        sharePositionOrigin: shareOrigin ?? _defaultShareOrigin,
      ).timeout(
        const Duration(seconds: _shareTimeoutSeconds),
        onTimeout: () {
          final timeoutMessage = _getLocalizedMessage(
            resolvedLocale,
            (l10n) => l10n.commonShareTimeout,
            'Sharing timed out',
          );
          throw Exception(timeoutMessage);
        },
      );

      _logger.info('テキスト共有成功', context: 'XShareChannel.share');
      return const Success<void>(null);
    } catch (e, st) {
      _logger.error(
        'テキスト共有エラー',
        context: 'XShareChannel.share',
        error: e,
        stackTrace: st,
      );

      // Get current locale for error message
      Locale? locale;
      try {
        final settingsService =
            await ServiceRegistration.getAsync<SettingsService>();
        locale = settingsService.locale;
      } catch (_) {
        locale = null;
      }
      final resolvedLocale = locale ?? PlatformDispatcher.instance.locale;

      final errorMessage = _getLocalizedMessage(
        resolvedLocale,
        (l10n) => l10n.commonShareFailedWithReason('Text sharing failed'),
        'Text sharing failed',
      );
      return Failure<void>(
        XShareException(errorMessage, originalError: e, stackTrace: st),
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

class XShareException extends AppException {
  const XShareException(
    super.message, {
    super.details,
    super.originalError,
    super.stackTrace,
  });
}
