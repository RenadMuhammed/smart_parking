import 'dart:convert';
import 'package:http/http.dart' as http;

class ReservationService {
  final String baseUrl = 'http://192.168.1.15:5000/api/reservation';

  Future<void> createReservation({
    required int userId,
    required int garageId,
    required String sectionId,
    required DateTime startTime,
    required DateTime endTime,
    required int duration,
    String status = "Pending",
  }) async {
    final Map<String, dynamic> reservationData = {
      "userId": userId,
      "garageId": garageId,
      "sectionId": sectionId,
      "startTime": startTime.toIso8601String(),
      "endTime": endTime.toIso8601String(),
      "duration": duration,
      "status": status,
    };

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(reservationData),
    );

    if (response.statusCode == 201) {
      print("✅ Reservation created successfully.");
    } else {
      print("❌ Failed to create reservation: ${response.statusCode}");
      print("Response body: ${response.body}");
      throw Exception('Failed to create reservation');
    }
  }
}
