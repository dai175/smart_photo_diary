import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_photo_diary/l10n/generated/app_localizations.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'mock_platform_channels.dart';

/// Helper utilities for widget testing
class WidgetTestHelpers {
  /// Wrap a widget with MaterialApp for testing
  static Widget wrapWithMaterialApp(Widget child, {ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? ThemeData(useMaterial3: true),
      home: Scaffold(body: child),
    );
  }

  /// Wrap a widget with MaterialApp + l10n delegates for testing
  static Widget wrapWithLocalizedApp(
    Widget child, {
    ThemeData? theme,
    Locale? locale,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale ?? const Locale('en'),
      theme: theme ?? ThemeData(useMaterial3: true),
      home: child,
    );
  }

  /// Wrap a widget with MaterialApp and Scaffold for testing
  static Widget wrapWithScaffold(Widget child, {ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? ThemeData(useMaterial3: true),
      home: Scaffold(body: SafeArea(child: child)),
    );
  }

  /// Create a test DiaryEntry with default values
  static DiaryEntry createTestDiaryEntry({
    String? id,
    DateTime? date,
    String? title,
    String? content,
    List<String>? photoIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? location,
    List<String>? tags,
    DateTime? tagsGeneratedAt,
  }) {
    final now = DateTime.now();
    return DiaryEntry(
      id: id ?? 'test-entry-id',
      date: date ?? now,
      title: title ?? 'Test Diary Title',
      content: content ?? 'This is a test diary content for widget testing.',
      photoIds: photoIds ?? ['photo1', 'photo2'],
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      location: location,
      tags: tags,
      tagsGeneratedAt: tagsGeneratedAt,
    );
  }

  /// Create multiple test DiaryEntry objects
  static List<DiaryEntry> createTestDiaryEntries(int count) {
    return List.generate(count, (index) {
      final date = DateTime.now().subtract(Duration(days: index));
      return createTestDiaryEntry(
        id: 'test-entry-$index',
        title: 'Test Diary $index',
        content: 'This is test diary content number $index.',
        date: date,
        createdAt: date,
        updatedAt: date,
        photoIds: ['photo${index}_1', 'photo${index}_2'],
        tags: ['tag$index', 'test'],
      );
    });
  }

  /// Setup common test environment
  static Future<void> setUpTestEnvironment() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    MockPlatformChannels.setupMocks();

    // Initialize Hive for testing
    await _initializeHive();
  }

  /// Initialize Hive for testing
  static Future<void> _initializeHive() async {
    try {
      const testDirectory = '/tmp/smart_photo_diary_test';
      await Hive.initFlutter(testDirectory);

      // Register adapters if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(DiaryEntryAdapter());
      }
    } catch (e) {
      // Ignore if already initialized
    }
  }

  /// Clean up test environment
  static Future<void> tearDownTestEnvironment() async {
    try {
      // Clear Hive data
      await Hive.deleteFromDisk();
    } catch (e) {
      // Ignore cleanup errors
    }
    MockPlatformChannels.clearMocks();
  }

  /// Pump and settle with timeout
  static Future<void> pumpAndSettleWithTimeout(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await tester.pumpAndSettle(timeout);
  }

  /// Find widget by type and verify it exists
  static void expectWidgetExists<T extends Widget>(Finder finder) {
    expect(
      finder,
      findsOneWidget,
      reason: 'Expected to find one ${T.toString()} widget',
    );
  }

  /// Find multiple widgets by type and verify count
  static void expectWidgetCount<T extends Widget>(Finder finder, int count) {
    expect(
      finder,
      findsNWidgets(count),
      reason: 'Expected to find $count ${T.toString()} widgets',
    );
  }

  /// Verify text exists in widget
  static void expectTextExists(String text) {
    expect(
      find.text(text),
      findsOneWidget,
      reason: 'Expected to find text: "$text"',
    );
  }

  /// Verify text exists multiple times
  static void expectTextCount(String text, int count) {
    expect(
      find.text(text),
      findsNWidgets(count),
      reason: 'Expected to find text "$text" $count times',
    );
  }

  /// Tap widget and pump
  static Future<void> tapAndPump(WidgetTester tester, Finder finder) async {
    await tester.tap(finder, warnIfMissed: false);
    await tester.pump();
  }

  /// Long press widget and pump
  static Future<void> longPressAndPump(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.longPress(finder);
    await tester.pump();
  }

  /// Enter text in field and pump
  static Future<void> enterTextAndPump(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pump();
  }

  /// Scroll widget and pump
  static Future<void> scrollAndPump(
    WidgetTester tester,
    Finder finder,
    Offset offset,
  ) async {
    await tester.drag(finder, offset);
    await tester.pump();
  }

  /// Find widget by key
  static Finder findByKey(String key) {
    return find.byKey(Key(key));
  }

  /// Find widget by value key
  static Finder findByValueKey(String value) {
    return find.byKey(ValueKey(value));
  }

  /// Create a mock ThemeData for testing
  static ThemeData createTestTheme({Brightness brightness = Brightness.light}) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: brightness,
      ),
    );
  }

  /// Test widget accessibility
  static Future<void> testAccessibility(WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  }

  /// Create a test MediaQuery for responsive testing
  static Widget wrapWithMediaQuery(
    Widget child, {
    Size size = const Size(800, 600),
    double devicePixelRatio = 1.0,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        devicePixelRatio: devicePixelRatio,
        padding: padding,
      ),
      child: child,
    );
  }

  /// Create a test Directionality widget
  static Widget wrapWithDirectionality(
    Widget child, {
    TextDirection textDirection = TextDirection.ltr,
  }) {
    return Directionality(textDirection: textDirection, child: child);
  }
}
