// lib/repositories/engineer_repository.dart

import 'dart:convert';
import 'dart:io' as io;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/UG/model/inventory_model.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/company_model.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/engineers_model.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/service_model.dart';

class AuthRepository {
  final String baseUrl = ApiEndpoint.baseUrl;

  // Add Engineer
  Future<Map<String, dynamic>> addEngineer(Engineer engineer) async {
    try {
      final url = Uri.parse('$baseUrl${ApiEndpoint.addEngineersData}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(engineer.toJson()),
      );

      final data = jsonDecode(response.body);
      print( "statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': data['data'] != null ? Engineer.fromJson(data['data']) : null,
          'message': data['message'] ?? 'Engineer added successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to add engineer',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Get All Engineers
  Future<Map<String, dynamic>> getEngineers() async {
    try {
      final url = Uri.parse('$baseUrl${ApiEndpoint.getEngineersData}');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 200) {
        List<Engineer> engineers = [];
        if (data['data'] != null) {
          engineers = (data['data'] as List)
              .map((item) => Engineer.fromJson(item))
              .toList();
        }

        return {
          'success': true,
          'data': engineers,
          'message': data['message'] ?? 'Engineers fetched successfully',
        };
      } else {
        return {
          'success': false,
          'data': <Engineer>[],
          'message': data['message'] ?? 'Failed to fetch engineers',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': <Engineer>[],
        'message': 'Error: ${e.toString()}',
      };
    }
  }


  // Add these methods to your existing AuthRepository class

// Update Engineer
Future<Map<String, dynamic>> updateEngineer(String engineerId, Engineer engineer) async {
  try {

    print('$baseUrl${ApiEndpoint.updateEngineer}/$engineerId');
    final url = Uri.parse('$baseUrl${ApiEndpoint.updateEngineer}/$engineerId');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(engineer.toJson()),
    );

    final data = jsonDecode(response.body);
        print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': Engineer.fromJson(data['data']),
        'message': data['message'] ?? 'Engineer updated successfully',
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to update engineer',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Error: ${e.toString()}',
    };
  }
}

// Delete Engineer
Future<Map<String, dynamic>> deleteEngineer(String engineerId) async {
  try {
     print('$baseUrl${ApiEndpoint.deleteEngineer}/$engineerId');
    final url = Uri.parse('$baseUrl${ApiEndpoint.deleteEngineer}/$engineerId');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
      print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': data['message'] ?? 'Engineer deleted successfully',
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to delete engineer',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Error: ${e.toString()}',
    };
  }
}


   // Add Company Details with Image
  Future<Map<String, dynamic>> addCompanyDetails(Map<String, dynamic> payload) async {
  try {
    final url = Uri.parse(ApiEndpoint.baseUrl + ApiEndpoint.addCompanyDetails);

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );

    final data = jsonDecode(response.body);

    print("statuscode------${response.statusCode}");
    print("response body------${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'data': data['data'] != null ? Company.fromJson(data['data']) : null,
        'message': data['message'] ?? 'Company saved successfully',
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to save company',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Error: ${e.toString()}',
    };
  }
}


  // Update Company Details with Image
 Future<Map<String, dynamic>> updateCompanyDetails(
    Map<String, dynamic> payload) async {
  try {
    final url =
        Uri.parse(ApiEndpoint.baseUrl + ApiEndpoint.updateCompanyDetails);

    print('🔄 API Call: updateCompanyDetails');
    print('🌐 URL: $url');
    print('📝 Payload: $payload');

    final response = await http
        .put(
          url,
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode(payload),
        )
        .timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        print('⏰ Request timed out after 30 seconds');
        throw Exception('Request timed out');
      },
    );

    print("statuscode------${response.statusCode}");
    print("response body------${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': data['data'] != null
            ? Company.fromJson(data['data'])
            : null,
        'message':
            data['message'] ?? 'Company details updated successfully',
      };
    } else {
      return {
        'success': false,
        'message':
            data['message'] ?? 'Failed to update company details',
      };
    }
  } catch (e) {
    print('❌ Error in updateCompanyDetails: ${e.toString()}');

    return {
      'success': false,
      'message': 'Error: ${e.toString()}',
    };
  }
}


  // Get Company Details
  Future<Map<String, dynamic>> getCompanyDetails() async {
    try {
      final url = Uri.parse(ApiEndpoint.baseUrl + ApiEndpoint.getCompanyDetails);
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 200) {
        Company? company;
        if (data['data'] != null) {
          company = Company.fromJson(data['data']);
        }

        return {
          'success': true,
          'data': company,
          'message': data['message'] ?? 'Company details fetched successfully',
        };
      } else {
        return {
          'success': false,
          'data': null,
          'message': data['message'] ?? 'Failed to fetch company details',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Error: ${e.toString()}',
      };
    }
  }



