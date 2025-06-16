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
# Run all tests (using FVM) - Currently 100% success rate
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

# Fix formatting
fvm dart format .

# Check for outdated dependencies
fvm flutter pub outdated
```

## Architecture Overview

### Service Layer Pattern
The app follows a service-oriented architecture with singleton services using lazy initialization via `ServiceLocator`:

- **`DiaryService`**: Central data management with Hive database operations, depends on `AiService` for tag generation
- **`PhotoService`**: Photo access and permissions via `photo_manager` plugin, implements `PhotoServiceInterface`
- **`AiService`**: AI diary generation with Google Gemini API and comprehensive offline fallbacks, implements `AiServiceInterface`
- **`ImageClassifierService`**: On-device ML inference using TensorFlow Lite MobileNet v2
- **`SettingsService`**: App configuration stored in SharedPreferences with Result<T> pattern for write operations
- **`StorageService`**: File system operations, data export functionality with user-selectable destinations, and database optimization
- **`LoggingService`**: Structured logging with levels and performance monitoring
- **`SubscriptionService`**: In-App Purchase integration for Premium subscriptions, implements `ISubscriptionService`

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
- **`service_registration.dart`**: Contains service registration logic and initialization order
- Services are registered at app startup and accessed via interfaces for better testability

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
- **On-device**: TensorFlow Lite MobileNet v2 model for image classification
- **Cloud AI**: Google Gemini 2.5 Flash integration for advanced diary generation
- **AI Service Components**:
  - `GeminiApiClient`: Direct API integration with Google Gemini, enhanced with EnvironmentConfig
  - `DiaryGenerator`: Core diary generation logic
  - `TagGenerator`: Automatic tag generation from content
  - `OfflineFallbackService`: Offline mode diary generation
- **Environment Management**: EnvironmentConfig provides robust API key management with validation
- **Assets**: ML models bundled in `assets/models/` directory

### Monetization Architecture
- **Freemium Model**: Basic (free, 10 AI generations/month) vs Premium (¥300/month, 100 generations + prompts)
- **In-App Purchase Integration**: Uses `in_app_purchase` plugin for subscription management
- **Usage Tracking**: AI generation counts with monthly reset functionality
- **Writing Prompts System**: 59 curated prompts (5 Basic + 54 Premium) across 8 categories
- **Plan Enforcement**: Feature access control based on subscription status

## Key Dependencies

### Core
- `hive` + `hive_flutter`: Local NoSQL database for diary storage
- `photo_manager`: Photo access and management with permission handling
- `tflite_flutter`: On-device ML inference for image classification
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
- `in_app_purchase`: Subscription and in-app purchase management

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
- `assets/models/mobilenet_v2_1.0_224_quant.tflite`: TensorFlow Lite model
- `assets/models/labels.txt`: Image classification labels
- `assets/data/writing_prompts.json`: Writing prompts data with metadata and categorization

## Development Notes

### Code Generation
Always run `fvm dart run build_runner build` after modifying Hive model classes to regenerate adapters.

### Code Quality Standards
- Always run `fvm flutter analyze` before committing code - currently **no issues** (clean codebase)
- Custom lint rules enforce single quotes, const constructors, and performance optimizations
- Fix all analyzer warnings and errors immediately to maintain code quality
- Project uses Japanese comments for business logic documentation
- Test suite must maintain 100% success rate - all failing tests should be investigated and either fixed or removed

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
- **Modal design**: Custom dialogs follow consistent design patterns with proper theme integration

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
- `AiService` → Connectivity checking for online/offline modes
- All services use dependency injection rather than tight coupling

### Writing Prompts System
- **Data Structure**: JSON file with 59 prompts across 8 categories (daily, travel, work, gratitude, reflection, creative, wellness, relationships)
- **Plan Distribution**: Basic users get 5 prompts (daily + gratitude), Premium users get all 59
- **Utility Classes**: `PromptCategoryUtils` for filtering, statistics, and plan-based access control
- **Quality Assurance**: Comprehensive test suite validates data integrity, prompt counts, and categorization

### Testing Architecture
The project follows a comprehensive 3-tier testing strategy with **100% success rate** (144+ passing tests):

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
- **`.env` file**: Create in root directory for Google Gemini API keys and other configuration
- **EnvironmentConfig**: Robust environment variable management with caching and validation (`lib/config/environment_config.dart`)
- **Android permissions**: Release builds require INTERNET permissions in AndroidManifest.xml for API calls
- **Asset bundling**: `.env` file is included as an asset in `pubspec.yaml` for release builds

### Platform Considerations
The app supports multiple platforms but photo access requires platform-specific permissions handled by `permission_handler`.

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

## Development Status

### Recent Achievements
- **Perfect test coverage**: 144+ tests with 100% success rate across unit, widget, and integration tests
- **Monetization implementation**: Complete freemium model with In-App Purchase integration
- **Writing prompts system**: 59 curated prompts with 8-category classification and plan-based access
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

### Current Architecture State
- **Production-ready services**: All core services (Diary, Photo, AI, ImageClassifier, Settings, Logging, Subscription) are fully implemented and tested
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
- Access to all 59 writing prompts across 8 categories
- Advanced filtering and analytics features
- 7-day free trial period

### Technical Implementation
- **Subscription Management**: Complete In-App Purchase integration via `SubscriptionService`
- **Usage Tracking**: Monthly AI generation counters with automatic reset
- **Feature Access Control**: Plan-based access enforcement throughout the app
- **Data Management**: Writing prompts categorized and filtered by subscription status

### Development Phases Completed
- **Phase 1**: Core subscription infrastructure and In-App Purchase integration
- **Phase 2.1**: Writing prompts data structure and content creation (59 prompts)
- **Current Status**: Ready for Phase 2.2 (PromptService implementation)