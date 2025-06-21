# Smart Photo Diary 開発ガイド

## 環境構築

### 必要なツール
- **Flutter SDK**: 3.32.0以上（FVM推奨）
- **Dart SDK**: 3.8.0以上（Flutterに同梱）
- **IDE**: Android Studio、VS Code、または IntelliJ IDEA
- **エミュレータ/実機**: Android Studio、Xcode、または実機デバッグ用
- **FVM**: Flutter Version Management（強く推奨）
- **Google Gemini API キー**: AI日記生成用

### セットアップ手順

```bash
# リポジトリをクローン
git clone https://github.com/dai175/smart_photo_diary.git
cd smart_photo_diary

# FVMを利用している場合（推奨）
fvm flutter pub get

# コード生成（Hiveアダプター・モデル）
fvm dart run build_runner build

# 環境変数設定（.envファイルを作成）
echo "GEMINI_API_KEY=your_api_key_here" > .env

# アプリを起動
fvm flutter run
```

### 環境変数設定

プロジェクトルートに`.env`ファイルを作成：

```bash
# Google Gemini API設定（必須）
GEMINI_API_KEY=your_actual_api_key_here

# デバッグ用プラン強制設定（オプション、デバッグビルドのみ）
# FORCE_PLAN=premium
```

## 開発コマンド

### 基本開発コマンド
```bash
# 依存関係の取得
fvm flutter pub get

# コード生成（Hiveモデル、アダプター）
fvm dart run build_runner build

# 強制再生成（競合解決）
fvm dart run build_runner build --delete-conflicting-outputs

# アプリ実行（デバッグモード）
fvm flutter run

# 特定デバイスでの実行
fvm flutter run -d <device_id>

# リリースモードでの実行
fvm flutter run --release

# プラン強制指定での実行（デバッグのみ）
fvm flutter run --dart-define=FORCE_PLAN=premium
```

### ホットリロード・開発中の操作
```
実行中のコマンド:
r   : ホットリロード（状態保持したまま再読み込み）
R   : ホットリスタート（完全再起動）
h   : ヘルプ表示
d   : デタッチ（バックグラウンド実行）
q   : 終了
```

### テスト実行コマンド
```bash
# 全テスト実行（600+テスト、100%成功率）
fvm flutter test

# テストカテゴリ別実行
fvm flutter test test/unit/              # ユニットテスト
fvm flutter test test/widget/            # ウィジェットテスト  
fvm flutter test test/integration/       # 統合テスト

# 組み合わせ実行
fvm flutter test test/unit/ test/integration/

# 特定のテストファイル実行
fvm flutter test test/unit/services/diary_service_mock_test.dart

# 特定のテストケース実行
fvm flutter test test/unit/services/ --name="should save diary entry"

# カバレッジ付きテスト実行
fvm flutter test --coverage

# 詳細出力でのテスト実行
fvm flutter test --reporter expanded

# JSON形式での結果出力（CI用）
fvm flutter test --reporter json

# 特定の分析テスト実行
fvm flutter test test/unit/services/analytics/
```

### ビルド・リリースコマンド
```bash
# デバッグビルド
fvm flutter build apk --debug

# リリースビルド（Android）
fvm flutter build apk --release                    # APK形式
fvm flutter build appbundle --release               # AAB形式（Google Play用）

# iOS ビルド（macOSのみ）
fvm flutter build ipa --release                     # IPA形式（App Store用）
fvm flutter build ios --release --no-codesign       # コード署名なし

# その他プラットフォーム
fvm flutter build macos --release
fvm flutter build windows --release  
fvm flutter build linux --release
fvm flutter build web --release

# APKインストール（Android実機）
adb install build/app/outputs/flutter-apk/app-release.apk

# アプリ起動（Android）
adb shell am start -n com.example.smart_photo_diary/.MainActivity
```

