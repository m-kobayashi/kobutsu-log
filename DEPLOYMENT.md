# デプロイ・設定ガイド

## 実装完了した機能

以下の全Issue（#2〜#9）が実装完了し、GitHubにプッシュされました：

- ✅ Issue #2: ログイン・登録画面UI
- ✅ Issue #3: ホーム画面（取引一覧）実装
- ✅ Issue #4: 取引API実装
- ✅ Issue #5: 取引登録画面実装
- ✅ Issue #6: Hive ローカルDB実装
- ✅ Issue #7: R2画像アップロード実装（エンドポイントのみ）
- ✅ Issue #8: 設定画面実装
- ✅ Issue #9: Riverpod状態管理実装

---

## 手動設定が必要な項目

### 1. Cloudflare R2バケット設定

画像アップロード機能を有効にするには、Cloudflare R2バケットの設定が必要です。

#### 手順:

1. Cloudflare Dashboardで R2 バケットを作成
   ```bash
   # バケット名例: kobutsu-log-images
   ```

2. `api/wrangler.toml` を編集してR2バケットバインディングを追加:
   ```toml
   [[r2_buckets]]
   binding = "IMAGES"
   bucket_name = "kobutsu-log-images"
   ```

3. `api/src/routes/upload.ts` の実装を有効化:
   ```typescript
   // 現在コメントアウトされている実装を有効化
   const formData = await c.req.formData();
   const file = formData.get('file') as File;
   const filename = `${userId}/${Date.now()}_${file.name}`;
   await c.env.IMAGES.put(filename, file.stream());
   const url = `https://your-r2-domain.com/${filename}`;
   ```

4. 公開URLの設定（Custom DomainまたはR2.dev URL）

---

### 2. Flutter環境変数設定

API_BASE_URLを環境に応じて設定します。

#### 開発環境:
```bash
# ローカル開発（Cloudflare Workers Dev）
flutter run --dart-define=API_BASE_URL=http://localhost:8787
```

#### 本番環境:
```bash
# デプロイ済みWorkers URL
flutter run --dart-define=API_BASE_URL=https://your-worker.workers.dev
```

または、`app/lib/config/constants.dart` を直接編集:
```dart
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://your-worker.workers.dev', // ここを変更
);
```

---

### 3. Firebase設定（既に完了している場合はスキップ）

- Firebase Console でプロジェクト作成済み
- Authentication: Email/Password、Google を有効化済み
- `app/lib/firebase_options.dart` が生成済み

追加で必要な設定:
- Android: `app/android/app/google-services.json`
- iOS: `app/ios/Runner/GoogleService-Info.plist`

---

### 4. Google Sign-In設定

#### Android
`app/android/app/build.gradle` に SHA-1 フィンガープリントを追加:
```bash
cd app/android
./gradlew signingReport
```
Firebase ConsoleでSHA-1を登録。

#### iOS
Firebase Consoleから `GoogleService-Info.plist` をダウンロードし、
`REVERSED_CLIENT_ID` をURL Schemesに追加（既にFlutterFire CLIで設定済みの場合は不要）。

---

### 5. Cloudflare Workers デプロイ

#### 前提:
- Cloudflare アカウント作成済み
- D1 データベース作成済み（Issue #1で実施）
- wrangler CLI インストール済み

#### デプロイ手順:

```bash
cd api

# 環境変数設定（wrangler.toml または .dev.vars）
# FIREBASE_PROJECT_ID=your-firebase-project-id

# デプロイ
npx wrangler deploy

# デプロイ後のURL確認
# https://kobutsu-log.your-account.workers.dev
```

---

### 6. Flutter ビルド・リリース

#### Android APK:
```bash
cd app
flutter build apk --release --dart-define=API_BASE_URL=https://your-worker.workers.dev
# 出力: app/build/app/outputs/flutter-apk/app-release.apk
```

#### iOS:
```bash
cd app
flutter build ios --release --dart-define=API_BASE_URL=https://your-worker.workers.dev
# Xcodeでアーカイブ・App Store Connect にアップロード
```

---

## 動作確認項目

### 基本フロー:
1. ✅ ユーザー登録（メール/パスワード）
2. ✅ Googleログイン
3. ✅ ホーム画面表示
4. ✅ 取引新規登録（オンライン）
5. ✅ 取引一覧表示・検索
6. ✅ 取引編集・削除
7. ✅ オフライン動作確認（機内モードで登録）
8. ✅ オンライン復帰時の自動同期
9. ✅ 月間登録上限（50件）チェック
10. ⚠️ 画像アップロード（R2設定後）

---

## トラブルシューティング

### エラー: "User not found. Please register first."
- 原因: Firebase UIDでDBに登録されていない
- 解決: ログアウト後、再度登録フローを実行

### エラー: "R2バケットが未設定です"
- 原因: wrangler.toml に R2 バインディングがない
- 解決: 上記「1. Cloudflare R2バケット設定」を実施

### エラー: CORS エラー
- 原因: API URLが間違っている
- 解決: API_BASE_URL を確認（http://localhost:8787 または https://your-worker.workers.dev）

### Flutter ビルドエラー: "Hive adapters not found"
- 原因: .g.dartファイルが生成されていない
- 解決: 手動で作成済み（`app/lib/models/*.g.dart`）

---

## 今後の拡張

### MVP後の機能追加候補:
- [ ] プレミアムプラン（RevenueCat統合）
- [ ] CSVエクスポート機能
- [ ] 取引統計グラフ表示
- [ ] プッシュ通知（月末リマインダー）
- [ ] 多言語対応
- [ ] ダークモード完全対応

---

## 参考リンク

- [Cloudflare Workers Docs](https://developers.cloudflare.com/workers/)
- [Cloudflare R2 Docs](https://developers.cloudflare.com/r2/)
- [Flutter Docs](https://docs.flutter.dev/)
- [Riverpod Docs](https://riverpod.dev/)
- [Firebase Auth Docs](https://firebase.google.com/docs/auth)

---

生成日時: 2025-12-16
