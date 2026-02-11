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

# Internationalization
fvm flutter gen-l10n              # Generate localization files

# Debug run
fvm flutter run
fvm flutter run --dart-define=FORCE_PLAN=premium  # Force premium plan
```

## Architecture Overview

### Directory Structure

```
lib/
├── core/                    # Core architecture
│   ├── result/             # Result<T> pattern (type-safe error handling)
│   ├── errors/             # Exception hierarchy (AppException base)
│   ├── service_locator.dart    # DI container
│   └── service_registration.dart # 2-phase service registration
├── services/                # Service layer
│   ├── interfaces/         # Service interfaces (I-prefix convention)
│   ├── ai/                 # AI services (Gemini API client, generators)
│   ├── social_share/       # Social sharing channels
│   └── *.dart              # Service implementations
├── models/                  # Data models (Hive-annotated)
│   ├── plans/              # Subscription plan definitions
│   └── states/             # State models
├── screens/                 # Screen widgets
├── controllers/             # Screen controllers (ChangeNotifier-based)
├── widgets/                 # Reusable widget components
├── shared/                  # Shared UI components (filters, etc.)
├── ui/                      # UI system
│   ├── design_system/      # Material Design 3 theme, colors, typography
│   ├── components/         # Common UI components (CustomDialog, etc.)
│   ├── animations/         # Animation definitions
│   └── error_display/      # Severity-based error display system
├── constants/               # App-wide constants
├── utils/                   # Utility functions
├── config/                  # Environment & IAP configuration
├── l10n/                    # Internationalization ARB files
├── localization/            # Locale extensions & utilities
└── debug/                   # Debug-only screens
```

### Key Patterns

- **Dependency injection** via `ServiceLocator` — services registered in `core/service_registration.dart` (2-phase: core services first, then dependent services)
- **Interface-oriented design** — all service interfaces use `I` prefix: `IDiaryService`, `IAiService`, `IPhotoService`, etc.
- **`Result<T>` pattern** for type-safe error handling (`sealed class` with `Success<T>` / `Failure<T>`) — new features MUST use this
- **Exception hierarchy** — `AppException` base class with specific subtypes in `lib/core/errors/`
- **State management** — `ChangeNotifier`-based controllers (no Provider/Riverpod/Bloc)
- **`build_runner`** for generating Hive type adapters

### Registered Services

| Service | Interface | Role |
|---------|-----------|------|
| LoggingService | ILoggingService | Unified logging |
| DiaryService | IDiaryService | Diary CRUD, search, filter |
| PhotoService | IPhotoService | Photo library access |
| PhotoCacheService | IPhotoCacheService | Photo thumbnail caching |
| PhotoAccessControlService | IPhotoAccessControlService | Premium photo access control |
| AiService | IAiService | AI diary/tag generation |
| SubscriptionService | ISubscriptionService | Subscription & usage tracking |
| SettingsService | ISettingsService | App settings, theme, locale |
| StorageService | IStorageService | Data export/import |
| PromptService | IPromptService | Writing prompt management |
| SocialShareService | ISocialShareService | X/Instagram sharing |
| DiaryImageGenerator | (concrete) | Social share image generation |
| TimelineGroupingService | (static) | Date-based timeline grouping |

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
- No gradients, follow Material Design 3 (theme defined in `ui/design_system/`)
- All UI text uses internationalization (i18n) via `context.l10n`, never hardcoded strings
- Variable names in English, UI text localized (Japanese/English)

### Testing
- Maintain 100% test success rate
- All new features must have tests
- Test structure mirrors source: `test/unit/`, `test/widget/`, `test/integration/`
- Use `mocktail` for mocking

## Platform Specifics

- Uses `photo_manager` and `permission_handler`
- Handle `PermissionState.limited` for iOS 14+
- Premium users can access photos from past 365 days
- In-App Purchase with StoreKit 2 support (`in_app_purchase` package)

## Internationalization (i18n)

- ARB files in `lib/l10n/`: `app_ja.arb` (Japanese), `app_en.arb` (English)
- Always use `context.l10n` for UI text
- Service methods accept `Locale?` parameter for language-specific operations
- Locale extensions in `lib/localization/`
