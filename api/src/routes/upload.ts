import { Hono } from 'hono';
import type { Context } from 'hono';

type Bindings = {
  DB: D1Database;
  // IMAGES: R2Bucket; // R2バケットは後で設定
  FIREBASE_PROJECT_ID: string;
};

type Variables = {
  userId: string;
};

const app = new Hono<{ Bindings: Bindings; Variables: Variables }>();

// 画像アップロード
app.post('/image', async (c: Context) => {
  const userId = c.get('userId');

  try {
    // Note: R2バケットの設定が必要
    // 現在はダミーレスポンスを返す
    // 実際の実装では、multipart/form-dataから画像を取得し、R2にアップロードする

    // TODO: R2バケット設定後に実装
    // const formData = await c.req.formData();
    // const file = formData.get('file') as File;
    // const filename = `${userId}/${Date.now()}_${file.name}`;
    // await c.env.IMAGES.put(filename, file.stream());
    // const url = `https://images.kobutsulog.example.com/${filename}`;

    // ダミーレスポンス
    return c.json({
      success: false,
      error: {
        message: 'R2バケットが未設定です。wrangler.tomlでIMAGESバインディングを設定してください。',
      },
    }, 501);
  } catch (error: any) {
    return c.json({
      success: false,
      error: { message: error.message },
    }, 500);
  }
});

export default app;
