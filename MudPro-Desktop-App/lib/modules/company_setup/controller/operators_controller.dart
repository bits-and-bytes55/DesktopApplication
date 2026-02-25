import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/operators_model.dart';
import '../../../auth_repo/auth_repo.dart';

class OperatorController extends GetxController {
  final _repo = AuthRepository();
  final ImagePicker _picker = ImagePicker();

  // Observable list of operators
  final RxList<OperatorModel> operators = <OperatorModel>[].obs;
  final RxBool isLoading = false.obs;
  RxBool isSaving = false.obs;

  // Store selected logo images for each row (index -> base64 string)
  final RxMap<int, String> selectedLogos = <int, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOperators();
  }

  /// Pick logo image from gallery
  Future<void> pickLogoImage(int rowIndex) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        // Convert to base64
        final bytes = await File(image.path).readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        
        selectedLogos[rowIndex] = base64Image;
        selectedLogos.refresh();
      }
    } catch (e) {
      print("Error picking logo image: $e");
    }
  }

  /// Clear logo for a specific row
  void clearLogo(int rowIndex) {
    selectedLogos.remove(rowIndex);
    selectedLogos.refresh();
  }

  /// Get logo for a row (from selectedLogos map)
  String? getLogoForRow(int rowIndex) {
    return selectedLogos[rowIndex];
  }

  /// SAVE FROM UI CONTROLLERS
  Future<Map<String, dynamic>> saveOperators(
      List<List<TextEditingController>> uiControllers) async {
    isSaving.value = true;

    final List<OperatorModel> list = [];

    for (var i = 0; i < uiControllers.length; i++) {
      var row = uiControllers[i];
      // skip empty rows
      if (row[0].text.trim().isEmpty) continue;

      // Get logo from selectedLogos map or use empty string
      String logoUrl = selectedLogos[i] ?? '';

      final newOperator = OperatorModel(
        company: row[0].text.trim(),
        contact: row[1].text.trim(),
        address: row[2].text.trim(),
        phone: row[3].text.trim(),
        email: row[4].text.trim(),
        logoUrl: logoUrl,
      );

      // Check if this operator already exists in the fetched operators list
      final exists = operators.any((existing) =>
          existing.company == newOperator.company &&
          existing.contact == newOperator.contact &&
          existing.address == newOperator.address &&
          existing.phone == newOperator.phone &&
          existing.email == newOperator.email);

      if (!exists) {
        list.add(newOperator);
      }
    }

    if (list.isEmpty) {
      isSaving.value = false;
      return {
        'success': false,
        'message': 'No new operator data to save',
      };
    }

    final body = list.map((e) => e.toJson()).toList();
    final res = await _repo.saveOperators(body);

    print("response body====${body}");
    print("response res====${res}");
    print("response statuscode====${res['statusCode']}");

    if (res['success'] == true || res['statusCode'] == 200) {
      // Refresh the operators list after saving
      await fetchOperators();
      // Clear selected logos after save
      selectedLogos.clear();
      isSaving.value = false;
      return {
        'success': true,
        'message': 'Operators saved successfully',
      };
    } else {
      isSaving.value = false;
      return {
        'success': false,
        'message': res['message'] ?? 'Save failed',
      };
    }
  }

  /// FETCH OPERATORS
  Future<void> fetchOperators() async {
    isLoading.value = true;

    final result = await _repo.getOperators();

    if (result['success'] == true) {
      operators.value = (result['data'] as List<dynamic>?)
              ?.map((item) =>
                  OperatorModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];
    } else {
      // No snackbar, handle in widget if needed
      operators.value = [];
    }

    isLoading.value = false;
  }

  /// UPDATE OPERATOR
  Future<Map<String, dynamic>> updateOperator(String id, OperatorModel operator) async {
    isSaving.value = true;

    final result = await _repo.updateOperator(id, operator.toJson());

    if (result['success'] == true) {
      await fetchOperators();
      isSaving.value = false;
      return {
        'success': true,
        'message': 'Operator updated successfully',
      };
    } else {
      isSaving.value = false;
      return {
        'success': false,
        'message': result['message'] ?? 'Failed to update operator',
      };
    }
  }

  /// DELETE OPERATOR
  Future<Map<String, dynamic>> deleteOperator(String id) async {
    isSaving.value = true;

    final result = await _repo.deleteOperator(id);

    if (result['success'] == true) {
      await fetchOperators();
      isSaving.value = false;
      return {
        'success': true,
        'message': 'Operator deleted successfully',
      };
    } else {
      isSaving.value = false;
      return {
        'success': false,
        'message': result['message'] ?? 'Failed to delete operator',
      };
    }
  }
}