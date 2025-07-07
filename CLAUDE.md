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

### CI/CD and GitHub Actions
```bash
# Trigger CI/CD pipeline (automatic on push/PR to main/develop)
git push origin main

# Create release (triggers release.yml workflow)
git tag v1.0.0
git push origin v1.0.0

# Manual deployment workflows require GitHub Secrets:
# - GEMINI_API_KEY: Google Gemini API key for production builds
# - GOOGLE_PLAY_SERVICE_ACCOUNT: Android deployment credentials  
# - APPSTORE_ISSUER_ID, APPSTORE_KEY_ID, APPSTORE_PRIVATE_KEY: iOS deployment
# - ANDROID_SIGNING_KEY, ANDROID_KEYSTORE_PASSWORD: Android signing
```

### Development
```bash
# Run app in development (using FVM)
fvm flutter run

# Hot reload and hot restart are available during development
```

### Testing
```bash
# Run all tests (using FVM) - Currently 683 tests with 100% success rate
fvm flutter test

# Run only unit tests (pure logic, mocked dependencies)
fvm flutter test test/unit/

# Run only widget tests (UI components)
fvm flutter test test/widget/

# Run only integration tests (full app flows)
fvm flutter test test/integration/

# Run unit + integration tests combined
fvm flutter test test/unit/ test/integration/

# Run specific test file
fvm flutter test test/unit/services/diary_service_mock_test.dart

# Run tests with coverage
fvm flutter test --coverage

# Run tests with verbose output
fvm flutter test --reporter expanded

# Run tests with JSON reporter (for CI/debugging)
fvm flutter test --reporter json
```

### Build Commands
```bash
# Debug build
fvm flutter build apk --debug

# Release builds
fvm flutter build apk --release
fvm flutter build appbundle
fvm flutter build ipa

# Build for specific platforms
fvm flutter build macos
fvm flutter build windows
fvm flutter build linux

# Install release APK on connected Android device
adb install build/app/outputs/flutter-apk/app-release.apk

# Launch app on device
adb shell am start -n com.example.smart_photo_diary/.MainActivity
```

### Linting and Code Quality
```bash
# Analyze code (configured to suppress info-level lints for cleaner output)
fvm flutter analyze

# Fix formatting (REQUIRED after any code changes)
fvm dart format .

# Check formatting without changing files (CI/CD safe)
fvm dart format --set-exit-if-changed .

# Check for outdated dependencies
fvm flutter pub outdated
```

### Code Formatting Requirements
**IMPORTANT**: Always run `fvm dart format .` after making any code changes to ensure consistent formatting:

```bash
# Standard workflow after code changes:
1. Make your code changes
2. fvm dart format .        # Format code automatically
3. fvm flutter analyze     # Check for issues
4. fvm flutter test        # Run tests
5. git add . && git commit  # Commit changes
```

The CI/CD pipeline uses `--set-exit-if-changed` flag and will fail if code is not properly formatted. This ensures consistent code style across the entire codebase.

## Architecture Overview

### Service Layer Pattern
The app follows a service-oriented architecture with singleton services using lazy initialization via `ServiceLocator`:

- **`DiaryService`**: Central data management with Hive database operations, depends on `AiService` for tag generation
- **`PhotoService`**: Photo access and permissions via `photo_manager` plugin, implements `PhotoServiceInterface`
- **`AiService`**: AI diary generation with Google Gemini API and comprehensive offline fallbacks, implements `AiServiceInterface`
- **`ImageClassifierService`**: On-device ML inference capabilities (placeholder for future ML integration)
- **`SettingsService`**: App configuration stored in SharedPreferences with Result<T> pattern for write operations
- **`StorageService`**: File system operations, data export functionality with user-selectable destinations, and database optimization
- **`LoggingService`**: Structured logging with levels and performance monitoring
- **`SubscriptionService`**: In-App Purchase integration for Premium subscriptions, implements `ISubscriptionService`
- **`PromptService`**: Writing prompt management with JSON asset loading, 3-tier caching system, freemium filtering, and comprehensive search capabilities, implements `IPromptService`

### Error Handling Architecture

The app implements a **Result<T> pattern** for functional error handling, providing type-safe alternatives to exception-based error handling:

#### Result<T> Pattern (`lib/core/result/`)
- **`Result<T>`**: Sealed class with `Success<T>` and `Failure<T>` variants
- **Functional operations**: `map`, `fold`, `chain`, `onSuccess`, `onFailure`
- **Helper utilities**: `ResultHelper` for easy creation and combination
- **Extensions**: Enhanced support for `Future<Result<T>>` and `List<Result<T>>`

#### Standardized Exception Hierarchy (`lib/core/errors/`)
- **`AppException`**: Base exception with message, details, and original error context
- **Domain-specific exceptions**: `ServiceException`, `PhotoAccessException`, `AiProcessingException`, etc.
- **`ErrorHandler`**: Utilities for error conversion, logging, and safe execution
- **`LoggingService`**: Structured logging with context and performance monitoring

### Dependency Injection
- **`ServiceLocator`**: Central dependency injection container supporting singleton, factory, and async factory patterns
- **`service_registration.dart`**: Contains service registration logic and initialization order with LoggingService integration
- Services are registered at app startup and accessed via interfaces for better testability
- **Service Dependencies**: PromptService depends on LoggingService; AiService depends on SubscriptionService; DiaryService depends on AiService and PhotoService

