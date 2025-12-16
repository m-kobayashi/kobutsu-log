import { Hono } from 'hono';
import { successResponse, errorResponse, validationErrorResponse } from '../utils/response';

type Bindings = {
  DB: D1Database;
  FIREBASE_PROJECT_ID: string;
};

const usersRouter = new Hono<{ Bindings: Bindings }>();

/**
 * GET /api/users/me
 * ログイン中のユーザー情報を取得
 */
usersRouter.get('/me', async (c) => {
  try {
    const firebaseUid = c.get('firebaseUid') as string;

    if (!firebaseUid) {
      return errorResponse(c, 'Authentication required', 401);
    }

    // ユーザー情報を取得
    const user = await c.env.DB.prepare(
      `SELECT id, firebase_uid, email, display_name, business_name, license_number, plan, created_at, updated_at
       FROM users
       WHERE firebase_uid = ?`
    )
      .bind(firebaseUid)
      .first();

    if (!user) {
      return errorResponse(c, 'User not found', 404);
    }

    return successResponse(c, { user });
  } catch (error) {
    console.error('Get user error:', error);
    return errorResponse(c, 'Failed to fetch user information', 500);
  }
});

/**
 * PUT /api/users/me
 * ログイン中のユーザー情報を更新
 */
usersRouter.put('/me', async (c) => {
  try {
    const firebaseUid = c.get('firebaseUid') as string;

    if (!firebaseUid) {
      return errorResponse(c, 'Authentication required', 401);
    }

    // 既存ユーザーの確認
    const existingUser = await c.env.DB.prepare(
      'SELECT id FROM users WHERE firebase_uid = ?'
    )
      .bind(firebaseUid)
      .first();

    if (!existingUser) {
      return errorResponse(c, 'User not found', 404);
    }

    // リクエストボディの取得
    const body = await c.req.json();
    const { display_name, business_name, license_number } = body;

    // バリデーション
    const errors: Record<string, string> = {};

    if (display_name !== undefined && typeof display_name !== 'string') {
      errors.display_name = 'Display name must be a string';
    }

    if (business_name !== undefined && typeof business_name !== 'string') {
      errors.business_name = 'Business name must be a string';
    }

    if (license_number !== undefined && typeof license_number !== 'string') {
      errors.license_number = 'License number must be a string';
    }

    if (Object.keys(errors).length > 0) {
      return validationErrorResponse(c, errors);
    }

    // 更新するフィールドを動的に構築
    const updates: string[] = [];
    const values: any[] = [];

    if (display_name !== undefined) {
      updates.push('display_name = ?');
      values.push(display_name || null);
    }

    if (business_name !== undefined) {
      updates.push('business_name = ?');
      values.push(business_name || null);
    }

    if (license_number !== undefined) {
      updates.push('license_number = ?');
      values.push(license_number || null);
    }

    if (updates.length === 0) {
      return errorResponse(c, 'No fields to update', 400);
    }

    // updated_at を常に更新
    updates.push('updated_at = ?');
    values.push(new Date().toISOString());

    // WHERE句のパラメータを追加
    values.push(firebaseUid);

    // ユーザー情報を更新
    await c.env.DB.prepare(
      `UPDATE users SET ${updates.join(', ')} WHERE firebase_uid = ?`
    )
      .bind(...values)
      .run();

    // 更新後のユーザー情報を取得
    const updatedUser = await c.env.DB.prepare(
      `SELECT id, firebase_uid, email, display_name, business_name, license_number, plan, created_at, updated_at
       FROM users
       WHERE firebase_uid = ?`
    )
      .bind(firebaseUid)
      .first();

    return successResponse(c, { user: updatedUser });
  } catch (error) {
    console.error('Update user error:', error);
    return errorResponse(c, 'Failed to update user information', 500);
  }
});

/**
 * GET /api/users/stats
 * ユーザーの統計情報を取得（月間登録件数など）
 */
usersRouter.get('/stats', async (c) => {
  try {
    const firebaseUid = c.get('firebaseUid') as string;

    if (!firebaseUid) {
      return errorResponse(c, 'Authentication required', 401);
    }

    // ユーザーIDを取得
    const user = await c.env.DB.prepare(
      'SELECT id, plan FROM users WHERE firebase_uid = ?'
    )
      .bind(firebaseUid)
      .first();

    if (!user) {
      return errorResponse(c, 'User not found', 404);
    }

    // 今月の開始日時を計算
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();

    // 今月の取引件数を取得
    const monthlyCount = await c.env.DB.prepare(
      `SELECT COUNT(*) as count
       FROM transactions
       WHERE user_id = ? AND created_at >= ?`
    )
      .bind(user.id, monthStart)
      .first();

    // 全取引件数を取得
    const totalCount = await c.env.DB.prepare(
      `SELECT COUNT(*) as count
       FROM transactions
       WHERE user_id = ?`
    )
      .bind(user.id)
      .first();

    // プラン制限
    const planLimits: Record<string, number> = {
      free: 50,
      premium: -1, // 無制限
    };

    const limit = planLimits[user.plan as string] || 50;

    return successResponse(c, {
      stats: {
        monthly_count: monthlyCount?.count || 0,
        total_count: totalCount?.count || 0,
        monthly_limit: limit,
        plan: user.plan,
      },
    });
  } catch (error) {
    console.error('Get stats error:', error);
    return errorResponse(c, 'Failed to fetch statistics', 500);
  }
});

export default usersRouter;
