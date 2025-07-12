# TestFlight ビルド・配布ガイド

Smart Photo DiaryアプリをTestFlightで配布するための詳細な手順書です。

## 目次

1. [事前準備](#事前準備)
2. [Xcodeでのビルド作成](#xcodeでのビルド作成)
3. [App Store Connectへのアップロード](#app-store-connectへのアップロード)
4. [TestFlightでの配布設定](#testflightでの配布設定)
5. [テスターへの配布](#テスターへの配布)
6. [トラブルシューティング](#トラブルシューティング)

## 事前準備

### 必要な設定の確認

#### 1. Apple Developer Program
- ✅ Apple Developer Program登録済み
- ✅ Team ID: `P785AMQPKJ`
- ✅ Bundle ID: `com.focuswave.dev.smartPhotoDiary`

#### 2. App Store Connect設定
- ✅ Paid Apps Agreement: Active
- ✅ Tax Forms: Active
- ✅ Banking Information: Active
- ✅ アプリ登録完了: Smart Photo Diary

#### 3. In-App Purchase設定
- ✅ Premium Monthly Plan: `smart_photo_diary_monthly`
- ✅ Premium Yearly Plan: `smart_photo_diary_yearly`

#### 4. コード設定
- ✅ Product ID統一済み
- ✅ Bundle ID統一済み
- ✅ Info.plist設定完了

### 開発環境の確認

```bash
# FVM (Flutter Version Management) の確認
fvm --version

# Flutterバージョンの確認
fvm flutter --version

# 依存関係の最新化
fvm flutter pub get

# コード生成（必要な場合）
fvm dart run build_runner build
```

## Xcodeでのビルド作成

### Step 1: Xcodeプロジェクトを開く

```bash
# プロジェクトルートから
open ios/Runner.xcworkspace
```

**重要:** `.xcodeproj` ではなく `.xcworkspace` を開くこと（CocoaPodsを使用しているため）

### Step 2: ビルド設定の確認

#### Signing & Capabilities設定
1. **Runner** ターゲットを選択
2. **Signing & Capabilities** タブをクリック
3. 以下を確認：
   - **Team**: `P785AMQPKJ (Daisuke Oba)`
   - **Bundle Identifier**: `com.focuswave.dev.smartPhotoDiary`
   - **Signing Certificate**: `iPhone Distribution` または `Apple Distribution`

#### Capabilities設定
必要なCapabilitiesが有効になっていることを確認：
- **In-App Purchase** ✅（課金機能用）
- **App Groups**（必要に応じて）

### Step 3: リリースビルドの作成

#### Command Line Build（推奨）
```bash
# プロジェクトルートで実行
fvm flutter build ios --release --no-codesign

# 成功確認
echo "✅ Flutter iOS build completed"
```

#### Xcodeでのビルド確認
1. **Product → Clean Build Folder** (Shift+Cmd+K)
2. **Product → Build** (Cmd+B)
3. エラーがないことを確認

### Step 4: Archive作成

#### Archiveの実行
1. **Product → Archive** (または Cmd+Shift+B)
2. **ビルドターゲット**が `Any iOS Device (arm64)` になっていることを確認
3. **Archive** ボタンをクリック

#### Archiveプロセス
- 通常 5-10分程度かかります
- 進行状況は上部のプログレスバーで確認
- エラーが発生した場合は後述のトラブルシューティングを参照

## App Store Connectへのアップロード

### Step 1: Organizer画面

Archive完了後、自動的にOrganizerが開きます（開かない場合は **Window → Organizer**）

#### Archive一覧の確認
- 最新のArchiveが上部に表示される
- **Date**: 作成日時
- **Version**: `1.0.0`
- **Build**: 自動増分されたビルド番号

### Step 2: 配布方法の選択

#### Distribute App
1. **Distribute App** ボタンをクリック
2. 配布方法を選択：
   - ✅ **App Store Connect** を選択
   - **Next** をクリック

#### Upload設定
1. **Upload** を選択（Exportではない）
2. **Next** をクリック

### Step 3: 配布オプション設定

#### App Store Connect配布オプション
- ✅ **Include bitcode for iOS content**: チェック
- ✅ **Upload your app's symbols**: チェック（クラッシュレポート用）
- ✅ **Manage Version and Build Number**: チェック（自動管理）

#### 署名設定
- ✅ **Automatically manage signing**: 推奨
- または手動署名の場合は適切な Distribution Certificate を選択

### Step 4: アップロード実行

#### 最終確認
1. **Upload** ボタンをクリック
2. アップロード進行状況を確認
3. 完了まで 5-15分程度

#### 成功確認
```
✅ App successfully uploaded
The following issues were found during processing:
- (警告がある場合は表示される)
```

## TestFlightでの配布設定

### Step 1: App Store Connect管理画面

#### アクセス方法
1. [App Store Connect](https://appstoreconnect.apple.com/) にアクセス
2. **Smart Photo Diary** アプリを選択
3. **TestFlight** タブをクリック

### Step 2: ビルド処理の確認

#### Processing状態
新しいビルドは最初 **Processing** 状態になります：
- **通常の処理時間**: 5-30分
- **Status**: `Processing` → `Ready to Test`

#### Processing完了の確認
- メール通知が届く
- App Store Connect画面でステータス更新

### Step 3: Export Compliance設定

#### Missing Compliance解決
新しいビルドに **Missing Compliance** 警告が表示される場合：

1. **Manage** ボタンをクリック
2. **Export Compliance Information** を入力：
   - **暗号化使用**: `None of the algorithms mentioned above` を選択
   - **Save** をクリック

### Step 4: External Testing設定

#### テストグループの確認
1. **External Testing** タブを選択
2. 既存のテストグループを確認
3. 必要に応じて新しいグループを作成

#### 新しいビルドの追加
1. **Select Version to Test** で最新ビルドを選択
2. **Save** をクリック
3. テスト情報の確認：
   - **What to Test**: テスト内容の説明
   - **Test Information**: アプリの説明

## テスターへの配布

### Step 1: テスター管理

#### 既存テスターの確認
- **External Testing** → **Testers** タブ
- 登録済みテスターのリストを確認

#### 新しいテスターの追加
1. **+** ボタンをクリック
2. **Email** と **First Name**, **Last Name** を入力
3. **Add** をクリック

### Step 2: 配布実行

#### テスター選択
1. 配布したいテスターを選択
2. **Add** ボタンをクリック

#### 配布通知
- テスターに自動的にメール通知が送信
- TestFlightアプリのインストール案内も含まれる

### Step 3: テスター側の手順

#### TestFlightアプリ
1. **TestFlight** アプリをApp Storeからダウンロード
2. 招待メールのリンクをタップ
3. **Accept** をタップしてテストに参加

#### アプリのインストール
1. TestFlightアプリで **Smart Photo Diary** を選択
2. **Install** をタップ
3. アプリがデバイスにインストールされる

## トラブルシューティング

### ビルドエラー

#### 署名エラー
```
Code Signing Error: No signing certificate found
```
**解決方法:**
1. Xcode → Preferences → Accounts
2. Apple ID確認・再ログイン
3. **Download Manual Profiles** をクリック

#### Bundle IDエラー
```
Bundle ID does not match
```
**解決方法:**
1. `ios/Runner.xcodeproj/project.pbxproj` でBundle ID確認
2. App Store Connect設定と一致させる

### アップロードエラー

#### API Key エラー
```
Unable to authenticate with App Store Connect
```
**解決方法:**
1. Xcode → Preferences → Accounts
2. Apple IDを削除・再追加
3. 2段階認証の確認

#### バイナリ拒否
```
Binary was rejected
```
**解決方法:**
1. Info.plist設定の確認
2. 必要なUsage Descriptionの追加
3. Export Compliance情報の設定

### TestFlight配布エラー

#### テスター招待エラー
```
Tester invitation failed
```
**解決方法:**
1. テスターのメールアドレス確認
2. External Testing Group設定確認
3. Test Information完成度確認

#### アプリクラッシュ
```
App crashes on launch
```
**解決方法:**
1. Device Logs確認
2. Xcode Console確認
3. Release Build設定確認

### In-App Purchase テストエラー

#### 「準備中」表示
```
現在、アプリ内課金機能の準備中です
```
**解決方法:**
1. App Store Connect契約確認（Paid Apps Agreement）
2. Product ID設定確認
3. App VersionでIn-App Purchase有効化

## ベストプラクティス

### ビルド前チェックリスト

- [ ] コード変更のテスト完了
- [ ] `fvm flutter analyze` でエラーなし
- [ ] `fvm flutter test` で全テスト成功
- [ ] Bundle ID・Product ID設定確認
- [ ] Info.plist設定確認

### 配布前チェックリスト

- [ ] Archive作成成功
- [ ] アップロード完了
- [ ] Processing状態確認
- [ ] Export Compliance設定
- [ ] テスター通知設定

### セキュリティ考慮事項

- [ ] API Keyがコードに含まれていない
- [ ] .env ファイルがgitignore済み
- [ ] 本番環境向け設定確認

## 参考リンク

- [Apple Developer Documentation - Distributing Your App for Beta Testing](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing)
- [App Store Connect - TestFlight Help](https://developer.apple.com/help/app-store-connect/test-a-beta-version/)
- [Flutter - Build and release for iOS](https://docs.flutter.dev/deployment/ios)

---

**最終更新**: 2025年7月12日  
**バージョン**: 1.0.0  
**担当**: Claude Code Assistant