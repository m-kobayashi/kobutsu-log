import { Hono } from 'hono';
import type { Context } from 'hono';

type Bindings = {
  DB: D1Database;
  FIREBASE_PROJECT_ID: string;
};

type Variables = {
  userId: string;
};

const app = new Hono<{ Bindings: Bindings; Variables: Variables }>();

// 月次統計取得
app.get('/monthly', async (c: Context) => {
  const userId = c.get('userId');
  const year = c.req.query('year') || new Date().getFullYear().toString();
  const month = c.req.query('month') || (new Date().getMonth() + 1).toString();

  try {
    const { results } = await c.env.DB.prepare(`
      SELECT
        COUNT(*) as count,
        SUM(CASE WHEN transaction_type = 'buy' THEN 1 ELSE 0 END) as buy_count,
        SUM(CASE WHEN transaction_type = 'sell' THEN 1 ELSE 0 END) as sell_count,
        SUM(CASE WHEN transaction_type = 'buy' THEN price ELSE 0 END) as buy_total,
        SUM(CASE WHEN transaction_type = 'sell' THEN price ELSE 0 END) as sell_total
      FROM transactions
      WHERE user_id = ?
      AND strftime('%Y', transaction_date) = ?
      AND strftime('%m', transaction_date) = ?
    `).bind(userId, year, month.padStart(2, '0')).all();

    return c.json({
      success: true,
      data: results[0] || {
        count: 0,
        buy_count: 0,
        sell_count: 0,
        buy_total: 0,
        sell_total: 0,
      },
    });
  } catch (error: any) {
    return c.json({
      success: false,
      error: { message: error.message },
    }, 500);
  }
});

export default app;
