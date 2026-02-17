// lib/services/health_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';

class HealthService {
  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse("${ApiEndpoint.baseUrl}/api/health"),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Server responded with ${response.statusCode}");
      }
    } on SocketException {
      throw Exception("Backend server not running");
    } on HttpException {
      throw Exception("HTTP error");
    } on FormatException {
      throw Exception("Invalid response format");
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }
}
