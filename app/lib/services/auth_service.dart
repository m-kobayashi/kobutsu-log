import 'package:firebase_auth/firebase_auth.dart' as firebase;
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;

/// 認証サービス
class AuthService {
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;
  // late final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn();

  /// 現在のFirebaseユーザー
  firebase.User? get currentUser => _auth.currentUser;

  /// 認証状態の変更を監視
  Stream<firebase.User?> get authStateChanges => _auth.authStateChanges();

  /// IDトークンを取得
  Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  /// メールアドレスとパスワードでログイン
  Future<firebase.UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// メールアドレスとパスワードで登録
  Future<firebase.UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Googleアカウントでログイン
  /// 注: MVP段階では一時的に無効化しています
  Future<firebase.UserCredential> signInWithGoogle() async {
    throw Exception('Google Sign In は現在利用できません。メール/パスワードでログインしてください。');

    // TODO: Android/iOS向けに Google Sign In を有効化する場合は以下のコメントを外す
    /*
    if (kIsWeb) {
      throw Exception('Google Sign In は Web プラットフォームでは現在サポートされていません。メール/パスワードでログインしてください。');
    }

    try {
      // Googleサインインフローを開始
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) {
        throw Exception('Googleログインがキャンセルされました');
      }

      // 認証情報を取得
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebaseの認証情報を作成
      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebaseにサインイン
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw _handleAuthException(e);
    }
    */
  }

  /// ログアウト
  Future<void> signOut() async {
    await _auth.signOut();
    // TODO: Google Sign In 有効化時は以下も追加
    // if (!kIsWeb && _googleSignIn != null) {
    //   await _googleSignIn!.signOut();
    // }
  }

  /// パスワードリセットメールを送信
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// 認証例外をハンドリング
  String _handleAuthException(dynamic e) {
    if (e is firebase.FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'このメールアドレスは登録されていません';
        case 'wrong-password':
          return 'パスワードが正しくありません';
        case 'email-already-in-use':
          return 'このメールアドレスは既に使用されています';
        case 'weak-password':
          return 'パスワードは6文字以上で入力してください';
        case 'invalid-email':
          return '無効なメールアドレスです';
        case 'user-disabled':
          return 'このアカウントは無効化されています';
        default:
          return '認証エラーが発生しました: ${e.message}';
      }
    }
    return e.toString();
  }
}
