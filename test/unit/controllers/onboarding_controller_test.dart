import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/controllers/onboarding_controller.dart';

void main() {
  late OnboardingController controller;
  bool manuallyDisposed = false;

  setUp(() {
    controller = OnboardingController();
    manuallyDisposed = false;
  });

  tearDown(() {
    if (!manuallyDisposed) {
      controller.dispose();
    }
  });

  group('OnboardingController', () {
    group('初期状態', () {
      test('currentPageは0', () {
        expect(controller.currentPage, 0);
      });

      test('isProcessingはfalse', () {
        expect(controller.isProcessing, isFalse);
      });

      test('isFirstPageはtrue', () {
        expect(controller.isFirstPage, isTrue);
      });

      test('isLastPageはfalse', () {
        expect(controller.isLastPage, isFalse);
      });

      test('pageCountは4', () {
        expect(controller.pageCount, 4);
      });
    });

    group('setCurrentPage', () {
      test('ページを変更するとnotifyListenersが呼ばれる', () {
        var notified = false;
        controller.addListener(() => notified = true);

        controller.setCurrentPage(2);

        expect(controller.currentPage, 2);
        expect(notified, isTrue);
      });

      test('同じページではnotifyListenersが呼ばれない', () {
        controller.setCurrentPage(1);

        var notified = false;
        controller.addListener(() => notified = true);

        controller.setCurrentPage(1);

        expect(notified, isFalse);
      });
    });

    group('isLastPage', () {
      test('ページ3でtrueを返す', () {
        controller.setCurrentPage(3);

        expect(controller.isLastPage, isTrue);
      });

      test('ページ2でfalseを返す', () {
        controller.setCurrentPage(2);

        expect(controller.isLastPage, isFalse);
      });
    });

    group('isFirstPage', () {
      test('ページ0でtrueを返す', () {
        expect(controller.isFirstPage, isTrue);
      });

      test('ページ1以上でfalseを返す', () {
        controller.setCurrentPage(1);

        expect(controller.isFirstPage, isFalse);
      });
    });

    group('dispose', () {
      test('dispose後にsetCurrentPageを呼んでも例外が発生しない', () {
        controller.dispose();
        manuallyDisposed = true;

        // _safeNotifyListenersが_disposed=trueを検出して
        // notifyListenersを呼ばないため例外なし
        expect(() => controller.setCurrentPage(1), returnsNormally);
      });
    });
  });
}
