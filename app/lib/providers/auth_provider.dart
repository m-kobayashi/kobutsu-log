import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kobutsu_log/services/auth_service.dart';
import 'package:kobutsu_log/services/api_service.dart';
import 'package:kobutsu_log/services/local_storage.dart';
import 'package:kobutsu_log/models/user.dart' as models;

/// AuthServiceプロバイダー
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// LocalStorageServiceプロバイダー
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

/// Firebase認証状態プロバイダー
final firebaseAuthStateProvider = StreamProvider<firebase.User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// IDトークンプロバイダー
final idTokenProvider = FutureProvider<String?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getIdToken();
});

/// ApiServiceプロバイダー
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(() {
    // 空文字を返す（インターセプターで非同期取得）
    return '';
  });
});

/// 認証状態管理プロバイダー
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(
    ref.read(authServiceProvider),
    ref.read(apiServiceProvider),
    ref.read(localStorageServiceProvider),
  );
});

/// 認証状態
class AuthState {
  final bool isLoading;
  final models.User? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    models.User? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

/// 認証状態管理
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final ApiService _apiService;
  final LocalStorageService _localStorage;

  AuthStateNotifier(
    this._authService,
    this._apiService,
    this._localStorage,
  ) : super(AuthState()) {
    _init();
  }

  /// 初期化
  Future<void> _init() async {
    // ローカルストレージからユーザー情報を読み込み
    final user = _localStorage.getUser();
    if (user != null) {
      state = state.copyWith(user: user);
    }

    // Firebase認証状態を監視
    _authService.authStateChanges.listen((firebaseUser) {
      if (firebaseUser != null) {
        _loadUser();
      } else {
        state = AuthState();
        _localStorage.deleteUser();
      }
    });
  }

  /// ユーザー情報を読み込み
  Future<void> _loadUser() async {
    try {
      state = state.copyWith(isLoading: true);
      final user = await _apiService.getCurrentUser();
      await _localStorage.saveUser(user);
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// メール/パスワードでログイン
  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      await _loadUser();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// メール/パスワードで登録
  Future<void> registerWithEmailPassword(String email, String password, {String? displayName}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Firebase認証で登録
      final credential = await _authService.registerWithEmailPassword(
        email: email,
        password: password,
      );

      // APIサーバーにユーザー登録
      final user = await _apiService.registerUser(
        firebaseUid: credential.user!.uid,
        email: email,
        displayName: displayName,
      );

      await _localStorage.saveUser(user);
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Googleでログイン
  Future<void> signInWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final credential = await _authService.signInWithGoogle();
      final firebaseUser = credential.user!;

      // 既存ユーザーか新規ユーザーか確認
      try {
        await _loadUser();
      } catch (e) {
        // ユーザーが存在しない場合は登録
        final user = await _apiService.registerUser(
          firebaseUid: firebaseUser.uid,
          email: firebaseUser.email!,
          displayName: firebaseUser.displayName,
        );
        await _localStorage.saveUser(user);
        state = state.copyWith(user: user);
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// ログアウト
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      await _localStorage.clearAll();
      state = AuthState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// ユーザー情報を更新
  Future<void> updateUser({
    String? displayName,
    String? businessName,
    String? licenseNumber,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final updatedUser = await _apiService.updateUser(
        displayName: displayName,
        businessName: businessName,
        licenseNumber: licenseNumber,
      );

      await _localStorage.saveUser(updatedUser);
      state = state.copyWith(isLoading: false, user: updatedUser);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}
