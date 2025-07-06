import 'package:http/http.dart' as http;
import 'dart:convert';


class ReservationService {
  static const String baseUrl = 'http://192.168.1.15:5000/api';

  static Future<bool> updateReservationStatus({
    required int reservationId,
    required String status,
  }) async {
    try {
      print("📡 Updating reservation $reservationId to status: $status");
      
      final response = await http.put(
        Uri.parse('$baseUrl/reservation/$reservationId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        print("✅ Reservation status updated successfully");
        return true;
      } else {
        print("❌ Failed to update reservation status");
        return false;
      }
    } catch (e) {
      print('❌ Error updating reservation status: $e');
      return false;
    }
  }

  static Future<int?> getLatestPendingReservation(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reservation/pending/$username'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reservationId'];
      }
      return null;
    } catch (e) {
      print('Error getting pending reservation: $e');
      return null;
    }
  }
}