### コード品質・静的解析
```bash
# 静的解析実行（目標: 0 issues維持）
fvm flutter analyze

# 問題の詳細表示
fvm flutter analyze --verbose

# コード整形
fvm dart format .

# 整形確認（CIで使用）
fvm dart format --set-exit-if-changed .

# 依存関係の確認・更新
fvm flutter pub outdated
fvm flutter pub upgrade

# 未使用依存関係の検出
fvm flutter pub deps
```

## アーキテクチャ・設計パターン

### サービス層設計

#### インターフェース定義
```dart
// サービスインターフェース例
abstract class IPromptService {
  Future<List<WritingPrompt>> getPromptsForPlan(SubscriptionPlan plan);
  Future<void> recordPromptUsage(String promptId);
  Future<PromptUsageAnalysis> analyzePromptFrequency({int days = 30});
}

// 実装クラス
class PromptService implements IPromptService {
  final LoggingService _loggingService;
  
  PromptService(this._loggingService);
  
  @override
  Future<List<WritingPrompt>> getPromptsForPlan(SubscriptionPlan plan) async {
    // 実装...
  }
}
```

#### 依存性注入の使用
```dart
// ServiceLocator経由でのサービス取得
final promptService = ServiceLocator.instance.get<IPromptService>();
final diaryService = ServiceLocator.instance.get<DiaryService>();

// サービス登録（main.dart）
ServiceLocator.instance.registerSingleton<IPromptService>(
  PromptService(ServiceLocator.instance.get<LoggingService>())
);
```

### エラーハンドリングパターン

#### Result<T>パターンの実装
```dart
// サービス層での使用
Future<Result<void>> saveDiary(DiaryEntry entry) async {
  try {
    await _hiveBox.put(entry.id, entry);
    await _updateStatistics();
    return Result.success(null);
  } catch (e) {
    _loggingService.error('Failed to save diary', error: e);
    return Result.failure(ServiceException('日記の保存に失敗しました', details: e.toString()));
  }
}

// UI層での使用
final result = await diaryService.saveDiary(newEntry);
result.fold(
  onSuccess: (_) {
    context.showSuccess('日記を保存しました');
    Navigator.pop(context);
  },
  onFailure: (error) {
    context.showError(error.message);
  },
);

// より簡潔な書き方
await saveDiary(newEntry)
  .showResultOnUI(context, onSuccess: (_) => '保存完了！');
```

#### 統一エラー表示
```dart
// 重要度別エラー表示
context.showInfo('情報メッセージ');
context.showWarning('警告メッセージ'); 
context.showError('エラーメッセージ');
context.showCriticalError('重大なエラー', onRetry: retryFunction);

// Result<T>からの直接表示
result.showErrorOnUI(context);
result.showErrorOnUIOfType<NetworkException>(context);
```

### 新機能開発ガイドライン

#### 必須パターン
1. **Result<T>パターン必須**: すべての新機能でResult<T>を使用
2. **インターフェース優先**: テスタビリティを重視した設計
3. **依存性注入**: ServiceLocator経由でのサービス取得
4. **テストファースト**: 実装前にテスト作成

#### 実装例
```dart
// 1. インターフェース定義
abstract class INewFeatureService {
  Future<Result<FeatureData>> processFeature(String input);
}

// 2. 実装クラス作成
class NewFeatureService implements INewFeatureService {
  final LoggingService _loggingService;
  
  NewFeatureService(this._loggingService);
  
  @override
  Future<Result<FeatureData>> processFeature(String input) async {
    return ResultHelper.tryExecuteAsync(() async {
      _loggingService.info('Processing feature with input: $input');
      // 処理実装
      return FeatureData(processed: input);
    });
  }
}

// 3. サービス登録
ServiceLocator.instance.registerSingleton<INewFeatureService>(
  NewFeatureService(ServiceLocator.instance.get<LoggingService>())
);

// 4. テスト作成
group('NewFeatureService', () {
  late INewFeatureService service;
  late MockLoggingService mockLoggingService;

  setUp(() {
    mockLoggingService = MockLoggingService();
    service = NewFeatureService(mockLoggingService);
  });

  test('should process feature successfully', () async {
    // テスト実装
  });
});
```