### Controller Pattern
- **`PhotoSelectionController`**: Uses `ChangeNotifier` for reactive photo selection state management with enhanced robustness and boundary checking
- **`DiaryScreenController`**: Manages diary screen state and interactions
- Controllers handle complex UI interactions and provide computed properties for widgets

### Data Models
- **`DiaryEntry`**: Primary data model with Hive annotations for local storage
- **`DiaryFilter`**: Filtering and search criteria for diary queries
- **`WritingPrompt`**: Writing prompt model with categories, tags, and Premium/Basic classification
- **`SubscriptionPlan`**: Subscription plan definitions (Basic, Premium Monthly/Yearly)
- **`SubscriptionStatus`**: Current subscription state with usage tracking
- Uses `build_runner` for generating Hive adapters (`diary_entry.g.dart`, `writing_prompt.g.dart`)

### AI/ML Architecture
- **Cloud AI**: Google Gemini 2.5 Flash integration for advanced diary generation
- **AI Service Components**:
  - `GeminiApiClient`: Direct API integration with Google Gemini, enhanced with EnvironmentConfig
  - `DiaryGenerator`: Core diary generation logic
  - `TagGenerator`: Automatic tag generation from content
  - `OfflineFallbackService`: Offline mode diary generation
- **Environment Management**: EnvironmentConfig provides robust API key management with validation
- **Assets**: Writing prompts and configuration data in `assets/data/` directory

### Monetization Architecture
- **Freemium Model**: Basic (free, 10 AI generations/month) vs Premium (¥300/month, 100 generations + prompts)
- **In-App Purchase Integration**: Uses `in_app_purchase` plugin for subscription management
- **Usage Tracking**: AI generation counts with monthly reset functionality
- **Writing Prompts System**: 20 curated prompts (5 Basic + 15 Premium) across 8 categories
- **Plan Enforcement**: Feature access control based on subscription status

## Key Dependencies

### Core
- `hive` + `hive_flutter`: Local NoSQL database for diary storage
- `photo_manager`: Photo access and management with permission handling
- `permission_handler`: Platform-specific permissions for photo access
- `connectivity_plus`: Network status checking for AI service fallbacks
- `shared_preferences`: Simple key-value storage for app settings
- `file_picker`: User-selectable file export destinations
- `package_info_plus`: App version and build information
- `table_calendar`: Calendar widget for diary timeline views
- `http`: Network requests for AI API integration
- `flutter_dotenv`: Environment variable management
- `uuid`: Unique identifier generation for diary entries
- `intl`: Internationalization and date formatting
- `in_app_purchase: 3.1.10`: Subscription management (pinned version for StoreKit 2 compatibility)
- `google_fonts`: Typography and font management
- `image`: Image processing and manipulation utilities

### Development
- `build_runner` + `hive_generator`: Code generation for Hive adapters
- `mocktail`: Testing framework for service mocking
- `flutter_lints`: Code analysis with custom rules

### Localization
- `flutter_localizations`: Japanese locale support to ensure proper font rendering
- Japanese locale (`ja_JP`) configured to prevent Chinese font variants in Japanese text

## Important Files

### Configuration
- `pubspec.yaml`: Dependencies and asset configuration
- `analysis_options.yaml`: Linting rules with Japanese text support and performance optimizations
- `.env`: Environment variables (API keys) - bundled as asset for release builds
- `android/app/src/main/AndroidManifest.xml`: Includes INTERNET permissions for API calls

### Generated Code
- `lib/models/diary_entry.g.dart`: Auto-generated Hive adapter (do not edit manually)

### Assets
- `assets/data/writing_prompts.json`: Writing prompts data with metadata and categorization
- `assets/images/`: Application assets and icons

### UI Components
- `lib/ui/components/custom_dialog.dart`: Unified modal design system
  - CustomDialog: Unified dialog component
  - PresetDialogs: Standard dialogs for success, error, confirmation, usage limits
  - CustomDialogAction: Unified button styles (Primary/Secondary/Danger)
- `lib/screens/diary_preview_screen.dart`: Optimized diary preview screen
  - Responsive content input field
  - Natural layout adjustment functionality
- `lib/screens/diary_detail_screen.dart`: Enhanced photo dialog functionality
  - Optimized photo display modal

## Development Notes

### Security Guidelines (CRITICAL)
**Always prioritize security best practices over convenience:**

1. **Environment Variables**:
   - NEVER suggest including `.env` files in `assets/` or application bundles
   - Always use project root placement: `/project-root/.env`
   - Use `dotenv.load(fileName: ".env")` to load from root, not assets

2. **API Key Management**:
   - Local development: `.env` in project root (gitignored)
   - CI/CD: GitHub Secrets with dynamic `.env` creation
   - Production: Environment variables or secure platform storage
   - NEVER bundle API keys in APK/IPA files

3. **Security-First Decision Making**:
   - When in doubt, choose the more secure option
   - Verify industry best practices before suggesting solutions
   - Consider long-term security implications of architectural decisions

### Git Operations and Development Rules (CRITICAL)
**IMPORTANT**: Always follow these rules when working with Git and making code changes:

#### Git Operations
1. **Never commit without explicit user approval**:
   - Complete code modifications and testing first
   - Report changes and results to user
   - Wait for user's explicit instruction to commit
   - Confirm commit message with user before executing

2. **Commit Guidelines**:
   - Only commit when functionality is tested and confirmed working
   - Never commit untested code or "work in progress"
   - Use descriptive commit messages that explain the "why" not just "what"
   - Follow the existing commit message format

