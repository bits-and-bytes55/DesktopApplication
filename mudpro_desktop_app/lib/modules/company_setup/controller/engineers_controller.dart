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