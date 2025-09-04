import 'package:photo_manager/photo_manager.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../core/service_registration.dart';
import '../services/logging_service.dart';

/// タイムライン表示用の統一写真取得サービス
class UnifiedPhotoService {
  static const UnifiedPhotoService _instance = UnifiedPhotoService._internal();
  
  factory UnifiedPhotoService() => _instance;
  
  const UnifiedPhotoService._internal();

  /// タイムライン用の全写真を取得
  Future<List<AssetEntity>> getTimelinePhotos() async {
    try {
      final photoService = ServiceRegistration.get<IPhotoService>();
      final subscriptionService = await ServiceRegistration.getAsync<ISubscriptionService>();
      final logger = await LoggingService.getInstance();

      // 権限チェック
      final hasPermission = await photoService.requestPermission();
      if (!hasPermission) {
        logger.info(
          'タイムライン写真取得: 権限なし',
          context: 'UnifiedPhotoService.getTimelinePhotos',
        );
        return [];
      }

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      
      // プランに応じた過去日数を取得
      final planResult = await subscriptionService.getCurrentPlanClass();
      final daysBack = planResult.isSuccess 
          ? planResult.value.pastPhotoAccessDays 
          : 365; // デフォルト1年

      final startDate = todayStart.subtract(Duration(days: daysBack));
      
      // 今日を含む全期間の写真を取得（今日の23:59:59まで）
      final endDate = todayStart.add(const Duration(days: 1));
      
      logger.info(
        'タイムライン写真取得開始',
        context: 'UnifiedPhotoService.getTimelinePhotos',
        data: 'range: $startDate ~ $endDate, daysBack: $daysBack',
      );

      final photos = await photoService.getPhotosInDateRange(
        startDate: startDate,
        endDate: endDate,
        limit: 1000, // タイムライン表示用の上限
      );

      logger.info(
        'タイムライン写真取得完了',
        context: 'UnifiedPhotoService.getTimelinePhotos',
        data: '取得件数: ${photos.length}',
      );

      return photos;
    } catch (e) {
      final logger = await LoggingService.getInstance();
      logger.error(
        'タイムライン写真取得エラー',
        context: 'UnifiedPhotoService.getTimelinePhotos',
        error: e,
      );
      return [];
    }
  }

  /// 今日の写真のみを取得（既存機能との互換性用）
  Future<List<AssetEntity>> getTodayPhotos() async {
    try {
      final photoService = ServiceRegistration.get<IPhotoService>();
      return await photoService.getTodayPhotos();
    } catch (e) {
      final logger = await LoggingService.getInstance();
      logger.error(
        '今日の写真取得エラー',
        context: 'UnifiedPhotoService.getTodayPhotos',
        error: e,
      );
      return [];
    }
  }

  /// 指定期間の写真を取得（既存機能との互換性用）
  Future<List<AssetEntity>> getPhotosInDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 200,
  }) async {
    try {
      final photoService = ServiceRegistration.get<IPhotoService>();
      return await photoService.getPhotosInDateRange(
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
    } catch (e) {
      final logger = await LoggingService.getInstance();
      logger.error(
        '期間指定写真取得エラー',
        context: 'UnifiedPhotoService.getPhotosInDateRange',
        error: e,
      );
      return [];
    }
  }
}