import { Context } from 'hono';

/**
 * API成功レスポンスのヘルパー関数
 */
export function successResponse(c: Context, data: any, status: number = 200) {
  return c.json({
    success: true,
    data,
  }, status);
}

/**
 * APIエラーレスポンスのヘルパー関数
 */
export function errorResponse(c: Context, message: string, status: number = 400) {
  return c.json({
    success: false,
    error: {
      message,
    },
  }, status);
}

/**
 * バリデーションエラーレスポンスのヘルパー関数
 */
export function validationErrorResponse(c: Context, errors: Record<string, string>) {
  return c.json({
    success: false,
    error: {
      message: 'Validation failed',
      fields: errors,
    },
  }, 400);
}
