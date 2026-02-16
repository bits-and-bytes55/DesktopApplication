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

  // List of controllers for table rows
  final List<EngineerRowControllers> rowControllers = [];

  @override
  void onInit() {
    super.onInit();
    // Initialize with 2 empty rows
    _initializeRows(1);
    // Fetch existing engineers
    fetchEngineers();
  }

  @override
  void onClose() {
    // Dispose all controllers
    for (var row in rowControllers) {
      row.dispose();
    }
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
      
      // Update UI with fetched data
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
    // Clear existing rows
    for (var row in rowControllers) {
      row.dispose();
    }
    rowControllers.clear();

    // Add rows for existing engineers
    for (var engineer in engineers) {
      final row = EngineerRowControllers();
      row.firstNameController.text = engineer.firstName;
      row.lastNameController.text = engineer.lastName;
      row.cellController.text = engineer.cell;
      row.officeController.text = engineer.office;
      row.emailController.text = engineer.email;
      row.photoController.text = engineer.photo ?? '';
      row.engineerId = engineer.id;
      rowControllers.add(row);
    }

    // Add 2 empty rows at the end
    _initializeRows(2);
  }

  // Add engineer
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
      
      // Refresh the list
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

  // Save all rows
  Future<void> saveAllRows() async {
    isSaving.value = true;

    int savedCount = 0;
    int errorCount = 0;

    for (var row in rowControllers) {
      if (!row.isEmpty && row.engineerId == null) {
        // Only save rows that have data and are not already saved
        final engineer = Engineer(
          firstName: row.firstNameController.text.trim(),
          lastName: row.lastNameController.text.trim(),
          cell: row.cellController.text.trim(),
          office: row.officeController.text.trim(),
          email: row.emailController.text.trim(),
          photo: row.photoController.text.trim().isEmpty
              ? null
              : row.photoController.text.trim(),
        );

        final result = await _repository.addEngineer(engineer);

        // Print API status and data to terminal
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
      // Set alert message instead of snackbar
      alertMessage.value = '$savedCount engineer(s) saved successfully';

      // Clear alert after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        alertMessage.value = '';
      });

      // Refresh the list
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

  // Check if row is filled and add new row if needed
  void checkAndAddRow(int rowIndex) {
    if (rowIndex >= rowControllers.length - 1) {
      // If editing the last or second-to-last row and it's not empty
      if (!rowControllers[rowIndex].isEmpty) {
        // Add a new empty row
        rowControllers.add(EngineerRowControllers());
      }
    }
  }
}

// Helper class to manage controllers for each row
class EngineerRowControllers {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController cellController = TextEditingController();
  final TextEditingController officeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController photoController = TextEditingController();
  
  String? engineerId; // To track if this row is already saved

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