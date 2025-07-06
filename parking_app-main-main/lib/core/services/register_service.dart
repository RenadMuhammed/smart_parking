import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisterService {
  final String baseUrl = 'http://192.168.1.15:5000/api/auth';
 

  /// Register a new user via the backend API
  Future<bool> register(Map<String, dynamic> data) async {
  final url = Uri.parse('$baseUrl/register');

  print('📦 Sending registration data: $data');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  } catch (e) {
    print('❗ Error sending request: $e');
    return false;
  }
}
}