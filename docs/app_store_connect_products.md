# App Store Connect 商品設定ガイド

## 概要

Smart Photo DiaryのiOS版In-App Purchase商品設定のためのガイドです。App Store Connectで設定する商品情報を定義します。

## 商品一覧

### 1. Premium月額プラン

**商品ID**: `smart_photo_diary_premium_monthly`
**商品タイプ**: Auto-Renewable Subscription
**価格**: ¥300/月
**サブスクリプショングループ**: Smart Photo Diary Premium
**期間**: 1ヶ月

**商品名（日本語）**: Smart Photo Diary Premium 月額プラン
**商品説明（日本語）**:
```
月100回のAI日記生成とプレミアム機能をご利用いただけます。

含まれる機能：
• 月100回までのAI日記生成
• ライティングプロンプト機能
• 高度なフィルタ・検索機能
• タグベース検索
• 日付範囲指定検索
• 時間帯フィルタ
• データエクスポート（複数形式）
• 優先カスタマーサポート
• 統計・分析ダッシュボード

いつでもキャンセル可能です。
```

**商品名（英語）**: Smart Photo Diary Premium Monthly
**商品説明（英語）**:
```
Access 100 AI diary generations per month and premium features.

Included features:
• Up to 100 AI diary generations per month
• Writing prompt assistance
• Advanced filtering and search
• Tag-based search
• Date range search
• Time filter
• Data export (multiple formats)
• Priority customer support
• Statistics and analytics dashboard

Cancel anytime.
```

### 2. Premium年額プラン

**商品ID**: `smart_photo_diary_premium_yearly`
**商品タイプ**: Auto-Renewable Subscription
**価格**: ¥2,800/年
**サブスクリプショングループ**: Smart Photo Diary Premium
**期間**: 1年

**商品名（日本語）**: Smart Photo Diary Premium 年額プラン
**商品説明（日本語）**:
```
月100回のAI日記生成とプレミアム機能を年額でご利用いただけます。月額プランより22%お得です。

含まれる機能：
• 月100回までのAI日記生成
• ライティングプロンプト機能
• 高度なフィルタ・検索機能
• タグベース検索
• 日付範囲指定検索
• 時間帯フィルタ
• データエクスポート（複数形式）
• 優先カスタマーサポート
• 統計・分析ダッシュボード

年額プランは月額プランより¥800お得です。
いつでもキャンセル可能です。
```

**商品名（英語）**: Smart Photo Diary Premium Yearly
**商品説明（英語）**:
```
Access 100 AI diary generations per month and premium features with yearly billing. Save 22% compared to monthly plan.

Included features:
• Up to 100 AI diary generations per month
• Writing prompt assistance
• Advanced filtering and search
• Tag-based search
• Date range search
• Time filter
• Data export (multiple formats)
• Priority customer support
• Statistics and analytics dashboard

Yearly plan saves ¥800 compared to monthly billing.
Cancel anytime.
```

## サブスクリプショングループ設定

**グループ名**: Smart Photo Diary Premium
**グループ表示名**: Premium Features
**ランク順序**: 
1. Premium年額プラン（推奨）
2. Premium月額プラン

## 無料トライアル設定

**対象商品**: Premium月額プラン、Premium年額プラン両方
**トライアル期間**: 7日間
**トライアル価格**: ¥0

**トライアル説明文**:
```
7日間無料でPremium機能をお試しいただけます。
トライアル期間中はいつでもキャンセル可能です。
```

## レビュー情報設定

**アプリ内購入レビュー情報**:
- スクリーンショット: Premium機能の画面（設定画面、統計画面等）
- レビューメモ: Premium機能の動作確認手順

## プライバシー設定

**データ収集**: なし
**追跡**: なし
**理由**: Smart Photo Diaryは完全にローカルで動作し、ユーザーデータを外部に送信しません

## テスト設定

**サンドボックステスト**:
- テスト用Apple IDでの購入テスト
- 購入・復元・キャンセルフローの確認
- 価格表示の確認

## 地域・価格設定

**主要地域の価格**:
- 日本: ¥300/月、¥2,800/年
- アメリカ: $2.99/月、$28.99/年
- その他地域: App Store Connectの推奨価格に従う

**価格設定の根拠**:
- 競合他社より手頃な価格設定
- AI機能のコストを考慮した適正価格
- 年額プランで22%の割引を提供

## 実装チェックリスト

### App Store Connect設定
- [ ] サブスクリプショングループ作成
- [ ] Premium月額プラン商品作成
- [ ] Premium年額プラン商品作成
- [ ] 商品説明文設定（日本語・英語）
- [ ] 価格設定（¥300/月、¥2,800/年）
- [ ] 無料トライアル設定（7日間）
- [ ] レビュー情報アップロード
- [ ] サンドボックステスター設定

### 契約・法的事項
- [ ] 有料アプリケーション契約確認
- [ ] 税務・銀行情報設定
- [ ] App Store Review Guidelines準拠確認

### テスト準備
- [ ] サンドボックステスト用Apple ID作成
- [ ] テストデバイス設定
- [ ] 購入フローテスト計画作成

## 注意事項

1. **商品IDは変更不可**: 一度App Store Connectに登録した商品IDは変更できません
2. **価格変更**: 価格変更は既存ユーザーに影響するため慎重に検討
3. **サブスクリプション管理**: ユーザーはiOS設定から直接管理可能
4. **レビュープロセス**: 新商品追加時はApp Reviewが必要
5. **テスト環境**: サンドボックス環境での十分なテストが必要

## サポート・トラブルシューティング

**よくある問題**:
- 商品が表示されない → 商品ステータスとアプリレビューステータスを確認
- 購入に失敗する → サンドボックス環境とテストアカウントの設定を確認
- 復元に失敗する → Transaction IDの管理を確認

**参考ドキュメント**:
- [App Store Connect ヘルプ](https://help.apple.com/app-store-connect/)
- [In-App Purchase Programming Guide](https://developer.apple.com/in-app-purchase/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)