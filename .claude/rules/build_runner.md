After modifying any file with `@HiveType` or `@HiveField` annotations, always run:

```
fvm dart run build_runner build
```

`lib/hive_registrar.g.dart` is auto-generated — never edit it manually.
