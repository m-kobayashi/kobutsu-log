import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';

/// 認証サービス
class AuthService {
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
  Future<firebase.UserCredential> signInWithGoogle() async {
    try {
      // Googleサインインフローを開始
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
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
  }

  /// ログアウト
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
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
