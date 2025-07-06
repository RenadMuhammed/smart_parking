import 'package:flutter/material.dart';

// Location model to represent latitude and longitude
class Location {
  final double latitude;
  final double longitude;

  Location({required this.latitude, required this.longitude});
}

// LocationService class with instance method to get the current location
class LocationService {
  Future<Location> getCurrentLocation() async {
    // Simulate getting the current location (You can replace this with actual code)
    return Location(latitude: 37.7749, longitude: -122.4194);
  }
}

// LocationProvider class that manages location state
class LocationProvider with ChangeNotifier {
  double _latitude = 0.0;
  double _longitude = 0.0;
  final LocationService _locationService = LocationService();  // Instance of LocationService

  double get latitude => _latitude;
  double get longitude => _longitude;

  // Method to update the location by calling LocationService
  Future<void> updateLocation() async {
    final location = await _locationService.getCurrentLocation();
    _latitude = location.latitude;
    _longitude = location.longitude;
    notifyListeners();
  }
}
