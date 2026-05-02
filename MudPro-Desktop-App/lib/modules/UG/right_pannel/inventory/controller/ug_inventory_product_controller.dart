import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/UG/model/inventory_model.dart';
import 'package:mudpro_desktop_app/modules/UG/right_pannel/inventory/model/ug_inventory_product_model.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/service_model.dart';

class InventoryProductsService {
  // ✅ Change to your actual backend URL
  static const String _baseUrl = ApiEndpoint.baseUrl;

  // ─── Apply: Save all categories at once ─────────────────
  static Future<void> applyInventoryData({
    required String wellId,
    required List<ProductInventoryModel> products,
    required List<PremixModel> premixed,
    required List<ObmModel> obm,
    List<PackageItem>? packages,
    List<ServiceItem>? services,
    List<EngineeringItem>? engineering,
    String? bulkTankSetupFee,
    String? taxRate,
    String? applyPricesOption,
    String? fromDate,
  }) async {
    final url = '${_baseUrl}ug-inventory/$wellId';
    print('🔵 [POST] Saving inventory to URL: $url');
    final uri = Uri.parse(url);

    final bodyData = {
      'wellId': wellId,
      'products': products.map((ProductInventoryModel p) => p.toJson()).toList(),
      'premixed': premixed.map((PremixModel p) => p.toJson()).toList(),
      'obm': obm.map((ObmModel o) => o.toJson()).toList(),
      'packages': packages?.map((e) => e.toJson()).toList() ?? [],
      'services': services?.map((e) => e.toJson()).toList() ?? [],
      'engineering': engineering?.map((e) => e.toJson()).toList() ?? [],
    };

    if (bulkTankSetupFee != null) bodyData['bulkTankSetupFee'] = bulkTankSetupFee;
    if (taxRate != null) bodyData['taxRate'] = taxRate;
    if (applyPricesOption != null) bodyData['applyPricesOption'] = applyPricesOption;
    if (fromDate != null) bodyData['fromDate'] = fromDate;

    final body = jsonEncode(bodyData);

    final response = await http.post(
      uri,
      headers: ApiEndpoint.jsonHeaders,
      body: body,
    );

    print('🟢 [POST] statusCode: ${response.statusCode}');
    print('🟢 [POST] responseBody: ${response.body}');

    final json = jsonDecode(response.body);

    if (response.statusCode != 200 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to save inventory');
    }
  }

  // ─── Get: Fetch full snapshot ───────────────────────────────
  static Future<Map<String, dynamic>> getInventoryData(String wellId) async {
    final url = '${_baseUrl}ug-inventory/$wellId';
    print('🔵 [GET] Fetching inventory from URL: $url');
    final uri = Uri.parse(url);

    final response = await http.get(uri, headers: ApiEndpoint.jsonHeaders);

    print('🟢 [GET] statusCode: ${response.statusCode}');
    print('🟢 [GET] responseBody: ${response.body}');

    final json = jsonDecode(response.body);

    if (response.statusCode != 200 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to fetch inventory');
    }

    return json['data'];
  }

  // ─── Specific Fetch Methods ─────────────────────────────────

  static Future<List<ProductInventoryModel>> fetchProducts(String wellId) async {
    final url = '${_baseUrl}ug-inventory/products/$wellId';
    print('🔵 [GET] Fetching products from URL: $url');
    final response = await http.get(Uri.parse(url), headers: ApiEndpoint.jsonHeaders);
    print('🟢 [GET] statusCode: ${response.statusCode}');
    print('🟢 [GET] responseBody: ${response.body}');
    final json = jsonDecode(response.body);
    if (response.statusCode == 200 && json['success'] == true) {
      return (json['data'] as List).map((e) => ProductInventoryModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<List<PackageItem>> fetchPackages(String wellId) async {
    final url = '${_baseUrl}ug-inventory/packages/$wellId';
    print('🔵 [GET] Fetching packages from URL: $url');
    final response = await http.get(Uri.parse(url), headers: ApiEndpoint.jsonHeaders);
    final json = jsonDecode(response.body);
    if (response.statusCode == 200 && json['success'] == true) {
      return (json['data'] as List).map((e) => PackageItem.fromJson(e)).toList();
    }
    return [];
  }

  static Future<List<ServiceItem>> fetchServices(String wellId) async {
    final url = '${_baseUrl}ug-inventory/services/$wellId';
    print('🔵 [GET] Fetching services from URL: $url');
    final response = await http.get(Uri.parse(url), headers: ApiEndpoint.jsonHeaders);
    final json = jsonDecode(response.body);
    if (response.statusCode == 200 && json['success'] == true) {
      return (json['data'] as List).map((e) => ServiceItem.fromJson(e)).toList();
    }
    return [];
  }

  static Future<List<EngineeringItem>> fetchEngineering(String wellId) async {
    final url = '${_baseUrl}ug-inventory/engineering/$wellId';
    print('🔵 [GET] Fetching engineering from URL: $url');
    final response = await http.get(Uri.parse(url), headers: ApiEndpoint.jsonHeaders);
    final json = jsonDecode(response.body);
    if (response.statusCode == 200 && json['success'] == true) {
      return (json['data'] as List).map((e) => EngineeringItem.fromJson(e)).toList();
    }
    return [];
  }
}
