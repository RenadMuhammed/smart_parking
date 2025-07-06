import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _usernameKey = 'username';
  
  // Save username to session
  static Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }
  
  // Get username from session
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }
  
  // Clear session (for logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
  
  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final username = await getUsername();
    return username != null;
  }

  static const String _reservationIdKey = 'reservationId';

static Future<void> saveReservationId(int reservationId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_reservationIdKey, reservationId);
}

static Future<int?> getReservationId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_reservationIdKey);
}

static Future<void> clearReservationId() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_reservationIdKey);
}
}