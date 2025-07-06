import 'package:http/http.dart' as http;
import 'package:smart_parking_app/core/models/user.dart';

class ApiService {
  Future<http.Response> get(String url) async {
    return await http.get(Uri.parse(url));
  }

  Future<http.Response> post(String url, Map<String, String> body) async {
    return await http.post(Uri.parse(url), body: body);
  }

  static updateUserProfile(UserModel user) {}

  static fetchUserProfile(String userId) {}

  static fetchGarageDetails(String garageId) {}

  static fetchGarages() {}
}