#### Security in Code
1. **API Keys and Secrets**:
   - NEVER hardcode API keys, passwords, or tokens in source code
   - Use only environment variables, config files, or build-time constants
   - If unsure about security implications, always ask user first

2. **Git History Security**:
   - Be aware that Git history is permanent and public when pushed
   - If secrets are accidentally committed, immediately inform user
   - Never attempt to "fix" security issues by adding new commits

### Code Generation
Always run `fvm dart run build_runner build` after modifying Hive model classes to regenerate adapters.

### Code Quality Standards
- Always run `fvm flutter analyze` before committing code - currently **no issues** (clean codebase)
- Custom lint rules enforce single quotes, const constructors, and performance optimizations
- Fix all analyzer warnings and errors immediately to maintain code quality
- Project uses Japanese comments for business logic documentation
- Test suite must maintain 100% success rate - all failing tests should be investigated and either fixed or removed

### UI Development Guidelines
- **Modal Design**: Always use CustomDialog for new modals and avoid AlertDialog
- **Text Alignment**: Use left-aligned text (textAlign: TextAlign.left) for user-facing content
- **Layout Constraints**: Avoid fixed heights and use natural layouts (Flexible, Expanded, etc.)
- **Visual Consistency**: Follow design system for icons, colors, and button styles
- **Responsive Design**: Create flexible layouts that adapt to different screen sizes and content lengths
- **User Experience**: Prioritize intuitive interactions and visual feedback

### Japanese Language Development
- **UI text**: All user-facing text is in Japanese
- **Comments**: Business logic and complex algorithms documented in Japanese
- **Variable names**: Use descriptive English names for code clarity
- **Debug messages**: May use Japanese for user-facing debug information

### UI Design Guidelines
- **No gradients**: All gradients have been removed for cleaner, simpler design
- **Consistent headers**: All screens use standard AppBar styling with unified colors and typography
- **Button consistency**: All buttons use solid colors (AppColors.primary/accent) instead of gradients
- **Material Design 3**: Follow MD3 principles with emphasis on solid colors and clean layouts
- **Typography standardization**: Section headings use AppTypography.headlineSmall (24sp) across all screens
- **Theme-aware colors**: Always use `Theme.of(context).colorScheme` for dynamic colors instead of fixed AppColors
- **Custom Dialog System**: Unified modal design with CustomDialog components
  - Complete migration from AlertDialog to CustomDialog
  - Standardized PresetDialogs (success, error, confirmation, usageLimit)
  - Consistent icons, color schemes, and button styles
- **Text Alignment Standards**: Left-aligned text following industry standards (textAlign: TextAlign.left)
  - All modal text uses left alignment (except loading messages)
  - Improved readability and natural reading flow
- **Responsive Layout Design**: Natural layout design avoiding fixed heights
  - Diary preview screen: Removed fixed height (400px) for natural sizing
  - Content input field: minLines: 12, maxLines: null for long text support
  - Optimized spacing for efficient screen space utilization
- **Photo Dialog Optimization**: Enhanced photo display dialogs
  - Proper close button positioning (top: -10, right: -10)
  - Visual improvements with clipBehavior: Clip.none
  - Optimized button size, background opacity, and border styling

### Error Handling Patterns

#### Result<T> Usage Guidelines
- **New features MUST use Result<T> pattern** for all operations that can fail (I/O, network, validation, etc.)
- **Existing code should be migrated gradually** - do not change service interfaces all at once
- **Start with write operations** (save, update, delete) as they typically have simpler return types
- **Prefer Result<void> for operations without return values** to minimize type complexity

#### Current Implementation Status
- **✅ Complete foundation**: Result<T> core implementation with comprehensive utilities and 100% test coverage
- **✅ Partial adoption**: SettingsService uses Result<T> for write operations (`setThemeMode`, `setAccentColor`, `setGenerationMode`)
- **🔄 Legacy support**: Existing service interfaces still use exception-based patterns for backward compatibility
- **📋 Migration targets**: DiaryService, PhotoService, AiService are candidates for gradual Result<T> adoption

#### Migration Strategy for Future Development
1. **Phase 1 - New Features** (Immediate):
   - All new service methods MUST return Result<T>
   - New services SHOULD implement Result<T> from the start
   - Use ResultHelper utilities for easy creation and error handling

2. **Phase 2 - Write Operations** (Next priority):
   - Migrate service write methods (save, update, delete) to Result<T>
   - Update corresponding UI error handling to use `fold()` pattern
   - Maintain backward compatibility with wrapper methods if needed

3. **Phase 3 - Read Operations** (Lower priority):
   - Migrate service read methods (get, list, search) to Result<T>
   - Update service interfaces gradually, one service at a time
   - Ensure comprehensive testing at each step

#### Best Practices
- **Use ResultHelper.tryExecuteAsync()** for wrapping existing exception-based code
- **Implement ErrorHandler.safeExecute()** for gradual migration of legacy code
- **Always test both success and failure paths** when implementing Result<T>
- **Use structured logging** via LoggingService for consistent error reporting and debugging
- **Avoid changing service interfaces and implementations simultaneously** - update incrementally

### Service Dependencies
Services follow a clear dependency hierarchy:
- `DiaryService` → `AiService` (for background tag generation)
- `AiService` → `SubscriptionService` (for usage limit checking)
- `PromptService` → `LoggingService` (for structured logging and performance monitoring)
- `AiService` → Connectivity checking for online/offline modes
- All services use dependency injection rather than tight coupling

