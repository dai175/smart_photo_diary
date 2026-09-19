# Changelog

## 1.9.7

- OpenRouter への AI プロバイダ移行と関連設定の整理
- Hive 暗号化不一致時のリカバリ改善
- 購入フローのブロッカー解消
- freeze-fatal 周辺の不要コメント・未使用ヒントの整理（deslop）

### main after tag `v1.9.7`（TestFlight Build 108 未含有）

タグ `v1.9.7`（`3bb24ef`）より後に main へ入った変更。次のビルド／タグで載る:

- Export compliance: `ITSAppUsesNonExemptEncryption=false`（#150）
- OpenRouter モデルを Actions Variable `OPENROUTER_MODEL` で設定可能に（#152。既定 `google/gemini-2.5-flash`）
