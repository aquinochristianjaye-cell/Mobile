import 'dart:convert';
import 'package:http/http.dart' as http;

class WorkerAssignmentService {
  static const String baseUrl =
      'http://192.168.100.236:8000/api';

  static Future<List<dynamic>> getAssignments(
    int workerId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/worker/$workerId/assignments',
      ),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['assignments'] ?? [];
    }

    throw Exception(
      'Failed to load assigned trucks',
    );
  }

  static Future<List<dynamic>> getCompletedAssignments(
    int workerId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/worker/$workerId/completed',
      ),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['assignments'] ?? [];
    }

    throw Exception(
      'Failed to load completed trucks',
    );
  }

  static Future<Map<String, dynamic>> startAssignment(
    int assignmentId,
  ) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/worker/assignments/$assignmentId/start',
      ),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final data = jsonDecode(response.body);

    throw Exception(
      data['message'] ??
          'Failed to start washing',
    );
  }

  static Future<Map<String, dynamic>> finishAssignment(
    int assignmentId,
  ) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/worker/assignments/$assignmentId/finish',
      ),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final data = jsonDecode(response.body);

    throw Exception(
      data['message'] ??
          'Failed to finish washing',
    );
  }
}