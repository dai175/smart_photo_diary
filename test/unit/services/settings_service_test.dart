import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_photo_diary/models/diary_length.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/models/subscription_info_v2.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/models/plans/plan.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';
import 'package:smart_photo_diary/services/settings_service.dart';

import '../../integration/mocks/mock_services.dart';

void main() {
  late SettingsService service;
  late MockSubscriptionServiceInterface mockSubscriptionService;

  setUpAll(() {
    registerMockFallbacks();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    serviceLocator.clear();

    mockSubscriptionService = MockSubscriptionServiceInterface();
    when(() => mockSubscriptionService.isInitialized).thenReturn(true);

    // SettingsService.initialize()でISubscriptionServiceをgetAsyncするため登録
    serviceLocator.registerAsyncFactory<ISubscriptionService>(
      () async => mockSubscriptionService,
    );

    service = SettingsService();
    await service.initialize();
  });

  tearDown(() {
    serviceLocator.clear();
  });

  group('SettingsService', () {
    group('themeMode / setThemeMode', () {
      test('デフォルト値 → ThemeMode.system', () {
        expect(service.themeMode, ThemeMode.system);
      });

      test('light設定 → 正しく永続化・取得', () async {
        await service.setThemeMode(ThemeMode.light);
        expect(service.themeMode, ThemeMode.light);
      });

      test('dark設定 → 正しく永続化・取得', () async {
        await service.setThemeMode(ThemeMode.dark);
        expect(service.themeMode, ThemeMode.dark);
      });

      test('system設定 → 正しく永続化・取得', () async {
        await service.setThemeMode(ThemeMode.dark);
        await service.setThemeMode(ThemeMode.system);
        expect(service.themeMode, ThemeMode.system);
      });

      test('setThemeModeはSuccessを返す', () async {
        final result = await service.setThemeMode(ThemeMode.light);
        expect(result.isSuccess, isTrue);
      });
    });

    group('locale / setLocale', () {
      test('デフォルト値 → null', () {
        expect(service.locale, isNull);
      });

      test('ja設定 → 正しく永続化・取得', () async {
        await service.setLocale(const Locale('ja'));
        expect(service.locale, const Locale('ja'));
      });

      test('en設定 → 正しく永続化・取得', () async {
        await service.setLocale(const Locale('en'));
        expect(service.locale, const Locale('en'));
      });

      test('localeNotifierが更新される', () async {
        expect(service.localeNotifier.value, isNull);
        await service.setLocale(const Locale('ja'));
        expect(service.localeNotifier.value, const Locale('ja'));
      });

      test('null設定でロケールがクリアされる', () async {
        await service.setLocale(const Locale('ja'));
        await service.setLocale(null);
        expect(service.locale, isNull);
        expect(service.localeNotifier.value, isNull);
      });

      test('country code付きロケールの永続化・取得', () async {
        await service.setLocale(const Locale('en', 'US'));
        final locale = service.locale;
        expect(locale?.languageCode, 'en');
        expect(locale?.countryCode, 'US');
      });
    });

    group('diaryLength / setDiaryLength', () {
      test('デフォルト値 → DiaryLength.standard', () {
        expect(service.diaryLength, DiaryLength.standard);
      });

      test('short設定 → 正しく永続化・取得', () async {
        await service.setDiaryLength(DiaryLength.short);
        expect(service.diaryLength, DiaryLength.short);
      });

      test('standard設定 → 正しく永続化・取得', () async {
        await service.setDiaryLength(DiaryLength.short);
        await service.setDiaryLength(DiaryLength.standard);
        expect(service.diaryLength, DiaryLength.standard);
      });

      test('setDiaryLengthはSuccessを返す', () async {
        final result = await service.setDiaryLength(DiaryLength.short);
        expect(result.isSuccess, isTrue);
      });
    });

    group('isFirstLaunch / setFirstLaunchCompleted', () {
      test('デフォルト → true', () {
        expect(service.isFirstLaunch, isTrue);
      });

      test('完了後 → false', () async {
        await service.setFirstLaunchCompleted();
        expect(service.isFirstLaunch, isFalse);
      });

      test('setFirstLaunchCompletedはSuccessを返す', () async {
        final result = await service.setFirstLaunchCompleted();
        expect(result.isSuccess, isTrue);
      });
    });

    group('generationMode', () {
      test('常にvisionを返す', () {
        expect(SettingsService.generationMode, DiaryGenerationMode.vision);
      });
    });

    group('getSubscriptionInfoV2', () {
      test('ISubscriptionService成功 → Success伝播', () async {
        final basicPlan = BasicPlan();
        final status = SubscriptionStatus(
          planId: basicPlan.id,
          isActive: true,
          startDate: DateTime.now(),
        );
        when(
          () => mockSubscriptionService.getCurrentStatus(),
        ).thenAnswer((_) async => Success(status));

        final result = await service.getSubscriptionInfoV2();

        expect(result.isSuccess, isTrue);
        expect(result.value, isA<SubscriptionInfoV2>());
      });

      test('ISubscriptionService失敗 → Failure伝播', () async {
        when(
          () => mockSubscriptionService.getCurrentStatus(),
        ).thenAnswer((_) async => const Failure(ServiceException('DB error')));

        final result = await service.getSubscriptionInfoV2();

        expect(result.isFailure, isTrue);
      });
    });

    group('getCurrentPlanClass', () {
      test('成功 → Success(Plan)を返す', () async {
        final plan = BasicPlan();
        when(
          () => mockSubscriptionService.getCurrentPlanClass(),
        ).thenAnswer((_) async => Success(plan));

        final result = await service.getCurrentPlanClass();

        expect(result.isSuccess, isTrue);
        expect(result.value, isA<Plan>());
      });

      test('失敗 → Failureを返す', () async {
        when(
          () => mockSubscriptionService.getCurrentPlanClass(),
        ).thenAnswer((_) async => const Failure(ServiceException('error')));

        final result = await service.getCurrentPlanClass();

        expect(result.isFailure, isTrue);
      });
    });

    group('getAvailablePlansV2', () {
      test('全プランのリストを返す', () async {
        final result = await service.getAvailablePlansV2();

        expect(result.isSuccess, isTrue);
        expect(result.value, isA<List<Plan>>());
        expect(result.value.length, greaterThan(0));
      });
    });

    group('getRemainingGenerations', () {
      test('成功 → Success(int)を返す', () async {
        when(
          () => mockSubscriptionService.getRemainingGenerations(),
        ).thenAnswer((_) async => const Success(5));

        final result = await service.getRemainingGenerations();

        expect(result.isSuccess, isTrue);
        expect(result.value, 5);
      });

      test('失敗 → Failureを返す', () async {
        when(
          () => mockSubscriptionService.getRemainingGenerations(),
        ).thenAnswer((_) async => const Failure(ServiceException('error')));

        final result = await service.getRemainingGenerations();

        expect(result.isFailure, isTrue);
      });
    });

    group('getNextResetDate', () {
      test('成功 → Success(DateTime)を返す', () async {
        final nextDate = DateTime(2026, 3, 1);
        when(
          () => mockSubscriptionService.getNextResetDate(),
        ).thenAnswer((_) async => Success(nextDate));

        final result = await service.getNextResetDate();

        expect(result.isSuccess, isTrue);
        expect(result.value, nextDate);
      });
    });

    group('canChangePlan', () {
      test('初期化済み → Success(true)', () async {
        when(() => mockSubscriptionService.getCurrentStatus()).thenAnswer(
          (_) async => Success(
            SubscriptionStatus(
              planId: 'basic',
              isActive: true,
              startDate: DateTime.now(),
            ),
          ),
        );

        final result = await service.canChangePlan();

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });
    });

    group('SubscriptionService未初期化時', () {
      test('getSubscriptionInfoV2 → Failure', () async {
        // 新しいSettingsServiceを作成し、subscriptionServiceを未設定にする
        SharedPreferences.setMockInitialValues({});
        serviceLocator.clear();
        // ISubscriptionServiceを登録しない
        final uninitService = SettingsService();
        // initializeを呼ばない（_subscriptionService == null）

        final result = await uninitService.getSubscriptionInfoV2();
        expect(result.isFailure, isTrue);
      });
    });
  });
}
