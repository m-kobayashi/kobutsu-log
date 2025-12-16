import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kobutsu_log/providers/auth_provider.dart';
import 'package:kobutsu_log/providers/transaction_provider.dart';
import 'package:kobutsu_log/widgets/transaction_card.dart';
import 'package:kobutsu_log/config/constants.dart';

/// ホーム画面（取引一覧）
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(transactionListProvider.notifier).loadMore();
    }
  }

  Future<void> _handleRefresh() async {
    await ref.read(transactionListProvider.notifier).refresh();
  }

  void _handleSearch(String query) {
    ref.read(transactionListProvider.notifier).search(query);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final transactionState = ref.watch(transactionListProvider);
    final theme = Theme.of(context);

    // 月次統計を取得
    final now = DateTime.now();
    final monthlyStats = ref.watch(
      monthlyStatsProvider((now.year, now.month)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('コブツログ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 検索バー
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '品名や相手方で検索',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _handleSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: _handleSearch,
            ),
          ),

          // 月次統計
          monthlyStats.when(
            data: (stats) {
              final count = stats['count'] as int? ?? 0;
              final limit = authState.user?.plan == 'free'
                  ? AppConstants.freeMonthlyLimit
                  : AppConstants.premiumMonthlyLimit;
              final percentage = limit > 0 ? (count / limit * 100).clamp(0, 100) : 0.0;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '今月の登録件数',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          '$count件 / ${limit > 0 ? "$limit件" : "無制限"}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (limit > 0) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 8,
                          backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            percentage >= 90
                                ? Colors.red
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // 取引一覧
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: transactionState.transactions.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: transactionState.transactions.length +
                          (transactionState.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= transactionState.transactions.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final transaction = transactionState.transactions[index];
                        return TransactionCard(
                          transaction: transaction,
                          onTap: () {
                            context.push('/transactions/${transaction.id}');
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push('/transactions/new');
          if (result == true) {
            _handleRefresh();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('新規登録'),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '取引が登録されていません',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '右下のボタンから新規登録できます',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
