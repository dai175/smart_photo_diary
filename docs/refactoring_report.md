# Refactoring Report

**Date:** 2026-02-27
**Scope:** Full codebase review (`lib/` directory)

---

## Summary

| Category | Count |
|----------|-------|
| Dead code / Unused code | 30+ |
| i18n / Logging rule violations | 6 |
| Duplicated logic | 12 |
| Redundancy / Inconsistency | 10 |

---

## High Priority

### 1. Dead Code — Unused UI Widgets & Classes (`lib/ui/`)

15+ unused widgets/classes found:

| Unused Symbol | File |
|---------------|------|
| `PulseWidget` | `lib/ui/animations/micro_interactions.dart` |
| `FloatingWidget` | `lib/ui/animations/micro_interactions.dart` |
| `BreatheWidget` | `lib/ui/animations/micro_interactions.dart` |
| `MicroInteractions.scaleOnTap` | `lib/ui/animations/micro_interactions.dart` |
| `AnimatedListBuilder` | `lib/ui/animations/list_animations.dart` |
| `PageTransitionExtensions` | `lib/ui/animations/page_transitions.dart` |
| `SmallCard` | `lib/ui/components/custom_card.dart` |
| `LargeCard` | `lib/ui/components/custom_card.dart` |
| `ElevatedCard` | `lib/ui/components/custom_card.dart` |
| `DeletableChip` | `lib/ui/components/modern_chip.dart` |
| `ChipCategory` | `lib/ui/components/modern_chip.dart` |
| `FilterChip` (custom) | `lib/ui/components/modern_chip.dart` |
| `ComponentConstants` | `lib/ui/component_constants.dart` |
| `AppColors` helpers (`getTextColorForBackground`, `withAlpha`, `getHoverColor`, `getFocusColor`, `getPressedColor`) | `lib/ui/design_system/app_colors.dart` |
| `AppTypography` helpers (`withWeight`, `withSize`, `withShadow`, `getResponsiveFontSize`) | `lib/ui/design_system/app_typography.dart` |
| `AppSpacing` helpers (`getResponsiveSpacing`, `getSafeAreaPadding`, `createAsymmetricRadius`) | `lib/ui/design_system/app_spacing.dart` |
| `AppTheme` helpers (`createCustomTheme`, `createBlurContainer`) | `lib/ui/design_system/app_theme.dart` |
| `DynamicPriceManager`, `createManager` | `lib/utils/dynamic_pricing_utils.dart` |
| `PhotoDateUtils.getSortedDateKeys`, `getSortedMonthKeys`, `getRelativeDateString` | `lib/utils/photo_date_utils.dart` |

### 2. Dead Code — `InAppPurchaseConfig` (`lib/config/in_app_purchase_config.dart`)

Large amount of unused code:

- `isIOS` / `isAndroid` — `isIOS` uses `identical(1, 1.0)` which is `false` in the Dart VM (int and double are different types), but may be `true` under dart2js (Web) where all numbers are JavaScript doubles
- `currentPlatformConfig` — unused
- `serverSideValidationEnabled` (always `false`), `receiptValidationEndpoint`, `fraudDetectionEnabled`, `purchaseValidationTimeoutSeconds` — unused
- `testAccounts`, `testProductIdPrefix`, `getTestProductId` — test-only, not used in production
- Feature flags (`inAppPurchaseEnabled`, `freeTrialEnabled`, `restorePurchasesEnabled`, `planChangeEnabled`, `purchaseHistoryEnabled`) — all return `true`, no conditional value
- `premiumMonthlyDisplayName`, `premiumYearlyDisplayName` and description equivalents — unused
- `InAppPurchaseException` — only referenced from tests
- `InAppPurchaseConfigValidator` — only referenced from tests

### 3. Dead Code — `PurchaseDataV2` (`lib/models/purchase_data_v2.dart`)

Entire file (`PurchaseProductV2` / `PurchaseResultV2`) is unused in production code. Only referenced from tests.

### 4. Dead Code — `PlanFactory` & `Plan` (`lib/models/plans/`)

- `PlanFactory.getPlansWithFeature` — unused in production
- `PlanFactory.getPlansWithMinimumLimit` — unused in production
- `PlanFactory.debugGetAllPlansInfo` — unused in production
- `Plan.hasMoreFeaturesThan` — unused in production

### 5. i18n Violations — Hardcoded Japanese Strings

CLAUDE.md rule: "All UI text uses internationalization (i18n) via `context.l10n`, never hardcoded strings"

