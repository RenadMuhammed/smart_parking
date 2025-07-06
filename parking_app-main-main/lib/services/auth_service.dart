import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${DatabaseService.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Invalid username or password'
        };
      } else {
        return {
          'success': false,
          'message': 'Login failed: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e'
      };
    }
  }
}