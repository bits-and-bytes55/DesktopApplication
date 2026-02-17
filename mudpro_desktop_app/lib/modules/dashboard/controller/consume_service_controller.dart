import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';

class ConsumeServiceController {
  final String baseUrl = ApiEndpoint.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ============ CONSUME PACKAGE APIs ============
  
  Future<Map<String, dynamic>> createConsumePackage({
    required String packageName,
    required String code,
    required String unit,
    required double price,
    required double initial,
    required double used,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}cs/consume-packages'),
        headers: _headers,
        body: jsonEncode({
          'packageName': packageName,
          'code': code,
          'unit': unit,
          'price': price,
          'initial': initial,
          'used': used,
        }),
      );

      final responseData = jsonDecode(response.body);
      print("Create Package - responsebody: ${response.body}");
      print("Create Package - statusCode: ${response.statusCode}");
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Package consumption created successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create package consumption',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> calculatePackageCost({
    required double initial,
    required double used,
    required double price,
  }) async {
    try {
      // Calculate locally (same as backend logic)
      final double finalValue = initial - used;
      final double cost = used * price;

      return {
        'success': true,
        'data': {
          'final': finalValue,
          'cost': cost,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error calculating cost: $e',
      };
    }
  }

  // ============ CONSUME SERVICE APIs ============
  
  Future<Map<String, dynamic>> createConsumeService({
    required String serviceName,
    required String code,
    required String unit,
    required double price,
    required double usage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}cs/consume-services'),
        headers: _headers,
        body: jsonEncode({
          'serviceName': serviceName,
          'code': code,
          'unit': unit,
          'price': price,
          'usage': usage,
        }),
      );

      final responseData = jsonDecode(response.body);
      print("Create Service - responsebody: ${response.body}");
      print("Create Service - statusCode: ${response.statusCode}");
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Service consumption created successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create service consumption',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> calculateServiceCost({
    required double usage,
    required double price,
  }) async {
    try {
      // Calculate locally (same as backend logic)
      final double cost = usage * price;

      return {
        'success': true,
        'data': {
          'cost': cost,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error calculating cost: $e',
      };
    }
  }

  // ============ CONSUME ENGINEERING APIs ============
  
  Future<Map<String, dynamic>> createConsumeEngineering({
    required String engineeringName,
    required String code,
    required String unit,
    required double price,
    required double usage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}cs/consume-engineering'),
        headers: _headers,
        body: jsonEncode({
          'engineeringName': engineeringName,
          'code': code,
          'unit': unit,
          'price': price,
          'usage': usage,
        }),
      );

      final responseData = jsonDecode(response.body);
      print("Create Engineering - responsebody: ${response.body}");
      print("Create Engineering - statusCode: ${response.statusCode}");
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Engineering consumption created successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create engineering consumption',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> calculateEngineeringCost({
    required double usage,
    required double price,
  }) async {
    try {
      // Calculate locally (same as backend logic)
      final double cost = usage * price;

      return {
        'success': true,
        'data': {
          'cost': cost,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error calculating cost: $e',
      };
    }
  }

  // ============ SAVE ALL DATA ============
  
  Future<Map<String, dynamic>> saveAllConsumptions({
    required List<Map<String, dynamic>> packages,
    required List<Map<String, dynamic>> services,
    required List<Map<String, dynamic>> engineering,
  }) async {
    try {
      // Save packages
      List<Map<String, dynamic>> packageResults = [];
      for (var pkg in packages) {
        if (pkg['packageName'] != null && pkg['packageName'].toString().isNotEmpty) {
          final result = await createConsumePackage(
            packageName: pkg['packageName'],
            code: pkg['code'] ?? '',
            unit: pkg['unit'] ?? '',
            price: (pkg['price'] ?? 0.0).toDouble(),
            initial: double.tryParse(pkg['initial'] ?? '0') ?? 0.0,
            used: double.tryParse(pkg['used'] ?? '0') ?? 0.0,
          );
          packageResults.add(result);
        }
      }

      // Save services
      List<Map<String, dynamic>> serviceResults = [];
      for (var srv in services) {
        if (srv['serviceName'] != null && srv['serviceName'].toString().isNotEmpty) {
          final result = await createConsumeService(
            serviceName: srv['serviceName'],
            code: srv['code'] ?? '',
            unit: srv['unit'] ?? '',
            price: (srv['price'] ?? 0.0).toDouble(),
            usage: double.tryParse(srv['usage'] ?? '0') ?? 0.0,
          );
          serviceResults.add(result);
        }
      }

      // Save engineering
      List<Map<String, dynamic>> engineeringResults = [];
      for (var eng in engineering) {
        if (eng['engineeringName'] != null && eng['engineeringName'].toString().isNotEmpty) {
          final result = await createConsumeEngineering(
            engineeringName: eng['engineeringName'],
            code: eng['code'] ?? '',
            unit: eng['unit'] ?? '',
            price: (eng['price'] ?? 0.0).toDouble(),
            usage: double.tryParse(eng['usage'] ?? '0') ?? 0.0,
          );
          engineeringResults.add(result);
        }
      }

      // Count successes
      final totalSuccess = packageResults.where((r) => r['success'] == true).length +
          serviceResults.where((r) => r['success'] == true).length +
          engineeringResults.where((r) => r['success'] == true).length;

      return {
        'success': true,
        'message': '$totalSuccess items saved successfully',
        'packageResults': packageResults,
        'serviceResults': serviceResults,
        'engineeringResults': engineeringResults,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error saving data: $e',
      };
    }
  }
}