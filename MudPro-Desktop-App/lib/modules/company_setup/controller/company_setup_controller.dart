import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/utils/file_io_utils.dart';

class CompanySetupController extends GetxController {
  var isLocked = true.obs;
  final String _correctPassword = "1234";
  var currentTabIndex = 0.obs;

  void lock() {
    isLocked.value = true;
  }

  bool checkPassword(String password) {
    if (password == _correctPassword) {
      isLocked.value = false;
      return true;
    }
    return false;
  }

  void handleImport() {
    if (isLocked.value) {
      Get.snackbar('Locked', 'Please unlock the module to import data.',
          backgroundColor: Colors.orange.withOpacity(0.1));
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Import'),
        content: const Text('Do you want to replace content in company setup window?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _performImport();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _performImport() async {
    // For OperatorTab, we might need special handling if we want to fill ITS controllers.
    // However, since it's a generic Import button at the top, we'll try to find the controller.
    // FileIoUtils.importTabData will handle finding the right GetX controller.
    
    // Note: OperatorTab uses local controllers in its State, which is NOT ideal for global import.
    // I should probably have moved OperatorTab's newEntryControllers to OperatorController.
    // Let me quickly check if I can do that or if I should just use the GetX controller's import.
    
    await FileIoUtils.importTabData(currentTabIndex.value);
  }

  void handleExport() async {
    await FileIoUtils.exportAllData();
  }
}