### Writing Prompts System  
- **PromptService Implementation**: Complete Phase 2.2.1 implementation with singleton pattern, JSON asset loading, and 3-tier caching
- **Data Structure**: JSON file with 20 prompts across 8 categories (daily, travel, work, gratitude, reflection, creative, wellness, relationships)
- **Plan Distribution**: Basic users get 5 prompts (daily + gratitude), Premium users get all 20
- **Caching Architecture**: Plan-based cache, category-based cache, and ID-based cache for optimal performance
- **Search Capabilities**: Full-text search across prompt text, tags, and descriptions with plan enforcement
- **Random Selection**: Weighted random selection based on priority values with category filtering
- **Utility Classes**: `PromptCategoryUtils` for filtering, statistics, and plan-based access control
- **UI Implementation**: Complete Phase 2.3.1 WritingPromptsScreen with navigation integration
- **Quality Assurance**: 45 comprehensive tests (26 unit + 11 mock + 8 integration) with 100% success rate

### Testing Architecture
The project follows a comprehensive 3-tier testing strategy with **100% success rate** (683 passing tests):

#### Unit Tests (`test/unit/`)
- **Pure logic testing** with mocked dependencies using `mocktail`
- **Service mock tests**: `*_service_mock_test.dart` files test service interfaces without external dependencies
- **Core utilities**: Test dependency injection, Result<T> pattern, and utility functions
- **Data validation**: Writing prompts data integrity tests with 12 test cases
- **Subscription system**: Comprehensive tests for monetization features and usage tracking
- **Enhanced robustness**: All PhotoSelectionController methods include boundary checking and input validation

#### Widget Tests (`test/widget/`)
- **UI component testing** with mocked services via dependency injection
- Test widget rendering, user interactions, and state management
- Use `WidgetTestHelpers` for common test setup and utilities

#### Integration Tests (`test/integration/`)
- **End-to-end flow testing** with real service implementations
- Test complete user workflows (photo selection → diary generation → saving)
- Use `IntegrationTestHelpers` for complex app state setup

#### Test Utilities
- **`MockPlatformChannels`**: Unified platform channel mocking
- **`WidgetTestHelpers`**: Common widget test utilities and setup
- **`IntegrationTestHelpers`**: Integration test environment setup

#### Testing Best Practices
- **Mock-first approach**: All external dependencies (APIs, platform channels, file systems) are mocked in unit tests
- **Interface-based testing**: Services implement interfaces for easy mocking and dependency injection
- **Comprehensive coverage**: Each service has both unit tests (mocked) and integration tests (real implementations)
- **Test isolation**: Each test is independent with proper setup/teardown
- **Result<T> testing**: Comprehensive unit tests for functional error handling patterns

### Environment Variables and Configuration

#### Security Best Practices
**CRITICAL**: Always follow these security guidelines when handling environment variables and API keys:

1. **NEVER include `.env` files in assets or application bundles**
   - Assets are extractable from APK/IPA files, exposing API keys
   - This is a major security vulnerability that can lead to API key theft

2. **Proper `.env` file management**:
   - **Local Development**: Place `.env` file in project root directory
   - **Version Control**: Always add `.env` to `.gitignore` (never commit API keys)
   - **CI/CD**: Use GitHub Secrets or environment variables, create `.env` dynamically
   - **Production**: Use platform-specific secure storage or environment variables

#### Implementation Details
- **`.env` file location**: Project root directory (`/project-root/.env`)
- **EnvironmentConfig**: Robust environment variable management with caching and validation (`lib/config/environment_config.dart`)
- **Loading method**: `dotenv.load(fileName: ".env")` loads from project root, not assets
- **Android permissions**: Release builds require INTERNET permissions in AndroidManifest.xml for API calls

#### Environment Variable Loading Strategy
```dart
// CORRECT: Load from project root
await dotenv.load(fileName: ".env");

// INCORRECT: Load from assets (security risk)
await dotenv.load(); // This loads from assets by default
```

#### CI/CD Environment Handling
- **GitHub Actions**: Creates `.env` file dynamically from secrets before build
- **Local Development**: Uses `.env` file from project root
- **Production Builds**: API keys injected via CI/CD secrets, never bundled in assets

#### Development Plan Override (Debug Mode Only)
For testing purposes, you can force a specific subscription plan in debug mode:
- **Environment variable**: `FORCE_PLAN` in `.env` file
- **Build-time constant**: `--dart-define=FORCE_PLAN=premium`
- **Valid values**: `basic`, `premium`, `premium_monthly`, `premium_yearly`
- **Security**: Automatically disabled in release builds (`kDebugMode` check)
- **Usage examples**:
  ```bash
  # Via .env file
  FORCE_PLAN=premium
  
  # Via build command
  fvm flutter run --dart-define=FORCE_PLAN=premium
  fvm flutter build apk --debug --dart-define=FORCE_PLAN=premium
  ```

### Platform Considerations
The app supports multiple platforms but photo access requires platform-specific permissions handled by `permission_handler`.

### iOS Photo Permission Implementation
**CRITICAL**: iOS photo permissions require specific implementation patterns for reliable operation:

