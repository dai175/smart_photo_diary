# Repository Guidelines

## Project Structure & Module Organization
- `lib/`: app code. Notable modules: `core/result` (Result<T>), `services/` (AI, analytics, IAP, social share), `models/`, `features/`, `ui/` (components, design_system), `widgets/`.
- `assets/`: `images/`, `data/`. Configure in `pubspec.yaml`.
- `test/`: `unit/`, `widget/`, `integration/` plus `mocks/` and `test_helpers/`.
- `scripts/`: build/release helpers (uses FVM), e.g. `dev_run.sh`.
- Platform folders: `android/`, `ios/`, `macos/`, `linux/`, `web/`, `windows/`. Docs in `docs/`.

## Build, Test, and Development Commands
- Setup: `fvm flutter pub get`
- Codegen (Hive, etc.): `fvm dart run build_runner build --delete-conflicting-outputs`
- Analyze: `fvm flutter analyze`
- Format: `fvm dart format .`
- Test (all / by suite): `fvm flutter test` | `fvm flutter test test/unit/`
- Run locally: `fvm flutter run -d <deviceId>` (see `fvm flutter devices`)
- Build (examples): `fvm flutter build apk --release`, `fvm flutter build ipa`

## Coding Style & Naming Conventions
- Language: Dart 3, Flutter 3.32 (managed via FVM; fallback to `flutter` if not using FVM).
- Indentation: 2 spaces. Strings: single quotes (`prefer_single_quotes`).
- Lints: configured in `analysis_options.yaml`; keep `flutter analyze` clean. Avoid `print`; always declare return types.
- Architecture: favor `Result<T>` for errors, service interfaces for DI, UI via reusable components in `ui/`.
- Naming: English identifiers; user‑facing copy may be Japanese. File names `snake_case.dart`.

## Testing Guidelines
- Frameworks: `flutter_test`, `mocktail`.
- Location & names: mirror source; files end with `_test.dart`.
- Run targeted suites: `fvm flutter test test/integration/` (or `unit/`, `widget/`).
- Coverage: `fvm flutter test --coverage` (CI reads from `coverage/`).
- Every non‑trivial change should include tests; prefer constructor injection for mocks.

## Commit & Pull Request Guidelines
- Commits: Conventional Commits (e.g., `feat(ui): add prompt picker`, `fix: overflow on onboarding`).
- PRs must: describe the change and rationale, link related issues, include screenshots for UI updates, and list test coverage/notes.
- Pre‑PR checklist: `flutter analyze`, `dart format .`, `flutter test` all pass; run codegen where applicable.

## Security & Configuration Tips
- Secrets: never commit `.env`. Provide `GEMINI_API_KEY` in local `.env` and use `--dart-define=GEMINI_API_KEY=...` for builds.
- iOS/Android signing and API keys should live in CI secrets (see README and `.github` workflows).

