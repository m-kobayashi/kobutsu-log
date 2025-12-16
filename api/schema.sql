-- コブツログ D1 データベーススキーマ

-- ユーザーテーブル
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  firebase_uid TEXT UNIQUE NOT NULL,
  email TEXT NOT NULL,
  display_name TEXT,
  business_name TEXT,
  license_number TEXT,
  plan TEXT DEFAULT 'free',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Firebase UIDでの高速検索用インデックス
CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);

-- 取引テーブル
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  transaction_type TEXT NOT NULL, -- 'buy' or 'sell'
  item_name TEXT NOT NULL,
  item_category TEXT,
  quantity INTEGER DEFAULT 1,
  price INTEGER NOT NULL,
  transaction_date DATETIME NOT NULL,
  -- 相手方情報（法令必須）
  counterparty_name TEXT NOT NULL,
  counterparty_address TEXT NOT NULL,
  counterparty_age INTEGER,
  counterparty_occupation TEXT,
  -- 本人確認
  id_verification_type TEXT NOT NULL,
  id_verification_number TEXT,
  -- その他
  photo_url TEXT,
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ユーザーIDでの高速検索用インデックス
CREATE INDEX idx_transactions_user_id ON transactions(user_id);

-- 取引日時でのソート用インデックス
CREATE INDEX idx_transactions_date ON transactions(user_id, transaction_date DESC);

-- 取引タイプでのフィルタリング用インデックス
CREATE INDEX idx_transactions_type ON transactions(user_id, transaction_type);
