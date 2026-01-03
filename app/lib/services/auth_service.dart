import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  // Register new user
  Future<AuthResult> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await _api.post(ApiConfig.register, {
      'name': name,
      'email': email,
      'password': password,
    }, withAuth: false);

    if (response.success && response.data != null) {
      final user = User.fromJson(response.data['user']);
      final token = response.data['token'];
      await _api.setToken(token);
      return AuthResult(success: true, user: user, token: token);
    }

    return AuthResult(success: false, message: response.message);
  }

  // Login
  Future<AuthResult> login(String email, String password) async {
    final response = await _api.post(ApiConfig.login, {
      'email': email,
      'password': password,
    }, withAuth: false);

    if (response.success && response.data != null) {
      final user = User.fromJson(response.data['user']);
      final token = response.data['token'];
      await _api.setToken(token);
      return AuthResult(success: true, user: user, token: token);
    }

    return AuthResult(success: false, message: response.message);
  }

  // Get current user
  Future<AuthResult> getCurrentUser() async {
    final token = await _api.getToken();
    if (token == null) {
      return AuthResult(success: false, message: 'Not logged in');
    }

    final response = await _api.get(ApiConfig.me);

    if (response.success && response.data != null) {
      final user = User.fromJson(response.data['user']);
      return AuthResult(success: true, user: user, token: token);
    }

    return AuthResult(success: false, message: response.message);
  }

  // Logout
  Future<void> logout() async {
    await _api.clearToken();
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final token = await _api.getToken();
    return token != null;
  }
}

class AuthResult {
  final bool success;
  final String message;
  final User? user;
  final String? token;

  AuthResult({required this.success, this.message = '', this.user, this.token});
}
