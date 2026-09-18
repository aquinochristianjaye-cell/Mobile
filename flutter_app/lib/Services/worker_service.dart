import 'dart:convert';
import 'package:http/http.dart' as http;


class WorkerService {
  static const String baseUrl =
      'http://127.0.0.1:8000/api';

  static Future<List<Map<String, dynamic>>> getWorkers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/workers'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load workers');
    }

    final data = jsonDecode(response.body);

    return List<Map<String, dynamic>>.from(
      data['workers'],
    );
  }
}