// lib/controllers/engineer_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/auth_repo/auth_repo.dart';
import 'package:mudpro_desktop_app/modules/company_setup/model/engineers_model.dart';


class EngineerController extends GetxController {
  final _repository = AuthRepository();

  // Observable list of engineers
  final RxList<Engineer> engineers = <Engineer>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString alertMessage = ''.obs;
  final RxString errorMessage = ''.obs;

  // Tracks which saved engineer row is currently being inline-edited
  final RxnString editingEngineerId = RxnString(null);

  // Inline edit controllers (reused for whichever row is active)
  final TextEditingController inlineFirstName = TextEditingController();
  final TextEditingController inlineLastName  = TextEditingController();
  final TextEditingController inlineCell      = TextEditingController();
  final TextEditingController inlineOffice    = TextEditingController();
  final TextEditingController inlineEmail     = TextEditingController();
  // Keeps original photo value so we don't lose it on inline edit
  String _inlinePhotoValue = '';

  // List of controllers for new (unsaved) table rows
  final List<EngineerRowControllers> rowControllers = [];

  @override
  void onInit() {
    super.onInit();
    _initializeRows(1);
    fetchEngineers();
  }

  @override
  void onClose() {
    for (var row in rowControllers) {
      row.dispose();
    }
    inlineFirstName.dispose();
    inlineLastName.dispose();
    inlineCell.dispose();
    inlineOffice.dispose();
    inlineEmail.dispose();
    super.onClose();
  }

  void _initializeRows(int count) {
    for (int i = 0; i < count; i++) {
      rowControllers.add(EngineerRowControllers());
    }
  }

  // Fetch all engineers
  Future<void> fetchEngineers() async {
    isLoading.value = true;

    final result = await _repository.getEngineers();

    if (result['success'] == true) {
      engineers.value = result['data'] as List<Engineer>;
      _populateRowsFromEngineers();
    } else {
      errorMessage.value = result['message'] ?? 'Failed to fetch engineers';
      Future.delayed(const Duration(seconds: 3), () {
        errorMessage.value = '';
      });
    }

    isLoading.value = false;
  }

  void _populateRowsFromEngineers() {
    for (var row in rowControllers) {
      row.dispose();
    }
    rowControllers.clear();

    for (var engineer in engineers) {
      final row = EngineerRowControllers();
      row.firstNameController.text = engineer.firstName;
      row.lastNameController.text  = engineer.lastName;
      row.cellController.text      = engineer.cell;
      row.officeController.text    = engineer.office;
      row.emailController.text     = engineer.email;
      row.photoController.text     = engineer.photo ?? '';
      row.engineerId               = engineer.id;
      rowControllers.add(row);
    }

    _initializeRows(2);
  }

  // ─── Inline Edit ────────────────────────────────────────────────────────────

  void startInlineEdit(EngineerRowControllers row) {
    // Cancel any other active inline edit first
    if (editingEngineerId.value != null && editingEngineerId.value != row.engineerId) {
      _restoreRow(editingEngineerId.value!);
    }

    inlineFirstName.text   = row.firstNameController.text;
    inlineLastName.text    = row.lastNameController.text;
    inlineCell.text        = row.cellController.text;
    inlineOffice.text      = row.officeController.text;
    inlineEmail.text       = row.emailController.text;
    _inlinePhotoValue      = row.photoController.text;

    editingEngineerId.value = row.engineerId;
  }

  void cancelInlineEdit() {
    if (editingEngineerId.value != null) {
      _restoreRow(editingEngineerId.value!);
    }
    editingEngineerId.value = null;
  }

  // Restore a row's controllers to its original engineer data
  void _restoreRow(String engineerId) {
    final engineer = engineers.firstWhereOrNull((e) => e.id == engineerId);
    if (engineer == null) return;
    final row = rowControllers.firstWhereOrNull((r) => r.engineerId == engineerId);
    if (row == null) return;
    row.firstNameController.text = engineer.firstName;
    row.lastNameController.text  = engineer.lastName;
    row.cellController.text      = engineer.cell;
    row.officeController.text    = engineer.office;
    row.emailController.text     = engineer.email;
    row.photoController.text     = engineer.photo ?? '';
  }