| Location | Hardcoded Content |
|----------|-------------------|
| `lib/models/import_result.dart` L23-39 | `'$successfulImports件の日記を正常に復元しました'` etc. |
| `lib/models/writing_prompt.dart` L232-236 | `'高'`, `'中'`, `'低'` |
| `lib/services/interfaces/social_share_service_interface.dart` L79-97 | `ShareFormat.displayName`: `'縦長'`, `'正方形'` |
| `lib/services/timeline_grouping_service.dart` L53-193 | `'今日'`, `'昨日'`, `'${date.year}年${date.month}月'` (in legacy methods) |
| `lib/utils/photo_date_utils.dart` L134-159 | `'今日'`, `'昨日'`, `'一昨日'`, `'$difference日前'` etc. (unused but violating) |

### 6. Logging Rule Violation

CLAUDE.md rule: "All log messages must be written in English"

- `lib/services/mixins/purchase_event_handler.dart` L155-158, L242-245, L265-268 — Japanese log messages (`'購入フラグをリセットしました'` etc.)

### 7. Potential Bug — `executeWithRetry` Scope Issue

`attempts` variable scope issue in retry logic may cause retry conditions to not function correctly (controllers layer).

---

## Medium Priority — Duplicated Logic

### 8. `TimelineGroupingService` — Legacy/Localized Method Duplication

- `groupPhotosForTimeline` and `groupPhotosForTimelineLocalized` share identical grouping logic (L29-45 / L115-131)
- `getTimelineHeader` and `getTimelineHeaderLocalized` share identical logic (L186-213)
- Legacy methods with hardcoded Japanese should be removed; callers should use localized versions

### 9. `GeminiApiClient` — `sendTextRequest` / `sendVisionRequest` Duplication

- API key validation (L78-87, L157-166)
- `generationConfig` + `safetySettings` JSON construction
- Response 200 check, error handling, logging
- Only difference is `contents.parts` construction
- **Fix:** Extract common request/response handling method

### 10. `PurchaseProductDelegate` / `PurchaseFlowDelegate` — Identical `_handleError`

- `_handleError<T>` implementation is identical in both files (L183-208 / L192-217)
- `_validatePreconditions` / `_validateBasePreconditions` also follow same pattern
- **Fix:** Extract to common base class or mixin

### 11. `XShareChannel` / `InstagramShareChannel` — Identical `_getLocalizedMessage`

- Same helper method duplicated (L149-160 / L112-123)
- `_shareTimeoutSeconds` and `_defaultShareOrigin` also duplicated
- **Fix:** Extract to common base class or utility

### 12. `ImageLayoutCalculator` — Scale Calculation Duplication

- `calculateTextSizes` (L128-163), `calculateSpacing` (L167-179), `calculateBrandFontSize` (L183-192) all compute `actualWidth / baseWidth` averaged with `actualHeight / baseHeight` then clamp
- Same `actualWidth = format.isHD ? format.scaledWidth : format.width` pattern appears in `DiaryImageGenerator` (L45-46, L99-100)
- **Fix:** Add `actualWidth` / `actualHeight` properties to `ShareFormat` enum; extract `_calculateScale(ShareFormat)` method

### 13. `DiaryQueryDelegate` — Filtering Logic Duplication

- `getFilteredDiaryEntries` and `getFilteredDiaryEntriesPage` duplicate date range filtering (L77-86 / L145-154) and text search filtering (L88-94 / L156-162)
- **Fix:** Extract common filtering to shared method

### 14. `SettingsSubscriptionDelegate` — Repeated `getCurrentStatus()` Pattern

- `getCurrentStatus()` + `isFailure` check + `throw` repeated in 4 methods (L20-27, L35-51, L55-63, L66-83)
- **Fix:** Extract `_getValidStatus()` helper or add `.unwrap()` extension to `Result<T>`

### 15. Locale Retrieval Pattern — 4 Duplications

```dart
Intl.getCurrentLocale().isEmpty ? 'ja' : Intl.getCurrentLocale()
```

Appears in:
- `lib/models/plans/plan.dart` L90-92, L107-109
- `lib/models/purchase_data_v2.dart` L76-78
- `lib/config/in_app_purchase_config.dart` L217-219

**Fix:** Extract to utility method

### 16. `SubscriptionStatus` — `currentPlanClass` / `getCurrentPlanClass()` Duplication