## テスト戦略・実装

### テスト分類と構造
```
test/
├── unit/                          # ユニットテスト（モック使用）
│   ├── services/                  # サービス層テスト
│   │   ├── analytics/             # 分析システム（58テスト）
│   │   ├── ai_service_mock_test.dart
│   │   ├── diary_service_mock_test.dart
│   │   ├── prompt_service_test.dart
│   │   └── subscription_service_test.dart
│   ├── models/                    # データモデルテスト
│   ├── core/                      # Result<T>、DI、基盤システム
│   └── utils/                     # ユーティリティ機能
├── widget/                        # ウィジェットテスト
│   ├── screens/                   # 画面コンポーネント
│   └── widgets/                   # 再利用可能ウィジェット
└── integration/                   # 統合テスト
    ├── prompt_features/           # プロンプト機能の統合テスト
    ├── subscription_features/     # 収益化機能の統合テスト
    └── test_helpers/              # テスト支援ユーティリティ
```

### テストベストプラクティス

#### 1. モックファーストアプローチ
```dart
// サービスのモック作成
class MockPromptService extends Mock implements IPromptService {}
class MockSubscriptionService extends Mock implements ISubscriptionService {}

// モックの設定
setUp(() {
  mockPromptService = MockPromptService();
  when(() => mockPromptService.getPromptsForPlan(any()))
    .thenAnswer((_) async => mockPrompts);
});
```

#### 2. Result<T>テストパターン
```dart
test('should return success when diary is saved', () async {
  // Arrange
  final entry = DiaryEntry(id: 'test', content: 'Test content');
  
  // Act
  final result = await diaryService.saveDiary(entry);
  
  // Assert
  expect(result.isSuccess, true);
  result.fold(
    onSuccess: (data) => expect(data, isNotNull),
    onFailure: (error) => fail('Should not fail'),
  );
});

test('should return failure when save fails', () async {
  // エラーケースのテスト
  when(() => mockHiveBox.put(any(), any())).thenThrow(Exception('DB Error'));
  
  final result = await diaryService.saveDiary(entry);
  
  expect(result.isFailure, true);
  result.fold(
    onSuccess: (_) => fail('Should not succeed'),
    onFailure: (error) => expect(error, isA<ServiceException>()),
  );
});
```

#### 3. 統合テストパターン
```dart
testWidgets('should complete diary creation flow', (tester) async {
  // 実際のサービスを使用した統合テスト
  await tester.pumpWidget(TestApp());
  
  // 写真選択
  await tester.tap(find.byType(PhotoSelectionButton));
  await tester.pumpAndSettle();
  
  // プロンプト選択
  await tester.tap(find.text('今日の出来事'));
  await tester.pumpAndSettle();
  
  // 日記生成
  await tester.tap(find.byType(GenerateDiaryButton));
  await tester.pumpAndSettle();
  
  // 結果確認
  expect(find.text('日記が生成されました'), findsOneWidget);
});
```

### テスト実行戦略
```bash
# 開発中: 関連テストのみ実行
fvm flutter test test/unit/services/prompt_service_test.dart

# PR前: 全テスト実行
fvm flutter test

# CI/CD: カバレッジ付き実行
fvm flutter test --coverage --reporter json
```

## コーディング規約・品質基準

### 命名規則
```dart
// クラス・ウィジェット: PascalCase
class PhotoSelectionController extends ChangeNotifier {}
class WritingPromptsScreen extends StatefulWidget {}

// 変数・関数: camelCase
String generateDiaryContent(List<String> tags) {}
final bool isGenerating = false;

// 定数: UPPER_SNAKE_CASE
const int MAX_PHOTOS_PER_DIARY = 5;
const String DEFAULT_DIARY_TEMPLATE = 'template';

// ファイル名: snake_case
photo_selection_controller.dart
writing_prompts_screen.dart

// プライベート変数: _camelCase
final DiaryService _diaryService;
bool _isLoading = false;
```

