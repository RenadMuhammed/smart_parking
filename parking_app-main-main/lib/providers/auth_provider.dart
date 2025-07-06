import 'package:flutter/material.dart';

class AuthService {
  // Login method that takes email and password as arguments
  Future<String> login(String email, String password) async {
    // Simulate a network request with Future.delayed
    await Future.delayed(const Duration(seconds: 2));

    // Here, add your actual authentication logic (e.g., making an API call)
    if (email == 'user@example.com' && password == 'password123') {
      return 'dummy_token';  // Return a dummy token if login is successful
    } else {
      return '';  // Return an empty string if authentication fails
    }
  }

  // Logout method to clear user data or session
  Future<void> logout() async {
    await Future.delayed(const Duration(seconds: 1));  // Simulate a network request
  }
}

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String _authToken = '';

  bool get isAuthenticated => _isAuthenticated;
  String get authToken => _authToken;

  // Login method
  Future<void> login(String email, String password) async {
    final token = await AuthService().login(email, password);
    if (token.isNotEmpty) {
      _authToken = token;
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  // Logout method
  Future<void> logout() async {
    await AuthService().logout();
    _authToken = '';
    _isAuthenticated = false;
    notifyListeners();
  }
}
