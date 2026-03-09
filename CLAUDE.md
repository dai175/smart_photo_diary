# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Smart Photo Diary is a Flutter mobile application that generates diary entries from photos using AI (Google Gemini). The app implements a freemium monetization model with Basic (free) and Premium subscription tiers. All user data is stored locally on the device (privacy-first design).

## Development Commands

```bash
# Setup and dependencies (using FVM - Flutter 3.32.0)
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

# Coverage measurement (threshold: 48%, enforced in CI)
fvm flutter test --coverage
lcov --summary coverage/lcov.info                                    # Summary
genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html  # HTML report

# Internationalization
fvm flutter gen-l10n              # Generate localization files

# Debug run
fvm flutter run
fvm flutter run --dart-define=FORCE_PLAN=premium  # Force premium plan
```

## Architecture Overview

### Directory Structure

- `lib/core/` — DI container, Result<T> pattern, exception hierarchy
- `lib/services/interfaces/` — all service interfaces (I-prefix)
- `lib/controllers/` — ChangeNotifier-based screen controllers
- `lib/ui/design_system/` — Material Design 3 theme, colors, typography
- `lib/ui/components/` — shared UI components (CustomDialog, buttons, etc.)
- `lib/l10n/` — ARB files (Japanese/English)

### Key Patterns

- **Dependency injection** via `ServiceLocator` — services registered in `core/service_registration.dart` (2-phase: core services first, then dependent services)
- **Interface-oriented design** — all service interfaces use `I` prefix: `IDiaryService`, `IAiService`, `IPhotoService`, etc.
- **`Result<T>` pattern** for type-safe error handling (`sealed class` with `Success<T>` / `Failure<T>`) — new features MUST use this
- **Exception hierarchy** — `AppException` base class with specific subtypes in `lib/core/errors/`
- **State management** — `ChangeNotifier`-based controllers (no Provider/Riverpod/Bloc)
- **Facade + Delegate pattern** — large services and controllers decompose into focused delegates (e.g., `DiaryQueryDelegate`, `PurchaseFlowDelegate`, `DiaryPreviewGenerationDelegate`). Each delegate has single responsibility and can be unit-tested independently.
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

### Git Rules (CRITICAL)
- Never commit without explicit user approval
- Always run `fvm flutter analyze` and `fvm dart format .` before commits

### UI Guidelines
- Use `CustomDialog` for modals, never `AlertDialog`
- No gradients, follow Material Design 3 (theme defined in `ui/design_system/`)
- All UI text uses internationalization (i18n) via `context.l10n`, never hardcoded strings
- Variable names in English, UI text localized (Japanese/English)

### Testing
- Maintain 100% test success rate
- All new features must have tests
- Test structure mirrors source: `test/unit/`, `test/widget/`, `test/integration/`
- Use `mocktail` for mocking

## Gotchas

- Run `fvm dart run build_runner build` after modifying any Hive `@HiveType` model
- Some controllers use delegate pattern (e.g., `diary_preview_generation_delegate.dart`) rather than extending ChangeNotifier directly
- Test helpers and shared mocks are in `test/mocks/` and `test/test_helpers/`
- `.env` must be in project root (not `assets/`), loaded via `dotenv.load(fileName: ".env")`
- `DiaryService` implements both `IDiaryCrudService` and `IDiaryQueryService` — split interface registrations resolve to the same `IDiaryService` instance via `registerAsyncFactory`

## Platform Specifics

- Handle `PermissionState.limited` for iOS 14+ (photo_manager)
- Premium users can access photos from past 365 days

## Internationalization (i18n)

- Always use `context.l10n` for UI text, never hardcoded strings
- Service methods accept `Locale?` parameter for language-specific operations
