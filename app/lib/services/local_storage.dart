import 'package:hive_flutter/hive_flutter.dart';
import 'package:kobutsu_log/models/user.dart';
import 'package:kobutsu_log/models/transaction.dart';

/// ローカルストレージサービス（Hive）
class LocalStorageService {
  static const String _userBoxName = 'user';
  static const String _transactionBoxName = 'transactions';
  static const String _settingsBoxName = 'settings';

  Box<User>? _userBox;
  Box<Transaction>? _transactionBox;
  Box<dynamic>? _settingsBox;

  /// 初期化
  Future<void> init() async {
    await Hive.initFlutter();

    // アダプターを登録
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionAdapter());
    }

    // Boxを開く
    _userBox = await Hive.openBox<User>(_userBoxName);
    _transactionBox = await Hive.openBox<Transaction>(_transactionBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  // ========== ユーザー関連 ==========

  /// ユーザー情報を保存
  Future<void> saveUser(User user) async {
    await _userBox?.put('current', user);
  }

  /// ユーザー情報を取得
  User? getUser() {
    return _userBox?.get('current');
  }

  /// ユーザー情報を削除
  Future<void> deleteUser() async {
    await _userBox?.delete('current');
  }

  // ========== 取引関連 ==========

  /// 取引を保存
  Future<void> saveTransaction(Transaction transaction) async {
    await _transactionBox?.put(transaction.id, transaction);
  }

  /// 取引を一括保存
  Future<void> saveTransactions(List<Transaction> transactions) async {
    final map = {for (var t in transactions) t.id: t};
    await _transactionBox?.putAll(map);
  }

  /// 取引を取得
  Transaction? getTransaction(String id) {
    return _transactionBox?.get(id);
  }

  /// 全取引を取得
  List<Transaction> getAllTransactions() {
    return _transactionBox?.values.toList() ?? [];
  }

  /// 未同期の取引を取得
  List<Transaction> getPendingSyncTransactions() {
    return _transactionBox?.values.where((t) => t.pendingSync).toList() ?? [];
  }

  /// 取引を削除
  Future<void> deleteTransaction(String id) async {
    await _transactionBox?.delete(id);
  }

  /// 全取引を削除
  Future<void> clearTransactions() async {
    await _transactionBox?.clear();
  }

  /// 取引を検索
  List<Transaction> searchTransactions(String query) {
    if (query.isEmpty) return getAllTransactions();

    final lowerQuery = query.toLowerCase();
    return _transactionBox?.values.where((t) {
          return t.itemName.toLowerCase().contains(lowerQuery) ||
              t.counterpartyName.toLowerCase().contains(lowerQuery);
        }).toList() ??
        [];
  }

  /// 月次取引を取得
  List<Transaction> getMonthlyTransactions(int year, int month) {
    return _transactionBox?.values.where((t) {
          return t.transactionDate.year == year && t.transactionDate.month == month;
        }).toList() ??
        [];
  }

  // ========== 設定関連 ==========

  /// 設定値を保存
  Future<void> setSetting(String key, dynamic value) async {
    await _settingsBox?.put(key, value);
  }

  /// 設定値を取得
  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox?.get(key, defaultValue: defaultValue) as T?;
  }

  /// 設定値を削除
  Future<void> deleteSetting(String key) async {
    await _settingsBox?.delete(key);
  }

  /// 全設定をクリア
  Future<void> clearSettings() async {
    await _settingsBox?.clear();
  }

  // ========== 全データクリア ==========

  /// 全データを削除（ログアウト時など）
  Future<void> clearAll() async {
    await Future.wait([
      _userBox?.clear() ?? Future.value(),
      _transactionBox?.clear() ?? Future.value(),
      _settingsBox?.clear() ?? Future.value(),
    ]);
  }

  /// Boxを閉じる
  Future<void> close() async {
    await Future.wait([
      _userBox?.close() ?? Future.value(),
      _transactionBox?.close() ?? Future.value(),
      _settingsBox?.close() ?? Future.value(),
    ]);
  }
}
