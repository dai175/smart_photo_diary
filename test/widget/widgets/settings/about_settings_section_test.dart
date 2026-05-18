import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:smart_photo_diary/widgets/settings/about_settings_section.dart';

import '../../../test_helpers/widget_test_helpers.dart';

void main() {
  PackageInfo buildPackageInfo({
    String version = '2.0.0',
    String buildNumber = '42',
  }) {
    return PackageInfo(
      appName: 'Smart Photo Diary',
      packageName: 'com.example.smart_photo_diary',
      version: version,
      buildNumber: buildNumber,
      buildSignature: '',
    );
  }

  Widget buildWidget({PackageInfo? packageInfo}) {
    return WidgetTestHelpers.wrapWithLocalizedApp(
      Scaffold(body: AboutSettingsSection(packageInfo: packageInfo)),
    );
  }

  group('AboutSettingsSection', () {
    group('version row', () {
      testWidgets('shows loading text when packageInfo is null', (
        tester,
      ) async {
        await tester.pumpWidget(buildWidget(packageInfo: null));
        await tester.pump();

        expect(find.text('App version'), findsOneWidget);
        expect(find.text('Loading...'), findsOneWidget);
      });

      testWidgets('shows version and build number when packageInfo available', (
        tester,
      ) async {
        await tester.pumpWidget(buildWidget(packageInfo: buildPackageInfo()));
        await tester.pump();

        expect(find.text('App version'), findsOneWidget);
        expect(find.text('2.0.0 (42)'), findsOneWidget);
      });

      testWidgets('version row has no tap action', (tester) async {
        await tester.pumpWidget(buildWidget(packageInfo: buildPackageInfo()));
        await tester.pump();

        await tester.tap(find.text('App version'));
        await tester.pump();
      });
    });

    group('privacy policy row', () {
      testWidgets('shows privacy policy title and subtitle', (tester) async {
        await tester.pumpWidget(buildWidget(packageInfo: buildPackageInfo()));
        await tester.pump();

        expect(find.text('Privacy policy'), findsOneWidget);
        expect(find.text('How your data is handled'), findsOneWidget);
      });
    });

    group('licenses row', () {
      testWidgets('shows license title and subtitle', (tester) async {
        await tester.pumpWidget(buildWidget(packageInfo: buildPackageInfo()));
        await tester.pump();

        expect(find.text('Licenses'), findsOneWidget);
        expect(find.text('Open source licenses'), findsOneWidget);
      });

      testWidgets('tapping licenses opens LicensePage', (tester) async {
        await tester.pumpWidget(buildWidget(packageInfo: buildPackageInfo()));
        await tester.pump();

        await tester.tap(find.text('Licenses'));
        await tester.pumpAndSettle();

        expect(find.byType(LicensePage), findsOneWidget);
      });
    });

    group('row count', () {
      testWidgets('renders three rows', (tester) async {
        await tester.pumpWidget(buildWidget(packageInfo: buildPackageInfo()));
        await tester.pump();

        expect(find.text('App version'), findsOneWidget);
        expect(find.text('Privacy policy'), findsOneWidget);
        expect(find.text('Licenses'), findsOneWidget);
      });
    });
  });
}
