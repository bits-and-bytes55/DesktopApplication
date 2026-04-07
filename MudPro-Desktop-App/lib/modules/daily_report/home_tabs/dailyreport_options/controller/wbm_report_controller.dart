import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mudpro_desktop_app/api_endpoint/api_endpoint.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/options_controller.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/modules/UG/controller/ug_pit_controller.dart'
    show kControllerWellId;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class ExportController {
  static const String baseUrl = ApiEndpoint.baseUrl;

  static Future<String> downloadAndOpenInventoryReport({
    String wellId = kControllerWellId,
  }) async {
    final optionsController = Get.isRegistered<OptionsController>()
        ? Get.find<OptionsController>()
        : null;

    final uri = Uri.parse('${baseUrl}export/inventory-export/$wellId').replace(
      queryParameters: {
        if (optionsController != null)
          'unitSystem': optionsController.activeUnitSystemLabel,
        if (optionsController != null)
          'lengthUnit': optionsController.getUnitForParameter('1'),
        if (optionsController != null)
          'volumeUnit': optionsController.getUnitForParameter('6'),
        if (optionsController != null)
          'mudWeightUnit': optionsController.getUnitForParameter('33'),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept':
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      },
    );
    debugPrint('[API] GET ${uri.toString()}');
    debugPrint('[API] Response status: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final tempDir = await getTemporaryDirectory();
    final filePath =
        '${tempDir.path}/WBM_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    await _applyLocalUnitContext(filePath);

    await OpenFilex.open(filePath);
    return filePath;
  }

  static Future<void> _applyLocalUnitContext(String filePath) async {
    if (!Get.isRegistered<OptionsController>()) {
      return;
    }

    final optionsController = Get.find<OptionsController>();
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables['Inventory'];

    if (sheet == null) {
      return;
    }

    _setCell(sheet, 'AE2', optionsController.activeUnitSystemLabel);

    final lengthUnit = optionsController.getUnitForParameter('1');
    final volumeUnit = optionsController.getUnitForParameter('6');
    final mudWeightUnit = optionsController.getUnitForParameter('33');

    _convertCellValue(sheet, 'AC9', fromUnit: '(m)', toUnit: lengthUnit);
    _convertCellValue(sheet, 'AC10', fromUnit: '(m)', toUnit: lengthUnit);
    _convertCellValue(sheet, 'AC11', fromUnit: '(m)', toUnit: lengthUnit);

    for (var row = 77; row <= 84; row++) {
      _convertCellValue(sheet, 'S$row', fromUnit: '(bbl)', toUnit: volumeUnit);
      _convertCellValue(sheet, 'U$row', fromUnit: '(ppg)', toUnit: mudWeightUnit);
    }

    for (var row = 95; row <= 101; row++) {
      _convertCellValue(sheet, 'S$row', fromUnit: '(bbl)', toUnit: volumeUnit);
    }

    final updatedBytes = excel.save();
    if (updatedBytes != null) {
      await File(filePath).writeAsBytes(updatedBytes, flush: true);
    }
  }

  static void _setCell(Sheet sheet, String address, Object value) {
    sheet.cell(CellIndex.indexByString(address)).value = value;
  }

  static void _convertCellValue(
    Sheet sheet,
    String address, {
    required String fromUnit,
    required String toUnit,
    int precision = 2,
  }) {
    if (AppUnits.sameUnit(fromUnit, toUnit)) {
      return;
    }

    final cell = sheet.cell(CellIndex.indexByString(address));
    final rawValue = cell.value?.toString() ?? '';
    final numericValue = double.tryParse(rawValue);

    if (numericValue == null) {
      return;
    }

    final converted = AppUnits.convertValue(
      numericValue,
      fromUnit: fromUnit,
      toUnit: toUnit,
    );

    if (converted == null) {
      return;
    }

    cell.value = double.parse(
      AppUnits.formatNumber(
        converted,
        precision: precision,
        trimTrailingZeros: false,
      ),
    );
  }
}
