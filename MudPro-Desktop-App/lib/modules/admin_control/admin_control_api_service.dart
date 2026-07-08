import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/installation/installation_identity.dart';

class AdminControlApiService {
  static Uri _uri(String path) => Uri.parse('${ApiEndpoint.baseUrl}$path');

  static Map<String, String> _headers([String adminToken = '']) {
    return {
      ...ApiEndpoint.jsonHeaders,
      if (adminToken.isNotEmpty) 'X-Admin-Session-Token': adminToken,
    };
  }

  static Future<Map<String, dynamic>> _devicePayload([
    Map<String, dynamic> extra = const {},
  ]) async {
    return {
      ...await InstallationIdentity.currentDevicePayload(),
      ...extra,
    };
  }

  static Future<Map<String, dynamic>> getStatus() async {
    final response = await http.get(
      _uri(ApiEndpoint.adminStatus),
      headers: _headers(),
    );
    return _decode(response);
  }

  static Future<Map<String, dynamic>> setupPassword({
    required String password,
    required String confirmPassword,
  }) async {
    final response = await http.post(
      _uri(ApiEndpoint.adminSetupPassword),
      headers: _headers(),
      body: jsonEncode(
        await _devicePayload({
          'password': password,
          'confirmPassword': confirmPassword,
        }),
      ),
    );
    return _decode(response);
  }

  static Future<Map<String, dynamic>> login(String password) async {
    final response = await http.post(
      _uri(ApiEndpoint.adminLogin),
      headers: _headers(),
      body: jsonEncode(await _devicePayload({'password': password})),
    );
    return _decode(response);
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
    required String adminToken,
  }) async {
    final response = await http.post(
      _uri(ApiEndpoint.adminChangePassword),
      headers: _headers(adminToken),
      body: jsonEncode(
        await _devicePayload({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      ),
    );
    return _decode(response);
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await http.post(
      _uri(ApiEndpoint.adminResetPassword),
      headers: _headers(),
      body: jsonEncode(
        await _devicePayload({
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      ),
    );
    return _decode(response);
  }

  static Future<Map<String, dynamic>> checkDeviceAccess() async {
    final response = await http.post(
      _uri(ApiEndpoint.deviceAuthCheck),
      headers: _headers(),
      body: jsonEncode(await _devicePayload()),
    );
    return _decode(response);
  }

  static Future<Map<String, dynamic>> registerCurrentDevice(
    String adminToken,
  ) async {
    final response = await http.post(
      _uri(ApiEndpoint.adminCurrentDevice),
      headers: _headers(adminToken),
      body: jsonEncode(await _devicePayload()),
    );
    return _decode(response);
  }

  static Future<Map<String, dynamic>> getDevices(String adminToken) async {
    final response = await http.get(
      _uri(ApiEndpoint.adminDevices),
      headers: _headers(adminToken),
    );
    return _decode(response);
  }

  static Future<Map<String, dynamic>> updateDeviceStatus({
    required String id,
    required String status,
    required String adminToken,
  }) async {
    final response = await http.patch(
      _uri('${ApiEndpoint.adminDevices}/$id/status'),
      headers: _headers(adminToken),
      body: jsonEncode({'status': status}),
    );
    return _decode(response);
  }

  static Future<Map<String, dynamic>> getLogs(String adminToken) async {
    final response = await http.get(
      _uri(ApiEndpoint.adminLogs),
      headers: _headers(adminToken),
    );
    return _decode(response);
  }

  static Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final message = body['message']?.toString() ?? 'Admin request failed';
    if (response.statusCode == 401 && message == 'Admin login required') {
      throw Exception('SESSION_EXPIRED');
    }
    throw Exception(message);
  }
}
