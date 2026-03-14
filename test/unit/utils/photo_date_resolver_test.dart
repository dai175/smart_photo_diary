import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/utils/photo_date_resolver.dart';

class MockAssetEntity extends Mock implements AssetEntity {}

void main() {
  group('PhotoDateResolver', () {
    group('resolveAssetDateTime', () {
      test('returns createDateTime when valid', () {
        final asset = MockAssetEntity();
        final validDate = DateTime(2025, 6, 15);
        when(() => asset.createDateTime).thenReturn(validDate);

        final result = PhotoDateResolver.resolveAssetDateTime(asset);

        expect(result, validDate);
      });

      test('falls back to modifiedDateTime when createDateTime is epoch', () {
        final asset = MockAssetEntity();
        final modifiedDate = DateTime(2025, 3, 10);
        when(() => asset.createDateTime).thenReturn(DateTime(1970));
        when(() => asset.modifiedDateTime).thenReturn(modifiedDate);

        final result = PhotoDateResolver.resolveAssetDateTime(asset);

        expect(result, modifiedDate);
      });

      test(
        'falls back to modifiedDateTime when createDateTime is before epoch',
        () {
          final asset = MockAssetEntity();
          final modifiedDate = DateTime(2025, 1, 1);
          when(() => asset.createDateTime).thenReturn(DateTime(1969, 12, 31));
          when(() => asset.modifiedDateTime).thenReturn(modifiedDate);

          final result = PhotoDateResolver.resolveAssetDateTime(asset);

          expect(result, modifiedDate);
        },
      );

      test('returns DateTime.now when both dates are invalid', () {
        final asset = MockAssetEntity();
        when(() => asset.createDateTime).thenReturn(DateTime(1970));
        when(() => asset.modifiedDateTime).thenReturn(DateTime(1969));

        final before = DateTime.now();
        final result = PhotoDateResolver.resolveAssetDateTime(asset);
        final after = DateTime.now();

        expect(
          result.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(result.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });
    });

    group('resolveMedianDateTime', () {
      test('returns median for odd number of assets', () {
        final assets = List.generate(3, (_) => MockAssetEntity());
        final dates = [
          DateTime(2025, 1, 1),
          DateTime(2025, 3, 1),
          DateTime(2025, 5, 1),
        ];

        for (int i = 0; i < assets.length; i++) {
          when(() => assets[i].createDateTime).thenReturn(dates[i]);
        }

        final result = PhotoDateResolver.resolveMedianDateTime(assets);

        // Median of sorted [Jan, Mar, May] at index 1 = Mar
        expect(result, DateTime(2025, 3, 1));
      });

      test('returns median for even number of assets', () {
        final assets = List.generate(4, (_) => MockAssetEntity());
        final dates = [
          DateTime(2025, 1, 1),
          DateTime(2025, 2, 1),
          DateTime(2025, 3, 1),
          DateTime(2025, 4, 1),
        ];

        for (int i = 0; i < assets.length; i++) {
          when(() => assets[i].createDateTime).thenReturn(dates[i]);
        }

        final result = PhotoDateResolver.resolveMedianDateTime(assets);

        // Index 4 ~/ 2 = 2, so Mar
        expect(result, DateTime(2025, 3, 1));
      });

      test('returns single date for one asset', () {
        final asset = MockAssetEntity();
        final date = DateTime(2025, 6, 1);
        when(() => asset.createDateTime).thenReturn(date);

        final result = PhotoDateResolver.resolveMedianDateTime([asset]);

        expect(result, date);
      });

      test('returns DateTime.now for empty list', () {
        final before = DateTime.now();
        final result = PhotoDateResolver.resolveMedianDateTime([]);
        final after = DateTime.now();

        expect(
          result.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(result.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });

      test('sorts dates before taking median', () {
        final assets = List.generate(3, (_) => MockAssetEntity());
        // Provide dates out of order
        final dates = [
          DateTime(2025, 5, 1),
          DateTime(2025, 1, 1),
          DateTime(2025, 3, 1),
        ];

        for (int i = 0; i < assets.length; i++) {
          when(() => assets[i].createDateTime).thenReturn(dates[i]);
        }

        final result = PhotoDateResolver.resolveMedianDateTime(assets);

        // Sorted: [Jan, Mar, May], median = Mar
        expect(result, DateTime(2025, 3, 1));
      });
    });
  });
}
