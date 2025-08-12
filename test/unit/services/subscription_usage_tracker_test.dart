import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:smart_photo_diary/services/subscription_usage_tracker.dart';
import 'package:smart_photo_diary/services/logging_service.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import '../helpers/hive_test_helpers.dart';

/// SubscriptionUsageTracker単体テスト
/// 
/// サブスクリプション使用量追跡機能の詳細テスト：
/// - 月次使用量取得と管理
/// - 残りAI生成回数の計算
/// - 使用可否判定とインクリメント処理
/// - 月次自動リセット機能
/// - 手動使用量リセット機能
/// - 次回リセット日計算
/// - Result<T>パターンによるエラーハンドリング
/// - 境界値・競合状態の処理
void main() {
  group('SubscriptionUsageTracker', () {
    late SubscriptionUsageTracker usageTracker;
    late Box<SubscriptionStatus> mockSubscriptionBox;
    late LoggingService mockLoggingService;

    setUpAll(() async {
      // Hiveテスト環境のセットアップ
      await HiveTestHelpers.setupHiveForTesting();
    });

    setUp(() async {
      // 各テスト前にHiveボックスをクリア
      await HiveTestHelpers.clearSubscriptionBox();

      // モックHiveボックス取得
      mockSubscriptionBox = await Hive.openBox<SubscriptionStatus>('subscription');
      
      // LoggingServiceインスタンスを作成
      mockLoggingService = await LoggingService.getInstance();
      
      // UsageTrackerインスタンス作成
      usageTracker = SubscriptionUsageTracker(
        mockSubscriptionBox,
        mockLoggingService,
      );

      // テスト用の基本ステータスを作成
      await _createBasicStatus(mockSubscriptionBox);
    });

    tearDown(() async {
      usageTracker.dispose();
      await mockSubscriptionBox.clear();
    });

    tearDownAll(() async {
      await HiveTestHelpers.closeHive();
    });

    group('初期化とプロパティ', () {
      test('初期化後にisInitializedがtrueになる', () {
        // Assert
        expect(usageTracker.isInitialized, isTrue);
      });

      test('dispose()後にisInitializedがfalseになる', () {
        // Act
        usageTracker.dispose();

        // Assert
        expect(usageTracker.isInitialized, isFalse);
      });
    });

    group('getMonthlyUsage()', () {
      test('初期状態で使用量0が返される', () async {
        // Act
        final result = await usageTracker.getMonthlyUsage();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, equals(0));
      });

      test('使用量が設定されている場合、正しい値が返される', () async {
        // Arrange
        await _createStatusWithUsage(mockSubscriptionBox, 5);

        // Act
        final result = await usageTracker.getMonthlyUsage();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, equals(5));
      });

      test('初期化されていない場合、エラーが返される', () async {
        // Arrange
        usageTracker.dispose();

        // Act
        final result = await usageTracker.getMonthlyUsage();

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
        expect(result.error.message, contains('UsageTracker is not initialized'));
      });
    });

    group('getRemainingGenerations()', () {
      test('Basicプラン初期状態で正しい残り回数が返される', () async {
        // Act
        final result = await usageTracker.getRemainingGenerations(_isValidBasicSubscription);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, equals(10)); // BasicPlan制限
      });

      test('Basicプランで使用後の残り回数が正しく計算される', () async {
        // Arrange
        await _createStatusWithUsage(mockSubscriptionBox, 3);

        // Act
        final result = await usageTracker.getRemainingGenerations(_isValidBasicSubscription);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, equals(7)); // 10 - 3 = 7
      });

      test('Premiumプランで初期状態の残り回数が返される', () async {
        // Arrange
        await _createPremiumMonthlyStatus(mockSubscriptionBox);

        // Act
        final result = await usageTracker.getRemainingGenerations(_isValidPremiumSubscription);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, equals(100)); // PremiumPlan制限
      });

      test('制限に達した場合、残り0回が返される', () async {
        // Arrange
        await _createStatusWithUsage(mockSubscriptionBox, 10); // Basicプラン制限

        // Act
        final result = await usageTracker.getRemainingGenerations(_isValidBasicSubscription);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, equals(0));
      });

      test('制限を超えた場合、負の値ではなく0が返される', () async {
        // Arrange
        await _createStatusWithUsage(mockSubscriptionBox, 15); // Basicプラン制限超過

        // Act
        final result = await usageTracker.getRemainingGenerations(_isValidBasicSubscription);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, equals(0)); // 負の値にならない
      });

      test('無効なサブスクリプションの場合、0が返される', () async {
        // Act
        final result = await usageTracker.getRemainingGenerations(_isInvalidSubscription);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, equals(0));
      });

      test('初期化されていない場合、エラーが返される', () async {
        // Arrange
        usageTracker.dispose();

        // Act
        final result = await usageTracker.getRemainingGenerations(_isValidBasicSubscription);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
      });
    });

    group('canUseAiGeneration()', () {
      test('Basicプラン初期状態で使用可能', () async {
        // Arrange
        final status = await _getCurrentStatus(mockSubscriptionBox);

        // Act
        final result = await usageTracker.canUseAiGeneration(status, _isValidBasicSubscription);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('Basicプラン制限内で使用可能', () async {
        // Arrange
        await _createStatusWithUsage(mockSubscriptionBox, 9); // 制限10の1回前
        final status = await _getCurrentStatus(mockSubscriptionBox);

        // Act
        final result = await usageTracker.canUseAiGeneration(status, _isValidBasicSubscription);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('Basicプラン制限に達すると使用不可', () async {
        // Arrange
        await _createStatusWithUsage(mockSubscriptionBox, 10); // 制限到達
        final status = await _getCurrentStatus(mockSubscriptionBox);

        // Act
        final result = await usageTracker.canUseAiGeneration(status, _isValidBasicSubscription);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });

      test('Premiumプランで高い制限まで使用可能', () async {
        // Arrange
        await _createPremiumMonthlyStatusWithUsage(mockSubscriptionBox, 50);
        final status = await _getCurrentStatus(mockSubscriptionBox);

        // Act
        final result = await usageTracker.canUseAiGeneration(status, _isValidPremiumSubscription);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('無効なサブスクリプションでは使用不可', () async {
        // Arrange
        final status = await _getCurrentStatus(mockSubscriptionBox);

        // Act
        final result = await usageTracker.canUseAiGeneration(status, _isInvalidSubscription);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });

      test('初期化されていない場合、エラーが返される', () async {
        // Arrange
        final status = await _getCurrentStatus(mockSubscriptionBox);
        usageTracker.dispose();

        // Act
        final result = await usageTracker.canUseAiGeneration(status, _isValidBasicSubscription);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
      });
    });

    group('incrementAiUsage()', () {
      test('有効なBasicプランで使用量がインクリメントされる', () async {
        // Arrange
        final status = await _getCurrentStatus(mockSubscriptionBox);

        // Act
        final result = await usageTracker.incrementAiUsage(status, _isValidBasicSubscription);

        // Assert
        expect(result.isSuccess, isTrue);

        // 使用量が1増加していることを確認
        final updatedUsage = await usageTracker.getMonthlyUsage();
        expect(updatedUsage.value, equals(1));
      });

      test('複数回のインクリメントが正しく処理される', () async {
        // Arrange
        final status = await _getCurrentStatus(mockSubscriptionBox);

        // Act
        for (int i = 0; i < 3; i++) {
          final result = await usageTracker.incrementAiUsage(status, _isValidBasicSubscription);
          expect(result.isSuccess, isTrue);
        }

        // Assert
        final usage = await usageTracker.getMonthlyUsage();
        expect(usage.value, equals(3));
      });

      test('制限に達した場合、インクリメントが失敗する', () async {
        // Arrange
        await _createStatusWithUsage(mockSubscriptionBox, 10); // Basicプラン制限
        final status = await _getCurrentStatus(mockSubscriptionBox);

        // Act
        final result = await usageTracker.incrementAiUsage(status, _isValidBasicSubscription);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
        expect(result.error.message, contains('Monthly AI generation limit reached'));
      });

      test('無効なサブスクリプションではインクリメント失敗', () async {
        // Arrange
        final status = await _getCurrentStatus(mockSubscriptionBox);

        // Act
        final result = await usageTracker.incrementAiUsage(status, _isInvalidSubscription);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
        expect(result.error.message, contains('subscription is not valid'));
      });

      test('初期化されていない場合、エラーが返される', () async {
        // Arrange
        final status = await _getCurrentStatus(mockSubscriptionBox);
        usageTracker.dispose();

        // Act
        final result = await usageTracker.incrementAiUsage(status, _isValidBasicSubscription);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
      });
    });

    group('resetUsage()', () {
      test('手動リセットで使用量がクリアされる', () async {
        // Arrange
        await _createStatusWithUsage(mockSubscriptionBox, 5);

        // Act
        final result = await usageTracker.resetUsage();

        // Assert
        expect(result.isSuccess, isTrue);

        final usage = await usageTracker.getMonthlyUsage();
        expect(usage.value, equals(0));
      });

      test('制限に達した状態からリセットで再び使用可能になる', () async {
        // Arrange
        await _createStatusWithUsage(mockSubscriptionBox, 10); // Basicプラン制限
        final status = await _getCurrentStatus(mockSubscriptionBox);

        // リセット前は使用不可
        final beforeReset = await usageTracker.canUseAiGeneration(status, _isValidBasicSubscription);
        expect(beforeReset.value, isFalse);

        // Act
        await usageTracker.resetUsage();

        // Assert
        final updatedStatus = await _getCurrentStatus(mockSubscriptionBox);
        final afterReset = await usageTracker.canUseAiGeneration(updatedStatus, _isValidBasicSubscription);
        expect(afterReset.value, isTrue);
      });

      test('初期化されていない場合、エラーが返される', () async {
        // Arrange
        usageTracker.dispose();

        // Act
        final result = await usageTracker.resetUsage();

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
      });
    });

    group('getNextResetDate()', () {
      test('次回リセット日が正しく計算される', () async {
        // Act
        final result = await usageTracker.getNextResetDate();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isA<DateTime>());

        final now = DateTime.now();
        final nextMonth = now.month == 12
            ? DateTime(now.year + 1, 1, 1)
            : DateTime(now.year, now.month + 1, 1);

        expect(result.value.year, equals(nextMonth.year));
        expect(result.value.month, equals(nextMonth.month));
        expect(result.value.day, equals(1));
      });

      test('12月の場合、翌年1月がリセット日になる', () async {
        // Arrange - 12月の場合をシミュレートするため、特定の日付でリセット日を作成
        await _createStatusWithCustomResetDate(mockSubscriptionBox, DateTime(2023, 12, 15));

        // Act
        final result = await usageTracker.getNextResetDate();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value.year, equals(2024));
        expect(result.value.month, equals(1));
        expect(result.value.day, equals(1));
      });

      test('初期化されていない場合、エラーが返される', () async {
        // Arrange
        usageTracker.dispose();

        // Act
        final result = await usageTracker.getNextResetDate();

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
      });
    });

    group('resetMonthlyUsageIfNeeded()', () {
      test('月次リセットが正常に実行される', () async {
        // Arrange
        await _createStatusWithUsage(mockSubscriptionBox, 5);

        // Act
        final result = await usageTracker.resetMonthlyUsageIfNeeded();

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('初期化されていない場合、エラーが返される', () async {
        // Arrange
        usageTracker.dispose();

        // Act
        final result = await usageTracker.resetMonthlyUsageIfNeeded();

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
      });
    });

    group('境界値テスト', () {
      test('Basicプラン制限ちょうど(10回)での使用可否', () async {
        // Arrange
        await _createStatusWithUsage(mockSubscriptionBox, 10);
        final status = await _getCurrentStatus(mockSubscriptionBox);

        // Act
        final result = await usageTracker.canUseAiGeneration(status, _isValidBasicSubscription);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });

      test('Premiumプラン制限ちょうど(100回)での使用可否', () async {
        // Arrange
        await _createPremiumMonthlyStatusWithUsage(mockSubscriptionBox, 100);
        final status = await _getCurrentStatus(mockSubscriptionBox);

        // Act
        final result = await usageTracker.canUseAiGeneration(status, _isValidPremiumSubscription);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });

      test('制限の1回前では使用可能', () async {
        // Arrange
        await _createStatusWithUsage(mockSubscriptionBox, 9); // Basic制限10の1回前
        final status = await _getCurrentStatus(mockSubscriptionBox);

        // Act
        final result = await usageTracker.canUseAiGeneration(status, _isValidBasicSubscription);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });
    });

    group('エラーハンドリング', () {
      test('サブスクリプションステータスが見つからない場合、エラーが返される', () async {
        // Arrange
        await mockSubscriptionBox.clear(); // ステータスを削除

        // Act
        final result = await usageTracker.getMonthlyUsage();

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
        expect(result.error.message, contains('Subscription status not found'));
      });

      test('Hive操作でエラーが発生した場合、適切にハンドリングされる', () async {
        // Arrange
        await mockSubscriptionBox.close(); // ボックスを閉じてエラーを発生させる

        // Act
        final result = await usageTracker.getMonthlyUsage();

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());

        // テスト後にボックスを再オープン
        mockSubscriptionBox = await Hive.openBox<SubscriptionStatus>('subscription');
        usageTracker = SubscriptionUsageTracker(
          mockSubscriptionBox,
          mockLoggingService,
        );
      });
    });

    group('並行処理テスト', () {
      test('複数の使用量取得が並行実行可能', () async {
        // Arrange
        await _createStatusWithUsage(mockSubscriptionBox, 5);

        // Act
        final futures = <Future>[];
        for (int i = 0; i < 3; i++) {
          futures.add(usageTracker.getMonthlyUsage());
        }

        final results = await Future.wait(futures);

        // Assert
        for (final result in results) {
          expect(result.isSuccess, isTrue);
          expect((result as dynamic).value, equals(5));
        }
      });

      test('残り回数取得と使用可否チェックの並行実行', () async {
        // Arrange
        await _createStatusWithUsage(mockSubscriptionBox, 3);
        final status = await _getCurrentStatus(mockSubscriptionBox);

        // Act
        final remainingFuture = usageTracker.getRemainingGenerations(_isValidBasicSubscription);
        final canUseFuture = usageTracker.canUseAiGeneration(status, _isValidBasicSubscription);

        final results = await Future.wait([remainingFuture, canUseFuture]);

        // Assert
        expect(results[0].isSuccess, isTrue);
        expect(results[1].isSuccess, isTrue);
        expect((results[0] as dynamic).value, equals(7)); // 10 - 3 = 7
        expect((results[1] as dynamic).value, isTrue);
      });
    });
  });
}

// =================================================================
// テスト用ヘルパー関数
// =================================================================

/// テスト用の基本サブスクリプション状態を作成
Future<void> _createBasicStatus(Box<SubscriptionStatus> box) async {
  final basicStatus = SubscriptionStatus(
    planId: SubscriptionConstants.basicPlanId,
    isActive: true,
    startDate: DateTime.now(),
    expiryDate: null,
    autoRenewal: false,
    monthlyUsageCount: 0,
    lastResetDate: DateTime.now(),
    transactionId: '',
    lastPurchaseDate: null,
  );

  await box.put(SubscriptionConstants.statusKey, basicStatus);
}

/// 指定した使用量でサブスクリプション状態を作成
Future<void> _createStatusWithUsage(Box<SubscriptionStatus> box, int usage) async {
  final status = SubscriptionStatus(
    planId: SubscriptionConstants.basicPlanId,
    isActive: true,
    startDate: DateTime.now(),
    expiryDate: null,
    autoRenewal: false,
    monthlyUsageCount: usage,
    lastResetDate: DateTime.now(),
    transactionId: '',
    lastPurchaseDate: null,
  );

  await box.put(SubscriptionConstants.statusKey, status);
}

/// Premiumサブスクリプション状態を作成
Future<void> _createPremiumMonthlyStatus(Box<SubscriptionStatus> box) async {
  final premiumStatus = SubscriptionStatus(
    planId: SubscriptionConstants.premiumMonthlyPlanId,
    isActive: true,
    startDate: DateTime.now(),
    expiryDate: DateTime.now().add(const Duration(days: 30)),
    autoRenewal: true,
    monthlyUsageCount: 0,
    lastResetDate: DateTime.now(),
    transactionId: 'test_transaction',
    lastPurchaseDate: DateTime.now(),
  );

  await box.put(SubscriptionConstants.statusKey, premiumStatus);
}

/// 指定した使用量でPremiumサブスクリプション状態を作成
Future<void> _createPremiumMonthlyStatusWithUsage(Box<SubscriptionStatus> box, int usage) async {
  final premiumStatus = SubscriptionStatus(
    planId: SubscriptionConstants.premiumMonthlyPlanId,
    isActive: true,
    startDate: DateTime.now(),
    expiryDate: DateTime.now().add(const Duration(days: 30)),
    autoRenewal: true,
    monthlyUsageCount: usage,
    lastResetDate: DateTime.now(),
    transactionId: 'test_transaction',
    lastPurchaseDate: DateTime.now(),
  );

  await box.put(SubscriptionConstants.statusKey, premiumStatus);
}

/// 指定したリセット日でサブスクリプション状態を作成
Future<void> _createStatusWithCustomResetDate(Box<SubscriptionStatus> box, DateTime resetDate) async {
  final status = SubscriptionStatus(
    planId: SubscriptionConstants.basicPlanId,
    isActive: true,
    startDate: DateTime.now(),
    expiryDate: null,
    autoRenewal: false,
    monthlyUsageCount: 0,
    lastResetDate: resetDate,
    transactionId: '',
    lastPurchaseDate: null,
  );

  await box.put(SubscriptionConstants.statusKey, status);
}

/// 現在のサブスクリプション状態を取得
Future<SubscriptionStatus> _getCurrentStatus(Box<SubscriptionStatus> box) async {
  final status = box.get(SubscriptionConstants.statusKey);
  if (status == null) {
    throw Exception('Status not found');
  }
  return status;
}

/// Basicプラン有効性チェック関数
bool _isValidBasicSubscription(SubscriptionStatus status) {
  return status.isActive && status.planId == SubscriptionConstants.basicPlanId;
}

/// Premiumプラン有効性チェック関数
bool _isValidPremiumSubscription(SubscriptionStatus status) {
  final isPremium = status.planId == SubscriptionConstants.premiumMonthlyPlanId ||
                    status.planId == SubscriptionConstants.premiumYearlyPlanId;
  final isActive = status.isActive;
  final isNotExpired = status.expiryDate?.isAfter(DateTime.now()) ?? false;
  
  return isPremium && isActive && isNotExpired;
}

/// 無効なサブスクリプション（常にfalseを返す）
bool _isInvalidSubscription(SubscriptionStatus status) {
  return false;
}