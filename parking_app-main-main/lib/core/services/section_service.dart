import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_parking_app/models/section.dart';

class SectionService {
  final String baseUrl = "http://192.168.1.15:5000/api"; // change if needed

  Future<List<Section>> fetchSectionsByGarageId(int garageId) async {
    final response = await http.get(Uri.parse('$baseUrl/section/$garageId'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Section.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load sections for garage $garageId');
    }
  }
}
