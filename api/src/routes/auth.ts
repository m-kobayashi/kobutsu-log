import { Hono } from 'hono';
import { successResponse, errorResponse, validationErrorResponse } from '../utils/response';
import { nanoid } from 'nanoid';

type Bindings = {
  DB: D1Database;
  FIREBASE_PROJECT_ID: string;
};

type Variables = {
  firebaseUid?: string;
  userEmail?: string;
};

const authRouter = new Hono<{ Bindings: Bindings; Variables: Variables }>();

/**
 * POST /api/auth/register
 * ユーザー登録API
 *
 * Firebase Authenticationで認証済みのユーザーをD1データベースに登録
 * 注意: このエンドポイントは認証ミドルウェアを通さず、手動でトークン検証を行う
 */
authRouter.post('/register', async (c) => {
  try {
    // トークンを手動で検証
    const authHeader = c.req.header('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return errorResponse(c, 'Authorization header required', 401);
    }

    const token = authHeader.substring(7);
    const parts = token.split('.');
    if (parts.length !== 3) {
      return errorResponse(c, 'Invalid token format', 401);
    }

    const payload = JSON.parse(atob(parts[1].replace(/-/g, '+').replace(/_/g, '/')));
    const firebaseUid = payload.sub as string;
    const userEmail = payload.email as string;

    if (!firebaseUid || !userEmail) {
      return errorResponse(c, 'Authentication required', 401);
    }

    // リクエストボディの取得
    const body = await c.req.json();
    const { display_name, business_name, license_number } = body;

    // バリデーション
    const errors: Record<string, string> = {};

    if (!userEmail || typeof userEmail !== 'string') {
      errors.email = 'Valid email is required';
    }

    if (display_name && typeof display_name !== 'string') {
      errors.display_name = 'Display name must be a string';
    }

    if (business_name && typeof business_name !== 'string') {
      errors.business_name = 'Business name must be a string';
    }

    if (license_number && typeof license_number !== 'string') {
      errors.license_number = 'License number must be a string';
    }

    if (Object.keys(errors).length > 0) {
      return validationErrorResponse(c, errors);
    }

    // 既存ユーザーチェック
    const existingUser = await c.env.DB.prepare(
      'SELECT id FROM users WHERE firebase_uid = ?'
    )
      .bind(firebaseUid)
      .first();

    if (existingUser) {
      return errorResponse(c, 'User already registered', 409);
    }

    // ユーザーID生成
    const userId = `user_${nanoid(16)}`;
    const now = new Date().toISOString();

    // ユーザー登録
    await c.env.DB.prepare(
      `INSERT INTO users (id, firebase_uid, email, display_name, business_name, license_number, plan, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
      .bind(
        userId,
        firebaseUid,
        userEmail,
        display_name || null,
        business_name || null,
        license_number || null,
        'free',
        now,
        now
      )
      .run();

    // 登録されたユーザー情報を取得
    const user = await c.env.DB.prepare(
      'SELECT id, firebase_uid, email, display_name, business_name, license_number, plan, created_at FROM users WHERE id = ?'
    )
      .bind(userId)
      .first();

    return successResponse(c, {
      user,
    }, 201);
  } catch (error) {
    console.error('Registration error:', error);
    return errorResponse(c, 'Failed to register user', 500);
  }
});

/**
 * POST /api/auth/verify
 * トークン検証API（デバッグ用）
 * 注意: このエンドポイントは /api/auth/* ミドルウェアを経由しないため、手動検証が必要
 */
authRouter.post('/verify', async (c) => {
  // 簡易トークン検証（本来はミドルウェアと同じ処理）
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return errorResponse(c, 'Authorization header required', 401);
  }

  const token = authHeader.substring(7);
  const parts = token.split('.');
  if (parts.length !== 3) {
    return errorResponse(c, 'Invalid token format', 401);
  }

  const payload = JSON.parse(atob(parts[1].replace(/-/g, '+').replace(/_/g, '/')));
  const firebaseUid = payload.sub as string;
  const userEmail = payload.email as string;

  if (!firebaseUid) {
    return errorResponse(c, 'Invalid token', 401);
  }

  return successResponse(c, {
    firebase_uid: firebaseUid,
    email: userEmail,
  });
});

export default authRouter;
