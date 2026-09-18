import 'dart:convert';
import 'package:http/http.dart' as http;

class WorkerAssignmentService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // ==========================================================
  // ACTIVE ASSIGNMENTS
  // ==========================================================

  static Future<List<dynamic>> getActiveAssignments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/assignments/active'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['assignments'] ?? [];
    }

    throw Exception('Failed to load active assignments');
  }

  // ==========================================================
  // COMPLETED ASSIGNMENTS
  // ==========================================================

  static Future<List<dynamic>> getCompletedAssignments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/assignments/completed'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['assignments'] ?? [];
    }

    throw Exception('Failed to load completed trucks');
  }
}