import 'dart:typed_data';
import 'dart:ui';

import 'package:photo_manager/photo_manager.dart';

import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';
import '../models/diary_length.dart';
import '../services/interfaces/ai_service_interface.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../utils/photo_date_resolver.dart';

/// AI日記生成の結果
class GenerationOutput {
  final String title;
  final String content;

  const GenerationOutput({required this.title, required this.content});
}

/// AI日記生成ロジックを担当する内部委譲クラス
class DiaryPreviewGenerationDelegate {
  final IPhotoService _photoService;
  final ILoggingService _logger;

  DiaryPreviewGenerationDelegate({
    required IPhotoService photoService,
    required ILoggingService logger,
  }) : _photoService = photoService,
       _logger = logger;

  /// 単一写真からAI日記を生成
  Future<Result<GenerationOutput>> generateFromSinglePhoto({
    required IAiService aiService,
    required AssetEntity asset,
    required DateTime photoDateTime,
    required Locale locale,
    String? prompt,
    String? contextText,
    DiaryLength diaryLength = DiaryLength.standard,
  }) async {
    final imageResult = await _photoService.getImageForAi(asset);
    if (imageResult.isFailure) {
      return Failure(imageResult.error);
    }

    final resultFromAi = await aiService.generateDiaryFromImage(
      imageData: imageResult.value,
      date: photoDateTime,
      prompt: prompt,
      contextText: contextText,
      locale: locale,
      diaryLength: diaryLength,
    );

    if (resultFromAi.isFailure) {
      return Failure(resultFromAi.error);
    }

    final value = resultFromAi.value;
    return Success(
      GenerationOutput(title: value.title, content: value.content),
    );
  }

  /// 複数写真からAI日記を生成
  Future<Result<GenerationOutput>> generateFromMultiplePhotos({
    required IAiService aiService,
    required List<AssetEntity> assets,
    required Locale locale,
    String? prompt,
    String? contextText,
    DiaryLength diaryLength = DiaryLength.standard,
    void Function(int current, int total)? onProgress,
  }) async {
    _logger.info(
      'Starting sequential analysis of multiple photos',
      context: 'DiaryPreviewGenerationDelegate',
    );

    final imagesWithTimes = <({Uint8List imageData, DateTime time})>[];
    for (final asset in assets) {
      final imageResult = await _photoService.getImageForAi(asset);
      if (imageResult.isSuccess) {
        imagesWithTimes.add((
          imageData: imageResult.value,
          time: PhotoDateResolver.resolveAssetDateTime(asset),
        ));
      } else {
        _logger.warning(
          'Failed to load image, skipping asset: ${asset.id}',
          context: 'DiaryPreviewGenerationDelegate.generateFromMultiplePhotos',
        );
      }
    }

    if (imagesWithTimes.isEmpty) {
      return const Failure(ServiceException('All image loading failed'));
    }

    final resultFromAi = await aiService.generateDiaryFromMultipleImages(
      imagesWithTimes: imagesWithTimes,
      prompt: prompt,
      contextText: contextText,
      onProgress: onProgress,
      locale: locale,
      diaryLength: diaryLength,
    );

    if (resultFromAi.isFailure) {
      return Failure(resultFromAi.error);
    }

    final value = resultFromAi.value;
    return Success(
      GenerationOutput(title: value.title, content: value.content),
    );
  }
}
