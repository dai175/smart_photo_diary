import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'config/environment_config.dart';
import 'constants/app_constants.dart';
import 'models/diary_entry.dart';
import 'models/subscription_status.dart';
import 'models/writing_prompt.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'core/service_locator.dart';
import 'services/settings_service.dart';
import 'services/logging_service.dart';
import 'core/service_registration.dart';
import 'ui/design_system/app_theme.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  // Flutterの初期化を確実に行う
  WidgetsFlutterBinding.ensureInitialized();

  // Hiveの初期化
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  // アダプターの登録
  Hive.registerAdapter(DiaryEntryAdapter());
  Hive.registerAdapter(SubscriptionStatusAdapter());
  Hive.registerAdapter(PromptCategoryAdapter());
  Hive.registerAdapter(WritingPromptAdapter());
  Hive.registerAdapter(PromptUsageHistoryAdapter());

  // アプリケーション初期化開始
  final appStartTime = DateTime.now();

  // サービスロケータの初期化（LoggingService登録のため先に実行）
  await ServiceRegistration.initialize();
  final logger = serviceLocator.get<LoggingService>();

  logger.info('アプリケーション初期化開始', context: 'main');
  logger.info('ServiceRegistration初期化完了', context: 'main');

  // 環境変数の初期化（LoggingServiceが利用可能になった後）
  await EnvironmentConfig.initialize();
  logger.info('EnvironmentConfig初期化完了', context: 'main');

  // 初期化完了時間の計測
  final initDuration = DateTime.now().difference(appStartTime);
  logger.info(
    'アプリケーション初期化完了',
    context: 'main',
    data: '初期化時間: ${initDuration.inMilliseconds}ms',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  SettingsService? _settingsService;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;
  bool _isFirstLaunch = false;
  Locale? _locale;
  ValueNotifier<Locale?>? _localeNotifier;

  // LoggingServiceアクセス用getter
  LoggingService get _logger => serviceLocator.get<LoggingService>();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      _settingsService = await ServiceLocator().getAsync<SettingsService>();
      final notifier = _settingsService!.localeNotifier;
      if (_localeNotifier != notifier) {
        _localeNotifier?.removeListener(_handleLocaleChanged);
        _localeNotifier = notifier;
        _localeNotifier?.addListener(_handleLocaleChanged);
      }

      setState(() {
        _themeMode = _settingsService!.themeMode;
        _isFirstLaunch = _settingsService!.isFirstLaunch;
        _locale = _localeNotifier?.value ?? _settingsService!.locale;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _logger.error(
        '設定の読み込みエラー',
        context: '_MyAppState._loadSettings',
        error: e,
      );
    }
  }

  void _onThemeChanged(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  void _handleLocaleChanged() {
    if (!mounted) return;
    setState(() {
      _locale = _localeNotifier?.value;
    });
  }

  @override
  void dispose() {
    _localeNotifier?.removeListener(_handleLocaleChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      title: AppConstants.appTitle,
      themeMode: _themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
      localeResolutionCallback: (locale, supportedLocales) {
        final preferred = _locale ?? locale;
        if (preferred == null) {
          return supportedLocales.first;
        }

        final exactMatch = supportedLocales.firstWhere(
          (supported) =>
              supported.languageCode == preferred.languageCode &&
              supported.countryCode == preferred.countryCode,
          orElse: () => supportedLocales.first,
        );

        if (exactMatch.languageCode == preferred.languageCode &&
            exactMatch.countryCode == preferred.countryCode) {
          return exactMatch;
        }

        final languageMatch = supportedLocales.firstWhere(
          (supported) => supported.languageCode == preferred.languageCode,
          orElse: () => supportedLocales.first,
        );

        return languageMatch;
      },
      home: _isFirstLaunch
          ? OnboardingScreen(onThemeChanged: _onThemeChanged)
          : HomeScreen(onThemeChanged: _onThemeChanged),
    );
  }
}
