All new service methods must return `Result<T>` (never throw or return nullable for expected errors).

```dart
// Good
Future<Result<Diary>> createDiary(...) async {
  try {
    return Success(diary);
  } on AppException catch (e) {
    return Failure(e);
  }
}

// Bad — do not throw or return null
Future<Diary?> createDiary(...) async { ... }
```

- Use `AppException` subtypes from `lib/core/errors/` — never catch-and-swallow
- Callers handle via `.when(success: ..., failure: ...)` or UI extensions in `lib/core/result/`
