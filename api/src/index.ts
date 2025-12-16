import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { authMiddleware } from './middleware/auth';
import authRouter from './routes/auth';
import usersRouter from './routes/users';

type Bindings = {
  DB: D1Database;
  // IMAGES: R2Bucket;
  FIREBASE_PROJECT_ID: string;
};

const app = new Hono<{ Bindings: Bindings }>();

// CORS設定
app.use('*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
}));

// Health check (認証不要)
app.get('/', (c) => c.json({ status: 'ok', service: 'kobutsu-log' }));

app.get('/api/health', (c) => c.json({
  status: 'healthy',
  timestamp: new Date().toISOString()
}));

// 認証付きルート
// /api/auth/* - 認証・登録関連
app.use('/api/auth/*', authMiddleware);
app.route('/api/auth', authRouter);

// /api/users/* - ユーザー情報管理
app.use('/api/users/*', authMiddleware);
app.route('/api/users', usersRouter);

// TODO: /api/transactions/* - 取引管理（Phase 2で実装）
// TODO: /api/upload/* - 画像アップロード（Phase 2で実装）

export default app;
