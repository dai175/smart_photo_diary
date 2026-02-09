# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Smart Photo Diary is a Flutter mobile application that generates diary entries from photos using AI. The app implements a freemium monetization model with Basic (free) and Premium subscription tiers.

## Development Commands

```bash
# Setup and dependencies (using FVM)
fvm flutter pub get
fvm dart run build_runner build

# Testing (100% success rate must be maintained)
fvm flutter test

# Code quality (REQUIRED before commits)
fvm flutter analyze                # Must show "No issues found!"
fvm dart format .                  # ALWAYS run after code changes

# Internationalization
fvm flutter gen-l10n              # Generate localization files
```

## Architecture Overview

- Dependency injection via `ServiceLocator` — services are registered in `core/service_registration.dart`
- All service interfaces use `I` prefix: `IDiaryService`, `IAiService`, etc.
- `Result<T>` pattern for type-safe error handling — new features MUST use this for all operations that can fail
- Exception types are defined in `lib/core/errors/`
- `build_runner` for generating Hive adapters

## Critical Development Guidelines

### Logging (MANDATORY)
ALL logging must use `LoggingService`. Never use `print`/`debugPrint` except in fallbacks when `ServiceLocator` is unavailable.

### Security (CRITICAL)
- NEVER commit API keys: Use `.env` file in project root (gitignored)
- NEVER include .env in assets: Always project root placement
- Environment loading: `dotenv.load(fileName: ".env")`

### Git Rules (CRITICAL)
- Never commit without explicit user approval
- Always run `fvm flutter analyze` and `fvm dart format .` before commits

### UI Guidelines
- Use `CustomDialog` for modals, never `AlertDialog`
- No gradients, follow Material Design 3
- All UI text uses internationalization (i18n) via `context.l10n`, never hardcoded strings
- Variable names in English, UI text localized (Japanese/English)

### Testing
- Maintain 100% test success rate
- All new features must have tests

## Platform Specifics

- Uses `photo_manager` and `permission_handler`
- Handle `PermissionState.limited` for iOS 14+
- Premium users can access photos from past 365 days

## Internationalization (i18n)

- ARB files in `lib/l10n/`: `app_ja.arb` (Japanese), `app_en.arb` (English)
- Always use `context.l10n` for UI text
- Service methods accept `Locale?` parameter for language-specific operations
