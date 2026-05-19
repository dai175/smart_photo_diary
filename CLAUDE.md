# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Smart Photo Diary is a Flutter mobile application that generates diary entries from photos using AI (Google Gemini). The app implements a freemium monetization model with Basic (free) and Premium subscription tiers. All user data is stored locally on the device (privacy-first design).

## Development Commands

```bash
# Setup and dependencies (using FVM - Flutter 3.41.4)
fvm install                        # Install the pinned Flutter version
fvm flutter pub get
fvm dart run build_runner build

# Testing (100% success rate must be maintained)
fvm flutter test
fvm flutter test test/unit/          # Unit tests only
fvm flutter test test/widget/        # Widget tests only
fvm flutter test test/integration/   # Integration tests only

# Code quality (REQUIRED before commits)
fvm flutter analyze                # Must show "No issues found!"
fvm dart format .                  # ALWAYS run after code changes

# Coverage measurement (threshold: 55%, enforced in CI)
fvm flutter test --coverage
lcov --summary coverage/lcov.info                                    # Summary
genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html  # HTML report

# Internationalization
fvm flutter gen-l10n              # Generate localization files

# Debug run
fvm flutter run
fvm flutter run --dart-define-from-file=.env --dart-define=FORCE_PLAN=premium_monthly  # Force premium plan
```

## Architecture Overview

### Directory Structure

- `lib/core/` — DI container, `result/` (Result<T> sealed class + UI/async extensions), exception hierarchy
  - `hive_encryption_helper.dart` — Hive box encryption (AES-256 via flutter_secure_storage)
- `lib/config/` — environment config (.env loader, build-time constants)
- `lib/constants/` — app-wide constants (subscription, theme, AI, cache)
- `lib/models/` — data models, Hive types, plan definitions (`plans/`), state models (`states/`)
- `lib/services/interfaces/` — all service interfaces (I-prefix)
- `lib/services/ai/` — Gemini client, prompt builder, tag/diary generators
- `lib/services/diary_image/` — diary image generation (layout, photo/text rendering)
- `lib/services/social_share/` — social share channel implementations
- `lib/services/mixins/` — shared service mixins (e.g., error handling)
- `lib/services/*.dart` — core service implementations, delegates, usage tracking, feature access control, and subscription state management (flat structure at services root)
- `lib/controllers/` — ChangeNotifier-based screen controllers, `BaseErrorController` (shared error handling), and utility notifiers (`PastPhotosNotifier`, `ScrollSignal`); `UpgradeDialogController` manages premium upgrade flow; `PhotoSelectionController` manages photo selection state
- `lib/screens/` — screen/page implementations with subdirectories (`home/`, `diary_detail/`, `diary_preview/`, `statistics/`, `onboarding/`) and root-level screen files (`settings_screen.dart`, `diary_screen.dart`)
- `lib/widgets/` — domain-specific reusable widgets organized into subdirs: `settings/`, `timeline/`, `upgrade/`; root-level widgets include diary cards, search, calendar
- `lib/ui/design_system/` — Material Design 3 theme, colors, typography
- `lib/ui/components/` — shared UI components
- `lib/ui/animations/` — micro-interactions, page transitions
- `lib/ui/error_display/` — error display system with severity levels
- `lib/shared/` — shared UI elements
- `lib/debug/` — debug screens (font debug)
- `lib/utils/` — utility functions
- `lib/l10n/` — ARB files (Japanese/English)
- `lib/localization/` — localization extensions and helpers

### Key Patterns

- **Dependency injection** via `ServiceLocator` — services registered in `core/service_registration.dart` (2-phase: core services first, then dependent services)
- **Interface-oriented design** — all service interfaces use `I` prefix: `IDiaryService`, `IAiService`, `IPhotoService`, etc.
- **`Result<T>` pattern** for type-safe error handling (`sealed class` with `Success<T>` / `Failure<T>`) — new features MUST use this
- **Exception hierarchy** — `AppException` base class with specific subtypes in `lib/core/errors/`
- **State management** — `ChangeNotifier`-based controllers (no Provider/Riverpod/Bloc)
- **Facade + Delegate pattern** — large services and controllers decompose into focused delegates (e.g., `DiaryQueryDelegate`, `PurchaseFlowDelegate`, `DiaryPreviewGenerationDelegate`). Each delegate has single responsibility and can be unit-tested independently.
  - Services: `DiaryService` → `DiaryCrudDelegate` + `DiaryQueryDelegate`, `StorageService` → `StorageExportDelegate` + `StorageImportDelegate`, `SubscriptionService` → `PurchaseFlowDelegate` + `PurchaseProductDelegate`, `SettingsService` → `SettingsSubscriptionDelegate`
  - Controllers: `DiaryPreviewController` → `DiaryPreviewGenerationDelegate` + `DiaryPreviewSaveDelegate`
