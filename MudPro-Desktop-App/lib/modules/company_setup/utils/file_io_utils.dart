import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
    _ImportProgressDialog? progressDialog;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        List<List<String>> data = [];
        final tabName = _tabDisplayName(activeTabIndex);
        progressDialog = _ImportProgressDialog('Importing $tabName');
        progressDialog.show();
        progressDialog.update(null, 'Reading selected file...');
        await Future<void>.delayed(const Duration(milliseconds: 60));

        if (path.endsWith('.xlsx')) {
          var bytes = await File(path).readAsBytes();
          var excel = Excel.decodeBytes(bytes);
          final sheetName = _resolveSheetName(excel, activeTabIndex);
          if (sheetName == null) {
            progressDialog.close();
            Get.snackbar(
              'Error',
              'Matching sheet not found for the selected tab',
            );
            return;
          }

          final table = excel.tables[sheetName];
          if (table == null) {
            progressDialog.close();
            Get.snackbar('Error', 'Selected sheet is empty');
            return;
          }
          final totalRows = table.rows.length;
          for (int i = 0; i < totalRows; i += 1) {
            final row = table.rows[i];
            data.add(row.map((cell) => _excelCellText(cell?.value)).toList());
            if (i == totalRows - 1 || i % 50 == 0) {
              progressDialog.update(
                0.05 + (0.20 * ((i + 1) / totalRows)),
                'Reading row ${i + 1} of $totalRows...',
              );
              await Future<void>.delayed(Duration.zero);
            }
          }
        } else if (path.endsWith('.txt')) {
          final lines = await File(path).readAsLines();
          for (int i = 0; i < lines.length; i += 1) {
            final line = lines[i];
            data.add(line.split('\t')); // Assume tab-separated for TXT
            if (i == lines.length - 1 || i % 50 == 0) {
              progressDialog.update(
                0.05 + (0.20 * ((i + 1) / lines.length)),
                'Reading row ${i + 1} of ${lines.length}...',
              );
              await Future<void>.delayed(Duration.zero);
            }
          }
        }

        if (data.isEmpty) {
          progressDialog.close();
          return;
        }

        Map<String, dynamic>? importResult;
        progressDialog.update(0.28, 'Saving imported data...');

        switch (activeTabIndex) {
          case 0: // Engineer
            importResult =
                await _ensureController<EngineerController>(
                  () => EngineerController(),
                ).importFromData(data);
            break;
          case 1: // Products
            importResult = await _getProductsController().importFromData(
              data,
              onProgress: (value, message) {
                final clampedValue = value.clamp(0.0, 1.0).toDouble();
                progressDialog?.update(
                  0.28 + (0.70 * clampedValue),
                  message,
                );
              },
            );
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

        progressDialog.update(1, 'Import completed');
        await Future<void>.delayed(const Duration(milliseconds: 250));
        progressDialog.close();

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

        final errors = importResult['errors'];
        if (errors is List && errors.isNotEmpty) {
          Get.defaultDialog(
            title: 'Import Issues',
            middleText: errors.take(20).join('\n'),
            textConfirm: 'OK',
            onConfirm: () => Get.back(),
          );
        }
      }
    } catch (e) {
      progressDialog?.close();
      Get.snackbar('Error', 'Import failed: $e');
    }
  }

  static String _tabDisplayName(int activeTabIndex) {
    switch (activeTabIndex) {
      case 0:
        return 'Engineers';
      case 1:
        return 'Products';
      case 2:
        return 'Services';
      case 3:
        return 'Operators';
      case 4:
        return 'Others';
      default:
        return 'Data';
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

    if (activeTabIndex == 1) {
      for (final name in sheetNames) {
        final table = excel.tables[name];
        if (table != null && _sheetLooksLikeProducts(table)) {
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

  static bool _sheetLooksLikeProducts(Sheet table) {
    final scanCount = table.rows.length < 20 ? table.rows.length : 20;
    for (int i = 0; i < scanCount; i += 1) {
      final headers = table.rows[i]
          .map((cell) => _headerKey(_excelCellText(cell?.value)))
          .where((value) => value.isNotEmpty)
          .toSet();
      if (_hasProductHeaderSet(headers)) return true;
    }
    return false;
  }

  static bool _hasProductHeaderSet(Set<String> headers) {
    if (headers.contains('product') ||
        headers.contains('product name') ||
        headers.contains('company brand name') ||
        headers.contains('brand name')) {
      return true;
    }

    if (headers.contains('code') && headers.contains('sg')) {
      return true;
    }

    return headers.where(_isProductSpecificHeaderKey).length >= 2;
  }

  static bool _isProductSpecificHeaderKey(String key) {
    return const {
      'product',
      'product name',
      'company brand name',
      'brand name',
      'item',
      'item name',
      'material',
      'code',
      'product code',
      'item code',
      'sg',
      's g',
      'density',
      'density sg',
      'density s g',
      'specific gravity',
      'unit num',
      'unit number',
      'qty',
      'quantity',
      'size',
      'num',
      'unit class',
      'class',
      'unit',
      'group',
      'product category',
      'category',
      'retail',
      'retail price',
      'a',
      'sales price',
      'price a',
      'a price',
      'b',
      'cogs',
      'price b',
      'b price',
    }.contains(key);
  }

  static String _headerKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _excelCellText(dynamic value) {
    if (value == null) return '';
    if (value is num) {
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }
      return value
          .toStringAsFixed(6)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
    }
    return value.toString().trim();
  }
}

class _ImportProgressDialog {
  _ImportProgressDialog(this.title);

  final String title;
  final RxnDouble value = RxnDouble();
  final RxString message = 'Preparing import...'.obs;
  bool _isOpen = false;

  void show() {
    if (_isOpen) return;
    _isOpen = true;
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 380,
            child: Obx(() {
              final currentValue = value.value;
              final clampedValue = currentValue == null
                  ? null
                  : currentValue.clamp(0.0, 1.0).toDouble();
              final percent = clampedValue == null
                  ? ''
                  : '${(clampedValue * 100).round()}%';
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: clampedValue),
                  const SizedBox(height: 12),
                  Text(
                    message.value,
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (percent.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      percent,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              );
            }),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void update(double? progress, String text) {
    value.value = progress?.clamp(0, 1).toDouble();
    message.value = text;
  }

  void close() {
    if (!_isOpen) return;
    _isOpen = false;
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }
}
