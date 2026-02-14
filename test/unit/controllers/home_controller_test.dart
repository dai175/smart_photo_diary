import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/controllers/home_controller.dart';

void main() {
  late HomeController controller;

  setUp(() {
    controller = HomeController();
  });

  tearDown(() {
    controller.dispose();
  });

  group('HomeController', () {
    group('初期状態', () {
      test('currentIndexは0', () {
        expect(controller.currentIndex, 0);
      });

      test('diaryScreenKeyはnullでない', () {
        expect(controller.diaryScreenKey, isNotNull);
      });

      test('statsScreenKeyはnullでない', () {
        expect(controller.statsScreenKey, isNotNull);
      });
    });

    group('setCurrentIndex', () {
      test('異なるインデックスに変更するとnotifyListenersが呼ばれる', () {
        var notified = false;
        controller.addListener(() => notified = true);

        controller.setCurrentIndex(2);

        expect(controller.currentIndex, 2);
        expect(notified, isTrue);
      });

      test('同じインデックスではnotifyListenersが呼ばれない', () {
        controller.setCurrentIndex(1);

        var notified = false;
        controller.addListener(() => notified = true);

        controller.setCurrentIndex(1);

        expect(notified, isFalse);
      });
    });

    group('refreshDiaryAndStats', () {
      test('diaryScreenKeyとstatsScreenKeyが更新される', () {
        final oldDiaryKey = controller.diaryScreenKey;
        final oldStatsKey = controller.statsScreenKey;

        controller.refreshDiaryAndStats();

        expect(controller.diaryScreenKey, isNot(oldDiaryKey));
        expect(controller.statsScreenKey, isNot(oldStatsKey));
      });

      test('notifyListenersが呼ばれる', () {
        var notified = false;
        controller.addListener(() => notified = true);

        controller.refreshDiaryAndStats();

        expect(notified, isTrue);
      });
    });

    group('refreshStatsAndSwitchTab', () {
      test('statsScreenKeyが更新されcurrentIndexが変更される', () {
        final oldStatsKey = controller.statsScreenKey;
        final oldDiaryKey = controller.diaryScreenKey;

        controller.refreshStatsAndSwitchTab(2);

        expect(controller.statsScreenKey, isNot(oldStatsKey));
        expect(controller.diaryScreenKey, oldDiaryKey);
        expect(controller.currentIndex, 2);
      });

      test('notifyListenersが呼ばれる', () {
        var notified = false;
        controller.addListener(() => notified = true);

        controller.refreshStatsAndSwitchTab(3);

        expect(notified, isTrue);
      });
    });
  });
}