#### Required Info.plist Keys
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>写真ライブラリにアクセスして、日記作成に使用する写真を取得します</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>写真ライブラリに新しい写真を保存します</string>
<key>PHPhotoLibraryPreventAutomaticLimitedAccessAlert</key>
<true/>
```

#### Permission Implementation Strategy
- **Dual Plugin Approach**: Use both `PhotoManager` and `permission_handler` for robust permission handling
- **PhotoManager**: Primary for photo access and Limited Photo Access detection
- **permission_handler**: Secondary for permission state checking and settings navigation

#### Limited Photo Access Handling (iOS 14+)
**IMPORTANT**: Limited Photo Access is a common user choice and must be properly supported:

1. **Detection**: Use `PermissionState.limited` from PhotoManager
2. **User Guidance**: Show explanatory dialog when photo count is low
3. **Photo Selection**: Use `PhotoManager.presentLimited()` to show selection UI
4. **Graceful Degradation**: App functions with selected photos only

#### Permission State Management
```dart
// Correct approach for permission checking
final pmState = await PhotoManager.requestPermissionExtend();
if (pmState.isAuth || pmState == PermissionState.limited) {
  // Both full and limited access are usable
  return true;
}
```

#### User Experience Best Practices
- **Never surprise users**: Always show explanatory dialog before opening Settings
- **Clear messaging**: Explain why permissions are needed and what Limited Access means
- **Settings navigation**: Use `openAppSettings()` with proper user consent
- **App lifecycle handling**: Check permissions when returning from Settings via `AppLifecycleState.resumed`

#### Bundle ID Considerations
- **Fresh permissions**: Changing Bundle ID resets all permission states
- **Clean installs**: Always test with fresh app installs to verify permission flows
- **Developer profiles**: Ensure proper signing and device trust for permission dialogs to appear

### Japanese Font Support
- **Locale configuration**: MaterialApp configured with Japanese locale (`ja_JP`) to ensure proper font selection
- **Font rendering**: Prevents Chinese font variants from displaying for Japanese text
- **Debug tools**: Font debug screen available in settings for testing font rendering (`/debug/font_debug_screen.dart`)

### Dark Theme Support
- **Complete theme integration**: All UI components properly support both light and dark themes
- **Text visibility**: All text colors use `Theme.of(context).colorScheme` instead of fixed AppColors for proper contrast
- **Modal consistency**: Custom dialogs automatically adapt colors based on current theme
- **Settings screen**: Proper contrast for secondary text and icons in dark mode

### Privacy and Local Storage
All user data stays on device. Hive database files are stored in app documents directory. No cloud synchronization by design.

## CI/CD and Deployment Architecture

### GitHub Actions Workflows
The project includes 4 automated workflows with distinct purposes:

#### 1. **ci.yml** - Continuous Integration
- **Trigger**: Push/PR to main/develop branches
- **Purpose**: Code quality validation and testing only
- **API Key**: Uses `dummy_key_for_ci` (unified dummy key for all CI builds)
- **Actions**: Run tests, analyze code, build debug/release APKs and iOS builds for verification
- **Artifacts**: No artifacts uploaded (builds are for verification only, contain dummy API keys)

#### 2. **release.yml** - GitHub Releases
- **Trigger**: Version tags (`v*`) or manual execution
- **Purpose**: Create GitHub Releases with downloadable builds
- **API Key**: Requires `${{ secrets.GEMINI_API_KEY }}` (fails if not set)
- **Output**: APK, AAB, iOS archive with SHA256 checksums
- **Target**: Developers, testers, direct distribution

#### 3. **android-deploy.yml** - Google Play Store
- **Trigger**: Manual execution only (`workflow_dispatch`)
- **Purpose**: Controlled deployment to Google Play Store
- **Requirements**: Google Play Console setup, service account, app registration
- **API Key**: Requires `${{ secrets.GEMINI_API_KEY }}` (fails if not set)
- **Output**: Signed AAB uploaded to Play Store (internal/alpha/beta/production tracks)

#### 4. **ios-deploy.yml** - App Store
- **Trigger**: Manual execution only (`workflow_dispatch`)
- **Purpose**: Controlled deployment to TestFlight/App Store
- **Requirements**: App Store Connect setup, certificates, app registration
- **API Key**: Requires `${{ secrets.GEMINI_API_KEY }}` (fails if not set)
- **Output**: Signed IPA uploaded to TestFlight or App Store

### Required GitHub Secrets
For production deployments, configure these repository secrets:
```bash
# Core API (required for all production builds)
GEMINI_API_KEY=your_google_gemini_api_key

# Android deployment (android-deploy.yml)
GOOGLE_PLAY_SERVICE_ACCOUNT=service_account_json
ANDROID_SIGNING_KEY=base64_encoded_keystore
ANDROID_KEYSTORE_PASSWORD=keystore_password
ANDROID_KEY_ALIAS=key_alias
ANDROID_KEY_PASSWORD=key_password

# iOS deployment (ios-deploy.yml)
APPSTORE_ISSUER_ID=app_store_connect_issuer_id
APPSTORE_KEY_ID=app_store_connect_key_id
APPSTORE_PRIVATE_KEY=app_store_connect_private_key
IOS_DISTRIBUTION_CERTIFICATE=p12_certificate_base64
IOS_CERTIFICATE_PASSWORD=certificate_password
IOS_TEAM_ID=apple_team_id
```

### Deployment Strategy (Industry Standard)
- **Development**: Use ci.yml for code validation (automatic)
- **Beta Testing**: Use release.yml for GitHub Releases distribution (tag-triggered)
- **Store Distribution**: Use android-deploy.yml and ios-deploy.yml (manual execution only)

### Staged Release Flow
```bash
# 1. Development Quality Checks (Automatic)
git push origin main                    # → ci.yml execution