### コメント・ドキュメント規則
```dart
/// 日記エントリーを保存します
/// 
/// [entry] 保存する日記エントリー
/// Returns: 保存が成功した場合はSuccess、失敗した場合はFailure
Future<Result<void>> saveDiary(DiaryEntry entry) async {
  // ビジネスロジックのコメントは日本語で記述
  // 複雑なアルゴリズムには詳細な説明を追加
  
  try {
    // データベース保存処理
    await _hiveBox.put(entry.id, entry);
    
    // 統計情報の更新
    await _updateStatistics();
    
    return Result.success(null);
  } catch (e) {
    return Result.failure(ServiceException('保存に失敗しました'));
  }
}
```

### コード品質要件
```dart
// 1. const コンストラクタの積極利用
const Text('固定テキスト');
const SizedBox(height: 16);

// 2. 型安全性の確保
Future<Result<List<DiaryEntry>>> getDiaries() async {} // ❌ List<DiaryEntry>
Future<Result<List<DiaryEntry>>> getDiaries() async {} // ✅ Result<List<DiaryEntry>>

// 3. null安全性
String? optionalValue;
final nonNullValue = optionalValue ?? 'default';

// 4. Result<T>パターンの使用
// ❌ 例外ベース
try {
  await riskyOperation();
} catch (e) {
  handleError(e);
}

// ✅ Result<T>ベース
final result = await riskyOperation();
result.fold(
  onSuccess: handleSuccess,
  onFailure: handleError,
);
```

## Git ワークフロー・コミット規約

### ブランチ戦略
```bash
main              # 安定版・本番ブランチ
├── develop       # 開発統合ブランチ
├── feature/xxx   # 機能開発ブランチ
├── fix/xxx       # バグ修正ブランチ
└── release/xxx   # リリース準備ブランチ
```

### コミットメッセージ規約
```bash
# フォーマット: type(scope): 日本語メッセージ
#
# Types:
# feat     - 新機能
# fix      - バグ修正  
# refactor - リファクタリング
# test     - テスト関連
# docs     - ドキュメント
# style    - コードスタイル（機能に影響なし）
# perf     - パフォーマンス改善
# ci       - CI/CD関連

# 例:
feat(prompt): ライティングプロンプト機能の実装
fix(ui): ダークテーマでの文字視認性を改善
refactor(service): Result<T>パターンを適用してエラーハンドリングを改善
test(analytics): プロンプト使用量分析のテストを追加
docs(architecture): アーキテクチャドキュメントを最新化
```

### プルリクエスト手順
```bash
# 1. 機能ブランチ作成
git checkout -b feature/new-analytics-dashboard

# 2. 実装・テスト作成
# コード実装...
# テスト作成...

# 3. コード品質チェック
fvm flutter analyze                    # 静的解析
fvm dart format --set-exit-if-changed . # フォーマット確認
fvm flutter test                       # 全テスト実行

# 4. コミット・プッシュ
git add .
git commit -m "feat(analytics): 使用量分析ダッシュボードを実装"
git push origin feature/new-analytics-dashboard

# 5. PR作成・コードレビュー
# GitHub UIでPR作成
# レビュー対応

# 6. マージ後のクリーンアップ
git checkout main
git pull origin main
git branch -d feature/new-analytics-dashboard
```

## CI/CD・デプロイ

### GitHub Actions ワークフロー
```bash
# 基本CI/CD（自動実行）
.github/workflows/ci.yml              # PR・push時の品質チェック

# デプロイワークフロー（手動実行）
.github/workflows/android-deploy.yml  # Google Play Store
.github/workflows/ios-deploy.yml     # App Store/TestFlight  
.github/workflows/release.yml        # GitHub Release

# 実行方法
git tag v1.0.0
git push origin v1.0.0               # リリースワークフロー自動実行
```

