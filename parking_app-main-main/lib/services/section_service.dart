import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_parking_app/models/section.dart';

class SectionService {
  static const String _baseUrl = 'http://192.168.1.15:5000/api';

  Future<List<Section>> fetchSectionsByGarage(int garageId) async {
    final url = Uri.parse('$_baseUrl/section/garage/$garageId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Section.fromJson(json)).toList();
    } else {
      print("❌ Failed to load sections: ${response.statusCode}");
      throw Exception('Failed to load sections');
    }
  }
}