# 2. Beta Distribution (Semi-automatic)
git tag v1.0.0-beta
git push origin v1.0.0-beta           # → release.yml execution

# 3. Production Distribution (Manual)
# Execute manually via GitHub Actions UI:
# - android-deploy.yml → Google Play Store
# - ios-deploy.yml → App Store/TestFlight
```

### Important Notes
- **CI vs Production**: CI uses dummy API keys and produces no artifacts; production workflows require real secrets
- **Secret Validation**: All production workflows (release, android-deploy, ios-deploy) fail immediately if GEMINI_API_KEY is not set
- **Store Registration**: Store deployment workflows will fail until apps are registered in respective stores
- **API Key Security**: CI workflows intentionally use dummy keys to avoid exposing real API keys during testing
- **Manual Control**: Production deployments require manual execution for safety and quality control
- **Industry Standard**: Follows best practices used by major tech companies for risk mitigation

## Development Status

### Recent Achievements
- **Perfect test coverage**: 683 tests with 100% success rate across unit, widget, and integration tests
- **PromptService complete implementation**: Phase 2.2.1 fully implemented with JSON asset loading, 3-tier caching, and comprehensive search
- **Monetization implementation**: Complete freemium model with In-App Purchase integration
- **Writing prompts system**: 20 curated prompts with 8-category classification and plan-based access
- **Result<T> pattern implementation**: Comprehensive functional error handling system with complete test coverage
- **Enhanced error handling**: Standardized exception hierarchy with structured logging
- **Service architecture refactoring**: Implemented dependency injection with ServiceLocator pattern
- **Controller robustness**: Enhanced PhotoSelectionController with boundary checks and input validation
- **Interface-based design**: All major services now implement interfaces for better testability
- **Code quality improvements**: Comprehensive error handling utilities and logging service
- **UI Design Unification**: Removed all gradients across the app for cleaner, simpler design
- **Header Standardization**: Unified all screen headers to use consistent AppBar styling
- **Comprehensive dark mode support**: Fixed text visibility issues and unified card design across all screens
- **Database optimization**: Implemented Hive database compaction and storage cleanup functionality
- **Enhanced export feature**: Added file picker integration for user-selectable export destinations
- **Build configuration**: Resolved Java version warnings and optimized Android build settings
- **Japanese font support**: Fixed font rendering issues with proper Japanese locale configuration
- **Debug tools**: Added font debug screen for troubleshooting font-related issues
- **Dark theme improvements**: Enhanced text visibility and modal contrast in dark mode
- **Modal system enhancements**: Improved custom dialog design with proper theme integration
- **UX workflow optimization**: Implemented modal-based prompt selection for streamlined diary creation
- **Prompt-less generation**: Enhanced support for diary generation without writing prompts
- **Loading state improvements**: Optimized loading indicators and message positioning for better user experience
- **✅ Phase 2.4.2 Analytics System Implementation**: Complete implementation of comprehensive analytics system for prompt usage analysis, user behavior tracking, and continuous improvement
- **CI/CD Pipeline Implementation**: Complete GitHub Actions workflows for automated testing, building, and deployment to GitHub Releases, Google Play Store, and App Store
- **Package Compatibility Resolution**: Fixed in_app_purchase compatibility issues with StoreKit 2 APIs by pinning to version 3.1.10
- **Unified Modal Design**: Consistent UI experience through CustomDialog components
- **Photo Permission UX Enhancement**: Clear messaging and visually unified permission dialogs
- **Diary Editing UX Optimization**: Improved editing experience with natural layouts and long text support
- **Photo Display Enhancement**: Improved photo dialogs with intuitive interactions
- **Text Standardization**: Enhanced readability with industry-standard left-aligned text
- **Responsive Design Implementation**: Natural and efficient layout design avoiding fixed heights

### Current Architecture State
- **Production-ready services**: All core services (Diary, Photo, AI, ImageClassifier, Settings, Logging, Subscription, Prompt) are fully implemented and tested
- **Functional error handling**: Result<T> pattern implemented with complete utilities and test coverage
- **Robust error handling**: Comprehensive offline fallbacks, error recovery mechanisms, and structured logging
- **Performance optimized**: Lazy initialization, efficient caching, optimized database operations, and performance monitoring
- **Platform support**: Multi-platform support with proper permission handling
- **High code quality**: Clean, well-documented codebase with strict adherence to Flutter best practices and functional programming patterns
- **Monetization ready**: Complete subscription system with usage tracking, plan enforcement, and premium feature access

### Current Implementation State of Result<T>
- **✅ Core implementation**: Complete Result<T> pattern with comprehensive API and 100% test coverage
- **✅ Foundation ready**: All utilities (ResultHelper, ErrorHandler, LoggingService) implemented and tested
- **✅ Partial adoption**: SettingsService demonstrates successful Result<T> usage for write operations
- **✅ Migration experience**: Learned best practices for gradual introduction without breaking existing code
- **🔄 Legacy compatibility**: Existing service interfaces maintained for backward compatibility during transition
- **📋 Future development**: All new features should adopt Result<T> pattern from day one

### Result<T> Migration Lessons Learned
- **Avoid wholesale interface changes**: Changing all service methods at once caused 221 analyze errors
- **Incremental migration works**: SettingsService partial migration was successful and maintainable  
- **Type complexity matters**: Result<void> is easier to adopt than Result<ComplexType>
- **Testing is crucial**: Comprehensive test coverage (41 tests) ensured Result<T> reliability
- **Documentation prevents confusion**: Clear migration strategy helps future development decisions

## Analytics System Architecture

### Usage Analytics Implementation (Phase 2.4.2)
The application includes a comprehensive 4-layer analytics system for prompt usage analysis and continuous improvement:

#### Layer 1: Basic Usage Frequency Analysis
- **PromptUsageAnalytics**: Statistical analysis of prompt usage patterns
- **Features**: Usage frequency distribution, prompt popularity ranking, diversity index calculation
- **Output**: Total usage metrics, most/least popular prompts, usage health score

#### Layer 2: Category Popularity Analysis  
- **CategoryPopularityReporter**: Detailed reporting and visualization for category usage trends
- **Features**: Category ranking, trend analysis with previous period comparison, formatted reports
- **Output**: Category popularity distribution, growth/decline trends, detailed usage reports

#### Layer 3: User Behavior Analysis
- **UserBehaviorAnalyzer**: Advanced behavioral pattern recognition and analysis
- **Features**: Time pattern analysis, usage trend detection, engagement scoring, consistency measurement
- **Output**: Detailed behavior insights with time patterns, usage regularity, engagement levels

#### Layer 4: Improvement Suggestion System
- **ImprovementSuggestionTracker**: Effect measurement and feedback collection for continuous improvement
- **Features**: Suggestion effectiveness analysis, user feedback tracking, continuous learning data generation
- **Output**: Personalized recommendations, effect measurement, success/failure factor analysis

#### Integration with PromptService
All analytics functionality is fully integrated into the main PromptService:
```dart
// Usage frequency analysis
final frequencyAnalysis = await promptService.analyzePromptFrequency(days: 30);