/// ===============================
  /// GET OPERATORS
  /// ===============================
  Future<Map<String, dynamic>> getOperators() async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoint.baseUrl + ApiEndpoint.getOperators),
        headers: {"Content-Type": "application/json"},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  /// ===============================
  /// SAVE OPERATORS (BULK)
  /// ===============================
  Future<Map<String, dynamic>> saveOperators(
      List<Map<String, dynamic>> body) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoint.baseUrl + ApiEndpoint.saveOperators),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }
 

 // Default headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };


  // UPDATE OPERATOR
Future<Map<String, dynamic>> updateOperator(
    String id, Map<String, dynamic> operatorData) async {
  try {
    final response = await http.put(
      Uri.parse('${ApiEndpoint.baseUrl}${ApiEndpoint.updateOperator}/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(operatorData),
    );

    final responseData = jsonDecode(response.body);
    print("Update operator response: ${response.body}");
    print("Status code: ${response.statusCode}");

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': responseData['message'] ?? 'Operator updated successfully',
        'data': responseData['data'],
      };
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to update operator',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Error: $e',
    };
  }
}

// DELETE OPERATOR
Future<Map<String, dynamic>> deleteOperator(String id) async {
  try {
    final response = await http.delete(
      Uri.parse('${ApiEndpoint.baseUrl}${ApiEndpoint.deleteOperator}/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    final responseData = jsonDecode(response.body);
    print("Delete operator response: ${response.body}");
    print("Status code: ${response.statusCode}");

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': responseData['message'] ?? 'Operator deleted successfully',
      };
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to delete operator',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Error: $e',
    };
  }
}

  // Add single product
  Future<Map<String, dynamic>> addProduct(ProductModel product) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoint.baseUrl + ApiEndpoint.addProducts),
        headers: _headers,
        body: jsonEncode(product.toJson()),
      );

      final responseData = jsonDecode(response.body);
      print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 201 ) {
        return {
          'success': true,
          'message': 'Product added successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to add product',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    } on FormatException {
      return {
        'success': false,
        'message': 'Invalid response format',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  // Bulk add products
  Future<Map<String, dynamic>> bulkAddProducts(List<ProductModel> products) async {
    try {
      final validProducts = products
          .where((p) => p.isValid())
          .map((p) => p.toJson())
          .toList();

      if (validProducts.isEmpty) {
        return {
          'success': false,
          'message': 'No valid products to save',
        };
      }

      final response = await http.post(
        Uri.parse(ApiEndpoint.baseUrl + ApiEndpoint.addBulkProducts),
        headers: _headers,
        body: jsonEncode(validProducts),
      );

      final responseData = jsonDecode(response.body);

      print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 201  || response.statusCode == 200) {
        return {
          'success': true,
          'message': '${responseData['saved']} products saved successfully',
          'saved': responseData['saved'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to save products',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    } on FormatException {
      return {
        'success': false,
        'message': 'Invalid response format',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  // Upload Excel file
  Future<Map<String, dynamic>> uploadExcel(String filePath) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiEndpoint.baseUrl + ApiEndpoint.addExcel),
      );

      // Add file
      var file = await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: MediaType('application', 'vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
      );
      
      request.files.add(file);

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      final responseData = jsonDecode(response.body);
      print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': '${responseData['inserted']} products imported successfully',
          'inserted': responseData['inserted'],
          'errors': responseData['errors'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to upload Excel',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    } on FormatException {
      return {
        'success': false,
        'message': 'Invalid response format',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  // Get products (pagination)
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
    String? group,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (group != null && group.isNotEmpty) 'Group': group,
      };

      final uri = Uri.parse(ApiEndpoint.baseUrl + ApiEndpoint.getProducts).replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri, headers: _headers);
      final responseData = jsonDecode(response.body);

      print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<ProductModel> products = (responseData['data'] as List)
            .map((json) => ProductModel.fromJson(json))
            .toList();

        return {
          'success': true,
          'products': products,
          'total': responseData['total'],
          'page': responseData['page'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch products',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    } on FormatException {
      return {
        'success': false,
        'message': 'Invalid response format',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

 // Add these methods to your existing AuthRepository class

// Update Product
Future<Map<String, dynamic>> updateProduct(String productId, ProductModel product) async {
  try {

     print('${baseUrl}v1/products/$productId');
    final response = await http.put(
      Uri.parse('${baseUrl}v1/products/$productId'),
      headers: _headers,
      body: jsonEncode(product.toJson()),
    );

    final responseData = jsonDecode(response.body);

     print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'data': ProductModel.fromJson(responseData['data']),
        'message': responseData['message'] ?? 'Product updated successfully',
      };
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to update product',
      };
    }
  } on SocketException {
    return {
      'success': false,
      'message': 'No internet connection',
    };
  } on FormatException {
    return {
      'success': false,
      'message': 'Invalid response format',
    };
  } catch (e) {
    return {
      'success': false,
      'message': 'An unexpected error occurred: $e',
    };
  }
}

// Delete Product
Future<Map<String, dynamic>> deleteProduct(String productId) async {
  try {

    print('${baseUrl}v1/products/$productId');

    final response = await http.delete(
      Uri.parse('${baseUrl}v1/products/$productId'),
      headers: _headers,
    );

    final responseData = jsonDecode(response.body);

     print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'message': responseData['message'] ?? 'Product deleted successfully',
      };
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to delete product',
      };
    }
  } on SocketException {
    return {
      'success': false,
      'message': 'No internet connection',
    };
  } on FormatException {
    return {
      'success': false,
      'message': 'Invalid response format',
    };
  } catch (e) {
    return {
      'success': false,
      'message': 'An unexpected error occurred: $e',
    };
  }
}

  // Restore product
  Future<Map<String, dynamic>> restoreProduct(String id) async {
    try {
      final response = await http.put(
        Uri.parse('${baseUrl}v1/products/restore/$id'),
        headers: _headers,
      );

      final responseData = jsonDecode(response.body);

       print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Product restored successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to restore product',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    } on FormatException {
      return {
        'success': false,
        'message': 'Invalid response format',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }


  // ============= CREATE OPERATIONS =============
  
  /// Add single pit
  Future<Map<String, dynamic>> addPit({
    required String pitName,
    required double capacity,
    required bool initialActive,
    required String wellId,
    String? reportId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}pit/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pitName': pitName,
          'capacity': capacity,
          'initialActive': initialActive,
          'wellId': wellId,
          if (reportId != null) 'reportId': reportId,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': PitModel.fromJson(data['data']),
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to add pit',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Bulk add pits
  Future<Map<String, dynamic>> bulkAddPits({
    required List<Map<String, dynamic>> pits,
    required String wellId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}pit/bulk-add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pits': pits,
          'wellId': wellId,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        final List<PitModel> insertedPits = (data['data'] as List)
            .map((pit) => PitModel.fromJson(pit))
            .toList();
        
        return {
          'success': true,
          'data': insertedPits,
          'message': data['message'],
          'skipped': data['skipped'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to add pits',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ============= READ OPERATIONS =============
  
  /// Get all pits for a well
  Future<Map<String, dynamic>> getAllPits(String wellId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}pit/well/$wellId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      print("statuscode------${response.statusCode}");
      print("response body------${response.body}");
      
      if (response.statusCode == 200) {
        final List<PitModel> pits = (data['data'] as List)
            .map((pit) => PitModel.fromJson(pit))
            .toList();
        
        return {
          'success': true,
          'data': pits,
          'totalCapacity': data['totalCapacity'],
          'count': data['count'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch pits',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Get selected (active) pits
  Future<Map<String, dynamic>> getSelectedPits(String wellId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}pit/well/$wellId/selected'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final List<PitModel> pits = (data['data'] as List)
            .map((pit) => PitModel.fromJson(pit))
            .toList();
        
        return {
          'success': true,
          'data': pits,
          'totalCapacity': data['totalCapacity'],
          'count': data['count'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch selected pits',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Get unselected (inactive) pits
  Future<Map<String, dynamic>> getUnselectedPits(String wellId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}pit/well/$wellId/unselected'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final List<PitModel> pits = (data['data'] as List)
            .map((pit) => PitModel.fromJson(pit))
            .toList();
        
        return {
          'success': true,
          'data': pits,
          'totalCapacity': data['totalCapacity'],
          'count': data['count'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch unselected pits',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Get single pit by ID
  Future<Map<String, dynamic>> getPitById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}pit/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': PitModel.fromJson(data['data']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch pit',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ============= UPDATE OPERATIONS =============
  
  /// Update single pit
  Future<Map<String, dynamic>> updatePit({
    required String id,
    String? pitName,
    double? capacity,
    bool? initialActive,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${baseUrl}pit/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (pitName != null) 'pitName': pitName,
          if (capacity != null) 'capacity': capacity,
          if (initialActive != null) 'initialActive': initialActive,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': PitModel.fromJson(data['data']),
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update pit',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Bulk update pits
  Future<Map<String, dynamic>> bulkUpdatePits(
    List<Map<String, dynamic>> updates,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${baseUrl}pit/bulk-update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'updates': updates}),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'modifiedCount': data['modifiedCount'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update pits',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Toggle lock/unlock pit
  Future<Map<String, dynamic>> toggleLockPit({
    required String id,
    required bool isLocked,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('${baseUrl}pit/$id/toggle-lock'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isLocked': isLocked}),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': PitModel.fromJson(data['data']),
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to toggle lock',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // ============= DELETE OPERATIONS =============
  
  /// Delete single pit
  Future<Map<String, dynamic>> deletePit(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}pit/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete pit',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Bulk delete pits
  Future<Map<String, dynamic>> bulkDeletePits(List<String> ids) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}pit/bulk-delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ids': ids}),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'deletedCount': data['deletedCount'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete pits',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Delete all pits for a well
  Future<Map<String, dynamic>> deleteAllPitsByWell(String wellId) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}pit/well/$wellId/all'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'deletedCount': data['deletedCount'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete pits',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }


  // ==================== PREMIXED API ====================

  Future<List<PremixModel>> getPremixed(String wellId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}${ApiEndpoint.getPremixed}/$wellId'),
        headers: _headers,
      );

       print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success']) {
          List<PremixModel> premixedList = (data['data'] as List)
              .map((item) => PremixModel.fromJson(item))
              .toList();
          return premixedList;
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch premixed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching premixed: $e');
      throw e;
    }
  }

  Future<PremixModel> createPremixed(String wellId, PremixModel premixed) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}${ApiEndpoint.addPremixed}/$wellId'),
        headers: _headers,
        body: json.encode(premixed.toJson()),
      );

       print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return PremixModel.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to create premixed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating premixed: $e');
      throw e;
    }
  }

  Future<PremixModel> updatePremixed(String id, PremixModel premixed) async {
    try {
      final response = await http.put(
        Uri.parse('${baseUrl}${ApiEndpoint.updatePremixed}/$id'),
        headers: _headers,
        body: json.encode(premixed.toJson()),
      );

       print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success']) {
          return PremixModel.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to update premixed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating premixed: $e');
      throw e;
    }
  }

  Future<void> deletePremixed(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}${ApiEndpoint.deletePremixed}/$id'),
        headers: _headers,
      );

 print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (!data['success']) {
          throw Exception(data['message'] ?? 'Failed to delete premixed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting premixed: $e');
      throw e;
    }
  }

  // ==================== OBM API ====================

  Future<List<ObmModel>> getObm(String wellId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}${ApiEndpoint.getObm}/$wellId'),
        headers: _headers,
      );

       print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success']) {
          List<ObmModel> obmList = (data['data'] as List)
              .map((item) => ObmModel.fromJson(item))
              .toList();
          return obmList;
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch OBM');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching OBM: $e');
      throw e;
    }
  }

  Future<ObmModel> createObm(String wellId, ObmModel obm) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}${ApiEndpoint.addObm}/$wellId'),
        headers: _headers,
        body: json.encode(obm.toJson()),
      );

       print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return ObmModel.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to create OBM');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating OBM: $e');
      throw e;
    }
  }

  Future<ObmModel> updateObm(String id, ObmModel obm) async {
    try {
      final response = await http.put(
        Uri.parse('${baseUrl}${ApiEndpoint.updateObm}/$id'),
        headers: _headers,
        body: json.encode(obm.toJson()),
      );

       print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success']) {
          return ObmModel.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to update OBM');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating OBM: $e');
      throw e;
    }
  }

  Future<void> deleteObm(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}${ApiEndpoint.deleteObm}/$id'),
        headers: _headers,
      );

      print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (!data['success']) {
          throw Exception(data['message'] ?? 'Failed to delete OBM');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting OBM: $e');
      throw e;
    }
  }

   // ============= PUMP METHODS =============

  // Get all pumps for a well
  // Get all pumps for a well
  Future<Map<String, dynamic>> getPumps(String wellId) async {
    try {
      
      
      final response = await http.get(
        Uri.parse('${baseUrl}pump/well/$wellId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error getting pumps: ${response.statusCode} - ${response.body}');
        return {
          'success': false, 
          'message': 'Failed to get pumps: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Error getting pumps: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Create new pump
  Future<Map<String, dynamic>> createPump(String wellId, Map<String, dynamic> pumpData) async {
    try {
      
      final response = await http.post(
        Uri.parse('${baseUrl}pump/well/$wellId'),
        headers: _headers,
        body: json.encode(pumpData),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('Error creating pump: ${response.statusCode} - ${response.body}');
        return {
          'success': false, 
          'message': 'Failed to create pump: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Error creating pump: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Update pump
  Future<Map<String, dynamic>> updatePump(String pumpId, Map<String, dynamic> pumpData) async {
    try {
     
      
      final response = await http.put(
        Uri.parse('${baseUrl}pump/$pumpId'),
        headers: _headers,
        body: json.encode(pumpData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error updating pump: ${response.statusCode} - ${response.body}');
        return {
          'success': false, 
          'message': 'Failed to update pump: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Error updating pump: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Delete pump
  Future<Map<String, dynamic>> deletePump(String pumpId) async {
    try {
      
      final response = await http.delete(
        Uri.parse('${baseUrl}pump/$pumpId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error deleting pump: ${response.statusCode} - ${response.body}');
        return {
          'success': false, 
          'message': 'Failed to delete pump: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Error deleting pump: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Delete all pumps for a well
  Future<Map<String, dynamic>> deleteAllPumps(String wellId) async {
    try {
      
      final response = await http.delete(
        Uri.parse('${baseUrl}pump/well/$wellId/all'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error deleting all pumps: ${response.statusCode} - ${response.body}');
        return {
          'success': false, 
          'message': 'Failed to delete all pumps: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Error deleting all pumps: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Bulk create/update pumps
  Future<Map<String, dynamic>> bulkUpsertPumps(String wellId, List<Map<String, dynamic>> pumps) async {
    try {
      
      final response = await http.post(
        Uri.parse('${baseUrl}pump/well/$wellId/bulk'),
        headers: _headers,
        body: json.encode({'pumps': pumps}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error bulk upserting pumps: ${response.statusCode} - ${response.body}');
        return {
          'success': false, 
          'message': 'Failed to bulk upsert pumps: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Error bulk upserting pumps: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get pump by ID
  Future<Map<String, dynamic>> getPumpById(String pumpId) async {
    try {
     
      
      final response = await http.get(
        Uri.parse('${baseUrl}pump/well/$pumpId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error getting pump: ${response.statusCode} - ${response.body}');
        return {
          'success': false, 
          'message': 'Failed to get pump: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Error getting pump: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== SHAKER API METHODS ====================
  
  // Get all shakers for a well
  Future<Map<String, dynamic>> getShakers(String wellId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}sce/shakers/$wellId'),
        headers: {'Content-Type': 'application/json'},
      );
      
        print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to get shakers',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Create a new shaker
  Future<Map<String, dynamic>> createShaker(
    String wellId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}sce/shakers/$wellId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      
        print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to create shaker',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Update a shaker
  Future<Map<String, dynamic>> updateShaker(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${baseUrl}sce/shakers/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

         print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to update shaker',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Delete a shaker
  Future<Map<String, dynamic>> deleteShaker(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}sce/shakers/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      
 print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to delete shaker',
        };
      }    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // ==================== OTHER SCE API METHODS ====================
  
  // Get all other SCE for a well
  Future<Map<String, dynamic>> getOtherSce(String wellId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}sce/other-sce/$wellId'),
        headers: {'Content-Type': 'application/json'},
      );
      
 print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to get other SCE',
        };
      }    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Create a new other SCE
  Future<Map<String, dynamic>> createOtherSce(
    String wellId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}sce/other-sce/$wellId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      
 print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to create other SCE',
        };
      }    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Update an other SCE
  Future<Map<String, dynamic>> updateOtherSce(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${baseUrl}sce/other-sce/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      
 print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to update other SCE',
        };
      }    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Delete an other SCE
  Future<Map<String, dynamic>> deleteOtherSce(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}sce/other-sce/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      
 print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to delete other SCE',
        };
      }    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }



   /// Create a new consume product
  Future<Map<String, dynamic>> createConsumeProduct({
    required String productId,
    required double initial,
    required double adjust,
    required double used,
    required double price,
    required int numberOfBags,
    required double weightPerBag,
    required double sg,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}consume-product'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'product': productId,
          'initial': initial,
          'adjust': adjust,
          'used': used,
          'price': price,
          'numberOfBags': numberOfBags,
          'weightPerBag': weightPerBag,
          'sg': sg,
        }),
      );

      final data = jsonDecode(response.body);

        print("statuscode------${response.statusCode}");
      print("response body------${response.body}");
      
      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create consume product',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Get all consume products
  Future<Map<String, dynamic>> getAllConsumeProducts() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}consume-product'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
        print("statuscode------${response.statusCode}");
      print("response body------${response.body}");
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'data': data['data'] ?? [],
          'count': data['count'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch consume products',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Update a consume product
  Future<Map<String, dynamic>> updateConsumeProduct({
    required String id,
    double? initial,
    double? adjust,
    double? used,
    double? price,
    int? numberOfBags,
    double? weightPerBag,
    double? sg,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      
      if (initial != null) body['initial'] = initial;
      if (adjust != null) body['adjust'] = adjust;
      if (used != null) body['used'] = used;
      if (price != null) body['price'] = price;
      if (numberOfBags != null) body['numberOfBags'] = numberOfBags;
      if (weightPerBag != null) body['weightPerBag'] = weightPerBag;
      if (sg != null) body['sg'] = sg;

      final response = await http.put(
        Uri.parse('${baseUrl}consume-product/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
        print("statuscode------${response.statusCode}");
      print("response body------${response.body}");
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update consume product',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Delete a consume product
  Future<Map<String, dynamic>> deleteConsumeProduct(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}consume-product/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

        print("statuscode------${response.statusCode}");
      print("response body------${response.body}");
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete consume product',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Calculate cost and volume locally (for instant feedback)
  Map<String, double> calculateLocally({
    required double initial,
    required double adjust,
    required double used,
    required double price,
    required int numberOfBags,
    required double weightPerBag,
    required double sg,
  }) {
    // Calculate final
    final double finalValue = initial + adjust - used;
    
    // Calculate cost
    final double cost = used * price;
    
    // Calculate volume in BBL
    final double totalWeight = numberOfBags * weightPerBag;
    double volumeBbl = 0.0;
    
    if (sg > 0) {
      volumeBbl = totalWeight / (sg * 158.987);
    }
    
    return {
      'final': finalValue,
      'cost': cost,
      'volumeBbl': double.parse(volumeBbl.toStringAsFixed(3)),
    };
  }
  
}