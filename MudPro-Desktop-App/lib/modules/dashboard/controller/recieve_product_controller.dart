import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';

class ReceiveProductController {
  final String baseUrl = ApiEndpoint.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ============ RECEIVE PRODUCT APIs ============
  
  Future<List<Map<String, dynamic>>> getReceiveProducts() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}receive-product'),
        headers: _headers,
      );

      print("Get Receive Products - responsebody: ${response.body}");
      print("Get Receive Products - statusCode: ${response.statusCode}");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((e) => e as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load receive products');
      }
    } catch (e) {
      print('Error fetching receive products: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>> createReceiveProduct({
    required String productName,
    required String code,
    required String unit,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}receive-product'),
        headers: _headers,
        body: jsonEncode({
          'productName': productName,
          'code': code,
          'unit': unit,
          'amount': amount,
        }),
      );

      final responseData = jsonDecode(response.body);
      print("Create Receive Product - responsebody: ${response.body}");
      print("Create Receive Product - statusCode: ${response.statusCode}");
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Product received successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to receive product',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateReceiveProduct({
    required String id,
    required String productName,
    required String code,
    required String unit,
    required double amount,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${baseUrl}receive-product/$id'),
        headers: _headers,
        body: jsonEncode({
          'productName': productName,
          'code': code,
          'unit': unit,
          'amount': amount,
        }),
      );

      final responseData = jsonDecode(response.body);
      print("Update Receive Product - responsebody: ${response.body}");
      print("Update Receive Product - statusCode: ${response.statusCode}");
      
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

  Future<Map<String, dynamic>> deleteReceiveProduct(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}receive-product/$id'),
        headers: _headers,
      );

      final responseData = jsonDecode(response.body);
      print("Delete Receive Product - responsebody: ${response.body}");
      print("Delete Receive Product - statusCode: ${response.statusCode}");
      
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

  // ============ RECEIVE PACKAGE APIs ============
  
  Future<List<Map<String, dynamic>>> getReceivePackages() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}receive-package'),
        headers: _headers,
      );

      print("Get Receive Packages - responsebody: ${response.body}");
      print("Get Receive Packages - statusCode: ${response.statusCode}");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((e) => e as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load receive packages');
      }
    } catch (e) {
      print('Error fetching receive packages: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>> createReceivePackage({
    required String packageName,
    required String code,
    required String unit,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}receive-package'),
        headers: _headers,
        body: jsonEncode({
          'packageName': packageName,
          'code': code,
          'unit': unit,
          'amount': amount,
        }),
      );

      final responseData = jsonDecode(response.body);
      print("Create Receive Package - responsebody: ${response.body}");
      print("Create Receive Package - statusCode: ${response.statusCode}");
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Package received successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to receive package',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateReceivePackage({
    required String id,
    required String packageName,
    required String code,
    required String unit,
    required double amount,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${baseUrl}receive-package/$id'),
        headers: _headers,
        body: jsonEncode({
          'packageName': packageName,
          'code': code,
          'unit': unit,
          'amount': amount,
        }),
      );

      final responseData = jsonDecode(response.body);
      print("Update Receive Package - responsebody: ${response.body}");
      print("Update Receive Package - statusCode: ${response.statusCode}");
      
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

  Future<Map<String, dynamic>> deleteReceivePackage(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}receive-package/$id'),
      );

      final responseData = jsonDecode(response.body);
      print("Delete Receive Package - responsebody: ${response.body}");
      print("Delete Receive Package - statusCode: ${response.statusCode}");
      
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

  // ============ SAVE ALL RECEIVE DATA ============
  
  Future<Map<String, dynamic>> saveAllReceiveData({
    required List<Map<String, dynamic>> products,
    List<Map<String, dynamic>> packages = const [],
  }) async {
    try {
      List<Map<String, dynamic>> productResults = [];
      List<Map<String, dynamic>> packageResults = [];

      // Save products
      for (var product in products) {
        if (product['productName'] != null && product['productName'].toString().isNotEmpty) {
          final result = await createReceiveProduct(
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
          final result = await createReceivePackage(
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