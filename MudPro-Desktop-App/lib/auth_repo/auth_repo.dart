// lib/repositories/engineer_repository.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/company_model.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/engineers_model.dart';

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


   // Add Company Details with Image
  Future<Map<String, dynamic>> addCompanyDetails(Company company, {File? logoFile}) async {
    try {
      final url = Uri.parse(ApiEndpoint.baseUrl + ApiEndpoint.addCompanyDetails);
      
      var request = http.MultipartRequest('POST', url);
      
      // Add text fields
      request.fields['companyName'] = company.companyName;
      request.fields['address'] = company.address;
      request.fields['phone'] = company.phone;
      request.fields['email'] = company.email;
      request.fields['currencySymbol'] = company.currencySymbol;
      request.fields['currencyFormat'] = company.currencyFormat;

      // Add logo file if provided
      if (logoFile != null) {
        var logoStream = http.ByteStream(logoFile.openRead());
        var logoLength = await logoFile.length();
        
        var multipartFile = http.MultipartFile(
          'logo',
          logoStream,
          logoLength,
          filename: logoFile.path.split('/').last,
        );
        
        request.files.add(multipartFile);
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': data['data'] != null ? Company.fromJson(data['data']) : null,
          'message': data['message'] ?? 'Company details saved successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to save company details',
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
  Future<Map<String, dynamic>> updateCompanyDetails(Company company, {File? logoFile}) async {
    try {
      final url = Uri.parse(ApiEndpoint.baseUrl + ApiEndpoint.updateCompanyDetails);
      
      var request = http.MultipartRequest('PUT', url);
      
      // Add text fields
      request.fields['companyName'] = company.companyName;
      request.fields['address'] = company.address;
      request.fields['phone'] = company.phone;
      request.fields['email'] = company.email;
      request.fields['currencySymbol'] = company.currencySymbol;
      request.fields['currencyFormat'] = company.currencyFormat;

      // Add logo file if provided
      if (logoFile != null) {
        var logoStream = http.ByteStream(logoFile.openRead());
        var logoLength = await logoFile.length();
        
        var multipartFile = http.MultipartFile(
          'logo',
          logoStream,
          logoLength,
          filename: logoFile.path.split('/').last,
        );
        
        request.files.add(multipartFile);
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
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
}