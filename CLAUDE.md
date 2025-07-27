# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Smart Photo Diary is a Flutter mobile application that generates diary entries from photos using AI. The app implements a freemium monetization model with Basic (free) and Premium subscription tiers. Core features include AI-powered diary generation, writing prompts, and complete offline functionality with privacy-first design.

## Development Commands

### Setup and Dependencies
```bash
# Get dependencies (using FVM)
fvm flutter pub get

# Code generation for Hive models (using FVM)
fvm dart run build_runner build

# Force rebuild generated code
fvm dart run build_runner build --delete-conflicting-outputs
```

### Development
```bash
# Run app in development (using FVM)
fvm flutter run

# Hot reload and hot restart are available during development
```

### Testing
```bash
# Run all tests (using FVM) - Currently 808+ tests with 100% success rate
fvm flutter test

# Run specific test types
fvm flutter test test/unit/        # Unit tests
fvm flutter test test/widget/      # Widget tests  
fvm flutter test test/integration/ # Integration tests

# Run tests with coverage
fvm flutter test --coverage
```

### Build Commands
```bash
# Debug build
fvm flutter build apk --debug

# Release builds
fvm flutter build apk --release
fvm flutter build appbundle
fvm flutter build ipa

# Install release APK on connected Android device
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Linting and Code Quality
```bash
# Analyze code (configured to suppress info-level lints for cleaner output)
fvm flutter analyze

# Fix formatting (REQUIRED after any code changes)
fvm dart format .

# Check formatting without changing files (CI/CD safe)
fvm dart format --set-exit-if-changed .
```

**IMPORTANT**: Always run `fvm dart format .` after making any code changes to ensure consistent formatting. The CI/CD pipeline will fail if code is not properly formatted.

### CI/CD and GitHub Actions
```bash
# Trigger CI/CD pipeline (automatic on push/PR to main/develop)
git push origin main

