# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

**サービス名**: コブツログ（KobutsuLog）
**概要**: 古物商向け法令対応の取引台帳管理アプリ
**詳細仕様**: SPEC.md を参照

## 技術スタック

### フロントエンド (app/)
- Flutter 3.x (Dart)
- 状態管理: flutter_riverpod
- ローカルDB: hive
- HTTPクライアント: dio
- ルーティング: go_router

### バックエンド (api/)
- Cloudflare Workers (TypeScript)
- Cloudflare D1 (SQLite)
- Cloudflare R2 (画像ストレージ)
- APIフレームワーク: hono

### 認証
- Firebase Authentication

## 開発コマンド

### Flutter (app/)
```bash
cd app
flutter pub get          # 依存関係インストール
flutter run              # 開発実行
flutter test             # テスト実行
flutter analyze          # 静的解析
flutter build appbundle  # Android リリースビルド
flutter build ios        # iOS リリースビルド
```

### Cloudflare Workers (api/)
```bash
cd api
npm install              # 依存関係インストール
npm run dev              # ローカル開発サーバー
npm test                 # テスト実行
npm run lint             # Lint実行
npx wrangler deploy      # デプロイ
npx wrangler tail        # ログ確認
```

### D1 データベース
```bash
cd api
npx wrangler d1 execute kobutsu-log-db --local --file=./schema.sql  # ローカル
npx wrangler d1 execute kobutsu-log-db --file=./schema.sql          # 本番
```

## ディレクトリ構成

```
kobutsu-log/
├── app/                    # Flutter アプリ
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/         # 設定・定数
│   │   ├── models/         # データモデル
│   │   ├── providers/      # Riverpod プロバイダ
│   │   ├── services/       # API・認証サービス
│   │   ├── screens/        # 画面
│   │   ├── widgets/        # 共通ウィジェット
│   │   └── utils/          # ユーティリティ
│   └── pubspec.yaml
│
├── api/                    # Cloudflare Workers
│   ├── src/
│   │   ├── index.ts        # エントリポイント
│   │   ├── routes/         # APIルート
│   │   ├── middleware/     # 認証・CORS
│   │   ├── services/       # Firebase・R2連携
│   │   └── utils/          # ユーティリティ
│   ├── wrangler.toml
│   └── package.json
│
├── .github/workflows/      # GitHub Actions
├── CLAUDE.md               # このファイル
├── SPEC.md                 # 詳細仕様
└── README.md
```

## 開発ルール

### オフラインファースト
- 必ずHiveでローカル保存を実装
- API失敗時はローカルデータで継続
- オンライン復帰時に同期

### セキュリティ
- Firebase ID Token検証（Workers側）
- 個人情報は暗号化保存
- HTTPS通信のみ

### 画像処理
- アップロード前に1MB以下に圧縮
- R2に保存、URLをDBに記録

### 制限チェック
- フロントエンド + バックエンド両方で実装
