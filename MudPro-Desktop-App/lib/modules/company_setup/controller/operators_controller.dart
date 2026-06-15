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
    selectedLogos[rowIndex] = '';
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
    List<List<String>> data = [[
      'Record ID',
      'Company',
      'Contact',
      'Address',
      'Phone',
      'E-mail',
      'Logo URL',
    ]];
    for (var op in operators) {
      data.add([
        op.id ?? '',
        op.company,
        op.contact,
        op.address,
        op.phone,
        op.email,
        op.logoUrl,
      ]);
    }
    return data;
  }

  Future<Map<String, dynamic>> importFromData(List<List<String>> rows) async {
    final importedRows = _parseImportedRows(rows);
    if (importedRows.isEmpty) {
      return {
        'success': false,
        'message': 'No valid operator rows found in the selected file',
      };
    }

    int updated = 0;
    int inserted = 0;
    final errors = <String>[];

    final byId = <String, OperatorModel>{};
    final byEmail = <String, OperatorModel>{};
    final byCompany = <String, OperatorModel>{};
    for (final operator in operators) {
      final id = operator.id?.trim();
      if (id != null && id.isNotEmpty) {
        byId[id] = operator;
      }
      final emailKey = _normalizeKey(operator.email);
      if (emailKey.isNotEmpty) {
        byEmail[emailKey] = operator;
      }
      final companyKey = _normalizeKey(operator.company);
      if (companyKey.isNotEmpty) {
        byCompany[companyKey] = operator;
      }
    }

    final newOperators = <OperatorModel>[];

    for (final row in importedRows) {
      final matchedOperator = _findExistingOperator(
        row: row,
        byId: byId,
        byEmail: byEmail,
        byCompany: byCompany,
      );

      final importedOperator = OperatorModel(
        id: matchedOperator?.id,
        company: row.company,
        contact: row.contact,
        address: row.address,
        phone: row.phone,
        email: row.email,
        logoUrl:
            row.logoUrl.isEmpty ? (matchedOperator?.logoUrl ?? '') : row.logoUrl,
      );

      if (matchedOperator?.id != null) {
        if (!_sameOperatorData(matchedOperator!, importedOperator)) {
          final updatePayload = {
            'company': importedOperator.company,
            'contact': importedOperator.contact,
            'address': importedOperator.address,
            'phone': importedOperator.phone,
            'email': importedOperator.email,
            'logoUrl': importedOperator.logoUrl,
          };
          final result = await _repo.updateOperator(
            matchedOperator.id!,
            updatePayload,
          );
          if (result['success'] == true) {
            updated += 1;
          } else {
            errors.add(
              'Operator ${row.company}: ${result['message'] ?? 'Update failed'}',
            );
          }
        }
      } else {
        newOperators.add(importedOperator);
      }
    }

    if (newOperators.isNotEmpty) {
      final result = await _repo.saveOperators(
        newOperators.map((item) => item.toJson()).toList(),
      );
      if (result['success'] == true) {
        inserted += newOperators.length;
      } else {
        errors.add(result['message'] ?? 'Failed to add imported operators');
      }
    }

    await fetchOperators();

    if (errors.isNotEmpty) {
      return {
        'success': false,
        'message':
            'Operator import finished with issues. Updated: $updated, Added: $inserted',
        'updated': updated,
        'inserted': inserted,
        'errors': errors,
      };
    }

    return {
      'success': true,
      'message': 'Operators imported successfully. Updated: $updated, Added: $inserted',
      'updated': updated,
      'inserted': inserted,
    };
  }

  OperatorModel? _findExistingOperator({
    required _ImportedOperatorRow row,
    required Map<String, OperatorModel> byId,
    required Map<String, OperatorModel> byEmail,
    required Map<String, OperatorModel> byCompany,
  }) {
    final recordId = row.recordId.trim();
    if (recordId.isNotEmpty && byId.containsKey(recordId)) {
      return byId[recordId];
    }

    final emailKey = _normalizeKey(row.email);
    if (emailKey.isNotEmpty && byEmail.containsKey(emailKey)) {
      return byEmail[emailKey];
    }

    final companyKey = _normalizeKey(row.company);
    if (companyKey.isNotEmpty && byCompany.containsKey(companyKey)) {
      return byCompany[companyKey];
    }

    return null;
  }

  bool _sameOperatorData(OperatorModel existing, OperatorModel imported) {
    return existing.company.trim() == imported.company.trim() &&
        existing.contact.trim() == imported.contact.trim() &&
        existing.address.trim() == imported.address.trim() &&
        existing.phone.trim() == imported.phone.trim() &&
        existing.email.trim() == imported.email.trim() &&
        existing.logoUrl.trim() == imported.logoUrl.trim();
  }

  List<_ImportedOperatorRow> _parseImportedRows(List<List<String>> rows) {
    if (rows.isEmpty) return const [];

    final header = rows.first.map((cell) => cell.trim().toLowerCase()).toList();
    final hasRecordId = header.isNotEmpty && header.first == 'record id';
    final startIndex = _looksLikeOperatorHeader(rows.first) ? 1 : 0;
    final parsed = <_ImportedOperatorRow>[];

    for (int i = startIndex; i < rows.length; i += 1) {
      final row = List<String>.from(rows[i]);
      final minimumLength = hasRecordId ? 7 : 6;
      while (row.length < minimumLength) {
        row.add('');
      }

      if (_looksLikeOperatorHeader(row)) {
        continue;
      }

      final offset = hasRecordId ? 1 : 0;
      final values = row.skip(offset).take(6).map((value) => value.trim()).toList();
      if (values.every((value) => value.isEmpty)) {
        continue;
      }

      parsed.add(
        _ImportedOperatorRow(
          recordId: hasRecordId ? row[0].trim() : '',
          company: values[0],
          contact: values[1],
          address: values[2],
          phone: values[3],
          email: values[4],
          logoUrl: values[5],
        ),
      );
    }

    return parsed;
  }

  bool _looksLikeOperatorHeader(List<String> row) {
    final normalized = row.map((cell) => cell.trim().toLowerCase()).toList();
    return normalized.contains('company') &&
        normalized.contains('contact') &&
        normalized.contains('e-mail');
  }

  String _normalizeKey(String value) => value.trim().toLowerCase();

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

class _ImportedOperatorRow {
  final String recordId;
  final String company;
  final String contact;
  final String address;
  final String phone;
  final String email;
  final String logoUrl;

  const _ImportedOperatorRow({
    required this.recordId,
    required this.company,
    required this.contact,
    required this.address,
    required this.phone,
    required this.email,
    required this.logoUrl,
  });
}
