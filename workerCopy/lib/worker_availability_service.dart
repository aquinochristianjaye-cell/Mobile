import 'dart:convert';

import 'package:http/http.dart' as http;

class WorkerAvailabilityService {
  static const String baseUrl =
      'http://127.0.0.1:8000/api';

  // ----------------------------------------------------------
  // GET CURRENT AVAILABILITY
  // ----------------------------------------------------------

  static Future<bool> getAvailability(int workerId) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/worker/$workerId/availability',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load worker availability.',
      );
    }

    final data = jsonDecode(response.body);

    return data['is_available'] == true ||
        data['is_available'] == 1;
  }

  // ----------------------------------------------------------
  // UPDATE AVAILABILITY
  // ----------------------------------------------------------

  static Future<bool> updateAvailability(
    int workerId,
    bool isAvailable,
  ) async {
    final response = await http.put(
      Uri.parse(
        '$baseUrl/worker/$workerId/availability',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'is_available': isAvailable,
      }),
    );

    if (response.statusCode != 200) {
      String message =
          'Failed to update worker availability.';

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

    return data['is_available'] == true ||
        data['is_available'] == 1;
  }
}