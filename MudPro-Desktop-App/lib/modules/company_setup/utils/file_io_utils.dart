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
  static const String _productsTag = 'products_controller';

  /// Exports all data from all tabs into a single Excel file
  static Future<void> exportAllData() async {
    try {
      final excel = Excel.createExcel();
      
      // Remove default sheet
      excel.delete('Sheet1');

      // 1. Engineers
      final engineerController =
          _ensureController<EngineerController>(() => EngineerController());
      await engineerController.fetchEngineers();
      _addSheet(excel, 'Engineers', engineerController.getExportData());

      // 2. Products
      final productsController = _getProductsController();
      await productsController.loadProducts();
      _addSheet(excel, 'Products', productsController.getExportData());

      // 3. Services (Multiple tables)
      final servicesController = _ensureController<ServicesGetxController>(
        () => ServicesGetxController(),
      );
      await servicesController.loadAllData();
      final servicesData = servicesController.getExportData();
      final List<List<String>> combinedServices = [];
      servicesData.forEach((key, value) {
        combinedServices.add([key]); // Section header
        combinedServices.addAll(value);
        combinedServices.add([]); // Spacer
      });
      _addSheet(excel, 'Services', combinedServices);

      // 4. Operators
      final operatorsController =
          _ensureController<OperatorController>(() => OperatorController());
      await operatorsController.fetchOperators();
      _addSheet(excel, 'Operators', operatorsController.getExportData());

      // 5. Others (Multiple tables)
      final othersController =
          _ensureController<OthersGetxController>(() => OthersGetxController());
      await othersController.fetchAllData();
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

  static Future<void> exportTabData(int activeTabIndex) async {
    try {
      final excel = Excel.createExcel();
      excel.delete('Sheet1');

      final sheetName = _sheetAliases(activeTabIndex).firstOrNull;
      if (sheetName == null) {
        Get.snackbar('Error', 'Unsupported tab selected for export');
        return;
      }

      switch (activeTabIndex) {
        case 0:
          final controller =
              _ensureController<EngineerController>(() => EngineerController());
          await controller.fetchEngineers();
          _addSheet(excel, 'Engineers', controller.getExportData());
          break;
        case 1:
          final controller = _getProductsController();
          await controller.loadProducts();
          _addSheet(excel, 'Products', controller.getExportData());
          break;
        case 2:
          final controller = _ensureController<ServicesGetxController>(
            () => ServicesGetxController(),
          );
          await controller.loadAllData();
          _addSheet(
            excel,
            'Services',
            _combineSectionRows(controller.getExportData()),
          );
          break;
        case 3:
          final controller =
              _ensureController<OperatorController>(() => OperatorController());
          await controller.fetchOperators();
          _addSheet(excel, 'Operators', controller.getExportData());
          break;
        case 4:
          final controller = _ensureController<OthersGetxController>(
            () => OthersGetxController(),
          );
          await controller.fetchAllData();
          _addSheet(
            excel,
            'Others',
            _combineSectionRows(controller.getExportData()),
          );
          break;
        default:
          Get.snackbar('Error', 'Unsupported tab selected for export');
          return;
      }

      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Current Tab',
        fileName:
            '${sheetName}_export_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputFile != null) {
        final fileBytes = excel.save();
        if (fileBytes != null) {
          File(outputFile)
            ..createSync(recursive: true)
            ..writeAsBytesSync(fileBytes);
          Get.snackbar('Success', '$sheetName exported successfully');
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Export failed: $e');
    }
  }

  static T _ensureController<T>(T Function() create) {
    if (Get.isRegistered<T>()) return Get.find<T>();
    return Get.put<T>(create());
  }

  static ProductsController _getProductsController() {
    if (Get.isRegistered<ProductsController>(tag: _productsTag)) {
      return Get.find<ProductsController>(tag: _productsTag);
    }
    if (Get.isRegistered<ProductsController>()) {
      return Get.find<ProductsController>();
    }
    return Get.put<ProductsController>(
      ProductsController(),
      tag: _productsTag,
    );
  }

  static void _addSheet(Excel excel, String name, List<List<String>> data) {
    Sheet sheetObject = excel[name];
    for (var row in data) {
      sheetObject.appendRow(row.cast<dynamic>());
    }
  }

  static List<List<String>> _combineSectionRows(
    Map<String, List<List<String>>> sections,
  ) {
    final combinedRows = <List<String>>[];
    sections.forEach((key, value) {
      combinedRows.add([key]);
      combinedRows.addAll(value);
      combinedRows.add([]);
    });
    return combinedRows;
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
          final sheetName = _resolveSheetName(excel, activeTabIndex);
          if (sheetName == null) {
            Get.snackbar(
              'Error',
              'Matching sheet not found for the selected tab',
            );
            return;
          }

          final table = excel.tables[sheetName];
          if (table == null) {
            Get.snackbar('Error', 'Selected sheet is empty');
            return;
          }
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

        Map<String, dynamic>? importResult;

        switch (activeTabIndex) {
          case 0: // Engineer
            importResult =
                await _ensureController<EngineerController>(
                  () => EngineerController(),
                ).importFromData(data);
            break;
          case 1: // Products
            importResult = await _getProductsController().importFromData(data);
            break;
          case 2: // Services
            importResult = await _ensureController<ServicesGetxController>(
              () => ServicesGetxController(),
            ).importFromData(data);
            break;
          case 3: // Operator
            importResult = await _ensureController<OperatorController>(
              () => OperatorController(),
            ).importFromData(data);
            break;
          case 4: // Others
            importResult = await _ensureController<OthersGetxController>(
              () => OthersGetxController(),
            ).importFromData(data);
            break;
        }

        if (importResult == null) {
          Get.snackbar('Error', 'Import handler not found for active tab');
          return;
        }

        final isSuccess = importResult['success'] == true;
        final message = importResult['message']?.toString().trim();
        final fallbackMessage = isSuccess
            ? 'Data imported into the active tab'
            : 'Import finished with issues';

        Get.snackbar(
          isSuccess ? 'Success' : 'Warning',
          message != null && message.isNotEmpty ? message : fallbackMessage,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Import failed: $e');
    }
  }

  static String? _resolveSheetName(Excel excel, int activeTabIndex) {
    final sheetNames = excel.tables.keys.toList();
    if (sheetNames.isEmpty) return null;

    final preferredNames = _sheetAliases(activeTabIndex);
    for (final candidate in preferredNames) {
      for (final name in sheetNames) {
        if (name.trim().toLowerCase() == candidate) {
          return name;
        }
      }
    }

    if (sheetNames.length == 1) {
      return sheetNames.first;
    }

    return null;
  }

  static List<String> _sheetAliases(int activeTabIndex) {
    switch (activeTabIndex) {
      case 0:
        return ['engineers', 'engineer'];
      case 1:
        return ['products', 'product'];
      case 2:
        return ['services', 'service'];
      case 3:
        return ['operators', 'operator'];
      case 4:
        return ['others', 'other'];
      default:
        return const [];
    }
  }
}