// Category popularity with trends
final categoryAnalysis = await promptService.analyzeCategoryPopularity(
  days: 30, isPremium: true, comparePreviousPeriod: true);

// Detailed user behavior analysis  
final behaviorAnalysis = await promptService.analyzeDetailedUserBehavior(
  days: 30, isPremium: true);

// Improvement suggestions based on usage patterns
final suggestions = await promptService.generateImprovementSuggestions(
  days: 30, isPremium: true);
```

#### Data Persistence and Tracking
- **Hive Database Integration**: All usage history and suggestion implementations stored locally
- **Privacy-First Design**: No cloud synchronization, all analytics data stays on device
- **Comprehensive Test Coverage**: 58+ dedicated analytics tests ensuring reliability
- **Performance Optimized**: Efficient caching and lazy calculation for real-time analysis

#### Statistical Algorithms and Data Science
The analytics system implements several advanced statistical and machine learning algorithms:
- **Shannon Entropy**: For measuring time consistency and behavioral pattern uniformity
- **Gini Coefficient**: For analyzing inequality in usage distribution across categories
- **Time Series Analysis**: Trend detection with weekly aggregation and change rate calculation
- **Behavioral Pattern Recognition**: Engagement scoring with multi-factor analysis
- **Recommendation Engine**: Personalized suggestions based on usage patterns and satisfaction metrics

## UI Error Display System

### Unified Error Display Architecture
The application uses a unified error display system that provides consistent error presentation across all screens and components:

#### Core Components
- **ErrorDisplayService**: Centralized service for showing errors with automatic logging and severity-based display methods
- **ErrorDisplayWidgets**: Reusable UI components (SnackBar, Dialog, Inline, FullScreen) with consistent styling
- **ErrorSeverity**: Four-level severity system (info, warning, error, critical) with appropriate visual feedback
- **ErrorDisplayConfig**: Predefined configurations for common error scenarios

#### Error Display Methods
1. **SnackBar**: Lightweight notifications for info/warning messages
2. **Dialog**: Modal alerts for errors requiring user acknowledgment  
3. **Inline**: Embedded error displays within content areas
4. **FullScreen**: Critical errors that block entire app functionality

#### Error Severity Levels
- **Info**: Informational messages (blue, SnackBar, 3s duration)
- **Warning**: Cautionary messages (orange, SnackBar, 4s duration)
- **Error**: Standard errors (red, Dialog, user dismissible)
- **Critical**: Severe errors (dark red, Dialog, retry required, non-dismissible)

#### Integration with Result<T>
The error display system is fully integrated with the Result<T> pattern:

```dart
// Direct error display from Result
result.showErrorOnUI(context);

// With success message
await operation()
  .showResultOnUI(context, 
    onSuccess: (value) => 'Successfully saved!');

// Conditional error display
result.showErrorOnUIOfType<NetworkException>(context);
```

#### Usage Patterns

**Service Layer Integration**:
```dart
class MyController extends BaseErrorController {
  Future<void> performAction(BuildContext context) async {
    await executeWithErrorDisplay(
      context,
      () => myService.doSomething(),
      errorConfig: ErrorDisplayConfig.criticalWithRetry,
      onRetry: () => performAction(context),
    );
  }
}
```

**UI Extensions**:
```dart
// Simple error display
context.showError(ServiceException('Failed to save'));

// Success messages
context.showSuccess('Data saved successfully!');