- Getter (L90-97) and method (L266-268) perform same logic (`PlanFactory.createPlan(planId)`)
- Getter has try/catch fallback, method does not
- Referenced from 21 files
- **Fix:** Unify into one

### 17. Button Row Pattern — 6 Duplications

All 6 button variants repeat `Row` + `if (icon != null)` + `Icon` + `SizedBox` + `Flexible(Text(...))`:
- `PrimaryButton` L43-58
- `AccentButton` L29-42
- `DangerButton` L43-58
- `SurfaceButton` L34-44
- `SecondaryButton` L37-44
- `TextOnlyButton` L33-43

**Fix:** Extract `_ButtonContent` widget

### 18. Animation Boilerplate — 7 Duplications

Identical `SingleTickerProviderStateMixin` + `AnimationController` + `initState`/`dispose`/`didUpdateWidget` pattern in:
- `_BounceWrapper`, `PulseWidget`, `FloatingWidget`, `BreatheWidget` (`micro_interactions.dart`)
- `_CustomCardState` (`custom_card.dart`)
- `_ModernChipState` (`modern_chip.dart`)
- `_AnimatedButtonState` (`animated_button_base.dart`)

**Fix:** Extract common base class or mixin

### 19. `PremiumMonthlyPlan` / `PremiumYearlyPlan` — Identical Feature Flags

Both classes have identical values for `isPremium`, `hasWritingPrompts`, `hasAdvancedFilters`, `hasAdvancedAnalytics`, `hasPrioritySupport`, `pastPhotoAccessDays`.

**Fix:** Create shared `PremiumPlan` base class

---

## Low Priority — Redundancy & Inconsistency

### 20. `SocialShareService.isFormatSupported` Always Returns `true`

`ShareFormat.values.contains(format)` is always `true` when `format` is of type `ShareFormat`. Method is meaningless.

### 21. `InAppPurchaseConfig` Is a Thin Wrapper Over `SubscriptionConstants`

`premiumMonthlyProductId`, `premiumYearlyProductId`, `premiumMonthlyPrice`, `premiumYearlyPrice`, `freeTrialDays` all just forward values from `SubscriptionConstants`.

### 22. DI Pattern Inconsistency — Global `serviceLocator` Access

- `GeminiApiClient._apiKey` static getter uses global `serviceLocator` instead of injected `_logger`
- `ImagePhotoRenderer` uses `ServiceLocator()` in static method
- `ImageTextRenderer.formatDate` gets `SettingsService` from service locator inside a rendering utility

**Fix:** Pass dependencies via constructor or method parameters

### 23. Button `isLoading` Support Inconsistency

Only `PrimaryButton` and `DangerButton` have `isLoading` parameter. `AccentButton`, `SecondaryButton`, `SurfaceButton`, `TextOnlyButton` do not.

### 24. Button Icon-Text Spacing Inconsistency

- `PrimaryButton` / `AccentButton`: `AppSpacing.sm` (8pt)
- `SecondaryButton` / `TextOnlyButton`: `AppSpacing.xs` (4pt)

### 25. Light/Dark Theme Structural Asymmetry

- `app_theme_light.dart` `textTheme.copyWith` (L68-76) — no color specified
- `app_theme_dark.dart` `textTheme.copyWith` (L71-98) — all styles have `AppTypography.withColor`

### 26. Excessive Animation Duration Constants

13 animation `Duration` constants in `AppConstants` with very close values: `microFastAnimationDuration` 80ms, `microBaseAnimationDuration` 100ms, `fastAnimationDuration` 150ms, `shortAnimationDuration` 180ms, `quickAnimationDuration` 200ms — too granular, should be consolidated.

### 27. Duplicate Max Photos Constant

- `AppConstants.maxPhotosSelection` = 3
- `SubscriptionConstants.maxPhotosPerEntry` = 3

Same value defined independently. Should reference one source.

### 28. Thumbnail Size/Quality Constants Scattered

Thumbnail sizes and quality values duplicated across `app_constants.dart` and `photo_cache_constants.dart`:
- `defaultThumbnailWidth/Height` = 200 vs `thumbnailSizeMedium` = 200
- `timelineThumbnailQuality` = 50 vs `thumbnailQualityLow` = 50
- `diaryThumbnailQuality` = 70 vs `thumbnailQualityMedium` = 70

### 29. `SubscriptionDisplayDataV2.getLocalizedDisplayData` — 15 Parameters

Method takes 15 arguments (7 formatters + 8 text strings). Should introduce a parameter object.
