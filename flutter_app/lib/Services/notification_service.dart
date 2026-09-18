import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static Future<List<dynamic>> getAdminNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/notifications'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['notifications'];
    } else {
      throw Exception('Failed to load notifications');
    }
  }
}