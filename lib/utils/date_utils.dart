/// DateTime の日付フォーマット拡張
extension DateFormatExtension on DateTime {
  /// YYYY-MM 形式の文字列を返す（例: "2026-03"）
  String toYearMonth() {
    return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
  }
}
