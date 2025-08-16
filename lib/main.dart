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
import 'core/service_locator.dart';
import 'services/settings_service.dart';
import 'core/service_registration.dart';
import 'ui/design_system/app_colors.dart';

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

  // 環境変数の初期化
  debugPrint('🔧 EnvironmentConfig初期化開始...');
  await EnvironmentConfig.initialize();
  debugPrint('🔧 EnvironmentConfig初期化完了: ${EnvironmentConfig.isInitialized}');

  // サービスロケータの初期化
  debugPrint('🔧 ServiceRegistration初期化開始...');
  await ServiceRegistration.initialize();
  debugPrint('🔧 ServiceRegistration初期化完了');

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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      _settingsService = await ServiceLocator().getAsync<SettingsService>();
      setState(() {
        _themeMode = _settingsService!.themeMode;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('設定の読み込みエラー: $e');
    }
  }

  void _onThemeChanged(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      title: AppConstants.appTitle,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // 日本語ロケール設定
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'), // 日本語
        Locale('en', 'US'), // 英語（フォールバック）
      ],
      locale: const Locale('ja', 'JP'), // デフォルトロケール
      home: HomeScreen(onThemeChanged: _onThemeChanged),
    );
  }
}
