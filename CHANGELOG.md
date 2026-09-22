# Changelog

## 1.9.8

- Export compliance: `ITSAppUsesNonExemptEncryption=false`（#150）
- OpenRouter モデルを Actions Variable `OPENROUTER_MODEL` で設定可能に（#152。既定 `google/gemini-2.5-flash`）
- オンボーディングのサンプル抜粋表示、iOS 写真権限文言のローカライズ、購入確認の改善（#155）
- 未使用の過去写真スタック・統計サービス削除（#156）
- 利用制限・機能ゲートを `ISubscriptionService` に一本化（#157）
- Home タイムライン読み込みを `HomeDataLoader` に抽出（#158）
- App Store 却下対応: 権限拒否後の Settings 誘導をやめ、決定を尊重する UX に変更（Guideline 4 / 5.1.1(iv)、#159）
- 写真権限拒否後も Home タイムラインで設定へのリンクを出せるよう修正（#160）
- ドキュメント鮮度揃えと完了プラン整理（#153 / #154）

## 1.9.7

- OpenRouter への AI プロバイダ移行と関連設定の整理
- Hive 暗号化不一致時のリカバリ改善
- 購入フローのブロッカー解消
- freeze-fatal 周辺の不要コメント・未使用ヒントの整理（deslop）