// Type-specific errors
context.showNetworkError('Connection failed', onRetry: retry);
```

**Widget Builders**:
```dart
FutureResultUIBuilder<List<Item>>(
  future: loadItems(),
  onSuccess: (items) => ItemList(items: items),
  showDialogErrors: true, // Show errors in dialogs
  onRetry: loadItems,
)
```

#### Best Practices
- **Use predefined ErrorDisplayConfig** for consistent behavior
- **Leverage BaseErrorController** for automatic error state management
- **Prefer contextual extensions** (context.showError) for brevity
- **Always provide retry mechanisms** for recoverable errors
- **Use severity levels appropriately** to guide user response

## Code Quality and Analysis

### Analyzer Configuration
The project uses a customized `analysis_options.yaml` configuration that:
- **Suppresses info-level lints** for cleaner output in production
- **Maintains strict error and warning detection** for actual code problems
- **Excludes generated files** (*.g.dart, *.freezed.dart) from analysis
- **Enforces consistent coding standards** through targeted linting rules

### Analyzer Philosophy
- **Zero tolerance for errors and warnings**: All error and warning-level issues must be resolved
- **Info-level suppression for mature codebase**: Style hints are suppressed to focus on functional issues
- **Clean CI/CD integration**: `flutter analyze` returns clear success/failure status

### Suppressed Info Rules (Rationale)
- `prefer_const_constructors`: Performance optimization hint, not critical for functionality
- `avoid_redundant_argument_values`: Code style preference, doesn't affect behavior
- `unintended_html_in_doc_comment`: Documentation formatting issue, not functional problem

This configuration is appropriate for a mature, production-ready codebase where the focus should be on preventing actual bugs rather than enforcing every style preference.

## Storage Management Features

### Data Export with File Picker
The app includes comprehensive data export functionality:
- **User-selectable destinations**: Uses `file_picker` package for cross-platform file saving
- **JSON format export**: Complete diary data including tags, metadata, and timestamps
- **Filtered exports**: Support for date range filtering during export
- **Structured data format**: Includes app metadata, version info, and export timestamps

### Database Optimization
Storage optimization features include:
- **Hive database compaction**: Reduces file fragmentation and reclaims deleted data space
- **Temporary file cleanup**: Automatic removal of temporary files and directories
- **Cache management**: Deletes cache files older than 7 days
- **Storage monitoring**: Real-time storage usage reporting with formatted size display

### Implementation Notes
- **StorageService.exportData()**: Returns file path or null, uses FilePicker.platform.saveFile()
- **StorageService.optimizeDatabase()**: Calls DiaryService.compactDatabase() and cleanup methods
- **StorageInfo class**: Provides formatted storage size calculations and breakdown by data type

## Monetization Strategy

### Current Implementation Status
The app implements a **two-tier freemium model** with the following structure:

#### Basic Plan (Free)
- 10 AI diary generations per month
- Access to 5 basic writing prompts (daily + gratitude categories)
- Core app functionality without premium features

#### Premium Plan (¥300/month, ¥2,800/year)
- 100 AI diary generations per month  
- Access to all 20 writing prompts across 8 categories
- Advanced filtering and analytics features
- 7-day free trial period

### Technical Implementation
- **Subscription Management**: Complete In-App Purchase integration via `SubscriptionService`
- **Usage Tracking**: Monthly AI generation counters with automatic reset
- **Feature Access Control**: Plan-based access enforcement throughout the app
- **Data Management**: Writing prompts categorized and filtered by subscription status

### In-App Purchase Implementation Status
**CRITICAL**: The app has complete technical implementation but requires App Store Connect setup:

#### ✅ Fully Implemented (Code)
- `in_app_purchase` plugin integration with StoreKit 2 compatibility (v3.1.10)
- Complete `SubscriptionService` with purchase flow handling
- Product ID configuration: `smart_photo_diary_premium_monthly`, `smart_photo_diary_premium_yearly`
- Regional pricing support (JP: ¥300/¥2800, US: $2.99/$28.99, etc.)
- Usage limit enforcement and plan-based feature access
- Purchase restoration and error handling
- Subscription state persistence with Hive database

#### ❌ Pending (App Store Connect)
- **Product registration** in App Store Connect required
- **App Review approval** needed for subscription functionality
- **Bundle ID registration** must match `com.focuswave.smartPhotoDiary`
- **Pricing and availability** configuration in App Store Connect

#### Development Testing
Use environment variable for testing subscription features:
```bash
# In .env file (debug builds only)
FORCE_PLAN=premium
```

#### Production Deployment Checklist
1. Register products in App Store Connect with exact product IDs
2. Configure pricing tiers and regional availability  
3. Set up subscription groups and free trial periods
4. Submit app for review with subscription functionality
5. Test sandbox purchases before production release

**Note**: All subscription logic is functional locally. Only the actual purchase transaction requires App Store Connect integration.

### Development Phases Completed
- **Phase 1**: Core subscription infrastructure and In-App Purchase integration
- **Phase 2.1**: Writing prompts data structure and content creation (20 prompts)
- **Phase 2.2**: PromptService implementation with complete backend functionality
- **Phase 2.3.1**: WritingPromptsScreen UI implementation with navigation integration
- **Phase 2.3.2**: Photo selection integration with modal prompt selection workflow
- **Phase 2.4.1**: Complete UX improvement with streamlined diary creation flow
- **Phase 2.4.2**: Comprehensive usage analytics system with prompt usage analysis, user behavior tracking, and continuous improvement
- **Current Status**: Production-ready monetization implementation with complete prompt system and advanced analytics