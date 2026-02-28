import 'dart:ui';

import 'package:photo_manager/photo_manager.dart';
import 'package:characters/characters.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/result/result.dart';
import '../../../core/service_registration.dart';
import '../../../localization/localization_utils.dart';
import '../../../constants/app_constants.dart';
import '../../../models/diary_entry.dart';
import '../../interfaces/logging_service_interface.dart';
import '../../interfaces/photo_service_interface.dart';
import '../../interfaces/settings_service_interface.dart';
import '../share_channel_mixin.dart';

/// テキスト共有チャネル実装（各プラットフォームで利用可能）
class XShareChannel with ShareChannelMixin {
  static const int _xCharLimit = 280;

  final ILoggingService _logger;
  final IPhotoService _photoService;

  XShareChannel({
    required ILoggingService logger,
    required IPhotoService photoService,
  }) : _logger = logger,
       _photoService = photoService;

  Future<Result<void>> share({
    required DiaryEntry diary,
    List<AssetEntity>? photos,
    Rect? shareOrigin,
  }) async {
    try {
      _logger.info(
        'Starting text share',
        context: 'XShareChannel.share',
        data: 'diary_id: ${diary.id}',
      );

      // 画像の準備（最大3枚）
      List<AssetEntity> assets;
      if (photos != null) {
        assets = photos;
      } else {
        final result = await _photoService.getAssetsByIds(diary.photoIds);
        if (result.isFailure) {
          _logger.warning(
            'Failed to load photo assets for sharing',
            context: 'XShareChannel.share',
            data: 'diary_id: ${diary.id}, error: ${result.error.message}',
          );
        }
        assets = result.getOrDefault([]);
      }
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
            await ServiceRegistration.getAsync<ISettingsService>();
        locale = settingsService.locale;
      } catch (_) {
        locale = null;
      }

      final resolvedLocale = locale ?? PlatformDispatcher.instance.locale;
      final appName = LocalizationUtils.appTitleFor(resolvedLocale);

      // テキスト生成（280文字以内ならアプリ名を付与、超える場合は省略）
      final bodyParts = <String>[];
      if (diary.title.isNotEmpty) {
        bodyParts.add(diary.title);
      }
      if (diary.content.isNotEmpty) {
        bodyParts.add(diary.content);
      }
      final bodyText = bodyParts.join('\n\n');
      final textWithAppName = '$bodyText\n\n$appName';
      final text = textWithAppName.characters.length <= _xCharLimit
          ? textWithAppName
          : bodyText;

      await SharePlus.instance
          .share(
            ShareParams(
              files: files,
              text: text,
              sharePositionOrigin:
                  shareOrigin ?? ShareChannelMixin.defaultShareOrigin,
            ),
          )
          .timeout(
            const Duration(seconds: ShareChannelMixin.shareTimeoutSeconds),
            onTimeout: () {
              final timeoutMessage = getLocalizedMessage(
                resolvedLocale,
                (l10n) => l10n.commonShareTimeout,
                'Sharing timed out',
              );
              throw Exception(timeoutMessage);
            },
          );

      _logger.info('Text share succeeded', context: 'XShareChannel.share');
      return const Success<void>(null);
    } catch (e, st) {
      _logger.error(
        'Text share error',
        context: 'XShareChannel.share',
        error: e,
        stackTrace: st,
      );

      // Get current locale for error message
      Locale? locale;
      try {
        final settingsService =
            await ServiceRegistration.getAsync<ISettingsService>();
        locale = settingsService.locale;
      } catch (_) {
        locale = null;
      }
      final resolvedLocale = locale ?? PlatformDispatcher.instance.locale;

      final errorMessage = getLocalizedMessage(
        resolvedLocale,
        (l10n) => l10n.commonShareFailedWithReason('Text sharing failed'),
        'Text sharing failed',
      );
      return Failure<void>(
        XShareException(errorMessage, originalError: e, stackTrace: st),
      );
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
