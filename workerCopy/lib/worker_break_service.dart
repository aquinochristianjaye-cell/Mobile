import 'dart:convert';

import 'package:http/http.dart' as http;

class WorkerBreakService {
  static const String baseUrl =
      'http://127.0.0.1:8000/api';

  static Future<bool> getBreak(int workerId) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/worker/$workerId/break',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load worker break status.',
      );
    }

    final data = jsonDecode(response.body);

    return data['is_on_break'] == true ||
        data['is_on_break'] == 1;
  }

  static Future<bool> updateBreak(
    int workerId,
    bool isOnBreak,
  ) async {
    final response = await http.put(
      Uri.parse(
        '$baseUrl/worker/$workerId/break',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'is_on_break': isOnBreak,
      }),
    );

    if (response.statusCode != 200) {
      String message =
          'Failed to update worker break status.';

      try {
        final data = jsonDecode(response.body);

        if (data['message'] != null) {
          message = data['message'].toString();
        }
      } catch (_) {
        // Keep the default error message.
      }

      throw Exception(message);
    }

    final data = jsonDecode(response.body);

    return data['is_on_break'] == true ||
        data['is_on_break'] == 1;
  }
}

