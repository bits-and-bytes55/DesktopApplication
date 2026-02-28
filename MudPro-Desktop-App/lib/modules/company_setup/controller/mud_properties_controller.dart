import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/mud_properties_model.dart';

class MudPropertiesController {
  // Change to your actual server base URL
  static const String _baseUrl = ApiEndpoint.baseUrl;
  static const String _userId = 'default'; // change per user/well as needed

  /// GET saved/selected mud properties from DB
  Future<SelectedMudProperties> getSelectedMudProperties() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/selected?userId=$_userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        return SelectedMudProperties.fromJson(json['data']);
      }
      throw Exception(json['message'] ?? 'Failed to fetch selected data');
    }
    throw Exception('Server error: ${response.statusCode}');
  }

  /// POST save selected mud properties to DB
  Future<SelectedMudProperties> saveSelectedMudProperties(
      SelectedMudProperties selected) async {
    final body = selected.toJson();
    body['userId'] = _userId;

    final response = await http.post(
      Uri.parse('$_baseUrl/selected'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        return SelectedMudProperties.fromJson(json['data']);
      }
      throw Exception(json['message'] ?? 'Failed to save');
    }
    throw Exception('Server error: ${response.statusCode}');
  }
}