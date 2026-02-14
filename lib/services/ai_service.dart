import 'dart:typed_data';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'ai/ai_service_interface.dart';
import 'ai/diary_generator.dart';
import 'ai/tag_generator.dart';
import 'interfaces/subscription_service_interface.dart';
import 'interfaces/logging_service_interface.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';

/// AIを使用して日記文を生成するサービスクラス（リファクタリング済み）
///
/// Phase 1.7.1: SubscriptionService統合による使用量制限実装
/// - generateDiary前の制限チェック
/// - 使用量カウント統合
/// - 月次リセット処理統合
class AiService implements IAiService {
  final DiaryGenerator _diaryGenerator;
  final TagGenerator _tagGenerator;
  final ISubscriptionService? _subscriptionService;
  final ILoggingService? _logger;

  AiService({
    DiaryGenerator? diaryGenerator,
    TagGenerator? tagGenerator,
    ISubscriptionService? subscriptionService,
    ILoggingService? logger,
  }) : _diaryGenerator = diaryGenerator ?? DiaryGenerator(),
       _tagGenerator = tagGenerator ?? TagGenerator(),
       _subscriptionService = subscriptionService,
       _logger = logger;

  @override
  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.any(
      (result) => result != ConnectivityResult.none,
    );
  }

  /// AI生成前の使用量チェック・月次リセット処理
  Future<Result<void>> _checkAiGenerationAllowed() async {
    if (_subscriptionService == null) return const Success(null);

    // Best-effort monthly reset — failure is non-critical
    final resetResult = await _subscriptionService.resetMonthlyUsageIfNeeded();
    if (resetResult.isFailure) {
      _logger?.warning(
        'Monthly usage reset failed',
        context: 'AiService._checkAiGenerationAllowed',
        data: resetResult.error.toString(),
      );
    }

    final canUseResult = await _subscriptionService.canUseAiGeneration();
    if (canUseResult.isFailure) {
      return Failure(canUseResult.error);
    }

    if (!canUseResult.value) {
      final currentPlanResult = await _subscriptionService
          .getCurrentPlanClass();
      final planName = currentPlanResult.isSuccess
          ? currentPlanResult.value.displayName
          : 'Basic';
      final remainingResult = await _subscriptionService
          .getRemainingGenerations();
      final remaining = remainingResult.isSuccess ? remainingResult.value : 0;

      return Failure(
        AiProcessingException(
          'Monthly AI generation limit reached. '
          'Current plan ($planName) has $remaining generations remaining. '
          'Upgrade to Premium for more generations.',
          isUsageLimitError: true,
          details: 'Usage limit exceeded for current plan',
        ),
      );
    }

    return const Success(null);
  }

  /// AI生成成功後の使用量記録
  Future<void> _recordAiUsage() async {
    if (_subscriptionService == null) return;

    final result = await _subscriptionService.incrementAiUsage();
    if (result.isFailure) {
      _logger?.warning(
        'Failed to record AI usage',
        context: 'AiService._recordAiUsage',
        data: result.error.toString(),
      );
    }
  }

  @override
  Future<Result<DiaryGenerationResult>> generateDiaryFromImage({
    required Uint8List imageData,
    required DateTime date,
    String? location,
    List<DateTime>? photoTimes,
    String? prompt,
    Locale? locale,
  }) async {
    final checkResult = await _checkAiGenerationAllowed();
    if (checkResult.isFailure) return Failure(checkResult.error);

    final online = await isOnline();
    final result = await _diaryGenerator.generateFromImage(
      imageData: imageData,
      date: date,
      location: location,
      photoTimes: photoTimes,
      prompt: prompt,
      isOnline: online,
      locale: locale ?? const Locale('ja'),
    );

    if (result.isSuccess) {
      await _recordAiUsage();
    }

    return result;
  }

  @override
  Future<Result<DiaryGenerationResult>> generateDiaryFromMultipleImages({
    required List<({Uint8List imageData, DateTime time})> imagesWithTimes,
    String? location,
    String? prompt,
    Function(int current, int total)? onProgress,
    Locale? locale,
  }) async {
    final checkResult = await _checkAiGenerationAllowed();
    if (checkResult.isFailure) return Failure(checkResult.error);

    final online = await isOnline();
    final result = await _diaryGenerator.generateFromMultipleImages(
      imagesWithTimes: imagesWithTimes,
      location: location,
      prompt: prompt,
      onProgress: onProgress,
      isOnline: online,
      locale: locale ?? const Locale('ja'),
    );

    if (result.isSuccess) {
      await _recordAiUsage();
    }

    return result;
  }

  @override
  Future<Result<List<String>>> generateTagsFromContent({
    required String title,
    required String content,
    required DateTime date,
    required int photoCount,
    Locale? locale,
  }) async {
    // Phase 1.7.1: タグ生成は使用量にカウントしない
    final online = await isOnline();
    return await _tagGenerator.generateTags(
      title: title,
      content: content,
      date: date,
      photoCount: photoCount,
      isOnline: online,
      locale: locale ?? const Locale('ja'),
    );
  }

  // Phase 1.7.3: UI連携準備メソッド実装

  @override
  Future<Result<int>> getRemainingGenerations() async {
    if (_subscriptionService == null) {
      return const Failure(
        ServiceException('SubscriptionService is not available'),
      );
    }

    return await _subscriptionService.getRemainingGenerations();
  }

  @override
  Future<Result<DateTime>> getNextResetDate() async {
    if (_subscriptionService == null) {
      return const Failure(
        ServiceException('SubscriptionService is not available'),
      );
    }

    return await _subscriptionService.getNextResetDate();
  }

  @override
  Future<Result<bool>> canUseAiGeneration() async {
    if (_subscriptionService == null) {
      return const Failure(
        ServiceException('SubscriptionService is not available'),
      );
    }

    // Best-effort monthly reset — failure is non-critical
    final resetResult = await _subscriptionService.resetMonthlyUsageIfNeeded();
    if (resetResult.isFailure) {
      _logger?.warning(
        'Monthly usage reset failed',
        context: 'AiService.canUseAiGeneration',
        data: resetResult.error.toString(),
      );
    }

    return await _subscriptionService.canUseAiGeneration();
  }
}
