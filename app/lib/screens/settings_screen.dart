import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kobutsu_log/providers/auth_provider.dart';
import 'package:kobutsu_log/utils/validators.dart';
import 'package:kobutsu_log/widgets/loading_overlay.dart';

/// 設定画面
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: LoadingOverlay(
        isLoading: authState.isLoading,
        child: ListView(
          children: [
            // アカウント情報
            _buildSectionHeader('アカウント'),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('メールアドレス'),
              subtitle: Text(user?.email ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('表示名'),
              subtitle: Text(user?.displayName ?? '未設定'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showEditNameDialog(context),
            ),
            const Divider(),

            // 事業者情報
            _buildSectionHeader('事業者情報'),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('屋号'),
              subtitle: Text(user?.businessName ?? '未設定'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showEditBusinessNameDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.badge),
              title: const Text('古物商許可番号'),
              subtitle: Text(user?.licenseNumber ?? '未設定'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showEditLicenseNumberDialog(context),
            ),
            const Divider(),

            // プラン
            _buildSectionHeader('プラン'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          user?.plan == 'free' ? '無料プラン' : 'プレミアムプラン',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (user?.plan == 'free')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '無料',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.plan == 'free' ? '月50件まで登録可能' : '無制限に登録可能',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (user?.plan == 'free') ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('プレミアムプランは準備中です'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                        child: const Text('プレミアムにアップグレード'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(),

            // その他
            _buildSectionHeader('その他'),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('利用規約'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('利用規約を表示')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('プライバシーポリシー'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('プライバシーポリシーを表示')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('バージョン情報'),
              subtitle: const Text('1.0.0'),
            ),
            const Divider(),

            // ログアウト
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('ログアウト', style: TextStyle(color: Colors.red)),
              onTap: () => _handleLogout(context),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Future<void> _showEditNameDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: ref.read(authStateProvider).user?.displayName ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('表示名を編集'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '表示名',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        await ref.read(authStateProvider.notifier).updateUser(
              displayName: result,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('表示名を更新しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showEditBusinessNameDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: ref.read(authStateProvider).user?.businessName ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('屋号を編集'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '屋号',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        await ref.read(authStateProvider.notifier).updateUser(
              businessName: result,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('屋号を更新しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showEditLicenseNumberDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: ref.read(authStateProvider).user?.licenseNumber ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('古物商許可番号を編集'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '許可番号',
            hintText: '例: 東京都公安委員会 第123456789号',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        await ref.read(authStateProvider.notifier).updateUser(
              licenseNumber: result,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('許可番号を更新しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(authStateProvider.notifier).signOut();

        if (mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
