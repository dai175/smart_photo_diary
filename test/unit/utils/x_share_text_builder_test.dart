import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/utils/x_share_text_builder.dart';

void main() {
  group('XShareTextBuilder', () {
    test('builds text with title, body, and app name', () {
      final text = XShareTextBuilder.build(
        title: 'タイトル',
        body: '本文です。複数行もOK。',
        appName: 'Smart Photo Diary',
      );

      expect(text, contains('タイトル'));
      expect(text, contains('本文です。'));
      expect(text.trim().endsWith('Smart Photo Diary'), isTrue);
      // 構成: タイトル, 空行, 本文, 空行, アプリ名
      final lines = text.split('\n');
      expect(lines.length, greaterThanOrEqualTo(5));
      expect(lines.first, 'タイトル');
      expect(lines[1], '');
      expect(lines[lines.length - 1], 'Smart Photo Diary');
    });

    test('trims body first when exceeding 280 chars', () {
      final longBody = 'あ' * 400; // 400文字
      final text = XShareTextBuilder.build(
        title: '短いタイトル',
        body: longBody,
        appName: 'Smart Photo Diary',
      );
      expect(text.length <= 320, isTrue); // ざっくり上限+α（絵文字等考慮）
      expect(text.contains('短いタイトル'), isTrue);
      // 本文に...が付与されるはず
      final lines = text.split('\n');
      // 本文行は末尾が...のどれか
      expect(lines.any((l) => l.endsWith('...')), isTrue);
    });

    test('trims title if body is short but still over limit', () {
      final longTitle = 'タ' * 500;
      final text = XShareTextBuilder.build(
        title: longTitle,
        body: '短い本文',
        appName: 'Smart Photo Diary',
      );
      final lines = text.split('\n');
      expect(lines.first.endsWith('...'), isTrue);
      expect(text.contains('短い本文'), isTrue);
    });

    test('omits title line if title is empty', () {
      final text = XShareTextBuilder.build(
        title: '',
        body: '本文のみ',
        appName: 'Smart Photo Diary',
      );
      final lines = text.split('\n');
      // 構成: 本文, 空行, アプリ名
      expect(lines.first, '本文のみ');
      expect(lines[1], '');
      expect(lines.last, 'Smart Photo Diary');
    });
  });
}
