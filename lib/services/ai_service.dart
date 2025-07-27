import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'ai/ai_service_interface.dart';
import 'ai/diary_generator.dart';
import 'ai/tag_generator.dart';
import 'interfaces/subscription_service_interface.dart';
import '../core/result/result.dart';
import '../core/errors/app_exceptions.dart';

/// AIを使用して日記文を生成するサービスクラス（リファクタリング済み）
///
/// Phase 1.7.1: SubscriptionService統合による使用量制限実装
/// - generateDiary前の制限チェック
/// - 使用量カウント統合
/// - 月次リセット処理統合
class AiService implements AiServiceInterface {
  final DiaryGenerator _diaryGenerator;
  final TagGenerator _tagGenerator;
  final ISubscriptionService? _subscriptionService;

  AiService({
    DiaryGenerator? diaryGenerator,
    TagGenerator? tagGenerator,
    ISubscriptionService? subscriptionService,
  }) : _diaryGenerator = diaryGenerator ?? DiaryGenerator(),
       _tagGenerator = tagGenerator ?? TagGenerator(),
       _subscriptionService = subscriptionService;

  @override
  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.any(
      (result) => result != ConnectivityResult.none,
    );
  }

  @override
  Future<Result<DiaryGenerationResult>> generateDiaryFromImage({
    required Uint8List imageData,
    required DateTime date,
    String? location,
    List<DateTime>? photoTimes,
    String? prompt,
  }) async {
    try {
      // Phase 1.7.1.2: generateDiary前の制限チェック実装
      if (_subscriptionService != null) {
        // 月次リセット処理統合 (Phase 1.7.1.4)
        await _subscriptionService.resetMonthlyUsageIfNeeded();

        // プラン別制限チェック（制限値はSubscriptionConstantsで管理）
        final canUseResult = await _subscriptionService.canUseAiGeneration();
        if (canUseResult.isFailure) {
          return Failure(canUseResult.error);
        }

        if (!canUseResult.value) {
          // Phase 1.7.2.2: 制限超過時の適切なエラーメッセージ
          final currentPlanResult = await _subscriptionService
              .getCurrentPlanClass();
          final planName = currentPlanResult.isSuccess
              ? currentPlanResult.value.displayName
              : 'Basic';
          final remainingResult = await _subscriptionService
              .getRemainingGenerations();
          final remaining = remainingResult.isSuccess
              ? remainingResult.value
              : 0;

          return Failure(
            AiProcessingException(
              'AI生成の月間制限に達しました。'
              '現在のプラン（$planName）では今月の残り使用回数は$remaining回です。'
              'より多くの生成を行うにはPremiumプランにアップグレードしてください。',
              details: 'Usage limit exceeded for current plan',
            ),
          );
        }
      }

      final online = await isOnline();
      final result = await _diaryGenerator.generateFromImage(
        imageData: imageData,
        date: date,
        location: location,
        photoTimes: photoTimes,
        prompt: prompt,
        isOnline: online,
      );

      // Phase 1.7.1.3: 使用量カウント統合
      // AI生成が成功した場合のみクレジットを消費する
      if (_subscriptionService != null) {
        await _subscriptionService.incrementAiUsage();
      }

      return Success(result);
    } catch (e) {
      return Failure(
        AiProcessingException(
          'AI日記生成中にエラーが発生しました',
          details: e.toString(),
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<DiaryGenerationResult>> generateDiaryFromMultipleImages({
    required List<({Uint8List imageData, DateTime time})> imagesWithTimes,
    String? location,
    String? prompt,
    Function(int current, int total)? onProgress,
  }) async {
    try {
      // Phase 1.7.1.2: generateDiary前の制限チェック実装
      if (_subscriptionService != null) {
        // 月次リセット処理統合 (Phase 1.7.1.4)
        await _subscriptionService.resetMonthlyUsageIfNeeded();

        // プラン別制限チェック（制限値はSubscriptionConstantsで管理）
        final canUseResult = await _subscriptionService.canUseAiGeneration();
        if (canUseResult.isFailure) {
          return Failure(canUseResult.error);
        }

        if (!canUseResult.value) {
          // Phase 1.7.2.2: 制限超過時の適切なエラーメッセージ
          final currentPlanResult = await _subscriptionService
              .getCurrentPlanClass();
          final planName = currentPlanResult.isSuccess
              ? currentPlanResult.value.displayName
              : 'Basic';
          final remainingResult = await _subscriptionService
              .getRemainingGenerations();
          final remaining = remainingResult.isSuccess
              ? remainingResult.value
              : 0;

          return Failure(
            AiProcessingException(
              'AI生成の月間制限に達しました。'
              '現在のプラン（$planName）では今月の残り使用回数は$remaining回です。'
              'より多くの生成を行うにはPremiumプランにアップグレードしてください。',
              details: 'Usage limit exceeded for current plan',
            ),
          );
        }
      }

      final online = await isOnline();
      final result = await _diaryGenerator.generateFromMultipleImages(
        imagesWithTimes: imagesWithTimes,
        location: location,
        prompt: prompt,
        onProgress: onProgress,
        isOnline: online,
      );

      // Phase 1.7.1.3: 使用量カウント統合
      // AI生成が成功した場合のみクレジットを消費する
      if (_subscriptionService != null) {
        await _subscriptionService.incrementAiUsage();
      }

      return Success(result);
    } catch (e) {
      return Failure(
        AiProcessingException(
          'AI日記生成中にエラーが発生しました',
          details: e.toString(),
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<List<String>>> generateTagsFromContent({
    required String title,
    required String content,
    required DateTime date,
    required int photoCount,
  }) async {
    try {
      // Phase 1.7.1: タグ生成は使用量にカウントしない
      final online = await isOnline();
      final result = await _tagGenerator.generateTags(
        title: title,
        content: content,
        date: date,
        photoCount: photoCount,
        isOnline: online,
      );

      return Success(result);
    } catch (e) {
      return Failure(
        AiProcessingException(
          'タグ生成中にエラーが発生しました',
          details: e.toString(),
          originalError: e,
        ),
      );
    }
  }

  // Phase 1.7.3: UI連携準備メソッド実装

  @override
  Future<Result<int>> getRemainingGenerations() async {
    if (_subscriptionService == null) {
      return Failure(ServiceException('SubscriptionService is not available'));
    }

    return await _subscriptionService.getRemainingGenerations();
  }

  @override
  Future<Result<DateTime>> getNextResetDate() async {
    if (_subscriptionService == null) {
      return Failure(ServiceException('SubscriptionService is not available'));
    }

    return await _subscriptionService.getNextResetDate();
  }

  @override
  Future<Result<bool>> canUseAiGeneration() async {
    if (_subscriptionService == null) {
      return Failure(ServiceException('SubscriptionService is not available'));
    }

    // 月次リセット処理統合
    await _subscriptionService.resetMonthlyUsageIfNeeded();

    return await _subscriptionService.canUseAiGeneration();
  }
}
