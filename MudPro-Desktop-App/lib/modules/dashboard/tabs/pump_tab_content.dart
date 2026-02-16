import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/pump_controller.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';
import 'package:mudpro_desktop_app/modules/dashboard/widgets/editable_cell.dart';
import 'package:mudpro_desktop_app/modules/dashboard/controller/dashboard_controller.dart';

class PumpPage extends StatelessWidget {
  PumpPage({super.key});
  final PumpController controller = Get.put(PumpController());
  final DashboardController dashboardController = Get.find<DashboardController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _header(),
            const SizedBox(height: 8),

            // Main content with scrolling
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pump Section - Responsive row
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 800) {
                          // Desktop/Large Screen Layout
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _pumpTable(),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: _summaryBox(),
                              ),
                            ],
                          );
                        } else {
                          // Mobile/Small Screen Layout
                          return Column(
                            children: [
                              _pumpTable(),
                              const SizedBox(height: 16),
                              _summaryBox(),
                            ],
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Shaker Section
                    _sectionTitle("Shaker"),
                    _shakerTable(),

                    const SizedBox(height: 16),

                    // Other SCE Section
                    _sectionTitle("Other SCE"),
                    _otherSCETable(),

                    const SizedBox(height: 16),

                    // Remarks and JSA Section
                    _remarksAndJSASection(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Pump",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Obx(() => ElevatedButton.icon(
              icon: Icon(
                controller.isLocked.value ? Icons.lock : Icons.lock_open,
                size: 20,
              ),
              label: Text(
                controller.isLocked.value ? "Unlock" : "Lock",
                style: const TextStyle(fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.isLocked.value
                  ? Colors.grey[700]
                  : Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: controller.isLocked.toggle,
            )),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  // ---------------- PUMP TABLE (Image Based Design) ----------------
  Widget _pumpTable() {
    return Obx(() => Container(
          decoration: _box(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: DataTable(
                columnSpacing: 20,
                horizontalMargin: 12,
                headingRowHeight: 40,
                dataRowHeight: 40,
                headingTextStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                dataTextStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
                columns: const [
                  DataColumn(label: Text("Web")),
                  DataColumn(label: Text("Nud")),
                  DataColumn(label: Text("Pump")),
                  DataColumn(label: Text("Operation")),
                  DataColumn(label: Text("Pit")),
                  DataColumn(label: Text("Safety")),
                  DataColumn(label: Text("Remarks")),
                  DataColumn(label: Text("JSA")),
                  DataColumn(label: Text("")),
                  DataColumn(label: Text("")),
                ],
                rows: [
                  // Header row
                  DataRow(
                    cells: [
                      DataCell(_buildPumpHeaderCell()),
                      const DataCell(Text("")),
                      const DataCell(Text("")),
                      const DataCell(Text("")),
                      const DataCell(Text("")),
                      const DataCell(Text("")),
                      const DataCell(Text("")),
                      const DataCell(Text("")),
                      const DataCell(Text("")),
                      const DataCell(Text("")),
                    ],
                  ),
                  // Data rows
                  ..._buildPumpDataRows(),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildPumpHeaderCell() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 12,
          headingRowHeight: 30,
          dataRowHeight: 40, // Increased height
          headingTextStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          columns: const [
            DataColumn(label: Text("Model")),
            DataColumn(label: Text("Type")),
            DataColumn(label: Text("Liner ID (in)")),
            DataColumn(label: Text("Rod OD (in)")),
            DataColumn(label: Text("Stk. Length (in)")),
            DataColumn(label: Text("Efficiency (%)")),
            DataColumn(label: Text("Displ. (bbl/stk)")),
            DataColumn(label: Text("Stroke (stk/min)")),
            DataColumn(label: Text("Rate (gpm)")),
            DataColumn(label: Text("Pump Pressure (psi)")),
          ],
          rows: [
            DataRow(
              cells: List.generate(
                10,
                (index) => DataCell(EditableCell(value: RxString(""))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DataRow> _buildPumpDataRows() {
    return controller.pumpRows.map((row) {
      return DataRow(
        cells: [
          DataCell(
            Container(
              width: 120,
              decoration: dashboardController.isLocked.value
                  ? null
                  : BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: row["model"],
                  isExpanded: true,
                  style: const TextStyle(fontSize: 11),
                  onChanged: dashboardController.isLocked.value
                      ? null
                      : (v) => row["model"] = v!,
                  items: controller.pumpModels
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e, style: const TextStyle(fontSize: 11)),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
          DataCell(EditableCell(value: RxString(row["liner"].toString()))),
          DataCell(EditableCell(value: RxString(row["stroke"].toString()))),
          DataCell(EditableCell(value: RxString(""))),
          DataCell(EditableCell(value: RxString(row["eff"].toString()))),
          DataCell(EditableCell(value: RxString("0.1018"))),
          DataCell(EditableCell(value: RxString("0.0"))),
          DataCell(EditableCell(value: RxString(""))),
          DataCell(EditableCell(value: RxString(""))),
          DataCell(EditableCell(value: RxString(""))),
        ],
      );
    }).toList();
  }

  Widget _buildPumpModelCell(String model, String type) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            model,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            type,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---------------- SUMMARY BOX (Image Based) ----------------
  Widget _summaryBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Summary",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow("Pump Rate", "0.0 gpm"),
          _buildSummaryRow("Pump Pressure", "0.0 psi"),
          _buildSummaryRow("Boost Pump Rate", "0.0 gpm"),
          _buildSummaryRow("Return Rate", "0.0 gpm"),
          _buildSummaryRow("DH Tools P. Loss", "0.0 psi"),
          _buildSummaryRow("Motor P. Loss", "0.0 psi"),
          _buildSummaryRow("Pump Rate", "0.0 gpm"),
          _buildSummaryRow("Pump Pressure", "0.0 psi"),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style:  TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SHAKER TABLE ----------------
  Widget _shakerTable() {
    return Obx(() => Container(
          decoration: _box(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: DataTable(
                columnSpacing: 20,
                horizontalMargin: 12,
                headingRowHeight: 40,
                dataRowHeight: 40,
                columns: const [
                  DataColumn(label: Text("Shaker")),
                  DataColumn(label: Text("Model")),
                  DataColumn(label: Text("Screen")),
                ],
                rows: controller.shakerRows.map((row) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          width: 100,
                          decoration: dashboardController.isLocked.value
                              ? null
                              : BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300, width: 1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: row["shaker"],
                              isExpanded: true,
                              style: const TextStyle(fontSize: 12),
                              onChanged: dashboardController.isLocked.value
                                  ? null
                                  : (v) => row["shaker"] = v!,
                              items: controller.shakerTypes
                                  .map((e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e,
                                            style:
                                                const TextStyle(fontSize: 12)),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                      DataCell(EditableCell(value: RxString(row["model"]!))),
                      const DataCell(Text(
                        "100 / 80 / 200",
                        style: TextStyle(fontSize: 12),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ));
  }

  // ---------------- OTHER SCE TABLE ----------------
  Widget _otherSCETable() {
    return Obx(() => Container(
          decoration: _box(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: DataTable(
                columnSpacing: 20,
                horizontalMargin: 12,
                headingRowHeight: 40,
                dataRowHeight: 40,
                columns: const [
                  DataColumn(label: Text("SCE")),
                  DataColumn(label: Text("Model")),
                  DataColumn(label: Text("Time (hr)")),
                  DataColumn(label: Text("OOC Wt (%)")),
                ],
                rows: controller.sceRows.map((row) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          width: 100,
                          decoration: dashboardController.isLocked.value
                              ? null
                              : BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300, width: 1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: row["sce"],
                              isExpanded: true,
                              style: const TextStyle(fontSize: 12),
                              onChanged: dashboardController.isLocked.value
                                  ? null
                                  : (v) => row["sce"] = v!,
                              items: controller.sceTypes
                                  .map((e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e,
                                            style:
                                                const TextStyle(fontSize: 12)),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                      DataCell(EditableCell(value: RxString(row["model"]!))),
                      DataCell(
                        SizedBox(
                          width: 80,
                          child: EditableCell(value: RxString("")),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 80,
                          child: EditableCell(value: RxString("")),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ));
  }

  // ---------------- REMARKS AND JSA SECTION ----------------
  Widget _remarksAndJSASection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Remarks & JSA",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Enter remarks here...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Colors.blue),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Enter JSA details here...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Colors.green),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  BoxDecoration _box() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      );
}
