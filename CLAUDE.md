# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Smart Photo Diary is a Flutter mobile application that generates diary entries from photos using AI. The app operates completely offline with local storage and privacy-first design.

## Development Commands

### Setup and Dependencies
```bash
# Get dependencies
flutter pub get

# Code generation for Hive models
dart run build_runner build

# Force rebuild generated code
dart run build_runner build --delete-conflicting-outputs
```

### Development
```bash
# Run app in development
flutter run

# Run with FVM (recommended)
fvm flutter run

# Hot reload and hot restart are available during development
```

### Testing
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

### Build Commands
```bash
# Debug build
flutter build apk --debug

# Release builds
flutter build apk --release
flutter build appbundle
flutter build ipa

# Build for specific platforms
flutter build macos
flutter build windows
flutter build linux
```

### Linting
```bash
# Analyze code
flutter analyze

# Fix formatting
dart format .
```

## Architecture Overview

### Service Layer Pattern
The app follows a service-oriented architecture with singleton services:

- **`DiaryService`**: Manages diary CRUD operations using Hive local database
- **`PhotoService`**: Handles photo permissions and retrieval via photo_manager
- **`AiService`**: AI diary generation with Google Gemini API and local fallback
- **`ImageClassifierService`**: On-device image classification using TensorFlow Lite
- **`SettingsService`**: App configuration and theme management
- **`StorageService`**: Local file system operations

### Data Models
- **`DiaryEntry`**: Primary data model with Hive annotations for local storage
- Uses `build_runner` for generating Hive adapters (`diary_entry.g.dart`)

### AI/ML Architecture
- **On-device**: TensorFlow Lite MobileNet v2 model for image classification
- **Cloud AI**: Google Gemini 2.5 Flash integration for advanced diary generation
- **Assets**: ML models bundled in `assets/models/` directory

## Key Dependencies

### Core
- `hive` + `hive_flutter`: Local NoSQL database
- `photo_manager`: Photo access and management
- `tflite_flutter`: On-device ML inference

### Development
- `build_runner` + `hive_generator`: Code generation
- `mocktail`: Testing framework
- `flutter_lints`: Code analysis

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
Always run `dart run build_runner build` after modifying Hive model classes to regenerate adapters.

### Testing Strategy
The project uses `mocktail` for unit testing. Services are designed to be easily mockable with their singleton pattern.

### Environment Variables
Create a `.env` file in the root directory for Google Gemini API keys and other configuration.

### Platform Considerations
The app supports multiple platforms but photo access requires platform-specific permissions handled by `permission_handler`.

### Privacy and Local Storage
All user data stays on device. Hive database files are stored in app documents directory. No cloud synchronization by design.