import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/import_result.dart';

void main() {
  group('StorageService Import Tests', () {
    group('ImportResult Model Tests', () {
      test('ImportResult should calculate properties correctly', () {
        final result = ImportResult(
          totalEntries: 10,
          successfulImports: 7,
          skippedEntries: 2,
          failedImports: 1,
          errors: ['エラー1'],
          warnings: ['警告1'],
        );

        expect(result.hasErrors, true);
        expect(result.hasWarnings, true);
        expect(result.isCompletelySuccessful, false);
        expect(result.summaryMessage, '成功: 7件、スキップ: 2件、失敗: 1件');
      });

      test('ImportResult should be completely successful when no errors', () {
        final result = ImportResult(
          totalEntries: 5,
          successfulImports: 5,
          skippedEntries: 0,
          failedImports: 0,
          errors: [],
          warnings: [],
        );

        expect(result.hasErrors, false);
        expect(result.hasWarnings, false);
        expect(result.isCompletelySuccessful, true);
        expect(result.summaryMessage, '5件の日記を正常に復元しました');
      });
    });

    group('Error Handling Tests', () {
      test('should handle empty errors and warnings lists', () {
        final result = ImportResult(
          totalEntries: 0,
          successfulImports: 0,
          skippedEntries: 0,
          failedImports: 0,
          errors: [],
          warnings: [],
        );

        expect(result.hasErrors, false);
        expect(result.hasWarnings, false);
        expect(result.summaryMessage, '0件の日記を正常に復元しました');
      });

      test('should handle multiple errors and warnings', () {
        final result = ImportResult(
          totalEntries: 10,
          successfulImports: 5,
          skippedEntries: 3,
          failedImports: 2,
          errors: ['エラー1', 'エラー2'],
          warnings: ['警告1', '警告2', '警告3'],
        );

        expect(result.hasErrors, true);
        expect(result.hasWarnings, true);
        expect(result.errors.length, 2);
        expect(result.warnings.length, 3);
        expect(result.summaryMessage, '成功: 5件、スキップ: 3件、失敗: 2件');
      });
    });
  });
}