# Create release (triggers release.yml workflow)
git tag v1.0.0
git push origin v1.0.0
```

## Architecture Overview

### Service Layer Pattern
The app follows a service-oriented architecture with singleton services using lazy initialization via `ServiceLocator`:

- **`DiaryService`**: Central data management with Hive database operations, depends on `AiService` for tag generation
- **`PhotoService`**: Photo access and permissions via `photo_manager` plugin
- **`AiService`**: AI diary generation with Google Gemini API and strict error handling to prevent unauthorized credit consumption
- **`ImageClassifierService`**: On-device ML inference capabilities
- **`SettingsService`**: App configuration stored in SharedPreferences with Result<T> pattern for write operations
- **`StorageService`**: File system operations and data export functionality
- **`LoggingService`**: Structured logging with levels and performance monitoring
- **`SubscriptionService`**: In-App Purchase integration for Premium subscriptions
- **`PromptService`**: Writing prompt management with JSON asset loading and 3-tier caching system

### Error Handling Architecture

The app implements a **Result<T> pattern** for functional error handling:

#### Result<T> Pattern (`lib/core/result/`)
- **`Result<T>`**: Sealed class with `Success<T>` and `Failure<T>` variants
- **Functional operations**: `map`, `fold`, `chain`, `onSuccess`, `onFailure`
- **Helper utilities**: `ResultHelper` for easy creation and combination

#### Standardized Exception Hierarchy (`lib/core/errors/`)
- **`AppException`**: Base exception with message, details, and original error context
- **Domain-specific exceptions**: `ServiceException`, `PhotoAccessException`, `AiProcessingException`, etc.
- **`ErrorHandler`**: Utilities for error conversion, logging, and safe execution

### Dependency Injection
- **`ServiceLocator`**: Central dependency injection container supporting singleton, factory, and async factory patterns
- Services are registered at app startup and accessed via interfaces for better testability

### Data Models
- **`DiaryEntry`**: Primary data model with Hive annotations for local storage
- **`WritingPrompt`**: Writing prompt model with categories, tags, and Premium/Basic classification
- **Plan Classes**: Type-safe subscription plan system (BasicPlan, PremiumMonthlyPlan, PremiumYearlyPlan)
- **`PlanFactory`**: Factory pattern for plan instantiation and management
- Uses `build_runner` for generating Hive adapters

### AI/ML Architecture
- **Cloud AI**: Google Gemini 2.5 Flash integration for advanced diary generation
- **Environment Management**: EnvironmentConfig provides robust API key management with validation
- **Credit Protection**: AI credits are only consumed when generation is successful

### Monetization Architecture
- **Freemium Model**: Basic (free, 10 AI generations/month) vs Premium (¥300/month, 100 generations + prompts)
- **Plan Class Architecture**: Type-safe, extensible plan management with factory pattern
- **In-App Purchase Integration**: Uses `in_app_purchase` plugin for subscription management
- **Usage Tracking**: AI generation counts with monthly reset functionality
- **Writing Prompts System**: 20 curated prompts (5 Basic + 15 Premium) across 8 categories

## Key Dependencies

### Core
- `hive` + `hive_flutter`: Local NoSQL database for diary storage
- `photo_manager`: Photo access and management with permission handling
- `permission_handler`: Platform-specific permissions for photo access
- `connectivity_plus`: Network status checking for AI service availability
- `shared_preferences`: Simple key-value storage for app settings
- `file_picker`: User-selectable file export destinations
- `http`: Network requests for AI API integration
- `flutter_dotenv`: Environment variable management
- `in_app_purchase: 3.1.10`: Subscription management (pinned version for StoreKit 2 compatibility)
- `google_fonts`: Typography and font management

### Development
- `build_runner` + `hive_generator`: Code generation for Hive adapters
- `mocktail`: Testing framework for service mocking
- `flutter_lints`: Code analysis with custom rules

## Important Files

### Configuration
- `pubspec.yaml`: Dependencies and asset configuration
- `analysis_options.yaml`: Linting rules with Japanese text support and performance optimizations
- `.env`: Environment variables (API keys) - **NEVER bundled in assets** (placed in project root)

### Generated Code
- `lib/models/diary_entry.g.dart`: Auto-generated Hive adapter (do not edit manually)

### Assets
- `assets/data/writing_prompts.json`: Writing prompts data with metadata and categorization

## Development Guidelines

### Security Guidelines (CRITICAL)
**Always prioritize security best practices:**

1. **Environment Variables**:
   - NEVER include `.env` files in `assets/` or application bundles
   - Always use project root placement: `/project-root/.env`
   - Use `dotenv.load(fileName: ".env")` to load from root, not assets

2. **API Key Management**:
   - Local development: `.env` in project root (gitignored)
   - CI/CD: GitHub Secrets with dynamic `.env` creation
   - Production: Environment variables or secure platform storage
   - NEVER bundle API keys in APK/IPA files

3. **AI Generation and Credit Protection**:
   - AI credits are only consumed on successful generation
   - Failed generations must throw exceptions, not return fallback content

### Git Operations and Development Rules (CRITICAL)
**IMPORTANT**: Always follow these rules when working with Git and making code changes:

#### Git Operations
1. **Never commit without explicit user approval**:
   - Complete code modifications and testing first
   - Report changes and results to user
   - Wait for user's explicit instruction to commit

2. **Commit Guidelines**:
   - Only commit when functionality is tested and confirmed working
   - Use descriptive commit messages that explain the "why" not just "what"

#### Code Quality Standards
- Always run `fvm flutter analyze` before committing code - currently **no issues** (clean codebase)
- Always run `fvm dart format .` after any code changes
- Test suite must maintain 100% success rate

### Error Handling Patterns

#### Result<T> Usage Guidelines
- **New features MUST use Result<T> pattern** for all operations that can fail
- **Existing code should be migrated gradually** - start with write operations
- **Prefer Result<void> for operations without return values**

#### Current Implementation Status
- **✅ Complete foundation**: Result<T> core implementation with comprehensive utilities and 100% test coverage
- **✅ Partial adoption**: SettingsService uses Result<T> for write operations
- **📋 Migration targets**: DiaryService, PhotoService, AiService for gradual Result<T> adoption

### UI Development Guidelines
- **Modal Design**: Always use CustomDialog for new modals and avoid AlertDialog
- **Text Alignment**: Use left-aligned text (textAlign: TextAlign.left) for user-facing content
- **Layout Constraints**: Avoid fixed heights and use natural layouts (Flexible, Expanded, etc.)
- **No gradients**: All gradients removed for cleaner, simpler design
- **Material Design 3**: Follow MD3 principles with emphasis on solid colors

### Japanese Language Development
- **UI text**: All user-facing text is in Japanese
- **Comments**: Business logic documented in Japanese
- **Variable names**: Use descriptive English names for code clarity
- **Locale configuration**: MaterialApp configured with Japanese locale (`ja_JP`)

### Platform Considerations
The app is designed as an **iPhone-only application** with iPad support explicitly disabled. Photo access requires platform-specific permissions handled by `permission_handler`.

#### iOS Photo Permission Implementation
**CRITICAL**: iOS photo permissions require specific implementation patterns:

#### Required Info.plist Keys
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>写真ライブラリにアクセスして、日記作成に使用する写真を取得します</string>
<key>PHPhotoLibraryPreventAutomaticLimitedAccessAlert</key>
<true/>
```

