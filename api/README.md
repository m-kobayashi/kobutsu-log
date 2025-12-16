# コブツログ API

Cloudflare Workers + Hono + D1 で構築された古物商向け取引台帳管理API

## セットアップ

### 1. 依存関係のインストール

```bash
cd api
npm install
```

### 2. D1データベースの作成

```bash
# 本番環境用データベース
npx wrangler d1 create kobutsu-log-db

# ステージング環境用データベース（オプション）
npx wrangler d1 create kobutsu-log-db-staging
```

### 3. データベースIDの設定

`wrangler.toml` の `<your-database-id>` を実際のデータベースIDに置き換えてください。

### 4. スキーマの適用

```bash
# 本番環境
npx wrangler d1 execute kobutsu-log-db --file=schema.sql

# ローカル開発環境
npx wrangler d1 execute kobutsu-log-db --local --file=schema.sql
```

### 5. ローカル開発サーバーの起動

```bash
npm run dev
```

開発サーバーは `http://localhost:8787` で起動します。

## 実装済みエンドポイント

### 認証関連

#### POST /api/auth/register
ユーザー登録

**ヘッダー:**
```
Authorization: Bearer <firebase_id_token>
```

**リクエストボディ:**
```json
{
  "display_name": "山田太郎",
  "business_name": "山田商店",
  "license_number": "東京都公安委員会 第123456789号"
}
```

**レスポンス:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "user_xxxxx",
      "firebase_uid": "xxxxx",
      "email": "user@example.com",
      "display_name": "山田太郎",
      "business_name": "山田商店",
      "license_number": "東京都公安委員会 第123456789号",
      "plan": "free",
      "created_at": "2025-01-15T10:00:00Z"
    }
  }
}
```

#### POST /api/auth/verify
トークン検証（デバッグ用）

**ヘッダー:**
```
Authorization: Bearer <firebase_id_token>
```

**レスポンス:**
```json
{
  "success": true,
  "data": {
    "firebase_uid": "xxxxx",
    "email": "user@example.com"
  }
}
```

### ユーザー情報管理

#### GET /api/users/me
ログイン中のユーザー情報取得

**ヘッダー:**
```
Authorization: Bearer <firebase_id_token>
```

**レスポンス:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "user_xxxxx",
      "firebase_uid": "xxxxx",
      "email": "user@example.com",
      "display_name": "山田太郎",
      "business_name": "山田商店",
      "license_number": "東京都公安委員会 第123456789号",
      "plan": "free",
      "created_at": "2025-01-15T10:00:00Z",
      "updated_at": "2025-01-15T10:00:00Z"
    }
  }
}
```

#### PUT /api/users/me
ユーザー情報更新

**ヘッダー:**
```
Authorization: Bearer <firebase_id_token>
```

**リクエストボディ:**
```json
{
  "display_name": "山田太郎",
  "business_name": "山田商店（更新）",
  "license_number": "東京都公安委員会 第123456789号"
}
```

**レスポンス:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "user_xxxxx",
      "firebase_uid": "xxxxx",
      "email": "user@example.com",
      "display_name": "山田太郎",
      "business_name": "山田商店（更新）",
      "license_number": "東京都公安委員会 第123456789号",
      "plan": "free",
      "created_at": "2025-01-15T10:00:00Z",
      "updated_at": "2025-01-15T11:00:00Z"
    }
  }
}
```

#### GET /api/users/stats
ユーザーの統計情報取得

**ヘッダー:**
```
Authorization: Bearer <firebase_id_token>
```

**レスポンス:**
```json
{
  "success": true,
  "data": {
    "stats": {
      "monthly_count": 15,
      "total_count": 127,
      "monthly_limit": 50,
      "plan": "free"
    }
  }
}
```

## エラーレスポンス

すべてのエラーは以下の形式で返されます：

```json
{
  "success": false,
  "error": {
    "message": "Error message here"
  }
}
```

バリデーションエラーの場合：

```json
{
  "success": false,
  "error": {
    "message": "Validation failed",
    "fields": {
      "email": "Valid email is required",
      "display_name": "Display name must be a string"
    }
  }
}
```

## HTTPステータスコード

- `200` - 成功
- `201` - 作成成功
- `400` - バリデーションエラー
- `401` - 認証エラー
- `404` - リソースが見つからない
- `409` - 競合（既に登録済みなど）
- `500` - サーバーエラー

## ディレクトリ構造

```
api/
├── src/
│   ├── index.ts              # メインエントリーポイント
│   ├── middleware/
│   │   └── auth.ts           # Firebase認証ミドルウェア
│   ├── routes/
│   │   ├── auth.ts           # 認証・登録ルート
│   │   └── users.ts          # ユーザー情報管理ルート
│   └── utils/
│       └── response.ts       # レスポンスヘルパー関数
├── schema.sql                # D1データベーススキーマ
├── wrangler.toml             # Cloudflare Workers設定
├── package.json
└── tsconfig.json
```

## 開発コマンド

```bash
# ローカル開発サーバー起動
npm run dev

# 型チェック
npm run typecheck

# デプロイ
npm run deploy

# D1データベースクエリ実行（ローカル）
npx wrangler d1 execute kobutsu-log-db --local --command="SELECT * FROM users"

# D1データベースクエリ実行（本番）
npx wrangler d1 execute kobutsu-log-db --command="SELECT * FROM users"
```

## セキュリティ

### Firebase認証

- すべての保護されたエンドポイントは、Firebase ID Tokenによる認証が必要です
- トークンは `Authorization: Bearer <token>` ヘッダーで送信します
- トークンの検証は `src/middleware/auth.ts` で実装されています

### 注意事項

1. **本番環境では完全なJWT検証を実装してください**
   - 現在の実装は簡易版です
   - Firebase公開鍵を使用した署名検証を実装することを推奨します

2. **個人情報の取り扱い**
   - 相手方情報は暗号化して保存することを検討してください
   - HTTPS通信を必須にしてください

3. **レート制限**
   - 本番環境では適切なレート制限を実装してください

## 次のステップ

Issue #2で以下を実装予定：

- [ ] 取引データのCRUD API (`/api/transactions`)
- [ ] 画像アップロードAPI (`/api/upload`)
- [ ] 月次統計API (`/api/stats/monthly`)
- [ ] プラン制限チェックの実装

## トラブルシューティング

### D1データベースが見つからない

```bash
# データベース一覧を確認
npx wrangler d1 list

# データベースを再作成
npx wrangler d1 create kobutsu-log-db
```

### ローカル開発時のデータベースリセット

```bash
# .wranglerディレクトリを削除
rm -rf .wrangler

# スキーマを再適用
npx wrangler d1 execute kobutsu-log-db --local --file=schema.sql
```

### CORS エラー

`wrangler.toml` で適切なCORS設定を行うか、`src/index.ts` のCORS設定を調整してください。

## ライセンス

Private
