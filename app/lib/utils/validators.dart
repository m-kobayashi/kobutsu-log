/// バリデーター
class Validators {
  /// メールアドレスバリデーション
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'メールアドレスを入力してください';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return '有効なメールアドレスを入力してください';
    }
    return null;
  }

  /// パスワードバリデーション
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'パスワードを入力してください';
    }
    if (value.length < 6) {
      return 'パスワードは6文字以上で入力してください';
    }
    return null;
  }

  /// 必須項目バリデーション
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'この項目'}を入力してください';
    }
    return null;
  }

  /// 数値バリデーション
  static String? number(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? '数値'}を入力してください';
    }
    if (int.tryParse(value) == null) {
      return '有効な数値を入力してください';
    }
    return null;
  }

  /// 正の数値バリデーション
  static String? positiveNumber(String? value, {String? fieldName}) {
    final error = number(value, fieldName: fieldName);
    if (error != null) return error;

    final num = int.parse(value!);
    if (num <= 0) {
      return '0より大きい数値を入力してください';
    }
    return null;
  }

  /// 年齢バリデーション
  static String? age(String? value) {
    if (value == null || value.isEmpty) {
      return null; // 年齢は任意項目
    }
    final ageNum = int.tryParse(value);
    if (ageNum == null) {
      return '有効な年齢を入力してください';
    }
    if (ageNum < 0 || ageNum > 150) {
      return '0〜150の範囲で入力してください';
    }
    return null;
  }
}
