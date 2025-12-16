import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kobutsu_log/models/transaction.dart';
import 'package:kobutsu_log/services/api_service.dart';
import 'package:kobutsu_log/services/local_storage.dart';
import 'package:kobutsu_log/providers/auth_provider.dart';

/// 取引一覧プロバイダー
final transactionListProvider = StateNotifierProvider<TransactionListNotifier, TransactionListState>((ref) {
  return TransactionListNotifier(
    ref.read(apiServiceProvider),
    ref.read(localStorageServiceProvider),
  );
});

/// 月次統計プロバイダー
final monthlyStatsProvider = FutureProvider.family<Map<String, dynamic>, (int, int)>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  final (year, month) = params;
  return await apiService.getMonthlyStats(year: year, month: month);
});

/// 取引一覧の状態
class TransactionListState {
  final List<Transaction> transactions;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final String searchQuery;

  TransactionListState({
    this.transactions = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.searchQuery = '',
  });

  TransactionListState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    bool? hasMore,
    String? error,
    String? searchQuery,
  }) {
    return TransactionListState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// 取引一覧管理
class TransactionListNotifier extends StateNotifier<TransactionListState> {
  final ApiService _apiService;
  final LocalStorageService _localStorage;
  int _currentPage = 1;

  TransactionListNotifier(this._apiService, this._localStorage)
      : super(TransactionListState()) {
    _init();
  }

  /// 初期化
  Future<void> _init() async {
    // ローカルストレージから取引を読み込み
    final transactions = _localStorage.getAllTransactions();
    state = state.copyWith(transactions: transactions);

    // サーバーから最新データを取得
    await refresh();
  }

  /// データを更新
  Future<void> refresh() async {
    _currentPage = 1;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final transactions = await _apiService.getTransactions(page: 1);
      await _localStorage.saveTransactions(transactions);

      state = state.copyWith(
        transactions: transactions,
        isLoading: false,
        hasMore: transactions.length >= 20,
      );
    } catch (e) {
      // オフライン時はローカルデータを使用
      final localTransactions = _localStorage.getAllTransactions();
      state = state.copyWith(
        transactions: localTransactions,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 次のページを読み込み
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    _currentPage++;

    try {
      final newTransactions = await _apiService.getTransactions(page: _currentPage);

      if (newTransactions.isEmpty) {
        state = state.copyWith(isLoading: false, hasMore: false);
        return;
      }

      await _localStorage.saveTransactions(newTransactions);

      state = state.copyWith(
        transactions: [...state.transactions, ...newTransactions],
        isLoading: false,
        hasMore: newTransactions.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 検索
  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query, isLoading: true);

    try {
      if (query.isEmpty) {
        await refresh();
      } else {
        final transactions = await _apiService.getTransactions(search: query);
        state = state.copyWith(
          transactions: transactions,
          isLoading: false,
          hasMore: false,
        );
      }
    } catch (e) {
      // オフライン時はローカル検索
      final localResults = _localStorage.searchTransactions(query);
      state = state.copyWith(
        transactions: localResults,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 取引を作成
  Future<void> createTransaction(Transaction transaction) async {
    try {
      final created = await _apiService.createTransaction(transaction);
      await _localStorage.saveTransaction(created);

      // リストの先頭に追加
      state = state.copyWith(
        transactions: [created, ...state.transactions],
      );
    } catch (e) {
      // オフライン時はローカルに保存（同期フラグ付き）
      final pendingTransaction = transaction.copyWith(pendingSync: true);
      await _localStorage.saveTransaction(pendingTransaction);

      state = state.copyWith(
        transactions: [pendingTransaction, ...state.transactions],
        error: 'オフライン: 後で同期されます',
      );
    }
  }

  /// 取引を更新
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      final updated = await _apiService.updateTransaction(transaction);
      await _localStorage.saveTransaction(updated);

      final updatedList = state.transactions.map((t) {
        return t.id == updated.id ? updated : t;
      }).toList();

      state = state.copyWith(transactions: updatedList);
    } catch (e) {
      // オフライン時はローカルに保存
      final pendingTransaction = transaction.copyWith(pendingSync: true);
      await _localStorage.saveTransaction(pendingTransaction);

      final updatedList = state.transactions.map((t) {
        return t.id == transaction.id ? pendingTransaction : t;
      }).toList();

      state = state.copyWith(
        transactions: updatedList,
        error: 'オフライン: 後で同期されます',
      );
    }
  }

  /// 取引を削除
  Future<void> deleteTransaction(String id) async {
    try {
      await _apiService.deleteTransaction(id);
      await _localStorage.deleteTransaction(id);

      state = state.copyWith(
        transactions: state.transactions.where((t) => t.id != id).toList(),
      );
    } catch (e) {
      // オフライン時はローカルから削除のみ
      await _localStorage.deleteTransaction(id);

      state = state.copyWith(
        transactions: state.transactions.where((t) => t.id != id).toList(),
        error: 'オフライン: 削除は後で同期されます',
      );
    }
  }

  /// 未同期の取引を同期
  Future<void> syncPendingTransactions() async {
    final pending = _localStorage.getPendingSyncTransactions();

    for (final transaction in pending) {
      try {
        final synced = await _apiService.createTransaction(transaction);

        // ローカルの同期フラグを解除
        final updated = synced.copyWith(pendingSync: false);
        await _localStorage.saveTransaction(updated);
      } catch (e) {
        // 同期失敗時はスキップ
        continue;
      }
    }

    await refresh();
  }
}
