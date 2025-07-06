import 'dart:convert';
import 'package:http/http.dart' as http;

class Garage {
  final int id;
  final String name;
  final double latitude;
  final double longitude;

  Garage({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

      factory Garage.fromJson(Map<String, dynamic> json) {
    return Garage(
      id: json['garageId'] ?? 0,
      name: json['name'] ?? 'Unnamed Garage',
      latitude: (json['latitude'] != null)
          ? double.tryParse(json['latitude'].toString()) ?? 0.0
          : 0.0,
      longitude: (json['longitude'] != null)
          ? double.tryParse(json['longitude'].toString()) ?? 0.0
          : 0.0,
    );
  }


}


class GarageService {
  final String baseUrl = 'http://192.168.1.15:5000/api/garage';

  Future<List<Garage>> fetchGarages() async {
  final url = Uri.parse(baseUrl);
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> jsonData = json.decode(response.body);

    // Return only garages with ID 6 or 7 and non-null coordinates
    final filtered = jsonData.where((item) =>
      (item['garageId'] == 6 || item['garageId'] == 7) &&
      item['latitude'] != null &&
      item['longitude'] != null
    ).toList();

    return filtered.map((json) => Garage.fromJson(json)).toList();
  } else {
    throw Exception("Failed to load garages: ${response.statusCode}");
  }
}

}
