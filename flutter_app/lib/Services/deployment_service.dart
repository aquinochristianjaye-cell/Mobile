import 'dart:convert';
import 'package:http/http.dart' as http;

class DeploymentService {
  static const String baseUrl = 'http://192.168.100.236:8000/api';

  static Future<Map<String, dynamic>> deployTruck({
    required int appointmentId,
    required int workerId,
    required int washBayId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/deploy'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'appointment_id': appointmentId,
        'worker_id': workerId,
        'wash_bay_id': washBayId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data;
    }

    throw Exception(
      data['message'] ?? 'Failed to deploy truck',
    );
  }
}