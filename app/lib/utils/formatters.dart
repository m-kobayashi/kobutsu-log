import 'package:intl/intl.dart';

/// フォーマッター
class Formatters {
  /// 金額フォーマット
  static String currency(int amount) {
    final formatter = NumberFormat('#,###');
    return '¥${formatter.format(amount)}';
  }

  /// 日付フォーマット
  static String date(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  /// 日時フォーマット
  static String dateTime(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
  }

  /// 相対日時フォーマット（例: 今日、昨日、3日前）
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(targetDay).inDays;

    if (difference == 0) {
      return '今日';
    } else if (difference == 1) {
      return '昨日';
    } else if (difference < 7) {
      return '$difference日前';
    } else {
      return DateFormat('MM/dd').format(date);
    }
  }

  /// 取引タイプの表示名
  static String transactionType(String type) {
    switch (type) {
      case 'buy':
        return '買取';
      case 'sell':
        return '販売';
      default:
        return type;
    }
  }

  /// 商品カテゴリの表示名
  static String itemCategory(String? category) {
    if (category == null) return '-';
    const categories = {
      'electronics': '家電・電化製品',
      'fashion': '衣類・ファッション',
      'accessories': 'アクセサリー',
      'furniture': '家具・インテリア',
      'sports': 'スポーツ用品',
      'books': '書籍・メディア',
      'other': 'その他',
    };
    return categories[category] ?? category;
  }

  /// 本人確認方法の表示名
  static String idVerificationType(String type) {
    const types = {
      'drivers_license': '運転免許証',
      'health_insurance': '健康保険証',
      'my_number': 'マイナンバーカード',
      'passport': 'パスポート',
      'residence_card': '在留カード',
      'other': 'その他',
    };
    return types[type] ?? type;
  }
}
