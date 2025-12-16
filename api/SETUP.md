# コブツログ API セットアップガイド

Issue #1「D1スキーマ + API基盤実装」の完了後の初期セットアップ手順

## 実装内容確認

以下のファイルが実装されました：

### スキーマ
- ✅ `schema.sql` - D1データベーススキーマ（users, transactionsテーブル）

### ソースコード
- ✅ `src/index.ts` - メインエントリーポイント（ルーティング設定）
- ✅ `src/middleware/auth.ts` - Firebase Token検証ミドルウェア
- ✅ `src/routes/auth.ts` - ユーザー登録API
- ✅ `src/routes/users.ts` - ユーザー情報管理API
- ✅ `src/utils/response.ts` - レスポンスヘルパー関数

### ドキュメント
- ✅ `README.md` - API仕様とエンドポイント一覧
- ✅ `SETUP.md` - このファイル

## セットアップ手順

### Step 1: 依存関係のインストール

```bash
cd /Users/kobayashi/develop/20_private/kobutsu-log/api
npm install
```

### Step 2: D1データベースの作成

#### ローカル開発用

ローカル開発では、Wranglerが自動的にローカルD1インスタンスを作成します。

```bash
# スキーマを適用（ローカル）
npx wrangler d1 execute kobutsu-log-db --local --file=schema.sql
```

#### 本番環境用

```bash
# D1データベースを作成
npx wrangler d1 create kobutsu-log-db

# 出力されたdatabase_idをメモして、wrangler.tomlの<your-database-id>を置き換える

# スキーマを適用（本番）
npx wrangler d1 execute kobutsu-log-db --file=schema.sql
```

### Step 3: 環境変数の設定

`wrangler.toml` の設定を確認：

```toml
[vars]
FIREBASE_PROJECT_ID = "saas-apps-c5dce"
```

Firebase Project IDが正しいことを確認してください。

### Step 4: ローカル開発サーバーの起動

```bash
npm run dev
```

開発サーバーが `http://localhost:8787` で起動します。

### Step 5: 動作確認

#### ヘルスチェック

```bash
curl http://localhost:8787/api/health
```

期待されるレスポンス：
```json
{
  "status": "healthy",
  "timestamp": "2025-12-16T..."
}
```

#### Firebase認証トークンの取得

FlutterアプリまたはFirebase SDKを使用してID Tokenを取得します。

```dart
// Flutter例
final user = FirebaseAuth.instance.currentUser;
final idToken = await user?.getIdToken();
```

#### ユーザー登録のテスト

```bash
curl -X POST http://localhost:8787/api/auth/register \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_FIREBASE_ID_TOKEN" \
  -d '{
    "display_name": "テストユーザー",
    "business_name": "テスト商店",
    "license_number": "東京都公安委員会 第123456789号"
  }'
```

#### ユーザー情報取得のテスト

```bash
curl http://localhost:8787/api/users/me \
  -H "Authorization: Bearer YOUR_FIREBASE_ID_TOKEN"
```

## データベース操作

### ローカルデータベースの確認

```bash
# テーブル一覧
npx wrangler d1 execute kobutsu-log-db --local --command="SELECT name FROM sqlite_master WHERE type='table'"

# ユーザー一覧
npx wrangler d1 execute kobutsu-log-db --local --command="SELECT * FROM users"

# テーブル構造確認
npx wrangler d1 execute kobutsu-log-db --local --command="PRAGMA table_info(users)"
```

### ローカルデータベースのリセット

```bash
# ローカルデータベースファイルを削除
rm -rf .wrangler

# スキーマを再適用
npx wrangler d1 execute kobutsu-log-db --local --file=schema.sql
```

## デプロイ

### 本番環境へのデプロイ

```bash
# TypeScriptの型チェック
npm run typecheck

# デプロイ
npm run deploy
```

デプロイ後、Workers URLが表示されます：
```
https://kobutsu-log-api.YOUR_SUBDOMAIN.workers.dev
```

## トラブルシューティング

### 問題: "Database not found"

**解決策:**
```bash
# データベース一覧を確認
npx wrangler d1 list

# データベースが存在しない場合は作成
npx wrangler d1 create kobutsu-log-db
```

### 問題: "FIREBASE_PROJECT_ID not configured"

**解決策:**
`wrangler.toml` の `[vars]` セクションを確認し、正しいFirebase Project IDが設定されているか確認してください。

### 問題: "Invalid or expired token"

**解決策:**
1. Firebase ID Tokenが有効か確認（期限は1時間）
2. Firebase Project IDが正しいか確認
3. トークンが正しく `Authorization: Bearer <token>` 形式で送信されているか確認

### 問題: 型エラーが発生する

**解決策:**
```bash
# 依存関係を再インストール
rm -rf node_modules package-lock.json
npm install

# 型チェック実行
npm run typecheck
```

## API仕様

詳細なAPI仕様は `README.md` を参照してください。

### 実装済みエンドポイント

- `POST /api/auth/register` - ユーザー登録
- `POST /api/auth/verify` - トークン検証（デバッグ用）
- `GET /api/users/me` - ユーザー情報取得
- `PUT /api/users/me` - ユーザー情報更新
- `GET /api/users/stats` - ユーザー統計情報取得

### 未実装（Phase 2予定）

- `GET /api/transactions` - 取引一覧
- `POST /api/transactions` - 取引登録
- `GET /api/transactions/:id` - 取引詳細
- `PUT /api/transactions/:id` - 取引更新
- `DELETE /api/transactions/:id` - 取引削除
- `POST /api/upload/image` - 画像アップロード
- `GET /api/stats/monthly` - 月次統計

## セキュリティ注意事項

### 本番環境で実装すべきこと

1. **完全なJWT検証**
   - 現在は簡易的なトークン検証のみ
   - Firebase公開鍵を使用した署名検証を実装する

2. **レート制限**
   - Cloudflare Workers の Rate Limiting を設定
   - ユーザーごとのリクエスト制限を実装

3. **個人情報の暗号化**
   - 相手方情報（氏名、住所など）の暗号化
   - Cloudflare Workers KVを使用した鍵管理

4. **CORS設定の厳格化**
   - 本番環境では `origin: '*'` を特定のドメインに制限

5. **エラーログの適切な管理**
   - センシティブ情報をログに出力しない
   - Cloudflare Workers のログストリーミングを設定

## 開発Tips

### VS Codeの推奨設定

`.vscode/settings.json`:
```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  }
}
```

### デバッグ方法

```typescript
// src/index.ts などでconsole.logを使用
console.log('Debug:', { firebaseUid, userEmail });

// Wranglerのログを確認
npm run dev
# ターミナルにリアルタイムでログが表示されます
```

## 次のステップ

Issue #1 の完了後、以下のフェーズに進みます：

1. **Issue #2**: 取引データCRUD API実装
2. **Issue #3**: 画像アップロード機能（R2連携）
3. **Issue #4**: Flutterアプリとの統合
4. **Issue #5**: オフライン同期機能

## サポート

問題が発生した場合は、以下を確認してください：

1. `npm run typecheck` でTypeScriptエラーがないか
2. `npx wrangler d1 list` でデータベースが存在するか
3. `wrangler.toml` の設定が正しいか
4. Firebase Project IDが正しいか

---

実装完了日: 2025-12-16
実装者: Claude Code (Backend Architect)
