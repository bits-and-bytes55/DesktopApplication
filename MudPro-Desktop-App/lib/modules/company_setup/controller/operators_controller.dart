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

  final RxList<OperatorModel> operators = <OperatorModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  final RxMap<int, String> selectedLogos = <int, String>{}.obs;

  // New entry controllers held in the controller for global access (Import)
  final RxList<List<TextEditingController>> newEntryControllers = <List<TextEditingController>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _resetNewEntries();
    fetchOperators();
  }

  void _resetNewEntries() {
    for (var row in newEntryControllers) {
      for (var ctrl in row) ctrl.text = '';
    }
    // We reuse existing row controllers rather than recreating them during normal flush
    if (newEntryControllers.isEmpty) {
      newEntryControllers.add(List.generate(6, (_) => TextEditingController()));
    }
  }

  Future<void> pickLogoImage(int rowIndex) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 80);
      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        selectedLogos[rowIndex] = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        selectedLogos.refresh();
      }
    } catch (e) {
      debugPrint("Error picking logo image: $e");
    }
  }

  void clearLogo(int rowIndex) {
    selectedLogos.remove(rowIndex);
    selectedLogos.refresh();
  }

  Future<Map<String, dynamic>> saveOperators() async {
    isSaving.value = true;
    final List<OperatorModel> list = [];
    for (var i = 0; i < newEntryControllers.length; i++) {
      var row = newEntryControllers[i];
      if (row[0].text.trim().isEmpty) continue;
      list.add(OperatorModel(
        company: row[0].text.trim(),
        contact: row[1].text.trim(),
        address: row[2].text.trim(),
        phone: row[3].text.trim(),
        email: row[4].text.trim(),
        logoUrl: selectedLogos[i] ?? '',
      ));
    }
    if (list.isEmpty) { isSaving.value = false; return {'success': false, 'message': 'No data to save'}; }
    final res = await _repo.saveOperators(list.map((e) => e.toJson()).toList());
    if (res['success'] == true) {
      await fetchOperators();
      _resetNewEntries();
      selectedLogos.clear();
      isSaving.value = false;
      return {'success': true, 'message': 'Operators saved successfully'};
    } else {
      isSaving.value = false;
      return {'success': false, 'message': res['message'] ?? 'Save failed'};
    }
  }

  List<List<String>> getExportData() {
    List<List<String>> data = [['Company', 'Contact', 'Address', 'Phone', 'E-mail', 'Logo URL']];
    for (var op in operators) data.add([op.company, op.contact, op.address, op.phone, op.email, op.logoUrl]);
    return data;
  }

  void importFromData(List<List<String>> rows) {
    _resetNewEntries();
    newEntryControllers.clear();
    for (int i = 0; i < rows.length; i++) {
      if (rows[i].length < 5) continue;
      final controllers = List.generate(6, (_) => TextEditingController());
      controllers[0].text = rows[i][0];
      controllers[1].text = rows[i][1];
      controllers[2].text = rows[i][2];
      controllers[3].text = rows[i][3];
      controllers[4].text = rows[i][4];
      if (rows[i].length > 5 && rows[i][5].startsWith('data:image')) selectedLogos[i] = rows[i][5];
      newEntryControllers.add(controllers);
    }
    if (newEntryControllers.isEmpty) newEntryControllers.add(List.generate(6, (_) => TextEditingController()));
    selectedLogos.refresh();
  }

  Future<void> fetchOperators() async {
    isLoading.value = true;
    final result = await _repo.getOperators();
    if (result['success'] == true) operators.assignAll((result['data'] as List).map((i) => OperatorModel.fromJson(i)).toList());
    isLoading.value = false;
  }

  Future<Map<String, dynamic>> updateOperator(String id, OperatorModel operator) async {
    isSaving.value = true;
    final res = await _repo.updateOperator(id, operator.toJson());
    if (res['success'] == true) { await fetchOperators(); isSaving.value = false; return {'success': true, 'message': 'Updated'}; }
    isSaving.value = false;
    return {'success': false, 'message': res['message'] ?? 'Failed'};
  }

  Future<Map<String, dynamic>> deleteOperator(String id) async {
    isSaving.value = true;
    final res = await _repo.deleteOperator(id);
    if (res['success'] == true) { await fetchOperators(); isSaving.value = false; return {'success': true, 'message': 'Deleted'}; }
    isSaving.value = false;
    return {'success': false, 'message': res['message'] ?? 'Failed'};
  }

  @override
  void onClose() {
    for (var row in newEntryControllers) { for (var ctrl in row) ctrl.dispose(); }
    super.onClose();
  }
}