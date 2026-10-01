import 'dart:convert';
import 'package:http/http.dart' as http;

class DriverTrackingService {
  static const String baseUrl =
      'http://127.0.0.1:8000/api';

  static Future<List<Map<String, dynamic>>> getDriverLocations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/drivers/locations'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load driver locations: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    final drivers = data['drivers'];

    if (drivers is! List) {
      return [];
    }

    return List<Map<String, dynamic>>.from(
      drivers.map(
        (driver) => Map<String, dynamic>.from(driver),
      ),
    );
  }
}