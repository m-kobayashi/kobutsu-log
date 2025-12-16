import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { authMiddleware } from './middleware/auth';
import authRouter from './routes/auth';
import usersRouter from './routes/users';
import transactionsRouter from './routes/transactions';
import statsRouter from './routes/stats';
import uploadRouter from './routes/upload';

type Bindings = {
  DB: D1Database;
  IMAGES: R2Bucket;
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
// /api/auth/* - 認証・登録関連（registerは除く）
app.route('/api/auth', authRouter);

// /api/users/* - ユーザー情報管理
app.use('/api/users/*', authMiddleware);
app.route('/api/users', usersRouter);

// /api/transactions/* - 取引管理
app.use('/api/transactions/*', authMiddleware);
app.route('/api/transactions', transactionsRouter);

// /api/stats/* - 統計情報
app.use('/api/stats/*', authMiddleware);
app.route('/api/stats', statsRouter);

// /api/upload/* - 画像アップロード（画像取得は認証不要、アップロードのみ認証必須）
app.use('/api/upload/image', authMiddleware);
app.route('/api/upload', uploadRouter);

export default app;
