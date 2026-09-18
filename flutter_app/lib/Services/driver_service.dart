import 'dart:convert';
import 'package:http/http.dart' as http;

class DriverService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static Future<List<Map<String, dynamic>>> getDrivers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/drivers'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load drivers');
    }

    final data = jsonDecode(response.body);

    return List<Map<String, dynamic>>.from(
      data['drivers'],
    );
  }
}