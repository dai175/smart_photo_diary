import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/services/photo_access_control_service.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import 'mocks/mock_services.dart';

void main() {
  group('過去の写真機能 シンプル統合テスト', () {
    late PhotoAccessControlService photoAccessControlService;
    late MockAssetEntity mockAsset;

    setUp(() {
      photoAccessControlService = PhotoAccessControlService();
      mockAsset = MockAssetEntity();
      registerFallbackValue(DateTime.now());
      registerFallbackValue(BasicPlan());
    });

    group('エンドツーエンドフロー', () {
      test('過去の写真選択→日記作成の基本フロー', () async {
        // 1. 過去の写真を準備
        final pastDate = DateTime.now().subtract(const Duration(days: 7));
        when(() => mockAsset.id).thenReturn('past_photo_1');
        when(() => mockAsset.createDateTime).thenReturn(pastDate);
        when(() => mockAsset.title).thenReturn('7日前の写真');

        // 2. プレミアムプランでのアクセス確認
        final premiumPlan = PremiumMonthlyPlan();
        final isAccessible = photoAccessControlService.isPhotoAccessible(
          pastDate,
          premiumPlan,
        );
        expect(isAccessible, true, reason: 'プレミアムプランでは7日前の写真にアクセス可能');

        // 3. 日記エントリの作成（実際のサービスでは生成される）
        final diaryEntry = DiaryEntry(
          id: 'diary_${DateTime.now().millisecondsSinceEpoch}',
          date: pastDate,
          title: '7日前の思い出',
          content: 'これは7日前の写真から作成された日記です。',
          photoIds: [mockAsset.id],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // 4. 作成された日記の検証
        expect(diaryEntry.photoIds.contains('past_photo_1'), true);
        expect(diaryEntry.date, pastDate);
        expect(diaryEntry.title, contains('7日前'));
      });

      test('制限写真タップ→アップグレード必要の確認', () async {
        // 1. 30日前の写真を準備
        final restrictedDate = DateTime.now().subtract(
          const Duration(days: 30),
        );
        when(() => mockAsset.id).thenReturn('restricted_photo_1');
        when(() => mockAsset.createDateTime).thenReturn(restrictedDate);
        when(() => mockAsset.title).thenReturn('30日前の写真');

        // 2. ベーシックプランでのアクセス確認
        final basicPlan = BasicPlan();
        final isAccessibleBasic = photoAccessControlService.isPhotoAccessible(
          restrictedDate,
          basicPlan,
        );
        expect(isAccessibleBasic, false, reason: 'ベーシックプランでは30日前の写真にアクセス不可');

        // 3. アクセス制限の理由を確認
        final accessRange = photoAccessControlService.getAccessRangeDescription(
          basicPlan,
          formatter: (days) => '$days days access',
        );
        expect(accessRange, equals('1 days access'));

        // 4. プレミアムプランでのアクセス確認
        final premiumPlan = PremiumMonthlyPlan();
        final isAccessiblePremium = photoAccessControlService.isPhotoAccessible(
          restrictedDate,
          premiumPlan,
        );
        expect(isAccessiblePremium, true, reason: 'プレミアムプランでは30日前の写真にアクセス可能');
      });

      test('プラン変更後のアクセス確認', () async {
        // 1. 様々な日付の写真を準備
        final photoDates = [
          DateTime.now(), // 今日
          DateTime.now().subtract(const Duration(days: 1)), // 1日前
          DateTime.now().subtract(const Duration(days: 7)), // 1週間前
          DateTime.now().subtract(const Duration(days: 30)), // 1ヶ月前
          DateTime.now().subtract(const Duration(days: 180)), // 6ヶ月前
        ];

        // 2. ベーシックプランでのアクセス可能数を確認
        final basicPlan = BasicPlan();
        int basicAccessibleCount = 0;
        for (final date in photoDates) {
          if (photoAccessControlService.isPhotoAccessible(date, basicPlan)) {
            basicAccessibleCount++;
          }
        }
        expect(basicAccessibleCount, 2, reason: 'ベーシックプランでは今日と1日前の写真のみアクセス可能');

        // 3. プレミアムプランでのアクセス可能数を確認
        final premiumPlan = PremiumMonthlyPlan();
        int premiumAccessibleCount = 0;
        for (final date in photoDates) {
          if (photoAccessControlService.isPhotoAccessible(date, premiumPlan)) {
            premiumAccessibleCount++;
          }
        }
        expect(premiumAccessibleCount, 5, reason: 'プレミアムプランでは全ての写真にアクセス可能');

        // 4. サブスクリプションステータスの変更をシミュレート
        final beforeUpgrade = SubscriptionStatus(
          planId: SubscriptionConstants.basicPlanId,
          monthlyUsageCount: 5,
          lastResetDate: DateTime.now(),
        );
        expect(
          beforeUpgrade.currentPlanClass.id,
          SubscriptionConstants.basicPlanId,
        );

        final afterUpgrade = SubscriptionStatus(
          planId: SubscriptionConstants.premiumMonthlyPlanId,
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          monthlyUsageCount: 5,
          lastResetDate: DateTime.now(),
        );
        expect(
          afterUpgrade.currentPlanClass.id,
          SubscriptionConstants.premiumMonthlyPlanId,
        );
        expect(afterUpgrade.currentPlanClass.isPremium, true);
      });

      test('日記作成フローの統合確認', () async {
        // 1. 過去の写真から日記作成のフローをシミュレート
        final photoDate = DateTime.now().subtract(const Duration(days: 14));
        final premiumPlan = PremiumMonthlyPlan();

        // 2. アクセス可能性を確認
        final canAccess = photoAccessControlService.isPhotoAccessible(
          photoDate,
          premiumPlan,
        );
        expect(canAccess, true);

        // 3. 日記作成の条件を確認
        final subscriptionStatus = SubscriptionStatus(
          planId: SubscriptionConstants.premiumMonthlyPlanId,
          monthlyUsageCount: 10,
          lastResetDate: DateTime.now(),
        );

        // 4. 月間制限内であることを確認
        final remainingGenerations =
            subscriptionStatus.currentPlanClass.monthlyAiGenerationLimit -
            subscriptionStatus.monthlyUsageCount;
        expect(remainingGenerations > 0, true, reason: 'AI生成の残り回数がある');

        // 5. 日記作成後の状態を確認
        subscriptionStatus.monthlyUsageCount++;
        expect(subscriptionStatus.monthlyUsageCount, 11);

        // 6. 使用済み写真の管理
        final usedPhotoIds = <String>{'past_photo_1', 'past_photo_2'};
        usedPhotoIds.add('past_photo_3');
        expect(usedPhotoIds.contains('past_photo_3'), true);
      });
    });
  });
}
