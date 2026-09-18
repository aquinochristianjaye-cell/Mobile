import 'dart:convert';
import 'package:http/http.dart' as http;

class AppointmentService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static Future<List<dynamic>> getAdminAppointments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/appointments'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['appointments'];
    } else {
      throw Exception('Failed to load appointments');
    }
  }
}