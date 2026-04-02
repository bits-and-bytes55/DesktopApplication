import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/engineers_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/products_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/services_getx_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/operators_controller.dart';
import 'package:mudpro_desktop_app/modules/company_setup/controller/others_getx_controller.dart';

class FileIoUtils {
  /// Exports all data from all tabs into a single Excel file
  static Future<void> exportAllData() async {
    try {
      final excel = Excel.createExcel();
      
      // Remove default sheet
      excel.delete('Sheet1');

      // 1. Engineers
      final engineerController = Get.find<EngineerController>();
      _addSheet(excel, 'Engineers', engineerController.getExportData());

      // 2. Products
      final productsController = Get.find<ProductsController>();
      _addSheet(excel, 'Products', productsController.getExportData());

      // 3. Services (Multiple tables)
      final servicesController = Get.find<ServicesGetxController>();
      final servicesData = servicesController.getExportData();
      final List<List<String>> combinedServices = [];
      servicesData.forEach((key, value) {
        combinedServices.add([key]); // Section header
        combinedServices.addAll(value);
        combinedServices.add([]); // Spacer
      });
      _addSheet(excel, 'Services', combinedServices);

      // 4. Operators
      final operatorsController = Get.find<OperatorController>();
      _addSheet(excel, 'Operators', operatorsController.getExportData());

      // 5. Others (Multiple tables)
      final othersController = Get.find<OthersGetxController>();
      final othersData = othersController.getExportData();
      final List<List<String>> combinedOthers = [];
      othersData.forEach((key, value) {
        combinedOthers.add([key]); // Section header
        combinedOthers.addAll(value);
        combinedOthers.add([]); // Spacer
      });
      _addSheet(excel, 'Others', combinedOthers);

      // Save file
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Company Setup Data',
        fileName: 'company_setup_export_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputFile != null) {
        var fileBytes = excel.save();
        if (fileBytes != null) {
          File(outputFile)
            ..createSync(recursive: true)
            ..writeAsBytesSync(fileBytes);
          Get.snackbar('Success', 'Data exported successfully to $outputFile');
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Export failed: $e');
    }
  }

  static void _addSheet(Excel excel, String name, List<List<String>> data) {
    Sheet sheetObject = excel[name];
    for (var row in data) {
      sheetObject.appendRow(row.cast<dynamic>());
    }
  }

  /// Imports data for the active tab from an Excel or Notepad file
  static Future<void> importTabData(int activeTabIndex) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        List<List<String>> data = [];

        if (path.endsWith('.xlsx')) {
          var bytes = File(path).readAsBytesSync();
          var excel = Excel.decodeBytes(bytes);
          // Just take the first sheet or relevant sheet for simplicity
          String sheetName = excel.tables.keys.first;
          var table = excel.tables[sheetName]!;
          for (var row in table.rows) {
            data.add(row.map((cell) => cell?.value?.toString() ?? '').toList());
          }
        } else if (path.endsWith('.txt')) {
          final lines = await File(path).readAsLines();
          for (var line in lines) {
            data.add(line.split('\t')); // Assume tab-separated for TXT
          }
        }

        if (data.isEmpty) return;

        // Strip headers if they exist (optional, but good for UX)
        // For now, let the controllers handle it as they might need headers.

        switch (activeTabIndex) {
          case 0: // Engineer
            Get.find<EngineerController>().importFromData(data);
            break;
          case 1: // Products
            Get.find<ProductsController>().importFromData(data);
            break;
          case 2: // Services
            Get.find<ServicesGetxController>().importFromData(data);
            break;
          case 3: // Operator
            Get.find<OperatorController>().importFromData(data);
            break;
          case 4: // Others
            Get.find<OthersGetxController>().importFromData(data);
            break;
        }
        Get.snackbar('Success', 'Data imported into the active tab');
      }
    } catch (e) {
      Get.snackbar('Error', 'Import failed: $e');
    }
  }
}
