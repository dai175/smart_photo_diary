class ImportResult {
  final int totalEntries;
  final int successfulImports;
  final int skippedEntries;
  final int failedImports;
  final List<String> errors;
  final List<String> warnings;

  ImportResult({
    required this.totalEntries,
    required this.successfulImports,
    required this.skippedEntries,
    required this.failedImports,
    required this.errors,
    required this.warnings,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get isCompletelySuccessful =>
      failedImports == 0 && errors.isEmpty && skippedEntries == 0;

  String get summaryMessage {
    if (isCompletelySuccessful) {
      return '$successfulImports件の日記を正常に復元しました';
    }

    final parts = <String>[];
    if (successfulImports > 0) {
      parts.add('成功: $successfulImports件');
    }
    if (skippedEntries > 0) {
      parts.add('スキップ: $skippedEntries件');
    }
    if (failedImports > 0) {
      parts.add('失敗: $failedImports件');
    }

    return parts.join('、');
  }
}