### ローカルでのCI/CD模擬
```bash
# CI/CDと同等のチェック実行
fvm dart format --set-exit-if-changed .
fvm flutter analyze --fatal-infos --fatal-warnings
fvm flutter test --coverage --reporter expanded
fvm flutter build apk --release
```

## トラブルシューティング

### よくある問題と解決法

#### 1. コード生成エラー
```bash
# 症状: build_runner build が失敗
# 解決:
fvm dart run build_runner clean
fvm flutter clean
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
```

#### 2. テスト失敗
```bash
# 症状: モック関連のテスト失敗
# 解決: モックの初期化確認
setUp(() {
  mockService = MockService();
  // 必要なwhen設定を追加
  when(() => mockService.method()).thenReturn(expectedValue);
});

# 症状: 非同期テストのタイムアウト
# 解決: pumpAndSettle()の追加
await tester.pumpAndSettle(Duration(seconds: 5));
```

#### 3. 権限・環境エラー
```bash
# 症状: 写真アクセス権限エラー
# 解決: AndroidManifest.xmlの権限設定確認
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

# 症状: API キーエラー
# 解決: .envファイルの作成・設定確認
echo "GEMINI_API_KEY=your_actual_key" > .env
```

#### 4. フォント・UI問題
```bash
# 症状: 日本語フォント表示問題
# 解決: ロケール設定確認
MaterialApp(
  locale: Locale('ja', 'JP'),
  localizationsDelegates: [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: [
    Locale('ja', 'JP'),
  ],
)
```

### デバッグ支援ツール
```dart
// 構造化ログの使用
final loggingService = ServiceLocator.instance.get<LoggingService>();
loggingService.info('Operation started', context: {'userId': user.id});
loggingService.error('Operation failed', error: e, context: context);

// エラー表示の詳細確認
result.fold(
  onSuccess: (data) => print('Success: $data'),
  onFailure: (error) {
    print('Error: ${error.message}');
    print('Details: ${error.details}');
    print('Original: ${error.originalError}');
  },
);

// パフォーマンス測定
final stopwatch = Stopwatch()..start();
await expensiveOperation();
loggingService.performance('Operation completed', 
  duration: stopwatch.elapsed);
```

## リリース準備・品質チェック

### リリース前チェックリスト
```bash
# ✅ コード品質
- [ ] Flutter analyze: 0 issues
- [ ] テスト成功率: 100%
- [ ] カバレッジ: 妥当なレベル
- [ ] Result<T>パターン: 新機能で適用

# ✅ 機能検証
- [ ] 基本フロー: 写真選択→日記生成→保存
- [ ] 収益化: プラン制限・アップグレード
- [ ] エラーハンドリング: 適切な表示・回復
- [ ] パフォーマンス: レスポンス時間

# ✅ ドキュメント
- [ ] CHANGELOG.md更新
- [ ] バージョン番号更新（pubspec.yaml）
- [ ] README.md最新化
- [ ] docs/最新化

# ✅ 環境検証
- [ ] Android実機テスト
- [ ] iOS実機テスト（macOSのみ）
- [ ] 各種画面サイズ・OS版対応確認
```

### バージョン管理・リリース
```bash
# バージョン番号更新
# pubspec.yaml
version: 1.2.0+3  # version_name+build_number

# タグ作成・リリース
git tag v1.2.0
git push origin v1.2.0

# 自動的にGitHub Releaseが作成され、
# Android APK・AAB、iOS IPAが生成される
```

この開発ガイドに従うことで、Smart Photo Diaryの高品質で保守性の高いコードを効率的に開発し、安定したリリースを継続できます。新機能開発時は特にResult<T>パターンとテストファーストアプローチを重視してください。