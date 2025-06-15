# サンドボックステスト環境設定ガイド

## 概要

Smart Photo DiaryのIn-App Purchase機能をサンドボックス環境でテストするための設定とテスト手順を説明します。

## iOS App Store Connect サンドボックス設定

### 1. サンドボックステスターアカウント作成

**App Store Connectでの設定**:
1. App Store Connect → ユーザーとアクセス → サンドボックステスター
2. 「+」ボタンで新規テスターを追加
3. 以下の情報を入力：

```
メールアドレス: test.ios@smartphotodiary.app
パスワード: TestPass123!
名前: Smart Photo Diary
姓: iOS Tester
国または地域: 日本
App Store 地域: 日本
```

**追加のテストアカウント**:
```
# 年額プランテスト用
メールアドレス: yearly.test@smartphotodiary.app
地域: 日本

# 月額プランテスト用  
メールアドレス: monthly.test@smartphotodiary.app
地域: 日本

# 復元テスト用
メールアドレス: restore.test@smartphotodiary.app
地域: 日本

# 地域別テスト用（アメリカ）
メールアドレス: us.test@smartphotodiary.app
地域: アメリカ合衆国
```

### 2. iOS デバイス設定

**テストデバイスの準備**:
1. **設定 > App Store** を開く
2. **アカウント情報** でサインアウト
3. **サンドボックスアカウント** セクションでテストアカウントにサインイン

**重要な注意事項**:
- 本番のApple IDでサンドボックス購入を試行しない
- テスト後は必ずサンドボックスアカウントからサインアウト
- テストアカウントは本番App Storeで使用不可

### 3. Xcodeプロジェクト設定

**StoreKit Configuration File**:
```xml
<!-- SmartPhotoDiary.storekit -->
{
  "identifier" : "SmartPhotoDiary",
  "nonRenewingSubscriptions" : [],
  "subscriptions" : [
    {
      "adHocOffers" : [],
      "codeOffers" : [],
      "displayPrice" : "300",
      "familyShareable" : false,
      "groupNumber" : 1,
      "internalID" : "smart_photo_diary_premium_monthly",
      "introductoryOffer" : {
        "internalID" : "monthly_trial",
        "paymentMode" : "free",
        "subscriptionPeriod" : "P7D"
      },
      "localizations" : [
        {
          "description" : "月100回のAI日記生成とプレミアム機能",
          "displayName" : "Premium Monthly",
          "locale" : "ja"
        }
      ],
      "productID" : "smart_photo_diary_premium_monthly",
      "recurringSubscriptionPeriod" : "P1M",
      "referenceName" : "Premium Monthly Plan",
      "subscriptionGroupNumber" : 1
    },
    {
      "adHocOffers" : [],
      "codeOffers" : [],
      "displayPrice" : "2800", 
      "familyShareable" : false,
      "groupNumber" : 1,
      "internalID" : "smart_photo_diary_premium_yearly",
      "introductoryOffer" : {
        "internalID" : "yearly_trial",
        "paymentMode" : "free", 
        "subscriptionPeriod" : "P7D"
      },
      "localizations" : [
        {
          "description" : "月100回のAI日記生成とプレミアム機能（年額22%割引）",
          "displayName" : "Premium Yearly",
          "locale" : "ja"
        }
      ],
      "productID" : "smart_photo_diary_premium_yearly",
      "recurringSubscriptionPeriod" : "P1Y",
      "referenceName" : "Premium Yearly Plan",
      "subscriptionGroupNumber" : 1
    }
  ],
  "version" : {
    "major" : 1,
    "minor" : 0
  }
}
```

## Android Google Play Console サンドボックス設定

### 1. ライセンステスト設定

**Google Play Consoleでの設定**:
1. Google Play Console → アプリ → 収益化設定
2. **ライセンステスト** セクションに移動
3. テストアカウントを追加：

```
test.android@smartphotodiary.app
yearly.test.android@smartphotodiary.app  
monthly.test.android@smartphotodiary.app
restore.test.android@smartphotodiary.app
```

### 2. 内部テスト配布

**内部テスト トラックの設定**:
1. **リリース > テスト > 内部テスト** を選択
2. **テスターを管理** でテストアカウント追加
3. テスト用APKまたはAABをアップロード

**テスト配布手順**:
```bash
# デバッグビルド作成
fvm flutter build apk --debug

# リリースビルド作成（署名必要）
fvm flutter build apk --release

# 内部テスト用にGoogle Play Consoleへアップロード
# (手動でコンソールからアップロード)
```

### 3. Play Billing Library設定

**Android Manifest設定**:
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="com.android.vending.BILLING" />
```

**Gradle依存関係**:
```gradle
// android/app/build.gradle
dependencies {
    implementation 'com.android.billingclient:billing:5.0.0'
}
```

## テスト環境用設定ファイル

### 環境変数設定

**テスト用 .env ファイル**:
```env
# .env.testing
ENVIRONMENT=testing
SANDBOX_TESTING=true
API_ENDPOINT=https://test-api.smartphotodiary.app
GEMINI_API_KEY=your_test_api_key_here
```

### Flutter設定

**テスト用設定クラス**:
```dart
// lib/config/environment_config_test.dart
class TestEnvironmentConfig {
  static const bool isSandbox = true;
  static const bool enableLogging = true;
  static const bool enablePurchaseValidation = false;
  
