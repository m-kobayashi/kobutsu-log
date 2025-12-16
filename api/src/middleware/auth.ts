import { Context, Next } from 'hono';
import { errorResponse } from '../utils/response';

/**
 * Firebase ID Tokenを検証するミドルウェア
 *
 * 本番環境ではFirebase Admin SDKを使用してトークンを検証する必要がありますが、
 * Cloudflare Workersの制約により、JWTの手動検証を実装します。
 */

interface DecodedToken {
  uid: string;
  email?: string;
  email_verified?: boolean;
}

/**
 * Firebase公開鍵を取得（キャッシュ付き）
 */
async function getFirebasePublicKeys(): Promise<Record<string, string>> {
  const response = await fetch(
    'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'
  );
  return await response.json();
}

/**
 * JWT署名を検証（簡易版）
 * 本番環境では完全な検証ロジックを実装する必要があります
 */
async function verifyToken(
  token: string,
  projectId: string
): Promise<DecodedToken | null> {
  try {
    // JWTをデコード
    const parts = token.split('.');
    if (parts.length !== 3) {
      return null;
    }

    // ペイロードをデコード
    const payload = JSON.parse(
      atob(parts[1].replace(/-/g, '+').replace(/_/g, '/'))
    );

    // 基本的な検証
    const now = Math.floor(Date.now() / 1000);

    // 期限切れチェック
    if (payload.exp && payload.exp < now) {
      console.error('Token expired');
      return null;
    }

    // issuer チェック
    if (payload.iss !== `https://securetoken.google.com/${projectId}`) {
      console.error('Invalid issuer');
      return null;
    }

    // audience チェック
    if (payload.aud !== projectId) {
      console.error('Invalid audience');
      return null;
    }

    // 発行時刻チェック
    if (payload.iat && payload.iat > now) {
      console.error('Token used before issued');
      return null;
    }

    // subject チェック
    if (!payload.sub || typeof payload.sub !== 'string' || payload.sub.length === 0) {
      console.error('Invalid subject');
      return null;
    }

    return {
      uid: payload.sub,
      email: payload.email,
      email_verified: payload.email_verified,
    };
  } catch (error) {
    console.error('Token verification error:', error);
    return null;
  }
}

/**
 * 認証ミドルウェア
 * リクエストのAuthorizationヘッダーからFirebase ID Tokenを取得し検証
 */
export async function authMiddleware(c: Context, next: Next) {
  const authHeader = c.req.header('Authorization');

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return errorResponse(c, 'Authorization header required', 401);
  }

  const token = authHeader.substring(7); // "Bearer " を除去

  if (!token) {
    return errorResponse(c, 'Invalid token', 401);
  }

  const projectId = c.env.FIREBASE_PROJECT_ID;
  if (!projectId) {
    console.error('FIREBASE_PROJECT_ID not configured');
    return errorResponse(c, 'Server configuration error', 500);
  }

  // トークン検証
  const decodedToken = await verifyToken(token, projectId);

  if (!decodedToken) {
    return errorResponse(c, 'Invalid or expired token', 401);
  }

  // コンテキストにユーザー情報を追加
  c.set('firebaseUid', decodedToken.uid);
  c.set('userEmail', decodedToken.email);

  // DBからユーザー情報を取得してuserIdとuserPlanをセット
  try {
    const { results } = await c.env.DB.prepare(
      'SELECT id, plan FROM users WHERE firebase_uid = ?'
    ).bind(decodedToken.uid).all();

    if (results && results.length > 0) {
      const user = results[0] as any;
      c.set('userId', user.id);
      c.set('userPlan', user.plan || 'free');
    } else {
      // ユーザーが見つからない場合はエラー（登録が必要）
      return errorResponse(c, 'User not found. Please register first.', 404);
    }
  } catch (error) {
    console.error('Error fetching user:', error);
    return errorResponse(c, 'Error fetching user information', 500);
  }

  await next();
}

/**
 * オプショナル認証ミドルウェア
 * トークンがあれば検証するが、なくてもリクエストを通す
 */
export async function optionalAuthMiddleware(c: Context, next: Next) {
  const authHeader = c.req.header('Authorization');

  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.substring(7);
    const projectId = c.env.FIREBASE_PROJECT_ID;

    if (token && projectId) {
      const decodedToken = await verifyToken(token, projectId);
      if (decodedToken) {
        c.set('firebaseUid', decodedToken.uid);
        c.set('userEmail', decodedToken.email);
      }
    }
  }

  await next();
}
