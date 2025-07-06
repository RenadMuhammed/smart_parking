import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class NavigationService {
  final String apiKey = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6Ijc4MTdjYjUwMzBjZjQ1ZDk4ZGZjNjQyMjM4MTY1MGViIiwiaCI6Im11cm11cjY0In0=';
  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "coordinates": [
          [start.longitude, start.latitude],
          [end.longitude, end.latitude]
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final coordinates = data['features'][0]['geometry']['coordinates'];

      return coordinates
          .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
          .toList();
    } else {
      throw Exception('Failed to fetch route');
    }
  }
}
