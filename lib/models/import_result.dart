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
}
