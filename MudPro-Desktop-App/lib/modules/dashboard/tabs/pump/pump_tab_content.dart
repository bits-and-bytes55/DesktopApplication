import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import '../../controller/pump_controller.dart';

class PumpPage extends StatelessWidget {
  PumpPage({super.key});
  final PumpController controller = Get.put(PumpController());
  final dashboard = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        if (width < 800) {
          return Container(
            color: Colors.white,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _header(),
                    const SizedBox(height: 12),
                    _pumpTable(),
                    const SizedBox(height: 12),
                    _summaryBox(),
                    const SizedBox(height: 12),
                    _shakerTable(),
                    const SizedBox(height: 12),
                    _otherSCETable(),
                  ],
                ),
              ),
            ),
          );
        } else {
          return Container(
            color: Colors.white,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT PORTION - Pump Table
                        Expanded(
                          flex: 5,
                          child: _pumpTable(),
                        ),
                        const SizedBox(width: 12),
                        // RIGHT PORTION - Summary Box
                        ConstrainedBox(
                          constraints: BoxConstraints(minWidth: 150, maxWidth: 400),
                          child: _summaryBox(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // SHAKER TABLE - Full Width
                    _shakerTable(),
                    const SizedBox(height: 12),
                    // OTHER SCE TABLE - Full Width
                    _otherSCETable(),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  // ================= HEADER =================
  Widget _header() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header with primary color
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.precision_manufacturing, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  "Pump & Equipment Configuration",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= PUMP TABLE =================
  Widget _pumpTable() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with primary color
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.settings, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "Pump Configuration",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Table
          Obx(() => Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Table(
                    border: TableBorder.all(
                      color: Colors.grey.shade300,
                      width: 1,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FixedColumnWidth(120),
                      1: FixedColumnWidth(80),
                      2: FixedColumnWidth(90),
                      3: FixedColumnWidth(90),
                      4: FixedColumnWidth(100),
                      5: FixedColumnWidth(100),
                      6: FixedColumnWidth(90),
                      7: FixedColumnWidth(100),
                      8: FixedColumnWidth(100),
                    },
                    children: [
                      // Header row
                      TableRow(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                        ),
                        children: [
                          _buildTableHeaderCell("Model", TextAlign.left),
                          _buildTableHeaderCell("Type", TextAlign.center),
                          _buildTableHeaderCell("Liner ID\n(in)", TextAlign.center),
                          _buildTableHeaderCell("Rod OD\n(in)", TextAlign.center),
                          _buildTableHeaderCell("Stroke Length\n(in)", TextAlign.center),
                          _buildTableHeaderCell("Efficiency\n(%)", TextAlign.center),
                           _buildTableHeaderCell("Displ.\n(bbl/stk)", TextAlign.center),
                            _buildTableHeaderCell("Stroke\n(stk/min)", TextAlign.center),
                          _buildTableHeaderCell("Rate\n(gpm)", TextAlign.center),
                        ],
                      ),
                      
                      // Data rows
                      ...List.generate(10, (i) {
                        if (i < controller.pumpRows.length) {
                          final row = controller.pumpRows[i];
                          return _buildPumpDataRow([
                            row["model"]!,
                            row["type"]!,
                            "${row["liner"]}",
                            "-",
                            "${row["stroke"]}",
                            "${row["eff"]}%",
                            "0.0",
                            "0",
                            "0",
                          ]);
                        } else {
                          return _buildPumpDataRow([
                            "",
                            "",
                            "",
                            "",
                            "",
                            "",
                            "",
                            "",
                            "",
                          ]);
                        }
                      }),
                    ],
                  ),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  // ================= SUMMARY BOX =================
  Widget _summaryBox() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with primary color
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.summarize, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  "Summary",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Table
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Table(
                  border: TableBorder.all(
                    color: Colors.grey.shade300,
                    width: 1,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: FixedColumnWidth(200),
                    1: FixedColumnWidth(150),
                  },
                  children: [
                    // Header row
                    TableRow(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                      ),
                      children: [
                        _buildTableHeaderCell("Parameter", TextAlign.left),
                        _buildTableHeaderCell("Value", TextAlign.center),
                      ],
                    ),

                    // Data rows
                    _buildSummaryTableRow("Pump Rate", "0.0", "gpm"),
                    _buildSummaryTableRow("Pump Pressure", "0", "psi"),
                    _buildSummaryTableRow("Boost Pump Rate", "0", "gpm"),
                    _buildSummaryTableRow("Return Rate", "0", "gpm"),
                    _buildSummaryTableRow("DH Tools P. Loss", "0", "psi"),
                    _buildSummaryTableRow("Motor P. Loss", "0", "psi"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= SHAKER TABLE =================
  Widget _shakerTable() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with primary color
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_alt, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  "Shaker Configuration",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Table
          Obx(() => Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Table(
                    border: TableBorder.all(
                      color: Colors.grey.shade300,
                      width: 1,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FixedColumnWidth(140),
                      1: FixedColumnWidth(140),
                      2: FixedColumnWidth(80),
                      3: FixedColumnWidth(80),
                      4: FixedColumnWidth(80),
                      5: FixedColumnWidth(80),
                      6: FixedColumnWidth(80),
                      7: FixedColumnWidth(80),
                      8: FixedColumnWidth(80),
                      9: FixedColumnWidth(80),
                      10: FixedColumnWidth(140),
                      11: FixedColumnWidth(140),
                    },
                    children: [
                      // Main Header row
                      TableRow(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                        ),
                        children: [
                          _buildTableHeaderCell("Shaker", TextAlign.left),
                          _buildTableHeaderCell("Model", TextAlign.center),
                          _buildTableHeaderCell("Screen", TextAlign.center),
                         _buildTableHeaderCell("", TextAlign.center),
                          _buildTableHeaderCell("", TextAlign.center),
                          _buildTableHeaderCell("", TextAlign.center),
                          _buildTableHeaderCell("", TextAlign.center),
                          _buildTableHeaderCell("", TextAlign.center),
                          _buildTableHeaderCell("", TextAlign.center),
                          _buildTableHeaderCell("", TextAlign.center),
                          _buildTableHeaderCell("Time(hr)", TextAlign.center),
                          _buildTableHeaderCell("OOC Wt. (%)", TextAlign.center),
                        ],
                      ),
                      
                      
                      // Data rows
                      ...List.generate(10, (i) {
                        if (i < controller.shakerRows.length) {
                          final row = controller.shakerRows[i];
                          return _buildPumpDataRow([
                            row["shaker"]!,
                            row["model"]!,
                            "100",
                            "80",
                            "200",
                            "150",
                            "120",
                            "90",
                            "60",
                            "40",
                            "",
                            "",
                          ]);
                        } else {
                          return _buildPumpDataRow([
                            "",
                            "",
                            "",
                            "",
                            "",
                            "",
                            "",
                            "",
                            "",
                            "",
                            "",
                            "",
                          ]);
                        }
                      }),
                    ],
                  ),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  // ================= OTHER SCE TABLE =================
  Widget _otherSCETable() {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 500),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      child: Column(
        children: [
          // Header with primary color
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.build, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  "Other SCE Equipment",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Table
          Obx(() => Container(
            constraints: const BoxConstraints(maxHeight: 350),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Table(
                    border: TableBorder.all(
                      color: Colors.grey.shade300,
                      width: 1,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FixedColumnWidth(140),
                      1: FixedColumnWidth(140),
                      2: FixedColumnWidth(100),
                      3: FixedColumnWidth(100),
                    },
                    children: [
                      // Header row
                      TableRow(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                        ),
                        children: [
                          _buildTableHeaderCell("SCE", TextAlign.left),
                          _buildTableHeaderCell("Model", TextAlign.center),
                          _buildTableHeaderCell("Time\n(hr)", TextAlign.center),
                          _buildTableHeaderCell("OOC Wt\n(%)", TextAlign.center),
                        ],
                      ),
                      
                      // Data rows
                      ...controller.sceRows.map((row) {
                        return _buildSCEDataRow([
                          row["sce"]!,
                          row["model"]!,
                          "",
                          "",
                        ]);
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          )),
        ],
      ),
    )
    );
  }

  // ================= HELPER METHODS =================
  Widget _buildTableHeaderCell(String text, TextAlign align) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryColor,
        ),
        textAlign: align,
      ),
    );
  }

  TableRow _buildPumpDataRow(List<dynamic> values) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
        color: Colors.white,
      ),
      children: values.asMap().entries.map((entry) {
        final index = entry.key;
        final value = entry.value;
        bool isDropdown = false;
        if (values.length == 9) { // Pump table
          isDropdown = index == 1; // only type, remove model dropdown
        } else if (values.length == 12) { // Shaker table
          isDropdown = index == 0; // only shaker, remove model dropdown
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          height: 30,
          child: dashboard.isLocked.value
              ? (value is List<String> ? Row(
                  children: value.map((v) => Expanded(
                    child: Text(
                      v,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )).toList(),
                ) : Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: index == 0 ? TextAlign.left : TextAlign.center,
                ))
              : isDropdown
                  ? _buildEditableDropdownCell(value, _getDropdownOptions(index, values.length))
                  : (value is List<String> ? Row(
                      children: value.map((v) => Expanded(
                        child: TextFormField(
                          initialValue: v,
                          style: TextStyle(fontSize: 11),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                            border: InputBorder.none,
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppTheme.primaryColor, width: 1),
                            ),
                          ),
                        ),
                      )).toList(),
                    ) : TextFormField(
                      initialValue: value,
                      style: TextStyle(fontSize: 11),
                      textAlign: index == 0 ? TextAlign.left : TextAlign.center,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                        border: InputBorder.none,
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.primaryColor, width: 1),
                        ),
                      ),
                    )),
        );
      }).toList(),
    );
  }

  TableRow _buildSCEDataRow(List<String> values) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
        color: Colors.white,
      ),
      children: values.asMap().entries.map((entry) {
        final index = entry.key;
        final value = entry.value;
        bool isDropdown = false;
        if (values.length == 4) { // SCE table
          isDropdown = index == 0;
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          height: 35,
          child: dashboard.isLocked.value
              ? Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: index == 0 ? TextAlign.left : TextAlign.center,
                )
              : isDropdown
                  ? _buildEditableDropdownCell(value, _getDropdownOptions(index, values.length))
                  : TextFormField(
                      initialValue: value,
                      style: TextStyle(fontSize: 11),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        border: InputBorder.none,
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.primaryColor, width: 1),
                        ),
                      ),
                    ),
        );
      }).toList(),
    );
  }

  Widget _buildEditableDropdownCell(String value, List<String> options) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value.isEmpty ? null : value,
        isExpanded: true,
        isDense: true,
        iconSize: 14,
        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        items: options.map((e) {
          return DropdownMenuItem(
            value: e,
            child: Text(e, style: TextStyle(fontSize: 11)),
          );
        }).toList(),
        onChanged: dashboard.isLocked.value ? null : (v) {},
      ),
    );
  }

  List<String> _getDropdownOptions(int index, int valuesLength) {
    if (valuesLength == 9) { // Pump table
      if (index == 0) return controller.pumpModels;
      if (index == 1) return ["Triplex", "Duplex", "Centrifugal", "Reciprocating"];
    } else if (valuesLength == 5) { // Shaker table
      if (index == 0) return controller.shakerTypes;
    } else if (valuesLength == 4) { // SCE table
      if (index == 0) return controller.sceTypes;
    }
    return [];
  }

  TableRow _buildSummaryTableRow(String label, String value, String unit) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
        color: Colors.white,
      ),
      children: [
        // Parameter cell
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.left,
          ),
        ),
        // Value cell
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: dashboard.isLocked.value
              ? Text(
                  "$value $unit",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: value,
                        style: TextStyle(fontSize: 11),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                          border: InputBorder.none,
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.primaryColor, width: 1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: dashboard.isLocked.value
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        "$value $unit",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: value,
                            style: TextStyle(fontSize: 11),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                              border: InputBorder.none,
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: AppTheme.primaryColor, width: 1),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          unit,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}