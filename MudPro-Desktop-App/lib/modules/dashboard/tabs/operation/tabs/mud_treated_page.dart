import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/options/app_units.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

// Controller
class MudTreatedController extends GetxController {
  // Addition section
  final receiveMud = '0'.obs;
  final baseFluid = '0'.obs;
  final weightMaterial = '56.42'.obs;
  final products = '32.29'.obs;
  final water = '1411.29'.obs;
  final formation = '0'.obs;
  final cuttings = '0'.obs;
  final subTotal = '1500.00'.obs;
  final total = '1500.00'.obs;
  
  // Active System section
  final fromStorage = '0.00'.obs;
  final mudTreated = '1500.00'.obs;
}

class MudTreatedPage extends GetView<MudTreatedController> {
  const MudTreatedPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Get.put(MudTreatedController());

    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      appBar: AppBar(
        title: const Text(
          'Mud Treated',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 18, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: 500,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main Addition Table
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFA0A0A0), width: 1),
                  ),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(2),
                    },
                    border: TableBorder.all(color: const Color(0xFFD0D0D0), width: 0.5),
                    children: [
                      // Header Row
                      TableRow(
                        decoration: BoxDecoration(color: AppTheme.primaryColor),
                        children: [
                          _buildHeaderCell('Addition'),
                          _buildHeaderCell('Active System\n${AppUnits.displayUnit('6', fallback: '(bbl)')}'),
                        ],
                      ),
                      // Data Rows
                      _buildDataRow('Receive Mud', controller.receiveMud, '0'),
                      _buildDataRow('Base Fluid', controller.baseFluid, '0'),
                      _buildDataRow('Weight Material', controller.weightMaterial, '56.42'),
                      _buildDataRow('Products', controller.products, '32.29'),
                      _buildDataRow('Water', controller.water, '1411.29'),
                      _buildDataRow('Formation', controller.formation, '0'),
                      _buildDataRow('Cuttings', controller.cuttings, '0'),
                      // Sub Total Row
                      TableRow(
                        decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
                        children: [
                          _buildLabelCell('Sub Total', bold: true),
                          _buildValueCell(controller.subTotal, '1500.00', bold: true),
                        ],
                      ),
                      // Total Row
                      TableRow(
                        decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
                        children: [
                          _buildLabelCell('Total', bold: true),
                          _buildValueCell(controller.total, '1500.00', bold: true),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Active System Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFA0A0A0), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active System Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          border: Border(
                            bottom: BorderSide(color: const Color(0xFFD0D0D0), width: 0.5),
                          ),
                        ),
                        child: const Text(
                          'Active System',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // From Storage Row
                      _buildActiveSystemRow('From Storage', controller.fromStorage, '0.00'),
                      // Mud Treated Row
                      _buildActiveSystemRow('Mud Treated', controller.mudTreated, '1500.00'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Close Button
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: const BorderSide(color: Color(0xFFB0B0B0), width: 1),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  TableRow _buildDataRow(String label, RxString valueObs, String initialValue) {
    return TableRow(
      children: [
        _buildLabelCell(label),
        _buildEditableCell(valueObs, initialValue),
      ],
    );
  }

  Widget _buildLabelCell(String text, {bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEditableCell(RxString valueObs, String initialValue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      alignment: Alignment.centerRight,
      child: Obx(() {
        return TextField(
          controller: TextEditingController(text: valueObs.value)
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: valueObs.value.length),
            ),
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black87,
          ),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          onChanged: (val) => valueObs.value = val,
        );
      }),
    );
  }

  Widget _buildValueCell(RxString valueObs, String initialValue, {bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      alignment: Alignment.centerRight,
      child: Obx(() => Text(
        valueObs.value.isEmpty ? initialValue : valueObs.value,
        style: TextStyle(
          fontSize: 10,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          color: Colors.black87,
        ),
      )),
    );
  }

  Widget _buildActiveSystemRow(String label, RxString valueObs, String initialValue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFD0D0D0), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Obx(() {
              return TextField(
                controller: TextEditingController(text: valueObs.value)
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: valueObs.value.length),
                  ),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide: const BorderSide(color: Color(0xFFB0B0B0), width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide: const BorderSide(color: Color(0xFFB0B0B0), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                onChanged: (val) => valueObs.value = val,
              );
            }),
          ),
          const SizedBox(width: 6),
          Text(
            AppUnits.displayUnit('6', fallback: '(bbl)'),
            style: TextStyle(
              fontSize: 9,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

