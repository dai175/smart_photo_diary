import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'ai/ai_service_interface.dart';
import 'ai/diary_generator.dart';
import 'ai/tag_generator.dart';

/// AIを使用して日記文を生成するサービスクラス（リファクタリング済み）
class AiService implements AiServiceInterface {
  final DiaryGenerator _diaryGenerator;
  final TagGenerator _tagGenerator;

  AiService({
    DiaryGenerator? diaryGenerator,
    TagGenerator? tagGenerator,
  }) : _diaryGenerator = diaryGenerator ?? DiaryGenerator(),
        _tagGenerator = tagGenerator ?? TagGenerator();

  @override
  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  @override
  Future<DiaryGenerationResult> generateDiaryFromLabels({
    required List<String> labels,
    required DateTime date,
    String? location,
    List<DateTime>? photoTimes,
    List<PhotoTimeLabel>? photoTimeLabels,
  }) async {
    final online = await isOnline();
    return await _diaryGenerator.generateFromLabels(
      labels: labels,
      date: date,
      location: location,
      photoTimes: photoTimes,
      photoTimeLabels: photoTimeLabels,
      isOnline: online,
    );
  }

  @override
  Future<DiaryGenerationResult> generateDiaryFromImage({
    required Uint8List imageData,
    required DateTime date,
    String? location,
    List<DateTime>? photoTimes,
  }) async {
    final online = await isOnline();
    return await _diaryGenerator.generateFromImage(
      imageData: imageData,
      date: date,
      location: location,
      photoTimes: photoTimes,
      isOnline: online,
    );
  }

  @override
  Future<DiaryGenerationResult> generateDiaryFromMultipleImages({
    required List<({Uint8List imageData, DateTime time})> imagesWithTimes,
    String? location,
    Function(int current, int total)? onProgress,
  }) async {
    final online = await isOnline();
    return await _diaryGenerator.generateFromMultipleImages(
      imagesWithTimes: imagesWithTimes,
      location: location,
      onProgress: onProgress,
      isOnline: online,
    );
  }

  @override
  Future<List<String>> generateTagsFromContent({
    required String title,
    required String content,
    required DateTime date,
    required int photoCount,
  }) async {
    final online = await isOnline();
    return await _tagGenerator.generateTags(
      title: title,
      content: content,
      date: date,
      photoCount: photoCount,
      isOnline: online,
    );
  }
}