  static const Map<String, String> testProductIds = {
    'monthly': 'test_smart_photo_diary_premium_monthly',
    'yearly': 'test_smart_photo_diary_premium_yearly',
  };
}
```

## テストシナリオ

### 1. 基本購入フローテスト

**テスト手順**:
```
1. アプリ起動
2. 設定画面 → Premium プラン選択
3. 月額プラン（¥300）選択
4. サンドボックス購入画面確認
5. Touch ID/Face ID で購入完了
6. Premium機能の有効化確認
7. AI生成回数が100回に変更されることを確認
```

**期待結果**:
- 購入完了後、即座にPremium機能が使用可能
- SubscriptionServiceの状態が正常に更新される
- UI上でPremiumプランの表示に変更される

### 2. 無料トライアルテスト

**テスト手順**:
```
1. 新規テストアカウントでアプリ起動
2. Premium プラン選択
3. 「7日間無料トライアル」の表示確認
4. 無料トライアル開始
5. Premium機能が即座に使用可能になることを確認
6. 設定画面でトライアル終了日の表示確認
```

**期待結果**:
- 7日間の無料期間が正しく設定される
- トライアル期間中はPremium機能がフル利用可能
- トライアル終了日が正確に表示される

### 3. 購入復元テスト

**テスト手順**:
```
1. テストアカウントでPremium購入
2. アプリをアンインストール
3. 同じアカウントでアプリを再インストール
4. 設定画面 → 「購入を復元」ボタンタップ
5. Premium状態の復元確認
```

**期待結果**:
- 以前の購入が正常に復元される
- 購入日、有効期限が正しく復元される
- Premium機能が即座に使用可能になる

### 4. プラン変更テスト

**テスト手順**:
```
1. 月額プランを購入
2. 年額プランに変更
3. プラン変更の処理確認
4. 新プランの反映確認
```

**期待結果**:
- プラン変更が正常に処理される
- 新しいプランの有効期限が正しく設定される
- 旧プランが適切にキャンセルされる

### 5. エラーケーステスト

**テストケース**:
```
1. ネットワーク切断時の購入
2. 購入キャンセル
3. 支払い方法エラー
4. 不正な商品ID
5. サーバーエラー（5xx）
```

**期待結果**:
- 適切なエラーメッセージが表示される
- アプリがクラッシュしない
- 購入状態が不整合にならない

## 自動テストスクリプト

### 購入フローテスト

```dart
// test/integration/purchase_flow_test.dart
void main() {
  group('Purchase Flow Integration Tests', () {
    testWidgets('Premium monthly purchase flow', (tester) async {
      // テストコード実装
      // 1. アプリ起動
      // 2. Premium プラン画面遷移
      // 3. 購入ボタンタップ
      // 4. サンドボックス購入処理
      // 5. Premium機能の有効化確認
    });
    
    testWidgets('Purchase restoration flow', (tester) async {
      // 購入復元テストコード
    });
    
    testWidgets('Free trial activation flow', (tester) async {
      // 無料トライアルテストコード
    });
  });
}
```

## テスト実行チェックリスト

### 事前準備
- [ ] サンドボックステスターアカウント作成完了
- [ ] テストデバイスにサンドボックスアカウント設定完了
- [ ] App Store Connect / Google Play Console商品設定完了
- [ ] アプリにテスト用ビルド設定適用完了

### iOS テスト
- [ ] 月額プラン購入テスト完了
- [ ] 年額プラン購入テスト完了
- [ ] 無料トライアル開始テスト完了
- [ ] 購入復元テスト完了
- [ ] 購入キャンセルテスト完了
- [ ] ネットワークエラーテスト完了

### Android テスト  
- [ ] 月額プラン購入テスト完了
- [ ] 年額プラン購入テスト完了
- [ ] 無料トライアル開始テスト完了
- [ ] 購入復元テスト完了
- [ ] 購入キャンセルテスト完了
- [ ] Google Play エラーテスト完了

### クロスプラットフォームテスト
- [ ] 同一アカウントでの異なるプラットフォーム間購入状態同期
- [ ] データ整合性確認
- [ ] パフォーマンステスト

## トラブルシューティング

### よくある問題と解決策

**商品が表示されない**:
```
原因: 商品がApp Store Connect/Google Play Consoleで承認されていない
解決: コンソールで商品のステータスを確認し、必要に応じて再提出
```

**サンドボックス購入が失敗する**:
```
原因: テストアカウントの設定が正しくない
解決: デバイスの設定でサンドボックスアカウントが正しく設定されているか確認
```

**購入復元が機能しない**:
```
原因: トランザクションIDの管理に問題がある
解決: ローカルストレージのトランザクション情報を確認
```

**無料トライアルが開始されない**:
```
原因: 商品設定で無料トライアルが有効になっていない
解決: App Store Connect/Google Play Consoleの商品設定を確認
```

## ログ・デバッグ情報

### テスト用ログ設定

```dart
// デバッグログの有効化
debugPrint('Purchase flow started');
debugPrint('Product ID: $productId');
debugPrint('Purchase result: $result');
```

### 重要な確認ポイント

1. **購入状態の変更タイミング**
2. **トランザクションIDの保存**
3. **有効期限の計算**
4. **エラーハンドリングの動作**
5. **UI状態の更新**

## 本番環境への移行

### 移行前チェックリスト

- [ ] 全サンドボックステスト完了
- [ ] 商品設定の本番環境用更新
- [ ] テスト用コードの削除
- [ ] 本番用証明書・署名の設定
- [ ] レビュー提出用素材準備

### 本番環境設定変更

```dart
// 本番用設定に変更
static const bool isSandboxEnvironment = false;
static const bool enableTestLogging = false;
```

## 参考資料

- [App Store Connect ヘルプ - サンドボックステスト](https://help.apple.com/app-store-connect/#/dev8b997bee1)
- [Google Play Console - ライセンステスト](https://developer.android.com/google/play/billing/test)
- [Flutter in_app_purchase plugin](https://pub.dev/packages/in_app_purchase)
- [iOS StoreKit Testing](https://developer.apple.com/documentation/storekittesting)