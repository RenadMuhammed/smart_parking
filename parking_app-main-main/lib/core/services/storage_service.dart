// core/services/storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const String _authTokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _pendingReservationKey = 'pending_reservation';
  static const String _activeReservationKey = 'active_reservation';

  // Auth Token Methods
  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  static Future<void> removeAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
  }

  // User Data Methods
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  static Future<void> removeUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
  }

  // Reservation Methods
  static Future<void> savePendingReservation(Map<String, dynamic> reservation) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingReservationKey, jsonEncode(reservation));
  }

  static Future<Map<String, dynamic>?> getPendingReservation() async {
    final prefs = await SharedPreferences.getInstance();
    final reservationString = prefs.getString(_pendingReservationKey);
    if (reservationString != null) {
      return jsonDecode(reservationString);
    }
    return null;
  }

  static Future<void> removePendingReservation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingReservationKey);
  }

  static Future<void> saveActiveReservation(Map<String, dynamic> reservation) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeReservationKey, jsonEncode(reservation));
  }

  static Future<Map<String, dynamic>?> getActiveReservation() async {
    final prefs = await SharedPreferences.getInstance();
    final reservationString = prefs.getString(_activeReservationKey);
    if (reservationString != null) {
      return jsonDecode(reservationString);
    }
    return null;
  }

  static Future<void> removeActiveReservation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeReservationKey);
  }

  // Clear all data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Add to StorageService class
  static const String _currentReservationIdKey = 'current_reservation_id';

  static Future<void> saveCurrentReservationId(int reservationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentReservationIdKey, reservationId);
  }

  static Future<int?> getCurrentReservationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentReservationIdKey);
  }

  static Future<void> clearCurrentReservationId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentReservationIdKey);
  }

}