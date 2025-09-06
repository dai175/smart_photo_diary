# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Smart Photo Diary is a Flutter mobile application that generates diary entries from photos using AI. The app implements a freemium monetization model with Basic (free) and Premium subscription tiers.

## Development Commands

### Essential Commands
```bash
# Setup and dependencies (using FVM)
fvm flutter pub get
fvm dart run build_runner build

# Development
fvm flutter run

# Testing (800+ tests, 100% success rate must be maintained)
fvm flutter test
fvm flutter test test/unit/        # Unit tests
fvm flutter test test/widget/      # Widget tests
fvm flutter test test/integration/ # Integration tests

# Code quality (REQUIRED before commits)
fvm flutter analyze                # Must show "No issues found!"
fvm dart format .                  # ALWAYS run after code changes
```

## Architecture Overview

### Service Layer Pattern
The app uses dependency injection via `ServiceLocator` with interface-based services:

- **`IDiaryService`**: Central data management with Hive database
- **`IAiService`**: AI diary generation with Google Gemini API
- **`IPhotoService`**: Photo access with permission handling
- **`ISubscriptionService`**: In-App Purchase integration
- **`LoggingService`**: Structured logging (no interface, singleton)

Services are registered at startup in `core/service_registration.dart` and accessed via:
```dart
final service = serviceLocator.get<IServiceName>();
```

### Error Handling with Result<T>
All services use the `Result<T>` pattern for type-safe error handling:
```dart
// Service methods return Result<T>
Future<Result<DiaryEntry>> saveDiary(DiaryEntry entry);

// Usage pattern
final result = await diaryService.saveDiary(entry);
result.fold(
  onSuccess: (diary) => // handle success,
  onFailure: (error) => // handle error,
);
```

### Data Models
- **`DiaryEntry`**: Primary model with Hive annotations for local storage
- **Plan Classes**: Type-safe subscription system (BasicPlan, PremiumMonthlyPlan, etc.)
- **`TimelinePhotoGroup`**: Photo grouping model for timeline display (Today, Yesterday, Monthly)
- Uses `build_runner` for generating Hive adapters

### Home Screen Architecture (Post Tab Unification)
The home screen has been unified from a tabbed interface to a single timeline view:

- **`TimelinePhotoWidget`**: Main timeline display with sticky headers and photo grids
- **`TimelineGroupingService`**: Handles photo grouping by date (Today/Yesterday/Monthly)
- **`PhotoSelectionController`**: Manages photo selection state and date restrictions
- **Smart FAB Integration**: Context-sensitive floating action button (Camera/Create Diary)
- **Performance Optimizations**: Index caching and dimming calculation caching for smooth scrolling

## Critical Development Guidelines

### Logging (MANDATORY)
**ALL logging must use LoggingService**. Never use print/debugPrint except in fallbacks:

```dart
// Service pattern
LoggingService get _logger => serviceLocator.get<LoggingService>();

// Usage
_logger.info('Message text', context: 'ClassName.methodName', data: 'Additional details');

// Fallback pattern only (for error handling)
try {
  final logger = serviceLocator.get<LoggingService>();
  logger.error('Error message', context: 'Context', error: e);
} catch (_) {
  debugPrint('Fallback: Error message');
}
```

### Service Interfaces
All service interfaces use `I` prefix: `IDiaryService`, `IAiService`, etc.

### Error Handling
- New features MUST use Result<T> for all operations that can fail
- Use proper exception types from `lib/core/errors/`

### Security (CRITICAL)
- NEVER commit API keys: Use `.env` file in project root (gitignored)
- NEVER include .env in assets: Always project root placement
- Environment loading: `dotenv.load(fileName: ".env")`

### Git Rules (CRITICAL)
- Never commit without explicit user approval
- Always run `fvm flutter analyze` and `fvm dart format .` before commits
- Wait for user instruction to commit changes

### UI Guidelines
- Use `CustomDialog` for modals, never `AlertDialog`
- Use left-aligned text: `textAlign: TextAlign.left`
- No gradients, follow Material Design 3
- All UI text in Japanese, variable names in English

### Testing
- Maintain 100% test success rate
- Use ServiceLocator setup in tests:
```dart
setUpAll(() async {
  serviceLocator.clear();
  final loggingService = await LoggingService.getInstance();
  serviceLocator.registerSingleton<LoggingService>(loggingService);
});
```

### Code Quality Standards
- Test coverage: All new features must maintain 100% test success rate
- Pre-commit checks: Always run format and analyze commands before commits
- Performance: Consider memory usage when handling large assets (photos, videos)

## Platform Specifics

**iPhone-only application** with specific permission handling:
- Uses `photo_manager` and `permission_handler`
- Handle `PermissionState.limited` for iOS 14+
- Premium users can access photos from past 365 days
- Required permissions: NSPhotoLibraryUsageDescription, NSCameraUsageDescription in Info.plist