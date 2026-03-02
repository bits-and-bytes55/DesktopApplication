import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/mud_properties_model.dart';

class MudPropertiesController {
  // Change to your actual server base URL
  static const String _baseUrl = ApiEndpoint.baseUrl;

  /// GET saved/selected mud properties from DB
  Future<SelectedMudProperties> getSelectedMudProperties() async {
    final response = await http.get(
      Uri.parse('${_baseUrl}mud-properties/selected'),
      headers: {'Content-Type': 'application/json'},
    );

    print('GET Response Status: ${response.statusCode}');
    print('GET Response Body: ${response.body}');

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

    final response = await http.post(
      Uri.parse('${_baseUrl}mud-properties/selected'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    print('GET Response Status: ${response.statusCode}');
    print('GET Response Body: ${response.body}');

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