import { Hono } from 'hono';
import type { Context } from 'hono';

type Bindings = {
  DB: D1Database;
  FIREBASE_PROJECT_ID: string;
};

type Variables = {
  userId: string;
  userPlan: string;
};

const app = new Hono<{ Bindings: Bindings; Variables: Variables }>();

// 取引一覧取得
app.get('/', async (c: Context) => {
  const userId = c.get('userId');
  const page = parseInt(c.req.query('page') || '1');
  const limit = parseInt(c.req.query('limit') || '20');
  const search = c.req.query('search') || '';
  const offset = (page - 1) * limit;

  try {
    let query = `
      SELECT * FROM transactions
      WHERE user_id = ?
    `;
    const params: any[] = [userId];

    // 検索条件
    if (search) {
      query += ` AND (item_name LIKE ? OR counterparty_name LIKE ?)`;
      params.push(`%${search}%`, `%${search}%`);
    }

    query += ` ORDER BY transaction_date DESC LIMIT ? OFFSET ?`;
    params.push(limit, offset);

    const { results } = await c.env.DB.prepare(query).bind(...params).all();

    return c.json({
      success: true,
      data: results,
      pagination: {
        page,
        limit,
        hasMore: results.length === limit,
      },
    });
  } catch (error: any) {
    return c.json({
      success: false,
      error: { message: error.message },
    }, 500);
  }
});

// 取引詳細取得
app.get('/:id', async (c: Context) => {
  const userId = c.get('userId');
  const id = c.req.param('id');

  try {
    const { results } = await c.env.DB.prepare(
      'SELECT * FROM transactions WHERE id = ? AND user_id = ?'
    ).bind(id, userId).all();

    if (!results || results.length === 0) {
      return c.json({
        success: false,
        error: { message: '取引が見つかりません' },
      }, 404);
    }

    return c.json({
      success: true,
      data: results[0],
    });
  } catch (error: any) {
    return c.json({
      success: false,
      error: { message: error.message },
    }, 500);
  }
});

// 取引登録
app.post('/', async (c: Context) => {
  const userId = c.get('userId');
  const userPlan = c.get('userPlan');

  try {
    const body = await c.req.json();

    // プラン制限チェック（無料プラン: 月50件）
    if (userPlan === 'free') {
      const now = new Date();
      const year = now.getFullYear();
      const month = now.getMonth() + 1;

      const { results: stats } = await c.env.DB.prepare(`
        SELECT COUNT(*) as count
        FROM transactions
        WHERE user_id = ?
        AND strftime('%Y', transaction_date) = ?
        AND strftime('%m', transaction_date) = ?
      `).bind(userId, year.toString(), month.toString().padStart(2, '0')).all();

      const count = stats[0]?.count || 0;
      if (count >= 50) {
        return c.json({
          success: false,
          error: { message: '月間登録上限（50件）に達しました' },
        }, 429);
      }
    }

    // バリデーション
    const requiredFields = [
      'transaction_type',
      'item_name',
      'price',
      'transaction_date',
      'counterparty_name',
      'counterparty_address',
      'id_verification_type',
    ];

    for (const field of requiredFields) {
      if (!body[field]) {
        return c.json({
          success: false,
          error: { message: `${field}は必須項目です` },
        }, 400);
      }
    }

    // IDを生成（UUIDv4相当）
    const id = crypto.randomUUID();
    const now = new Date().toISOString();

    // 取引を登録
    await c.env.DB.prepare(`
      INSERT INTO transactions (
        id, user_id, transaction_type, item_name, item_category,
        quantity, price, transaction_date,
        counterparty_name, counterparty_address, counterparty_age, counterparty_occupation,
        id_verification_type, id_verification_number,
        photo_url, notes, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      id,
      userId,
      body.transaction_type,
      body.item_name,
      body.item_category || null,
      body.quantity || 1,
      body.price,
      body.transaction_date,
      body.counterparty_name,
      body.counterparty_address,
      body.counterparty_age || null,
      body.counterparty_occupation || null,
      body.id_verification_type,
      body.id_verification_number || null,
      body.photo_url || null,
      body.notes || null,
      now,
      now
    ).run();

    // 登録したデータを取得
    const { results } = await c.env.DB.prepare(
      'SELECT * FROM transactions WHERE id = ?'
    ).bind(id).all();

    return c.json({
      success: true,
      data: results[0],
    }, 201);
  } catch (error: any) {
    return c.json({
      success: false,
      error: { message: error.message },
    }, 500);
  }
});

// 取引更新
app.put('/:id', async (c: Context) => {
  const userId = c.get('userId');
  const id = c.req.param('id');

  try {
    const body = await c.req.json();

    // 存在確認
    const { results: existing } = await c.env.DB.prepare(
      'SELECT id FROM transactions WHERE id = ? AND user_id = ?'
    ).bind(id, userId).all();

    if (!existing || existing.length === 0) {
      return c.json({
        success: false,
        error: { message: '取引が見つかりません' },
      }, 404);
    }

    const now = new Date().toISOString();

    // 更新
    await c.env.DB.prepare(`
      UPDATE transactions SET
        transaction_type = ?,
        item_name = ?,
        item_category = ?,
        quantity = ?,
        price = ?,
        transaction_date = ?,
        counterparty_name = ?,
        counterparty_address = ?,
        counterparty_age = ?,
        counterparty_occupation = ?,
        id_verification_type = ?,
        id_verification_number = ?,
        photo_url = ?,
        notes = ?,
        updated_at = ?
      WHERE id = ? AND user_id = ?
    `).bind(
      body.transaction_type,
      body.item_name,
      body.item_category || null,
      body.quantity || 1,
      body.price,
      body.transaction_date,
      body.counterparty_name,
      body.counterparty_address,
      body.counterparty_age || null,
      body.counterparty_occupation || null,
      body.id_verification_type,
      body.id_verification_number || null,
      body.photo_url || null,
      body.notes || null,
      now,
      id,
      userId
    ).run();

    // 更新後のデータを取得
    const { results } = await c.env.DB.prepare(
      'SELECT * FROM transactions WHERE id = ?'
    ).bind(id).all();

    return c.json({
      success: true,
      data: results[0],
    });
  } catch (error: any) {
    return c.json({
      success: false,
      error: { message: error.message },
    }, 500);
  }
});

// 取引削除
app.delete('/:id', async (c: Context) => {
  const userId = c.get('userId');
  const id = c.req.param('id');

  try {
    // 存在確認
    const { results: existing } = await c.env.DB.prepare(
      'SELECT id FROM transactions WHERE id = ? AND user_id = ?'
    ).bind(id, userId).all();

    if (!existing || existing.length === 0) {
      return c.json({
        success: false,
        error: { message: '取引が見つかりません' },
      }, 404);
    }

    // 削除
    await c.env.DB.prepare(
      'DELETE FROM transactions WHERE id = ? AND user_id = ?'
    ).bind(id, userId).run();

    return c.json({
      success: true,
      message: '取引を削除しました',
    });
  } catch (error: any) {
    return c.json({
      success: false,
      error: { message: error.message },
    }, 500);
  }
});

export default app;
