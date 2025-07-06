import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentService {
  static const String baseUrl = 'http://192.168.1.15:5000/api';

  Future<bool> createPayment({
    required int userId,
    required String username,
    required String cardNumber,
    required String cardType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'username': username,
          'cardNumber': cardNumber,
          'cardType': cardType,
          'expiryDate': '',
          'cvv': '',
        }),
      );

      print('Payment response: ${response.body}');
      
      if (response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      print('Payment error: $e');
      return false;
    }
  }
}