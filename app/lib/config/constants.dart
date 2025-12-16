/// アプリケーション設定定数
class AppConstants {
  // API設定
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://kobutsu-log-api.m-kobayashi-v.workers.dev',
  );

  // プラン制限
  static const int freeMonthlyLimit = 50;
  static const int premiumMonthlyLimit = -1; // 無制限

  // 画像設定
  static const int maxImageSizeMB = 1;
  static const int maxImageSizeBytes = maxImageSizeMB * 1024 * 1024;

  // 取引タイプ
  static const String transactionTypeBuy = 'buy';
  static const String transactionTypeSell = 'sell';

  // 本人確認方法
  static const Map<String, String> idVerificationTypes = {
    'drivers_license': '運転免許証',
    'health_insurance': '健康保険証',
    'my_number': 'マイナンバーカード',
    'passport': 'パスポート',
    'residence_card': '在留カード',
    'other': 'その他',
  };

  // 商品カテゴリ
  static const List<String> itemCategories = [
    'electronics',
    'fashion',
    'accessories',
    'furniture',
    'sports',
    'books',
    'other',
  ];

  static const Map<String, String> itemCategoryLabels = {
    'electronics': '家電・電化製品',
    'fashion': '衣類・ファッション',
    'accessories': 'アクセサリー',
    'furniture': '家具・インテリア',
    'sports': 'スポーツ用品',
    'books': '書籍・メディア',
    'other': 'その他',
  };
}