#### Limited Photo Access Handling (iOS 14+)
- **Detection**: Use `PermissionState.limited` from PhotoManager
- **User Guidance**: Show explanatory dialog when photo count is low
- **Photo Selection**: Use `PhotoManager.presentLimited()` to show selection UI

### Testing Architecture
The project follows a comprehensive 3-tier testing strategy with **100% success rate** (808+ passing tests):

#### Unit Tests (`test/unit/`)
- Pure logic testing with mocked dependencies using `mocktail`
- Service mock tests with `*_service_mock_test.dart` files

#### Widget Tests (`test/widget/`)
- UI component testing with mocked services via dependency injection

#### Integration Tests (`test/integration/`)
- End-to-end flow testing with real service implementations

### Environment Variables and Configuration

#### Security Best Practices
**CRITICAL**: Never include `.env` files in assets or application bundles.

- **Local Development**: Place `.env` file in project root directory
- **Version Control**: Always add `.env` to `.gitignore`
- **CI/CD**: Use GitHub Secrets, create `.env` dynamically
- **Loading method**: `dotenv.load(fileName: ".env")` loads from project root

#### Development Plan Override (Debug Mode Only)
For testing subscription features:
```bash
# In .env file (debug builds only)
FORCE_PLAN=premium
```

## Development Status

### Current Implementation State
- **Production-ready services**: All core services are fully implemented and tested
- **Plan Class Architecture**: Complete migration from enum to class-based plan management
- **Functional error handling**: Result<T> pattern implemented with complete utilities
- **Performance optimized**: Lazy initialization, efficient caching, optimized database operations
- **High code quality**: Clean, well-documented codebase with 100% test success rate
- **Type-safe monetization**: Extensible plan system with factory pattern

### Recent Achievements
- **Plan Class Migration**: Successfully migrated from SubscriptionPlan enum to Plan class architecture
- Perfect test coverage: 808+ tests with 100% success rate
- Complete freemium model with In-App Purchase integration
- Writing prompts system with 20 curated prompts
- Result<T> pattern implementation for robust error handling
- Service architecture with dependency injection
- Enhanced UI/UX with unified design system
- Complete CI/CD pipeline implementation
- **Type Safety Enhancement**: Improved extensibility and maintainability through Plan class system
- Production-ready Smart Photo Diary v1.0 with modern architecture

## CI/CD and Deployment

The project includes automated GitHub Actions workflows:

- **ci.yml**: Continuous integration (automatic on push/PR)
- **release.yml**: GitHub releases (tag-triggered)
- **android-deploy.yml**: Google Play Store deployment (manual)
- **ios-deploy.yml**: App Store deployment (manual)

### Required GitHub Secrets
```bash
# Core API (required for production builds)
GEMINI_API_KEY=your_google_gemini_api_key

# Store deployment secrets (configure as needed)
GOOGLE_PLAY_SERVICE_ACCOUNT=service_account_json
ANDROID_SIGNING_KEY=base64_encoded_keystore
IOS_DISTRIBUTION_CERTIFICATE=p12_certificate_base64
APPLE_ID=apple_developer_account_email
```

### Release Process
```bash
# Create and push version tag
git tag v1.0.1
git push origin v1.0.1

# Automatic GitHub Release creation
# Manual store deployment via GitHub Actions workflows
```