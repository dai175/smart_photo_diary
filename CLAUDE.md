# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Smart Photo Diary is a Flutter mobile application that generates diary entries from photos using AI. The app operates completely offline with local storage and privacy-first design.

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
# Run all tests (using FVM)
fvm flutter test

# Run tests with coverage
fvm flutter test --coverage

# Run specific test file
fvm flutter test test/widget_test.dart
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
```

### Linting
```bash
# Analyze code
fvm flutter analyze

# Fix formatting
fvm dart format .
```

## Architecture Overview

### Service Layer Pattern
The app follows a service-oriented architecture with singleton services using lazy initialization:

- **`DiaryService`**: Central data management with Hive database operations, depends on `AiService` for tag generation
- **`PhotoService`**: Photo access and permissions via `photo_manager` plugin
- **`AiService`**: AI diary generation with Google Gemini API and comprehensive offline fallbacks
- **`ImageClassifierService`**: On-device ML inference using TensorFlow Lite MobileNet v2
- **`SettingsService`**: App configuration stored in SharedPreferences
- **`StorageService`**: File system operations and data export functionality

### Controller Pattern
- **`PhotoSelectionController`**: Uses `ChangeNotifier` for reactive photo selection state management
- Controllers handle complex UI interactions and provide computed properties for widgets

### Data Models
- **`DiaryEntry`**: Primary data model with Hive annotations for local storage
- Uses `build_runner` for generating Hive adapters (`diary_entry.g.dart`)

### AI/ML Architecture
- **On-device**: TensorFlow Lite MobileNet v2 model for image classification
- **Cloud AI**: Google Gemini 2.5 Flash integration for advanced diary generation
- **Assets**: ML models bundled in `assets/models/` directory

## Key Dependencies

### Core
- `hive` + `hive_flutter`: Local NoSQL database for diary storage
- `photo_manager`: Photo access and management with permission handling
- `tflite_flutter`: On-device ML inference for image classification
- `permission_handler`: Platform-specific permissions for photo access
- `connectivity_plus`: Network status checking for AI service fallbacks

### Development
- `build_runner` + `hive_generator`: Code generation for Hive adapters
- `mocktail`: Testing framework for service mocking
- `flutter_lints`: Code analysis with custom rules

## Important Files

### Configuration
- `pubspec.yaml`: Dependencies and asset configuration
- `analysis_options.yaml`: Linting rules
- `.env`: Environment variables (API keys)

### Generated Code
- `lib/models/diary_entry.g.dart`: Auto-generated Hive adapter (do not edit manually)

### Assets
- `assets/models/mobilenet_v2_1.0_224_quant.tflite`: TensorFlow Lite model
- `assets/models/labels.txt`: Image classification labels

## Development Notes

### Code Generation
Always run `fvm dart run build_runner build` after modifying Hive model classes to regenerate adapters.

### Code Quality
Always run `fvm flutter analyze` before committing code. Fix all analyzer warnings and errors immediately to maintain code quality.

### Service Dependencies
Services follow a clear dependency hierarchy:
- `DiaryService` → `AiService` (for background tag generation)
- `AiService` → Connectivity checking for online/offline modes
- All services use dependency injection rather than tight coupling

### Testing Strategy
The project uses `mocktail` for unit testing. Services are designed to be easily mockable with their singleton pattern.

### Environment Variables
Create a `.env` file in the root directory for Google Gemini API keys and other configuration.

### Platform Considerations
The app supports multiple platforms but photo access requires platform-specific permissions handled by `permission_handler`.

### Privacy and Local Storage
All user data stays on device. Hive database files are stored in app documents directory. No cloud synchronization by design.