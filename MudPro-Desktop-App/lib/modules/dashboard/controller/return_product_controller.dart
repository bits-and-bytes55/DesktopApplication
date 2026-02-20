import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';

class ReturnProductController {
  final String baseUrl = ApiEndpoint.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ============ RETURN PRODUCT APIs ============
  
  Future<List<Map<String, dynamic>>> getReturnProducts() async {
    try {
print("Fetching return products from: ${Uri.parse('${baseUrl}return-products')}");

      final response = await http.get(
        Uri.parse('${baseUrl}return-products'),
        headers: _headers,
      );

      print("Get Return Products - responsebody: ${response.body}");
      print("Get Return Products - statusCode: ${response.statusCode}");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((e) => e as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load return products');
      }
    } catch (e) {
      print('Error fetching return products: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>> createReturnProduct({
    required String productName,
    required String code,
    required String unit,
    required double amount,
  }) async {
    try {

      print("url: ${Uri.parse('${baseUrl}return-products')}");

      
      final response = await http.post(
        Uri.parse('${baseUrl}return-products'),
        headers: _headers,
        body: jsonEncode({
          'productName': productName,
          'code': code,
          'unit': unit,
          'amount': amount,
        }),
      );

      final responseData = jsonDecode(response.body);
      print("Create Return Product - responsebody: ${response.body}");
      print("Create Return Product - statusCode: ${response.statusCode}");
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Product returned successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to return product',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateReturnProduct({
    required String id,
    required String productName,
    required String code,
    required String unit,
    required double amount,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${baseUrl}return-products/$id'),
        headers: _headers,
        body: jsonEncode({
          'productName': productName,
          'code': code,
          'unit': unit,
          'amount': amount,
        }),
      );

      final responseData = jsonDecode(response.body);
      print("Update Return Product - responsebody: ${response.body}");
      print("Update Return Product - statusCode: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Product updated successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update product',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteReturnProduct(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}return-products/$id'),
        headers: _headers,
      );

      final responseData = jsonDecode(response.body);
      print("Delete Return Product - responsebody: ${response.body}");
      print("Delete Return Product - statusCode: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Product deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete product',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ============ RETURN PACKAGE APIs ============
  
  Future<List<Map<String, dynamic>>> getReturnPackages() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}return-packages'),
        headers: _headers,
      );

      print("Get Return Packages - responsebody: ${response.body}");
      print("Get Return Packages - statusCode: ${response.statusCode}");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((e) => e as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load return packages');
      }
    } catch (e) {
      print('Error fetching return packages: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>> createReturnPackage({
    required String packageName,
    required String code,
    required String unit,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}return-packages'),
        headers: _headers,
        body: jsonEncode({
          'packageName': packageName,
          'code': code,
          'unit': unit,
          'amount': amount,
        }),
      );

      final responseData = jsonDecode(response.body);
      print("Create Return Package - responsebody: ${response.body}");
      print("Create Return Package - statusCode: ${response.statusCode}");
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Package returned successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to return package',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateReturnPackage({
    required String id,
    required String packageName,
    required String code,
    required String unit,
    required double amount,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${baseUrl}return-packages/$id'),
        headers: _headers,
        body: jsonEncode({
          'packageName': packageName,
          'code': code,
          'unit': unit,
          'amount': amount,
        }),
      );

      final responseData = jsonDecode(response.body);
      print("Update Return Package - responsebody: ${response.body}");
      print("Update Return Package - statusCode: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Package updated successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update package',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteReturnPackage(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}return-packages/$id'),
        headers: _headers,
      );

      final responseData = jsonDecode(response.body);
      print("Delete Return Package - responsebody: ${response.body}");
      print("Delete Return Package - statusCode: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Package deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete package',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ============ SAVE ALL RETURN DATA ============
  
  Future<Map<String, dynamic>> saveAllReturnData({
    required List<Map<String, dynamic>> products,
    List<Map<String, dynamic>> packages = const [],
  }) async {
    try {
      List<Map<String, dynamic>> productResults = [];
      List<Map<String, dynamic>> packageResults = [];

      // Save products
      for (var product in products) {
        if (product['productName'] != null && product['productName'].toString().isNotEmpty) {
          final result = await createReturnProduct(
            productName: product['productName'],
            code: product['code'] ?? '',
            unit: product['unit'] ?? '',
            amount: double.tryParse(product['amount'] ?? '0') ?? 0.0,
          );
          productResults.add(result);
        }
      }

      // Save packages
      for (var pkg in packages) {
        if (pkg['packageName'] != null && pkg['packageName'].toString().isNotEmpty) {
          final result = await createReturnPackage(
            packageName: pkg['packageName'],
            code: pkg['code'] ?? '',
            unit: pkg['unit'] ?? '',
            amount: double.tryParse(pkg['amount'] ?? '0') ?? 0.0,
          );
          packageResults.add(result);
        }
      }

      final totalSuccess = productResults.where((r) => r['success'] == true).length +
          packageResults.where((r) => r['success'] == true).length;

      return {
        'success': true,
        'message': '$totalSuccess items saved successfully',
        'productResults': productResults,
        'packageResults': packageResults,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error saving data: $e',
      };
    }
  }
}