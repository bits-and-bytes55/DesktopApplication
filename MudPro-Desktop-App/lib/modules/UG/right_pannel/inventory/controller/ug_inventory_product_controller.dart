import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/UG/model/inventory_model.dart' hide PremixModel, ObmModel;
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/model/ug_inventory_product_model.dart';

class InventoryProductsService {
  // ✅ Change to your actual backend URL
  static const String _baseUrl = ApiEndpoint.baseUrl;

  // ─── Apply: Save all three tables at once ─────────────────
  static Future<void> applyInventoryData({
    required String wellId,
    required List<ProductInventoryModel> products,
    required List<PremixModel> premixed,
    required List<ObmModel> obm,
  }) async {
    final uri = Uri.parse('${_baseUrl}inventory-products/apply');

    final body = jsonEncode({
      'wellId': wellId,
      'products': products.map((p) => p.toJson()).toList(),
      'premixed': premixed.map((p) => p.toJson()).toList(),
      'obm': obm.map((o) => o.toJson()).toList(),
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    final json = jsonDecode(response.body);

    print('statusCode: ${response.statusCode}');
    print('responseBody: ${response.body}');

    if (response.statusCode != 200 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to save inventory');
    }
  }

  // ─── Get: Fetch all three tables for a well ───────────────
  static Future<Map<String, dynamic>> getInventoryData(String wellId) async {
    final uri = Uri.parse('$_baseUrl/$wellId');

    final response = await http.get(uri, headers: {'Content-Type': 'application/json'});

    final json = jsonDecode(response.body);

    if (response.statusCode != 200 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to fetch inventory');
    }

    final data = json['data'];

    return {
      'products': (data['products'] as List)
          .map((e) => ProductInventoryModel.fromJson(e))
          .toList(),
      'premixed': (data['premixed'] as List)
          .map((e) => PremixModel.fromJson(e))
          .toList(),
      'obm': (data['obm'] as List)
          .map((e) => ObmModel.fromJson(e))
          .toList(),
    };
  }
}