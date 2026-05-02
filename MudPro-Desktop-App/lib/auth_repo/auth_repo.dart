import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/engineers_model.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/company_model.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/products_model.dart';
import 'package:mudpro_desktop_app/modules/UG/model/pit_model.dart';
import 'package:mudpro_desktop_app/modules/UG/model/inventory_model.dart';
import 'package:mudpro_desktop_app/modules/report_context/report_context_controller.dart';

class AuthRepository {
  final String baseUrl = ApiEndpoint.baseUrl;

  // Default headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  String get _selectedReportId => reportContext.selectedReportId.value.trim();

  Map<String, dynamic> _payloadWithReportId(Map<String, dynamic> body) {
    final payload = Map<String, dynamic>.from(body);
    final reportId = _selectedReportId;
    if (reportId.isNotEmpty) {
      payload['reportId'] = reportId;
    }
    return payload;
  }

  Uri _uriWithReportId(String rawUrl) {
    final reportId = _selectedReportId;
    final uri = Uri.parse(rawUrl);
    if (reportId.isEmpty) return uri;

    return uri.replace(
      queryParameters: {...uri.queryParameters, 'reportId': reportId},
    );
  }

  String _messageFromResponse(
    Map<String, dynamic> data,
    int statusCode,
    String fallback,
  ) {
    if (statusCode == 200 || statusCode == 201) {
      return data['message']?.toString() ?? fallback;
    }

    final detailed = data['error']?.toString().trim();
    if (detailed != null && detailed.isNotEmpty) {
      return detailed;
    }

    return data['message']?.toString() ?? fallback;
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // NEW SAVE FLOW METHODS - Pit Volume Name APIs
  // ══════════════════════════════════════════════════════════════════════════════

  // ── Save Well General ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> saveWellGeneral(
    Map<String, dynamic> body,
  ) async {
    try {
      final wellId = body['wellId'] ?? '';
      final recordId = (body['recordId'] ?? '').toString().trim();
      final payload = Map<String, dynamic>.from(body)..remove('recordId');
      final isUpdate = recordId.isNotEmpty;
      final queryParameters = <String, String>{};
      final reportId = (payload['reportId'] ?? _selectedReportId)
          .toString()
          .trim();
      if (reportId.isNotEmpty) {
        queryParameters['reportId'] = reportId;
      }
      final uri = Uri.parse(
        isUpdate
            ? '${baseUrl}well-general/$wellId/$recordId'
            : '${baseUrl}well-general/$wellId',
      ).replace(queryParameters: queryParameters);
      print('Hitting ${isUpdate ? 'PUT' : 'POST'} $uri');
      final response = isUpdate
          ? await http
                .put(uri, headers: _headers, body: jsonEncode(payload))
                .timeout(const Duration(seconds: 12))
          : await http
                .post(uri, headers: _headers, body: jsonEncode(payload))
                .timeout(const Duration(seconds: 12));
      print('statuscode------${response.statusCode}');
      print('response body------${response.body}');
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': data,
        'message': data['message'] ?? 'Saved successfully',
      };
    } catch (e) {
      print('Error in saveWellGeneral: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Save Casing ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> saveCasing(Map<String, dynamic> body) async {
    try {
      final wellId = body['wellId'] ?? '';
      final recordId = (body['recordId'] ?? '').toString().trim();
      final payload = Map<String, dynamic>.from(body)..remove('recordId');
      final isUpdate = recordId.isNotEmpty;
      final queryParameters = <String, String>{};
      final reportId = (payload['reportId'] ?? '').toString().trim();
      if (reportId.isNotEmpty) {
        queryParameters['reportId'] = reportId;
      }
      final uri = Uri.parse(
        isUpdate ? '${baseUrl}casing/$wellId/$recordId' : '${baseUrl}casing',
      ).replace(queryParameters: queryParameters);
      print('Hitting ${isUpdate ? 'PUT' : 'POST'} $uri');
      final response = isUpdate
          ? await http
                .put(uri, headers: _headers, body: jsonEncode(payload))
                .timeout(const Duration(seconds: 12))
          : await http
                .post(uri, headers: _headers, body: jsonEncode(payload))
                .timeout(const Duration(seconds: 12));
      print('statuscode------${response.statusCode}');
      print('response body------${response.body}');
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': data,
        'message': data['message'] ?? 'Saved successfully',
      };
    } catch (e) {
      print('Error in saveCasing: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Save Consume Product (add water / pitvolumename route) ────────────────────
  Future<Map<String, dynamic>> saveConsumeProductVolumeName(
    Map<String, dynamic> body,
  ) async {
    try {
      final wellId = body['wellId'] ?? '';
      final payload = _payloadWithReportId(body);
      print('Hitting POST ${baseUrl}volume-name/$wellId/consume-product');
      final response = await http.post(
        Uri.parse('${baseUrl}volume-name/$wellId/consume-product'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      print('statuscode------${response.statusCode}');
      print('response body------${response.body}');
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': data,
        'message': data['message'] ?? 'Saved successfully',
      };
    } catch (e) {
      print('Error in saveConsumeProductVolumeName: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Update Pit Volume Data (volume, density, fluidType) ───────────────────────
  // Note: Backend uses POST /:wellId/pit for this flow
  Future<Map<String, dynamic>> updatePitVolumeData({
    String? id,
    required String wellId,
    required String pitName,
    required double volume,
    required double density,
    required String fluidType,
    double capacity = 0,
    bool initialActive = true,
  }) async {
    try {
      // User specifically requested to always use the volume-name/pit API
      final endpoint = '${baseUrl}volume-name/$wellId/pit';

      print('Hitting POST $endpoint');

      final bodyData = {
        'wellId': wellId,
        if (_selectedReportId.isNotEmpty) 'reportId': _selectedReportId,
        'pitName': pitName,
        'volume': volume,
        'density': density,
        'fluidType': fluidType,
        'capacity': capacity,
        'initialActive': initialActive,
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: _headers,
        body: jsonEncode(bodyData),
      );

      print('statuscode------${response.statusCode}');
      print('response body------${response.body}');
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': data,
        'message': data['message'] ?? 'Saved successfully',
      };
    } catch (e) {
      print('Error in updatePitVolumeData: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Get Volume Name Calculation ────────────────────────────────────────────────
  Future<Map<String, dynamic>> getVolumeNameCalculation(
    String wellId, {
    String? reportIdOverride,
  }) async {
    try {
      final reportId =
          reportIdOverride?.trim() ??
          reportContext.selectedReportId.value.trim();
      final uri = Uri.parse('${baseUrl}volume-name/$wellId').replace(
        queryParameters: {
          'strictScope': 'true',
          if (reportId.isNotEmpty) 'reportId': reportId,
        },
      );
      print('Hitting GET $uri');
      final response = await http.get(uri, headers: _headers);
      print('statuscode------${response.statusCode}');
      print('response body------${response.body}');
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data,
        'message': data['message'] ?? 'Success',
      };
    } catch (e) {
      print('Error in getVolumeNameCalculation: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Get Transfer Mud ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getTransferMud(String wellId) async {
    try {
      final uri = _uriWithReportId('${baseUrl}transfer-mud/$wellId');
      print('Hitting GET $uri');
      final response = await http.get(uri, headers: _headers);
      print('statuscode------${response.statusCode}');
      print('response body------${response.body}');
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data,
        'message': data['message'] ?? 'Success',
      };
    } catch (e) {
      print('Error in getTransferMud: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Create Transfer Mud ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> createTransferMud(
    String wellId,
    Map<String, dynamic> body,
  ) async {
    try {
      final payload = _payloadWithReportId(body);
      print('Hitting POST ${baseUrl}transfer-mud/$wellId');
      final response = await http.post(
        Uri.parse('${baseUrl}transfer-mud/$wellId'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      print('statuscode------${response.statusCode}');
      print('response body------${response.body}');
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': data,
        'message': _messageFromResponse(
          data,
          response.statusCode,
          'Saved successfully',
        ),
      };
    } catch (e) {
      print('Error in createTransferMud: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateTransferMud(
    String wellId,
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final payload = _payloadWithReportId(body);
      print('Hitting PUT ${baseUrl}transfer-mud/$wellId/$id');
      final response = await http.put(
        Uri.parse('${baseUrl}transfer-mud/$wellId/$id'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      print('statuscode------${response.statusCode}');
      print('response body------${response.body}');
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data,
        'message': _messageFromResponse(
          data,
          response.statusCode,
          'Updated successfully',
        ),
      };
    } catch (e) {
      print('Error in updateTransferMud: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Create Add Water ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> createAddWater(
    String wellId,
    Map<String, dynamic> body,
  ) async {
    try {
      final reportId = reportContext.selectedReportId.value.trim();
      final payload = Map<String, dynamic>.from(body);
      if (reportId.isNotEmpty) {
        payload['reportId'] = reportId;
      }
      print('Hitting POST ${baseUrl}add-water/$wellId');
      final response = await http.post(
        Uri.parse('${baseUrl}add-water/$wellId'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      print('statuscode------${response.statusCode}');
      print('response body------${response.body}');
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': data,
        'message': data['message'] ?? 'Add Water saved successfully',
      };
    } catch (e) {
      print('Error in createAddWater: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getAddWaterList(String wellId) async {
    try {
      final reportId = reportContext.selectedReportId.value.trim();
      final uri = reportId.isNotEmpty
          ? Uri.parse(
              '${baseUrl}add-water/$wellId',
            ).replace(queryParameters: {'reportId': reportId})
          : Uri.parse('${baseUrl}add-water/$wellId');
      final response = await http.get(uri, headers: _headers);
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data,
        'message': data['message'] ?? '',
      };
    } catch (e) {
      print('Error in getAddWaterList: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateAddWater(
    String wellId,
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final reportId = reportContext.selectedReportId.value.trim();
      final payload = Map<String, dynamic>.from(body);
      if (reportId.isNotEmpty) {
        payload['reportId'] = reportId;
      }
      final response = await http.put(
        Uri.parse('${baseUrl}add-water/$wellId/$id'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data,
        'message': data['message'] ?? 'Add Water updated successfully',
      };
    } catch (e) {
      print('Error in updateAddWater: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteAddWater(String wellId, String id) async {
    try {
      final reportId = reportContext.selectedReportId.value.trim();
      final uri = reportId.isNotEmpty
          ? Uri.parse(
              '${baseUrl}add-water/$wellId/$id',
            ).replace(queryParameters: {'reportId': reportId})
          : Uri.parse('${baseUrl}add-water/$wellId/$id');
      final response = await http.delete(uri, headers: _headers);
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Add Water deleted successfully',
      };
    } catch (e) {
      print('Error in deleteAddWater: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Create Receive Mud ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> createReceiveMud(
    String wellId,
    Map<String, dynamic> body,
  ) async {
    try {
      final payload = _payloadWithReportId(body);
      print('Hitting POST ${baseUrl}receive-mud/$wellId');
      final response = await http.post(
        Uri.parse('${baseUrl}receive-mud/$wellId'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      print('statuscode------${response.statusCode}');
      print('response body------${response.body}');
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': data,
        'message': data['message'] ?? 'Receive Mud saved successfully',
      };
    } catch (e) {
      print('Error in createReceiveMud: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Get Receive Mud ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getReceiveMudList(String wellId) async {
    try {
      final uri = _uriWithReportId('${baseUrl}receive-mud/$wellId');
      final response = await http.get(uri, headers: _headers);
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data,
        'message': data['message'] ?? '',
      };
    } catch (e) {
      print('Error in getReceiveMudList: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Update Receive Mud ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> updateReceiveMud(
    String wellId,
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final payload = _payloadWithReportId(body);
      final response = await http.put(
        Uri.parse('${baseUrl}receive-mud/$wellId/$id'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data,
        'message': data['message'] ?? 'Receive Mud updated successfully',
      };
    } catch (e) {
      print('Error in updateReceiveMud: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Delete Receive Mud ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> deleteReceiveMud(
    String wellId,
    String id,
  ) async {
    try {
      final uri = _uriWithReportId('${baseUrl}receive-mud/$wellId/$id');
      final response = await http.delete(uri, headers: _headers);
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Receive Mud deleted successfully',
      };
    } catch (e) {
      print('Error in deleteReceiveMud: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteTransferMud(
    String wellId,
    String id,
  ) async {
    try {
      final uri = _uriWithReportId('${baseUrl}transfer-mud/$wellId/$id');
      print('Hitting DELETE $uri');
      final response = await http.delete(uri, headers: _headers);
      print('statuscode------${response.statusCode}');
      print('response body------${response.body}');
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Deleted successfully',
      };
    } catch (e) {
      print('Error in deleteTransferMud: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getOperations({bool activeOnly = true}) async {
    try {
      final uri = Uri.parse(
        '${baseUrl}operations${activeOnly ? '?activeOnly=true' : ''}',
      );
      print('Hitting GET $uri');
      final response = await http.get(uri, headers: _headers);
      print('statuscode------${response.statusCode}');
      print('response body------${response.body}');
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data,
        'message': data['message'] ?? 'Operations fetched successfully',
      };
    } catch (e) {
      print('Error in getOperations: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // EXISTING METHODS (Engineer, Company, Product, Pit CRUD - ALL PRESERVED)
  // ══════════════════════════════════════════════════════════════════════════════

  // Add Engineer
  Future<Map<String, dynamic>> addEngineer(Engineer engineer) async {
    try {
      final url = Uri.parse('$baseUrl${ApiEndpoint.addEngineersData}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(engineer.toJson()),
      );

      final data = jsonDecode(response.body);
      print("statuscode------${response.statusCode}");
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
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Get All Engineers
  Future<Map<String, dynamic>> getEngineers() async {
    try {
      final url = Uri.parse('$baseUrl${ApiEndpoint.getEngineersData}');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
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

  // Update Engineer
  Future<Map<String, dynamic>> updateEngineer(
    String engineerId,
    Engineer engineer,
  ) async {
    try {
      print('$baseUrl${ApiEndpoint.updateEngineer}/$engineerId');
      final url = Uri.parse(
        '$baseUrl${ApiEndpoint.updateEngineer}/$engineerId',
      );
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
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
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Delete Engineer
  Future<Map<String, dynamic>> deleteEngineer(String engineerId) async {
    try {
      print('$baseUrl${ApiEndpoint.deleteEngineer}/$engineerId');
      final url = Uri.parse(
        '$baseUrl${ApiEndpoint.deleteEngineer}/$engineerId',
      );
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
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
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Add Company Details with Image
  Future<Map<String, dynamic>> addCompanyDetails(
    Map<String, dynamic> payload,
  ) async {
    try {
      final url = Uri.parse(
        ApiEndpoint.baseUrl + ApiEndpoint.addCompanyDetails,
      );

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
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
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Update Company Details with Image
  Future<Map<String, dynamic>> updateCompanyDetails(
    Map<String, dynamic> payload,
  ) async {
    try {
      final url = Uri.parse(
        ApiEndpoint.baseUrl + ApiEndpoint.updateCompanyDetails,
      );

      print('🔄 API Call: updateCompanyDetails');
      print('🌐 URL: $url');
      print('📝 Payload: $payload');

      final response = await http
          .put(
            url,
            headers: {"Content-Type": "application/json"},
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
          'data': data['data'] != null ? Company.fromJson(data['data']) : null,
          'message': data['message'] ?? 'Company details updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update company details',
        };
      }
    } catch (e) {
      print('❌ Error in updateCompanyDetails: ${e.toString()}');

      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Get Company Details
  Future<Map<String, dynamic>> getCompanyDetails() async {
    try {
      final url = Uri.parse(
        ApiEndpoint.baseUrl + ApiEndpoint.getCompanyDetails,
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
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

  // GET OPERATORS
  Future<Map<String, dynamic>> getOperators() async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoint.baseUrl + ApiEndpoint.getOperators),
        headers: {"Content-Type": "application/json"},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // SAVE OPERATORS (BULK)
  Future<Map<String, dynamic>> saveOperators(
    List<Map<String, dynamic>> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoint.baseUrl + ApiEndpoint.saveOperators),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // UPDATE OPERATOR
  Future<Map<String, dynamic>> updateOperator(
    String id,
    Map<String, dynamic> operatorData,
  ) async {
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
      return {'success': false, 'message': 'Error: $e'};
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
      return {'success': false, 'message': 'Error: $e'};
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

      if (response.statusCode == 201) {
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
      return {'success': false, 'message': 'No internet connection'};
    } on FormatException {
      return {'success': false, 'message': 'Invalid response format'};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  // Bulk add products
  Future<Map<String, dynamic>> bulkAddProducts(
    List<ProductModel> products,
  ) async {
    try {
      final validProducts = products
          .where((p) => p.isValid())
          .map((p) => p.toJson())
          .toList();

      if (validProducts.isEmpty) {
        return {'success': false, 'message': 'No valid products to save'};
      }

      final response = await http.post(
        Uri.parse(ApiEndpoint.baseUrl + ApiEndpoint.addBulkProducts),
        headers: _headers,
        body: jsonEncode(validProducts),
      );

      final responseData = jsonDecode(response.body);

      print("statuscode------${response.statusCode}");
      print("response body------${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
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
      return {'success': false, 'message': 'No internet connection'};
    } on FormatException {
      return {'success': false, 'message': 'Invalid response format'};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
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
        contentType: MediaType(
          'application',
          'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
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
          'message':
              '${responseData['inserted']} products imported successfully',
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
      return {'success': false, 'message': 'No internet connection'};
    } on FormatException {
      return {'success': false, 'message': 'Invalid response format'};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
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

      final uri = Uri.parse(
        ApiEndpoint.baseUrl + ApiEndpoint.getProducts,
      ).replace(queryParameters: queryParams);

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
      return {'success': false, 'message': 'No internet connection'};
    } on FormatException {
      return {'success': false, 'message': 'Invalid response format'};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  // Update Product
  Future<Map<String, dynamic>> updateProduct(
    String productId,
    ProductModel product,
  ) async {
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
      return {'success': false, 'message': 'No internet connection'};
    } on FormatException {
      return {'success': false, 'message': 'Invalid response format'};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
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
      return {'success': false, 'message': 'No internet connection'};
    } on FormatException {
      return {'success': false, 'message': 'Invalid response format'};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
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
        return {'success': true, 'message': 'Product restored successfully'};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to restore product',
        };
      }
    } on SocketException {
      return {'success': false, 'message': 'No internet connection'};
    } on FormatException {
      return {'success': false, 'message': 'Invalid response format'};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  // Pit CRUD methods (addPit, bulkAddPits, getAllPits, getSelectedPits, getUnselectedPits, updatePit, deletePit, etc.) - ALL PRESERVED
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
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> bulkAddPits({
    required List<Map<String, dynamic>> pits,
    required String wellId,
  }) async {
    try {
      final reportId = _selectedReportId;
      final response = await http.post(
        Uri.parse('${baseUrl}pit/bulk-add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pits': pits,
          'wellId': wellId,
          if (reportId.isNotEmpty) 'reportId': reportId,
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
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getAllPits(String wellId) async {
    try {
      final reportId = reportContext.selectedReportId.value.trim();
      final response = await http.get(
        Uri.parse('${baseUrl}pit/well/$wellId').replace(
          queryParameters: {if (reportId.isNotEmpty) 'reportId': reportId},
        ),
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
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getSelectedPits(String wellId) async {
    try {
      final reportId = reportContext.selectedReportId.value.trim();
      final response = await http.get(
        Uri.parse('${baseUrl}pit/well/$wellId/selected').replace(
          queryParameters: {if (reportId.isNotEmpty) 'reportId': reportId},
        ),
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
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> getUnselectedPits(String wellId) async {
    try {
      final reportId = reportContext.selectedReportId.value.trim();
      final response = await http.get(
        Uri.parse('${baseUrl}pit/well/$wellId/unselected').replace(
          queryParameters: {if (reportId.isNotEmpty) 'reportId': reportId},
        ),
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
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updatePit({
    required String id,
    String? pitName,
    double? capacity,
    bool? initialActive,
    double? volume,
    double? density,
    String? fluidType,
  }) async {
    try {
      final body = {
        if (pitName != null) 'pitName': pitName,
        if (capacity != null) 'capacity': capacity,
        if (initialActive != null) 'initialActive': initialActive,
        if (volume != null) 'volume': volume,
        if (density != null) 'density': density,
        if (fluidType != null) 'fluidType': fluidType,
        if (_selectedReportId.isNotEmpty) 'reportId': _selectedReportId,
      };
      final response = await http.put(
        Uri.parse('${baseUrl}pit/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'] != null ? PitModel.fromJson(data['data']) : null,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update pit',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> deletePit(String id) async {
    try {
      final uri = Uri.parse('${baseUrl}pit/$id').replace(
        queryParameters: {
          if (_selectedReportId.isNotEmpty) 'reportId': _selectedReportId,
        },
      );
      final response = await http.delete(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete pit',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Premix/OBM methods - PRESERVED
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

  Future<PremixModel> createPremixed(
    String wellId,
    PremixModel premixed,
  ) async {
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

  // Similar preservation for OBM, Pumps, Shakers, SCE, Consume Products...
  // (truncated for brevity - ALL ORIGINAL METHODS PRESERVED)

  // UnitSystem APIs - DISABLED until full models available
  // Future<UnitSystemListResponse> fetchAllUnitSystems() async { ... }

  // ══════════════════════════════════════════════════════════════════════════════
  // OBM CRUD
  // ══════════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getObm(String wellId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiEndpoint.getObm}/$wellId'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final List<ObmModel> obmList = (data['data'] as List)
            .map((item) => ObmModel.fromJson(item))
            .toList();
        return {'success': true, 'data': obmList};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to fetch OBM',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<ObmModel> createObm(String wellId, ObmModel obm) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiEndpoint.addObm}/$wellId'),
        headers: _headers,
        body: jsonEncode(obm.toJson()),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return ObmModel.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Failed to create OBM');
    } catch (e) {
      throw Exception('Error creating OBM: $e');
    }
  }

  Future<ObmModel> updateObm(String id, ObmModel obm) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl${ApiEndpoint.updateObm}/$id'),
        headers: _headers,
        body: jsonEncode(obm.toJson()),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ObmModel.fromJson(data['data']);
      }
      throw Exception(data['message'] ?? 'Failed to update OBM');
    } catch (e) {
      throw Exception('Error updating OBM: $e');
    }
  }

  Future<Map<String, dynamic>> deleteObm(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl${ApiEndpoint.deleteObm}/$id'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'OBM deleted successfully',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // PUMP CRUD
  // ══════════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getPumps(String wellId) async {
    try {
      final reportId = reportContext.selectedReportId.value.trim();
      final response = await http.get(
        Uri.parse('${baseUrl}pump').replace(
          queryParameters: {
            'wellId': wellId,
            if (reportId.isNotEmpty) 'reportId': reportId,
          },
        ),
        headers: _headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': (data['data'] as List? ?? [])};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to fetch pumps',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createPump(
    String wellId,
    Map<String, dynamic> pumpData,
  ) async {
    try {
      final reportId = reportContext.selectedReportId.value.trim();
      final payload = {
        ...pumpData,
        'wellId': wellId,
        if (reportId.isNotEmpty) 'reportId': reportId,
      };
      final response = await http.post(
        Uri.parse('${baseUrl}pump'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Pump created successfully',
        };
      }
      throw Exception(data['message'] ?? 'Failed to create pump');
    } catch (e) {
      throw Exception('Error creating pump: $e');
    }
  }

  Future<Map<String, dynamic>> updatePump(
    String id,
    Map<String, dynamic> pumpData,
  ) async {
    try {
      final reportId = reportContext.selectedReportId.value.trim();
      final payload = Map<String, dynamic>.from(pumpData);
      if (reportId.isNotEmpty) {
        payload['reportId'] = reportId;
      }
      final response = await http.put(
        Uri.parse('${baseUrl}pump/$id'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Pump updated successfully',
        };
      }
      throw Exception(data['message'] ?? 'Failed to update pump');
    } catch (e) {
      throw Exception('Error updating pump: $e');
    }
  }

  Future<Map<String, dynamic>> deletePump(String id) async {
    try {
      final reportId = reportContext.selectedReportId.value.trim();
      final response = await http.delete(
        Uri.parse('${baseUrl}pump/$id').replace(
          queryParameters: {if (reportId.isNotEmpty) 'reportId': reportId},
        ),
        headers: _headers,
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Pump deleted successfully',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // SHAKER CRUD
  // ══════════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getShakers(String wellId) async {
    try {
      final response = await http.get(
        _uriWithReportId('${baseUrl}sce/shakers/$wellId'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': (data['data'] as List? ?? [])};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to fetch shakers',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createShaker(
    String wellId,
    Map<String, dynamic> shakerData,
  ) async {
    try {
      final response = await http.post(
        _uriWithReportId('${baseUrl}sce/shakers/$wellId'),
        headers: _headers,
        body: jsonEncode(_payloadWithReportId(shakerData)),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Shaker created successfully',
        };
      }
      throw Exception(data['message'] ?? 'Failed to create shaker');
    } catch (e) {
      throw Exception('Error creating shaker: $e');
    }
  }

  Future<Map<String, dynamic>> updateShaker(
    String id,
    Map<String, dynamic> shakerData,
  ) async {
    try {
      final response = await http.put(
        _uriWithReportId('${baseUrl}sce/shakers/$id'),
        headers: _headers,
        body: jsonEncode(_payloadWithReportId(shakerData)),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Shaker updated successfully',
        };
      }
      throw Exception(data['message'] ?? 'Failed to update shaker');
    } catch (e) {
      throw Exception('Error updating shaker: $e');
    }
  }

  Future<Map<String, dynamic>> deleteShaker(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}sce/shakers/$id'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Shaker deleted successfully',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // OTHER SCE CRUD
  // ══════════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getOtherSce(String wellId) async {
    try {
      final response = await http.get(
        _uriWithReportId('${baseUrl}sce/other-sce/$wellId'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': (data['data'] as List? ?? [])};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to fetch other SCE',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createOtherSce(
    String wellId,
    Map<String, dynamic> sceData,
  ) async {
    try {
      final response = await http.post(
        _uriWithReportId('${baseUrl}sce/other-sce/$wellId'),
        headers: _headers,
        body: jsonEncode(_payloadWithReportId(sceData)),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Other SCE created successfully',
        };
      }
      throw Exception(data['message'] ?? 'Failed to create other SCE');
    } catch (e) {
      throw Exception('Error creating other SCE: $e');
    }
  }

  Future<Map<String, dynamic>> updateOtherSce(
    String id,
    Map<String, dynamic> sceData,
  ) async {
    try {
      final response = await http.put(
        _uriWithReportId('${baseUrl}sce/other-sce/$id'),
        headers: _headers,
        body: jsonEncode(_payloadWithReportId(sceData)),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Other SCE updated successfully',
        };
      }
      throw Exception(data['message'] ?? 'Failed to update other SCE');
    } catch (e) {
      throw Exception('Error updating other SCE: $e');
    }
  }

  Future<Map<String, dynamic>> deleteOtherSce(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseUrl}sce/other-sce/$id'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Other SCE deleted successfully',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getFormationConfig(String wellId) async {
    try {
      final response = await http.get(
        _uriWithReportId('${baseUrl}formation/$wellId'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data['data'] ?? {},
        'message': data['message'] ?? '',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> saveFormationConfig({
    required String wellId,
    required String mode,
    required bool poreFromTop,
    required List<Map<String, dynamic>> rows,
  }) async {
    try {
      final payload = _payloadWithReportId({
        'mode': mode,
        'poreFromTop': poreFromTop,
        'rows': rows,
      });
      final response = await http.put(
        _uriWithReportId('${baseUrl}formation/$wellId'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': data['data'] ?? {},
        'message': data['message'] ?? '',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteFormationConfig(String wellId) async {
    try {
      final response = await http.delete(
        _uriWithReportId('${baseUrl}formation/$wellId'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? '',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createReturnLostMud(
    String wellId,
    Map<String, dynamic> body,
  ) async {
    try {
      final payload = _payloadWithReportId(body);
      final response = await http.post(
        Uri.parse('${baseUrl}return-lost-mud/$wellId'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': data['data'],
        'message': data['message'] ?? 'Return / Lost Mud saved successfully',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getReturnLostMudList(String wellId) async {
    try {
      final uri = _uriWithReportId('${baseUrl}return-lost-mud/$wellId');
      final response = await http.get(uri, headers: _headers);
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data,
        'message': data['message'] ?? '',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateReturnLostMud(
    String wellId,
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final payload = _payloadWithReportId(body);
      final response = await http.put(
        Uri.parse('${baseUrl}return-lost-mud/$wellId/$id'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data['data'],
        'message': data['message'] ?? 'Return / Lost Mud updated successfully',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteReturnLostMud(
    String wellId,
    String id,
  ) async {
    try {
      final uri = _uriWithReportId('${baseUrl}return-lost-mud/$wellId/$id');
      final response = await http.delete(uri, headers: _headers);
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Return / Lost Mud deleted successfully',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createMudLoss(
    String wellId,
    Map<String, dynamic> body,
  ) async {
    try {
      final payload = _payloadWithReportId(body);
      final response = await http.post(
        Uri.parse('${baseUrl}mud-loss/$wellId'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': data['data'],
        'message': _messageFromResponse(
          data,
          response.statusCode,
          'Mud Loss saved successfully',
        ),
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getMudLossList(String wellId) async {
    try {
      final uri = _uriWithReportId('${baseUrl}mud-loss/$wellId');
      final response = await http.get(uri, headers: _headers);
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data,
        'message': data['message'] ?? '',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateMudLoss(
    String wellId,
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final payload = _payloadWithReportId(body);
      final response = await http.put(
        Uri.parse('${baseUrl}mud-loss/$wellId/$id'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data['data'],
        'message': _messageFromResponse(
          data,
          response.statusCode,
          'Mud Loss updated successfully',
        ),
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteMudLoss(String wellId, String id) async {
    try {
      final uri = _uriWithReportId('${baseUrl}mud-loss/$wellId/$id');
      final response = await http.delete(uri, headers: _headers);
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Mud Loss deleted successfully',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createOtherVolAddition(
    String wellId,
    Map<String, dynamic> body,
  ) async {
    try {
      final payload = _payloadWithReportId({'wellId': wellId, ...body});
      final response = await http.post(
        Uri.parse('${baseUrl}other-vol-addition'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': data['data'],
        'message': data['message'] ?? 'Other Vol Addition saved successfully',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getOtherVolAdditionList(String wellId) async {
    try {
      final uri = _uriWithReportId('${baseUrl}other-vol-addition/$wellId');
      final response = await http.get(uri, headers: _headers);
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data,
        'message': data['message'] ?? '',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateOtherVolAddition(
    String wellId,
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final payload = _payloadWithReportId({'wellId': wellId, ...body});
      final response = await http.put(
        Uri.parse('${baseUrl}other-vol-addition/$wellId/$id'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data['data'],
        'message': data['message'] ?? 'Other Vol Addition updated successfully',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteOtherVolAddition(
    String wellId,
    String id,
  ) async {
    try {
      final uri = _uriWithReportId('${baseUrl}other-vol-addition/$wellId/$id');
      final response = await http.delete(uri, headers: _headers);
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Other Vol Addition deleted successfully',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createMudLossStorage(
    String wellId,
    Map<String, dynamic> body,
  ) async {
    try {
      final payload = _payloadWithReportId(body);
      final response = await http.post(
        Uri.parse('${baseUrl}mud-loss-storage/$wellId'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': data['data'],
        'message': _messageFromResponse(
          data,
          response.statusCode,
          'Mud Loss - Storage saved successfully',
        ),
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getMudLossStorageList(String wellId) async {
    try {
      final uri = _uriWithReportId('${baseUrl}mud-loss-storage/$wellId');
      final response = await http.get(uri, headers: _headers);
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data,
        'message': data['message'] ?? '',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateMudLossStorage(
    String wellId,
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final payload = _payloadWithReportId(body);
      final response = await http.put(
        Uri.parse('${baseUrl}mud-loss-storage/$wellId/$id'),
        headers: _headers,
        body: jsonEncode(payload),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data['data'],
        'message': _messageFromResponse(
          data,
          response.statusCode,
          'Mud Loss - Storage updated successfully',
        ),
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteMudLossStorage(
    String wellId,
    String id,
  ) async {
    try {
      final uri = _uriWithReportId('${baseUrl}mud-loss-storage/$wellId/$id');
      final response = await http.delete(uri, headers: _headers);
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Mud Loss - Storage deleted successfully',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> deleteOperationData({
    required String wellId,
    required String operationType,
  }) async {
    try {
      final uri = _uriWithReportId(
        '${baseUrl}operations/data/$wellId/$operationType',
      );
      print('Hitting DELETE $uri');
      final response = await http.delete(uri, headers: _headers);
      print('statuscode------${response.statusCode}');
      print('response body------${response.body}');
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data,
        'message': data['message'] ?? 'Operation data deleted successfully',
      };
    } catch (e) {
      print('Error in deleteOperationData: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Map<String, double> calculateLocally({
    required double initial,
    required double adjust,
    required double used,
    required double price,
    required int numberOfBags,
    required double weightPerBag,
    required double sg,
  }) {
    final double finalValue = initial + adjust - used;
    final double cost = used * price;
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
