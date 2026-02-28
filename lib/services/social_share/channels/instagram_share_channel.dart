import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../../../constants/app_constants.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/result/result.dart';
import '../../../core/service_registration.dart';
import '../../../models/diary_entry.dart';
import '../../interfaces/logging_service_interface.dart';
import '../../diary_image_generator.dart';
import '../../interfaces/social_share_service_interface.dart';
import '../../interfaces/settings_service_interface.dart';
import '../share_channel_mixin.dart';

/// Instagram系（埋め込み画像を生成して共有）チャネル実装
class InstagramShareChannel with ShareChannelMixin {
  final ILoggingService _logger;
  final DiaryImageGenerator _imageGenerator;

  InstagramShareChannel({
    required ILoggingService logger,
    required DiaryImageGenerator imageGenerator,
  }) : _logger = logger,
       _imageGenerator = imageGenerator;

  Future<Result<void>> share({
    required DiaryEntry diary,
    required ShareFormat format,
    List<AssetEntity>? photos,
    Rect? shareOrigin,
  }) async {
    // ロケールを先に解決（catch でも使えるようスコープ外に）
    Locale? locale;
    try {
      final settingsService =
          await ServiceRegistration.getAsync<ISettingsService>();
      locale = settingsService.locale;
    } catch (_) {
      locale = null;
    }
    final resolvedLocale = locale ?? ui.PlatformDispatcher.instance.locale;

    try {
      _logger.info(
        'Starting Instagram share: ${format.name}',
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

      await SharePlus.instance
          .share(
            ShareParams(
              files: [XFile(imageFile.path)],
              text: '${diary.title}\n\n${AppConstants.shareHashtag}',
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

      _logger.info(
        'Instagram share succeeded',
        context: 'InstagramShareChannel.share',
      );
      return const Success<void>(null);
    } catch (e, st) {
      _logger.error(
        'Instagram share error',
        context: 'InstagramShareChannel.share',
        error: e,
        stackTrace: st,
      );
      final errorMessage = getLocalizedMessage(
        resolvedLocale,
        (l10n) => l10n.commonShareFailedWithReason('Image sharing failed'),
        'Image sharing failed',
      );
      return Failure<void>(
        InstagramShareException(errorMessage, originalError: e, stackTrace: st),
      );
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
