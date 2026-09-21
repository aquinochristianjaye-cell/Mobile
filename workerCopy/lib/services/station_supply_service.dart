import 'dart:convert';

import 'package:http/http.dart' as http;

class StationSupplyService {
  static const String baseUrl =
      'http://192.168.100.236:8000/api';

  // Get the current supply levels
  static Future<Map<String, double>> getSupplies() async {
    final response = await http.get(
      Uri.parse('$baseUrl/supplies'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load supply levels',
      );
    }

    final data = jsonDecode(response.body);

    final supplies =
        data['supplies'] as List<dynamic>;

    final Map<String, double> result = {};

    for (final supply in supplies) {
      final name = supply['name'].toString();
      final level =
          double.tryParse(
                supply['level'].toString(),
              ) ??
              0;

      result[name] = level;
    }

    return result;
  }

  // Update all three supply levels
  static Future<void> updateSupplies({
    required double foamWash,
    required double disinfectant,
    required double water,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/worker/supplies'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'foam_wash': foamWash.round(),
        'disinfectant': disinfectant.round(),
        'water': water.round(),
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);

      throw Exception(
        data['message'] ??
            'Failed to update supply levels',
      );
    }
  }
}