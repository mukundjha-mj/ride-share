import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final SocketService _socketService = SocketService();

  User? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String _error = '';

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String get error => _error;

  // Initialize - check if already logged in
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.getCurrentUser();
    if (result.success && result.user != null) {
      _user = result.user;
      _isAuthenticated = true;
      // 🔌 Connect socket on restore session
      _socketService.connect();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Register
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    final result = await _authService.register(name, email, password);

    if (result.success && result.user != null) {
      _user = result.user;
      _isAuthenticated = true;
      _isLoading = false;
      // 🔌 Connect socket
      _socketService.connect();
      notifyListeners();
      return true;
    }

    _error = result.message;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    final result = await _authService.login(email, password);

    if (result.success && result.user != null) {
      _user = result.user;
      _isAuthenticated = true;
      _isLoading = false;
      // 🔌 Connect socket
      _socketService.connect();
      notifyListeners();
      return true;
    }

    _error = result.message;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Logout
  Future<void> logout() async {
    // 🔌 Disconnect socket
    _socketService.disconnect();
    await _authService.logout();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }
}
