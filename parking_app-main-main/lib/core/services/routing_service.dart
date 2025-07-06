import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  final String _apiKey = 'your_api_key_here'; // Replace with your key

  Future<List<LatLng>> getRouteCoordinates(LatLng start, LatLng end) async {
    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$_apiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final coords = data['features'][0]['geometry']['coordinates'];
      return coords.map<LatLng>((coord) => LatLng(coord[1], coord[0])).toList();
    } else {
      throw Exception('Failed to load route: ${response.body}');
    }
  }
}
