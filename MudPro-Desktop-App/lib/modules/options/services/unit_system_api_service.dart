import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import '../model/unit_system_model.dart';

class UnitSystemApiService {
  static final UnitSystemApiService _instance = UnitSystemApiService._internal();
  factory UnitSystemApiService() => _instance;
  UnitSystemApiService._internal();

  final String baseUrl = ApiEndpoint.baseUrl;
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ── Fetch all unit systems ───────────────────────────────────────────────────
  Future<UnitSystemListResponse> fetchAll() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/unitsystems'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final systems = (data['data'] as List? ?? [])
            .map((item) => UnitSystemModel.fromJson(item as Map<String, dynamic>))
            .toList();
        return UnitSystemListResponse(
          success: true,
          data: systems,
        );
      }
      return UnitSystemListResponse(
        success: false,
        data: [],
        message: 'Failed to fetch unit systems',
      );
    } catch (e) {
      return UnitSystemListResponse(
        success: false,
        data: [],
        message: e.toString(),
      );
    }
  }

  // ── Create new unit system ───────────────────────────────────────────────────
  Future<UnitSystemResponse> create({
    required String name,
    required String baseTemplate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/unitsystems'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'baseTemplate': baseTemplate,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UnitSystemResponse(
          success: true,
          data: UnitSystemModel.fromJson(data['data']),
        );
      }
      return UnitSystemResponse(
        success: false,
        message: 'Failed to create unit system',
      );
    } catch (e) {
      return UnitSystemResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // ── Update all parameters ────────────────────────────────────────────────────
  Future<UnitSystemResponse> updateAll({
    required String id,
    required List<Map<String, String>> parameters,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/unitsystems/$id'),
        headers: _headers,
        body: jsonEncode({'parameters': parameters}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UnitSystemResponse(
          success: true,
          data: UnitSystemModel.fromJson(data['data']),
        );
      }
      return UnitSystemResponse(
        success: false,
        message: 'Failed to update unit system',
      );
    } catch (e) {
      return UnitSystemResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  // ── Patch single parameter unit ──────────────────────────────────────────────
  Future<bool> patchParameterUnit({
    required String systemId,
    required String paramNumber,
    required String unit,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/unitsystems/$systemId/parameter/$paramNumber'),
        headers: _headers,
        body: jsonEncode({'unit': unit}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Patch error: $e');
      return false;
    }
  }

  // ── Delete unit system ───────────────────────────────────────────────────────
  Future<bool> delete(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/unitsystems/$id'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Delete error: $e');
      return false;
    }
  }

  // ── Seed default systems (US/SI) ─────────────────────────────────────────────
  Future<UnitSystemListResponse> seedDefaultSystems() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/unitsystems/seed-defaults'),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final systems = (data['data'] as List? ?? [])
            .map((item) => UnitSystemModel.fromJson(item as Map<String, dynamic>))
            .toList();
        return UnitSystemListResponse(
          success: true,
          data: systems,
        );
      }
      return UnitSystemListResponse(
        success: false,
        data: [],
        message: 'Failed to seed defaults',
      );
    } catch (e) {
      return UnitSystemListResponse(
        success: false,
        data: [],
        message: e.toString(),
      );
    }
  }
}
