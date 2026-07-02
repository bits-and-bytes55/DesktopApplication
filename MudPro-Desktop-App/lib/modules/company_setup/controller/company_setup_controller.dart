import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/utils/file_io_utils.dart';

class CompanySetupController extends GetxController {
  var isLocked = true.obs;
  final String _correctPassword = "1234";
  var currentTabIndex = 0.obs;
  Worker? _dashboardLockWorker;

  @override
  void onInit() {
    super.onInit();
    final dashboardController = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : null;
    if (dashboardController != null) {
      isLocked.value = dashboardController.isLocked.value;
      _dashboardLockWorker = ever<bool>(dashboardController.isLocked, (locked) {
        if (isLocked.value != locked) {
          isLocked.value = locked;
        }
      });
    }
  }

  @override
  void onClose() {
    _dashboardLockWorker?.dispose();
    super.onClose();
  }

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
      Get.snackbar(
        'Locked',
        'Please unlock the module to import data.',
        backgroundColor: Colors.orange.withOpacity(0.1),
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Import'),
        content: const Text(
          'Do you want to replace content in company setup window?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('No')),
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
    await FileIoUtils.importTabData(currentTabIndex.value);
  }

  void handleExport() async {
    await FileIoUtils.exportTabData(currentTabIndex.value);
  }

  void handleExportAll() async {
    await FileIoUtils.exportAllData();
  }
}
