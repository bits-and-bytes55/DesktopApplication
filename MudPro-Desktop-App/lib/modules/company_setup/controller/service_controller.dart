import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/service_model.dart';

class ServiceController {
  final String baseUrl = ApiEndpoint.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ============ PACKAGE APIs ============
  
  Future<Map<String, dynamic>> addPackages(List<PackageItem> packages) async {
    try {
      if (packages.length == 1) {
        final response = await http.post(
          Uri.parse('$baseUrl${ApiEndpoint.addPackages}'),
          headers: _headers,
          body: jsonEncode(packages.first.toJson()),
        );

        final responseData = jsonDecode(response.body);
        print("responsebody: ${response.body}");
        print("statusCode: ${response.statusCode}");
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          return {
            'success': true,
            'message': 'Package added successfully',
            'data': responseData['data'],
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to add package',
          };
        }
      } else {
        final response = await http.post(
          Uri.parse('$baseUrl${ApiEndpoint.addBulkPackages}'),
          headers: _headers,
          body: jsonEncode(packages.map((e) => e.toJson()).toList()),
        );

        final responseData = jsonDecode(response.body);
        print("responsebody: ${response.body}");
        print("statusCode: ${response.statusCode}");

        if (response.statusCode == 201 || response.statusCode == 200) {
          return {
            'success': true,
            'message': '${packages.length} packages added successfully',
            'saved': packages.length,
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to add packages',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<List<PackageItem>> getPackages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiEndpoint.getPackages}'),
        headers: _headers,
      );
      print("responsebody: ${response.body}");
      print("statusCode: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((e) => PackageItem.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load packages');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> updatePackage(String id, PackageItem package) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl${ApiEndpoint.updatePackage}/$id'),
        headers: _headers,
        body: jsonEncode(package.toJson()),
      );

      final responseData = jsonDecode(response.body);
      print("responsebody: ${response.body}");
      print("statusCode: ${response.statusCode}");

      if (response.statusCode == 200 ) {
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

  Future<Map<String, dynamic>> deletePackage(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl${ApiEndpoint.deletePackage}/$id'),
        headers: _headers,
      );

      final responseData = jsonDecode(response.body);
      print("responsebody: ${response.body}");
      print("statusCode: ${response.statusCode}");

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Package deleted successfully',
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

  // ============ SERVICE APIs ============
  
  Future<Map<String, dynamic>> addServices(List<ServiceItem> services) async {
    try {
      if (services.length == 1) {
        final response = await http.post(
          Uri.parse('$baseUrl${ApiEndpoint.addServices}'),
          headers: _headers,
          body: jsonEncode(services.first.toJson()),
        );

        final responseData = jsonDecode(response.body);
        print("responsebody: ${response.body}");
        print("statusCode: ${response.statusCode}");
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          return {
            'success': true,
            'message': 'Service added successfully',
            'data': responseData['data'],
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to add service',
          };
        }
      } else {
        final response = await http.post(
          Uri.parse('$baseUrl${ApiEndpoint.addBulkServices}'),
          headers: _headers,
          body: jsonEncode(services.map((e) => e.toJson()).toList()),
        );

        final responseData = jsonDecode(response.body);
        print("responsebody: ${response.body}");
        print("statusCode: ${response.statusCode}");

        if (response.statusCode == 201 || response.statusCode == 200) {
          return {
            'success': true,
            'message': '${services.length} services added successfully',
            'saved': services.length,
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to add services',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<List<ServiceItem>> getServices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiEndpoint.getServices}'),
        headers: _headers,
      );

      print("responsebody: ${response.body}");
      print("statusCode: ${response.statusCode}");
        
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((e) => ServiceItem.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load services');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> updateService(String id, ServiceItem service) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl${ApiEndpoint.updateService}/$id'),
        headers: _headers,
        body: jsonEncode(service.toJson()),
      );

      final responseData = jsonDecode(response.body);
      print("responsebody: ${response.body}");
      print("statusCode: ${response.statusCode}");

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Service updated successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update service',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteService(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl${ApiEndpoint.deleteService}/$id'),
        headers: _headers,
      );

      final responseData = jsonDecode(response.body);
      print("responsebody: ${response.body}");
      print("statusCode: ${response.statusCode}");

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Service deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete service',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ============ ENGINEERING APIs ============
  
  Future<Map<String, dynamic>> addEngineering(List<EngineeringItem> engineering) async {
    try {
      if (engineering.length == 1) {
        final response = await http.post(
          Uri.parse('$baseUrl${ApiEndpoint.addEngineering}'),
          headers: _headers,
          body: jsonEncode(engineering.first.toJson()),
        );

        final responseData = jsonDecode(response.body);
        print("responsebody: ${response.body}");
        print("statusCode: ${response.statusCode}");

        if (response.statusCode == 201 || response.statusCode == 200) {
          return {
            'success': true,
            'message': 'Engineering item added successfully',
            'data': responseData['data'],
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to add engineering',
          };
        }
      } else {
        
        final response = await http.post(
          Uri.parse('$baseUrl${ApiEndpoint.addBulkEngineering}'),
          headers: _headers,
          body: jsonEncode(engineering.map((e) => e.toJson()).toList()),
        );

        final responseData = jsonDecode(response.body);
        print("responsebody: ${response.body}");
        print("statusCode: ${response.statusCode}");

        if (response.statusCode == 201 || response.statusCode == 200) {
          return {
            'success': true,
            'message': '${engineering.length} engineering items added successfully',
            'saved': engineering.length,
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to add engineering',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<List<EngineeringItem>> getEngineering() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiEndpoint.getEngineering}'),
        headers: _headers,
      );

      print("responsebody: ${response.body}");
      print("statusCode: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((e) => EngineeringItem.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load engineering');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> updateEngineering(String id, EngineeringItem engineering) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl${ApiEndpoint.updateEngineering}/$id'),
        headers: _headers,
        body: jsonEncode(engineering.toJson()),
      );

      final responseData = jsonDecode(response.body);
      print("responsebody: ${response.body}");
      print("statusCode: ${response.statusCode}");

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Engineering updated successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update engineering',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteEngineering(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl${ApiEndpoint.deleteEngineering}/$id'),
        headers: _headers,
      );

      final responseData = jsonDecode(response.body);
      print("responsebody: ${response.body}");
      print("statusCode: ${response.statusCode}");

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Engineering deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete engineering',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}