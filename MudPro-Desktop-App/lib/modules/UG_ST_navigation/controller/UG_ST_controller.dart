import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/UG_ST_navigation/model/UG_ST_model.dart';

class UgStController extends GetxController {
  var selectedWellTab = 0.obs; // 0 = Well
  var isLocked = true.obs;
  var isLoading = false.obs;

  final casingVerticalScroll = ScrollController();
  final casingHorizontalScroll = ScrollController();

  @override
  void onInit() {
    fetchCasings();
    super.onInit();
  }

  @override
  void onClose() {
    casingVerticalScroll.dispose();
    casingHorizontalScroll.dispose();
    super.onClose();
  }

  // Summary table data
  var summaryData = [
    {'type': 'TD', 'amount': '3139.75', 'unit': '(m)'},
    {'type': 'Days', 'amount': '30', 'unit': '(days)'},
    {'type': 'Total Cost', 'amount': '29,967.35', 'unit': '(\$)'},
  ].obs;

  // Big plan table data
  var planData = <List<String>>[
    ["1", "2377.44", "5", "0.00", "8.30", "8.40", "65", "75", "15", "22", "28", "12", "16", "25", "30", "9.5"],
    ["2", "2742.60", "10", "18,641.34", "10.60", "11.00", "68", "78", "18", "25", "30", "14", "18", "28", "32", "9.8"],
    ["3", "3139.75", "30", "29,967.35", "12.50", "13.00", "72", "82", "20", "28", "32", "15", "20", "30", "35", "10.0"],
    ["4", "3500.00", "45", "45,231.20", "13.20", "13.80", "75", "85", "22", "30", "35", "16", "22", "32", "38", "10.2"],
    ["5", "4000.00", "60", "68,945.50", "14.00", "14.50", "78", "88", "24", "32", "38", "18", "24", "35", "40", "10.5"],
    ["6", "4500.00", "75", "92,345.75", "14.80", "15.20", "80", "90", "26", "35", "40", "20", "26", "38", "42", "10.8"],
    ["7", "5000.00", "90", "125,678.90", "15.50", "16.00", "82", "92", "28", "38", "42", "22", "28", "40", "45", "11.0"],
    ["8", "5500.00", "105", "158,234.10", "16.20", "16.80", "85", "95", "30", "40", "45", "24", "30", "42", "48", "11.2"],
  ].obs;

  final casings = <CasingRow>[].obs;

  Future<void> fetchCasings() async {
    isLoading.value = true;
    try {
      final response = await http.get(Uri.parse('${ApiEndpoint.baseUrl}casing'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body['success']) {
          final List<dynamic> data = body['data'];
          casings.assignAll(data.map((e) => CasingRow.fromJson(e)).toList());
        }
      }
    } catch (e) {
      print('Error fetching casings: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCasing(CasingRow casing) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoint.baseUrl}casing'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(casing.toJson()),
      );
      if (response.statusCode == 201) {
        fetchCasings();
      }
    } catch (e) {
      print('Error adding casing: $e');
    }
  }

  Future<void> updateCasing(CasingRow casing) async {
    if (casing.dbId == null) return;
    try {
      final response = await http.put(
        Uri.parse('${ApiEndpoint.baseUrl}casing/${casing.dbId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(casing.toJson()),
      );
      if (response.statusCode == 200) {
        fetchCasings();
      }
    } catch (e) {
      print('Error updating casing: $e');
    }
  }

  Future<void> deleteCasing(String dbId) async {
    try {
      final response = await http.delete(Uri.parse('${ApiEndpoint.baseUrl}casing/$dbId'));
      if (response.statusCode == 200) {
        fetchCasings();
      }
    } catch (e) {
      print('Error deleting casing: $e');
    }
  }


  // Interval list
  final intervals = <String>[
    'UG-0293 ST',
    'New Interval (2)',
    'New Interval (1)',
    'Suspension',
    '8.5" Hole',
  ].obs;


  final sectionData = [
  SectionPoint(0, 0),
  SectionPoint(500, 20),
  SectionPoint(1000, 40),
  SectionPoint(2000, 60),
  SectionPoint(4000, 120),
  SectionPoint(6000, 200),
  SectionPoint(8000, 400),
];


  // Selected index
  final selectedIndex = (-1).obs;

  // Counter for new interval naming
  int _newIntervalCount = 3;

  void select(int index) {
    selectedIndex.value = index;
  }

  void insertBefore() {
    if (selectedIndex.value == -1) return;

    intervals.insert(
      selectedIndex.value,
      'New Interval (${_newIntervalCount++})',
    );
  }

  void insertAfter() {
    if (selectedIndex.value == -1) return;

    intervals.insert(
      selectedIndex.value + 1,
      'New Interval (${_newIntervalCount++})',
    );
  }

  void removeInterval() {
    if (selectedIndex.value == -1) return;

    intervals.removeAt(selectedIndex.value);
    selectedIndex.value = -1;
  }



  void switchWellTab(int index) {
    selectedWellTab.value = index;
  }

  void toggleLock() {
    isLocked.value = !isLocked.value;
  }

  void updateSummaryData(int index, String key, String value) {
    summaryData[index][key] = value;
    summaryData.refresh();
  }

  void updatePlanData(int row, int col, String value) {
    planData[row][col] = value;
    planData.refresh();
  }
}