- **Constructor injection** — service dependencies injected via constructors
- **`build_runner`** for generating Hive type adapters
- **Async stale prevention** — use `_requestVersion` pattern: capture version before async op, check after completion to discard stale results

### Registered Services

See `lib/core/service_registration.dart` for the full service registry.
- 2-phase registration: Phase 1 (independent core services) → Phase 2 (cross-dependent services)
- `DiaryService` implements split interfaces: `IDiaryCrudService` + `IDiaryQueryService` (resolve to same instance)
- 3 registration types: `registerSingleton` (eager), `registerFactory` (per call), `registerAsyncFactory` (async init)

## Critical Development Guidelines

### Logging (MANDATORY)
ALL logging must use `LoggingService`. Never use `print`/`debugPrint` except in fallbacks when `ServiceLocator` is unavailable.
All log messages, exception messages, and debug data map keys must be written in English (comments may remain in Japanese).

### Security (CRITICAL)
- NEVER commit API keys: Use `.env` file in project root (gitignored)
- NEVER include .env in assets: Always project root placement
- Environment loading: `dotenv.load(fileName: ".env")`
- `.env.example` provides template — copy to `.env` and fill in values

### Git Rules (CRITICAL)
- Never commit without explicit user approval
- Always run `fvm flutter analyze` and `fvm dart format .` before commits

### Commit Messages
- Use Conventional Commits format: `<type>: <description>`
- Types: `fix:`, `feat:`, `refactor:`, `chore:`, `docs:`, `test:`
- Write in English, concise (1 sentence preferred)
- Focus on "why" not "what" in the description

### Pull Requests
- Title: short (<70 chars), use same Conventional Commits prefix
- Body format:
  ```
  ## Summary
  - <bullet points describing changes>

  ## Test Plan
  - <how to verify the changes>
  ```

### UI Guidelines

See **[DESIGN.md](DESIGN.md)** for the full design system reference (colors, typography, spacing, component rules).

Key rules for quick reference:
- Use `CustomDialog` for modals, never `AlertDialog`
- No gradients; CTA buttons use `AppColors.accentDark` (not `accent`) for WCAG AA compliance
- All UI text via `context.l10n`, never hardcoded strings
- Variable names in English, UI text localized (Japanese/English)
- Service methods accept `Locale?` parameter for language-specific operations

- **Dark mode**: Before marking any UI task done, verify both light and dark modes. See **[DESIGN.md — ダークモード実装ルール](DESIGN.md)** for the full checklist.

### Testing
- Maintain 100% test success rate
- All new features must have tests
- Test structure mirrors source: `test/unit/`, `test/widget/`, `test/integration/`
- Use `mocktail` for mocking
- Coverage threshold: 55% (CI enforced); **UI layer (`lib/ui/`, `lib/widgets/`, `lib/screens/`) is excluded from measurement**

## Gotchas

- `.claude/rules/` contains modular rule files auto-loaded by Claude Code: `dark_mode.md`, `build_runner.md`, `result_pattern.md`, `logging.md` — edit these to update specific rules without touching this file
- `.claude.local.md` is gitignored — use for personal/local Claude Code settings
- Run `fvm dart run build_runner build` after modifying any Hive `@HiveType` model
- `lib/hive_registrar.g.dart` is auto-generated by build_runner — do NOT edit manually
- **Hive CE silent data discard**: Hive CE silently discards data on encryption mismatch (no exception thrown). Always check migration state BEFORE opening boxes with cipher. See `lib/core/hive_encryption_helper.dart`
- `test/temp/` is used for temporary test artifacts — do not commit test data there

## CI/CD

- `.github/workflows/ci.yml` — test, analyze, format check, coverage (min 55%, UI layer excluded), build
- `.github/workflows/release.yml` — release automation
- `.github/workflows/ios-deploy.yml` — iOS deployment

## Platform Specifics

- Handle `PermissionState.limited` for iOS 14+ (photo_manager)
- Premium users can access photos from past 365 days
