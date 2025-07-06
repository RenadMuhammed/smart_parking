import 'dart:convert';
import 'package:http/http.dart' as http;

class DatabaseService {
  // Replace with your computer's IP address
  static const String baseUrl = 'http://192.168.1.15:5000/api';
  
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/testconnection/test'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to connect: ${response.statusCode}'
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