import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:smart_parking_app/screens/booking/garage_details_screen.dart';
import 'package:smart_parking_app/services/garage_service.dart';
import 'package:smart_parking_app/widgets/common/profile_button.dart';
class MapScreen extends StatefulWidget {
  final Garage? selectedGarage; // Add this
  
  const MapScreen({Key? key, this.selectedGarage}) : super(key: key); // Update constructor

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Garage> garages = [];
  LatLng? _currentPosition;
  List<LatLng> _routePoints = [];

  final String _orsApiKey = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6Ijc4MTdjYjUwMzBjZjQ1ZDk4ZGZjNjQyMjM4MTY1MGViIiwiaCI6Im11cm11cjY0In0=';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    loadGarages();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      
      // Draw route to selected garage if provided
      if (widget.selectedGarage != null) {
        _drawRoute(LatLng(widget.selectedGarage!.latitude, widget.selectedGarage!.longitude));
      }
    }
  }

  Future<void> loadGarages() async {
    final fetchedGarages = await GarageService().fetchGarages();
    setState(() {
      garages = fetchedGarages;
    });
  }

  Future<void> _drawRoute(LatLng destination) async {
    if (_currentPosition == null) return;

    final url = Uri.parse("https://api.openrouteservice.org/v2/directions/driving-car/geojson");

    final response = await http.post(
      url,
      headers: {
        'Authorization': _orsApiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "coordinates": [
          [_currentPosition!.longitude, _currentPosition!.latitude],
          [destination.longitude, destination.latitude]
        ]
      }),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final coords = decoded['features'][0]['geometry']['coordinates'] as List;
      setState(() {
        _routePoints = coords
            .map((point) => LatLng(point[1].toDouble(), point[0].toDouble()))
            .toList();
      });
    } else {
      print("❌ Failed to fetch route: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _currentPosition ?? (garages.isNotEmpty
        ? LatLng(garages[0].latitude, garages[0].longitude)
        : const LatLng(30.0444, 31.2357)); // Cairo fallback

    return Scaffold(
      appBar: AppBar(
        title: const Text("Garage Map"),
        leading: widget.selectedGarage != null ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ) : null,
        actions: const [
          ProfileButton(), // Add this
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: widget.selectedGarage != null 
              ? LatLng(widget.selectedGarage!.latitude, widget.selectedGarage!.longitude)
              : center,
          initialZoom: 16.0,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
          ),
          if (_currentPosition != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentPosition!,
                  width: 60,
                  height: 60,
                  child: const Icon(Icons.my_location, color: Colors.red, size: 36),
                )
              ],
            ),
          MarkerLayer(
            markers: garages.map((garage) {
              final point = LatLng(garage.latitude, garage.longitude);
              final isSelected = widget.selectedGarage?.id == garage.id;
              
              return Marker(
                point: point,
                width: 80,
                height: 80,
                child: GestureDetector(
                  onTap: () {
                    _drawRoute(point);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GarageDetailsScreen(garage: garage),
                      ),
                    );
                  },
                  child: Tooltip(
                    message: garage.name,
                    child: Icon(
                      Icons.local_parking, 
                      color: isSelected ? Colors.green : Colors.blue, 
                      size: isSelected ? 45 : 40,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_routePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routePoints,
                  strokeWidth: 4.0,
                  color: Colors.green,
                ),
              ],
            ),
        ],
      ),
    );
  }
}