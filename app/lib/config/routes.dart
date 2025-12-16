import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kobutsu_log/providers/auth_provider.dart';
import 'package:kobutsu_log/screens/login_screen.dart';
import 'package:kobutsu_log/screens/register_screen.dart';
import 'package:kobutsu_log/screens/home_screen.dart';
import 'package:kobutsu_log/screens/transaction_form_screen.dart';
import 'package:kobutsu_log/screens/settings_screen.dart';

/// ルーター設定
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      if (isLoggedIn && isLoggingIn) {
        return '/';
      }
      return null;
    },
    routes: [
      // ログイン画面
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // 新規登録画面
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ホーム画面
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),

      // 取引登録画面
      GoRoute(
        path: '/transactions/new',
        builder: (context, state) => const TransactionFormScreen(),
      ),

      // 取引編集画面
      GoRoute(
        path: '/transactions/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TransactionFormScreen(transactionId: id);
        },
      ),

      // 設定画面
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
