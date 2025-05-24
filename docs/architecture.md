# アーキテクチャ設計

## システム構成
```
smart-photo-diary/
├── lib/
│   ├── app/                  # アプリ全体のエントリーポイント
│   ├── core/                 # コア機能（AI処理、DB、共通ロジック）
│   ├── features/             # 機能ごとのモジュール
│   │   ├── photo_picker/     # 写真選択機能
│   │   ├── diary_generator/  # 日記生成機能
│   │   └── statistics/       # 統計表示機能
│   └── shared/               # 共通ウィジェット・ユーティリティ
├── test/                     # テストコード
└── pubspec.yaml              # 依存関係・設定
```

## 技術スタック（予定）
- **フレームワーク**: Flutter 3.x
- **言語**: Dart
- **状態管理**: Riverpod + StateNotifier
- **データベース**: Hive（ローカルDB、暗号化対応）
- **AI処理**: TensorFlow Lite（TFLite Flutter Plugin）
- **画像処理**: image_picker, image_cropper
- **テスト**: flutter_test, mocktail, integration_test

## データフロー
1. ユーザーが写真を選択（`image_picker`）
2. 写真をトリミング・加工（`image_cropper`）
3. AIが写真を解析してテキストを生成（TFLite）
4. 生成テキストをユーザーが編集（`flutter_quill`）
5. 日記データをHiveに保存
6. 統計情報を更新・表示（`fl_chart`）

## アーキテクチャパターン
- **クリーンアーキテクチャ**を採用
- **レイヤードアーキテクチャ**で関心の分離
- **BLoCパターン**を部分的に採用

## セキュリティ・プライバシー
- すべてのデータは端末内に暗号化して保存
- 写真のメタデータは自動的に削除
- バックアップはパスワード保護（オプション）
- 生体認証サポート

## パフォーマンス最適化
- 画像の遅延読み込み
- メモリ効率の良い画像キャッシュ
- アイソレートを使用した重い処理の並列実行
- ウィジェットの再ビルドを最小限に抑える設計