  Future<void> saveInlineEdit() async {
    if (editingEngineerId.value == null) return;

    final updatedEngineer = Engineer(
      id: editingEngineerId.value,
      firstName: inlineFirstName.text.trim(),
      lastName:  inlineLastName.text.trim(),
      cell:      inlineCell.text.trim(),
      office:    inlineOffice.text.trim(),
      email:     inlineEmail.text.trim(),
      photo:     _inlinePhotoValue.isEmpty ? null : _inlinePhotoValue,
    );

    await updateEngineer(editingEngineerId.value!, updatedEngineer);
    // updateEngineer calls fetchEngineers on success which resets rows;
    // clear editing state regardless
    editingEngineerId.value = null;
  }

  // ─── CRUD ───────────────────────────────────────────────────────────────────

  Future<void> addEngineer(Engineer engineer) async {
    isSaving.value = true;

    final result = await _repository.addEngineer(engineer);

    if (result['success'] == true) {
      Get.snackbar(
        'Success',
        result['message'] ?? 'Engineer added successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );
      await fetchEngineers();
    } else {
      Get.snackbar(
        'Error',
        result['message'] ?? 'Failed to add engineer',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    }

    isSaving.value = false;
  }

  Future<void> updateEngineer(String engineerId, Engineer engineer) async {
    isSaving.value = true;

    final result = await _repository.updateEngineer(engineerId, engineer);

    if (result['success'] == true) {
      alertMessage.value = result['message'] ?? 'Engineer updated successfully';
      Future.delayed(const Duration(seconds: 3), () {
        alertMessage.value = '';
      });
      await fetchEngineers();
    } else {
      errorMessage.value = result['message'] ?? 'Failed to update engineer';
      Future.delayed(const Duration(seconds: 3), () {
        errorMessage.value = '';
      });
    }

    isSaving.value = false;
  }

  Future<void> deleteEngineer(String engineerId) async {
    isSaving.value = true;

    final result = await _repository.deleteEngineer(engineerId);

    if (result['success'] == true) {
      alertMessage.value = result['message'] ?? 'Engineer deleted successfully';
      Future.delayed(const Duration(seconds: 3), () {
        alertMessage.value = '';
      });
      await fetchEngineers();
    } else {
      errorMessage.value = result['message'] ?? 'Failed to delete engineer';
      Future.delayed(const Duration(seconds: 3), () {
        errorMessage.value = '';
      });
    }

    isSaving.value = false;
  }

  Future<void> saveAllRows() async {
    isSaving.value = true;

    int savedCount = 0;
    int errorCount = 0;

    for (var row in rowControllers) {
      if (!row.isEmpty && row.engineerId == null) {
        final engineer = Engineer(
          firstName: row.firstNameController.text.trim(),
          lastName:  row.lastNameController.text.trim(),
          cell:      row.cellController.text.trim(),
          office:    row.officeController.text.trim(),
          email:     row.emailController.text.trim(),
          photo:     row.photoController.text.trim().isEmpty
              ? null
              : row.photoController.text.trim(),
        );

        final result = await _repository.addEngineer(engineer);

        debugPrint('API Status: ${result['success']}');
        debugPrint('API Data: ${result['data']}');
        debugPrint('API Message: ${result['message']}');

        if (result['success'] == true) {
          savedCount++;
        } else {
          errorCount++;
        }
      }
    }

    if (savedCount > 0) {
      alertMessage.value = '$savedCount engineer(s) saved successfully';
      Future.delayed(const Duration(seconds: 3), () {
        alertMessage.value = '';
      });
      await fetchEngineers();
    }

    if (errorCount > 0) {
      Get.snackbar(
        'Warning',
        '$errorCount engineer(s) failed to save',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade900,
      );
    }

    if (savedCount == 0 && errorCount == 0) {
      Get.snackbar(
        'Info',
        'No new data to save',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade900,
      );
    }

    isSaving.value = false;
  }

  void checkAndAddRow(int rowIndex) {
    if (rowIndex >= rowControllers.length - 1) {
      if (!rowControllers[rowIndex].isEmpty) {
        rowControllers.add(EngineerRowControllers());
      }
    }
  }

  // ─── Export/Import Helpers ────────────────────────────────────────────────

  List<List<String>> getExportData() {
    List<List<String>> data = [[
      'Record ID',
      'First Name',
      'Last Name',
      'Cell',
      'Office',
      'E-mail',
    ]];
    for (var eng in engineers) {
      data.add([
        eng.id ?? '',
        eng.firstName,
        eng.lastName,
        eng.cell,
        eng.office,
        eng.email,
      ]);
    }
    return data;
  }

  Future<Map<String, dynamic>> importFromData(List<List<String>> rows) async {
    final importedRows = _parseImportedRows(rows);
    if (importedRows.isEmpty) {
      return {
        'success': false,
        'message': 'No valid engineer rows found in the selected file',
      };
    }

    int updated = 0;
    int inserted = 0;
    final errors = <String>[];

    final byId = <String, Engineer>{};
    final byEmail = <String, Engineer>{};
    final byName = <String, Engineer>{};
    for (final engineer in engineers) {
      final id = engineer.id?.trim();
      if (id != null && id.isNotEmpty) {
        byId[id] = engineer;
      }
      final emailKey = _normalizeKey(engineer.email);
      if (emailKey.isNotEmpty) {
        byEmail[emailKey] = engineer;
      }
      final nameKey = _engineerFallbackKey(
        firstName: engineer.firstName,
        lastName: engineer.lastName,
        cell: engineer.cell,
      );
      if (nameKey.isNotEmpty) {
        byName[nameKey] = engineer;
      }
    }

    for (final row in importedRows) {
      final matchedEngineer = _findExistingEngineer(
        row: row,
        byId: byId,
        byEmail: byEmail,
        byName: byName,
      );
      final importedEngineer = Engineer(
        id: matchedEngineer?.id,
        firstName: row.firstName,
        lastName: row.lastName,
        cell: row.cell,
        office: row.office,
        email: row.email,
        photo: matchedEngineer?.photo,
      );

      if (matchedEngineer?.id != null) {
        if (!_sameEngineerData(matchedEngineer!, importedEngineer)) {
          final updatePayload = Engineer(
            firstName: importedEngineer.firstName,
            lastName: importedEngineer.lastName,
            cell: importedEngineer.cell,
            office: importedEngineer.office,
            email: importedEngineer.email,
            photo: importedEngineer.photo,
          );
          final result = await _repository.updateEngineer(
            matchedEngineer.id!,
            updatePayload,
          );
          if (result['success'] == true) {
            updated += 1;
          } else {
            errors.add(
              'Engineer ${row.email.isNotEmpty ? row.email : '${row.firstName} ${row.lastName}'}: ${result['message'] ?? 'Update failed'}',
            );
          }
        }
      } else {
        final result = await _repository.addEngineer(importedEngineer);
        if (result['success'] == true) {
          inserted += 1;
        } else {
          errors.add(
            'Engineer ${row.email.isNotEmpty ? row.email : '${row.firstName} ${row.lastName}'}: ${result['message'] ?? 'Add failed'}',
          );
        }
      }
    }

    await fetchEngineers();

    if (errors.isNotEmpty) {
      return {
        'success': false,
        'message':
            'Engineer import finished with issues. Updated: $updated, Added: $inserted',
        'updated': updated,
        'inserted': inserted,
        'errors': errors,
      };
    }

    return {
      'success': true,
      'message': 'Engineers imported successfully. Updated: $updated, Added: $inserted',
      'updated': updated,
      'inserted': inserted,
    };
  }

  Engineer? _findExistingEngineer({
    required _ImportedEngineerRow row,
    required Map<String, Engineer> byId,
    required Map<String, Engineer> byEmail,
    required Map<String, Engineer> byName,
  }) {
    final recordId = row.recordId.trim();
    if (recordId.isNotEmpty && byId.containsKey(recordId)) {
      return byId[recordId];
    }

    final emailKey = _normalizeKey(row.email);
    if (emailKey.isNotEmpty && byEmail.containsKey(emailKey)) {
      return byEmail[emailKey];
    }

    final nameKey = _engineerFallbackKey(
      firstName: row.firstName,
      lastName: row.lastName,
      cell: row.cell,
    );
    if (nameKey.isNotEmpty && byName.containsKey(nameKey)) {
      return byName[nameKey];
    }

    return null;
  }

  bool _sameEngineerData(Engineer existing, Engineer imported) {
    return existing.firstName.trim() == imported.firstName.trim() &&
        existing.lastName.trim() == imported.lastName.trim() &&
        existing.cell.trim() == imported.cell.trim() &&
        existing.office.trim() == imported.office.trim() &&
        existing.email.trim() == imported.email.trim();
  }

  List<_ImportedEngineerRow> _parseImportedRows(List<List<String>> rows) {
    if (rows.isEmpty) return const [];

    final header = rows.first.map((cell) => cell.trim().toLowerCase()).toList();
    final hasRecordId = header.isNotEmpty && header.first == 'record id';
    final startIndex = _looksLikeEngineerHeader(rows.first) ? 1 : 0;
    final parsed = <_ImportedEngineerRow>[];

    for (int i = startIndex; i < rows.length; i += 1) {
      final row = List<String>.from(rows[i]);
      final minimumLength = hasRecordId ? 6 : 5;
      while (row.length < minimumLength) {
        row.add('');
      }

      if (_looksLikeEngineerHeader(row)) {
        continue;
      }

      final offset = hasRecordId ? 1 : 0;
      final values = row.skip(offset).take(5).map((value) => value.trim()).toList();
      if (values.every((value) => value.isEmpty)) {
        continue;
      }

      parsed.add(
        _ImportedEngineerRow(
          recordId: hasRecordId ? row[0].trim() : '',
          firstName: values[0],
          lastName: values[1],
          cell: values[2],
          office: values[3],
          email: values[4],
        ),
      );
    }

    return parsed;
  }

  bool _looksLikeEngineerHeader(List<String> row) {
    final normalized = row.map((cell) => cell.trim().toLowerCase()).toList();
    return normalized.contains('first name') &&
        normalized.contains('last name') &&
        normalized.contains('e-mail');
  }

  String _normalizeKey(String value) => value.trim().toLowerCase();

  String _engineerFallbackKey({
    required String firstName,
    required String lastName,
    required String cell,
  }) {
    final first = _normalizeKey(firstName);
    final last = _normalizeKey(lastName);
    final phone = _normalizeKey(cell);
    return '$first|$last|$phone';
  }

  void showDeleteConfirmation(BuildContext context, String engineerId, String engineerName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete $engineerName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                deleteEngineer(engineerId);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

// Helper class to manage controllers for each row
class EngineerRowControllers {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController  = TextEditingController();
  final TextEditingController cellController      = TextEditingController();
  final TextEditingController officeController    = TextEditingController();
  final TextEditingController emailController     = TextEditingController();
  final TextEditingController photoController     = TextEditingController();

  String? engineerId;

  bool get isEmpty =>
      firstNameController.text.trim().isEmpty &&
      lastNameController.text.trim().isEmpty &&
      cellController.text.trim().isEmpty &&
      officeController.text.trim().isEmpty &&
      emailController.text.trim().isEmpty;

  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    cellController.dispose();
    officeController.dispose();
    emailController.dispose();
    photoController.dispose();
  }
}

class _ImportedEngineerRow {
  final String recordId;
  final String firstName;
  final String lastName;
  final String cell;
  final String office;
  final String email;

  const _ImportedEngineerRow({
    required this.recordId,
    required this.firstName,
    required this.lastName,
    required this.cell,
    required this.office,
    required this.email,
  });
}
