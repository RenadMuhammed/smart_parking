import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_parking_app/core/services/storage_service.dart'; // Add this

class AuthService {
  static const String _baseUrl = 'http://192.168.1.15:5000/api/auth';
  static String? _authToken; // Add this
  
  // Add getter for auth token
  static String? get authToken => _authToken;

  // 🔐 Register
  static Future<bool> register(Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('❌ Registration failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❗ Error sending register request: $e');
      return false;
    }
  }

  // 🔑 Login (updated to save token)
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        
        // Save auth token if provided by backend
        if (userData['token'] != null) {
          _authToken = userData['token'];
          await StorageService.saveAuthToken(userData['token']);
        }
        
        // Save user data
        await StorageService.saveUserData({
          'username': username,
          'userId': userData['userId'] ?? userData['id'],
          'email': userData['email'] ?? '',
        });
        
        return {
          "success": true,
          "user": userData,
        };
      } else {
        return {"success": false};
      }
    } catch (e) {
      print('❗ Login error: $e');
      return {"success": false, "error": e.toString()};
    }
  }

  // Add this method to your existing AuthService class
static Future<bool> validateToken() async {
  try {
    // Check if user data exists
    final userData = await StorageService.getUserData();
    if (userData != null && userData['username'] != null) {
      // For now, just check if user data exists
      // You can add an API call to validate with your backend later
      return true;
    }
    return false;
  } catch (e) {
    print('❗ Token validation error: $e');
    return false;
  }
}

// Add logout method
static Future<void> logout() async {
  await StorageService.clearAll();
}

  // Add auth headers helper
  static Map<String, String> getAuthHeaders() {
    return {
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      'Content-Type': 'application/json',
    };
  }
}