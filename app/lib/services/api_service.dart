import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:kobutsu_log/config/constants.dart';
import 'package:kobutsu_log/models/user.dart' as models;
import 'package:kobutsu_log/models/transaction.dart';

/// APIサービス
class ApiService {
  late final Dio _dio;
  final String Function() _getToken;

  ApiService(this._getToken) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // インターセプター: 認証トークンを自動付与
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Firebase AuthからIDトークンを非同期取得
        try {
          final auth = firebase_auth.FirebaseAuth.instance;
          final user = auth.currentUser;
          if (user != null) {
            final token = await user.getIdToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
        } catch (e) {
          // トークン取得失敗時はログ出力のみ
          print('Failed to get ID token: $e');
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ));
  }

  // ========== ユーザー関連 ==========

  /// ユーザー登録
  Future<models.User> registerUser({
    required String firebaseUid,
    required String email,
    String? displayName,
  }) async {
    try {
      final response = await _dio.post('/api/auth/register', data: {
        'firebase_uid': firebaseUid,
        'email': email,
        'display_name': displayName,
      });

      return models.User.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 現在のユーザー情報を取得
  Future<models.User> getCurrentUser() async {
    try {
      final response = await _dio.get('/api/users/me');
      return models.User.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// ユーザー情報を更新
  Future<models.User> updateUser({
    String? displayName,
    String? businessName,
    String? licenseNumber,
  }) async {
    try {
      final response = await _dio.put('/api/users/me', data: {
        if (displayName != null) 'display_name': displayName,
        if (businessName != null) 'business_name': businessName,
        if (licenseNumber != null) 'license_number': licenseNumber,
      });

      return models.User.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ========== 取引関連 ==========

  /// 取引一覧を取得
  Future<List<Transaction>> getTransactions({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final response = await _dio.get('/api/transactions', queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      });

      final transactions = (response.data['data'] as List)
          .map((json) => Transaction.fromJson(json))
          .toList();

      return transactions;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 取引を作成
  Future<Transaction> createTransaction(Transaction transaction) async {
    try {
      final response = await _dio.post(
        '/api/transactions',
        data: transaction.toJson(),
      );

      return Transaction.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 取引を取得
  Future<Transaction> getTransaction(String id) async {
    try {
      final response = await _dio.get('/api/transactions/$id');
      return Transaction.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 取引を更新
  Future<Transaction> updateTransaction(Transaction transaction) async {
    try {
      final response = await _dio.put(
        '/api/transactions/${transaction.id}',
        data: transaction.toJson(),
      );

      return Transaction.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 取引を削除
  Future<void> deleteTransaction(String id) async {
    try {
      await _dio.delete('/api/transactions/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 月次統計を取得
  Future<Map<String, dynamic>> getMonthlyStats({
    int? year,
    int? month,
  }) async {
    try {
      final now = DateTime.now();
      final response = await _dio.get('/api/stats/monthly', queryParameters: {
        'year': year ?? now.year,
        'month': month ?? now.month,
      });

      return response.data['data'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ========== 画像アップロード ==========

  /// 画像をアップロード
  Future<String> uploadImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post('/api/upload/image', data: formData);
      return response.data['data']['url'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ========== エラーハンドリング ==========

  String _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      if (statusCode == 401) {
        return '認証エラー: ログインし直してください';
      } else if (statusCode == 403) {
        return 'アクセス権限がありません';
      } else if (statusCode == 404) {
        return 'データが見つかりません';
      } else if (statusCode == 429) {
        return '月間登録上限に達しました';
      } else if (data is Map && data['error'] != null) {
        return data['error']['message'] ?? 'エラーが発生しました';
      }
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'タイムアウトしました。通信環境を確認してください';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'サーバーに接続できません';
    }

    return 'エラーが発生しました: ${e.message}';
  }
}
