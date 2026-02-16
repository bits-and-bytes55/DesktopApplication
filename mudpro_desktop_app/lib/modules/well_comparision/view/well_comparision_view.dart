import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mudpro_desktop_app/modules/well_comparision/controller/well_comparision_controller.dart';
import 'package:mudpro_desktop_app/modules/well_comparision/model/well_comparision_model.dart';
import 'package:mudpro_desktop_app/theme/app_theme.dart';

class WellComparisonPage extends StatelessWidget {
  WellComparisonPage({super.key});

  final controller = Get.put(WellComparisonController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _header(),
          const SizedBox(height: 1),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Section - Pads & Reports
                Container(
                  width: 400,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Colors.grey.shade300)),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: _leftSection(),
                ),
                
                // Right Section - Comparison Table
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(8),
                      ),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    margin: const EdgeInsets.only(left: 1),
                    child: _rightSection(),
                  ),
                ),
              ],
            ),
          ),
          _bottomButtons(),
        ],
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _header() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
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
              Icon(Icons.compare, size: 22, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Text(
                "Well Comparison",
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Obx(() => Text(
                  "${controller.comparedReports.length} wells selected",
                  style: AppTheme.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                )),
          ),
        ],
      ),
    );
  }

  // ---------------- LEFT SECTION ----------------
  Widget _leftSection() {
    return Column(
      children: [
        // Left Section Header
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.folder_open, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                "Pads & Reports",
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              _addReportButton(),
            ],
          ),
        ),
        
        // Pads List
        Expanded(
          child: Obx(() => controller.pads.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: controller.pads.length,
                  itemBuilder: (context, index) => _buildPadTile(controller.pads[index]),
                )),
        ),
      ],
    );
  }

  Widget _addReportButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: controller.addDummyPad,
        icon: Icon(Icons.add, size: 14, color: Colors.white),
        label: Text(
          "Add Report",
          style: AppTheme.caption.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            "No pads available",
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Click 'Add Report' to add a new pad",
            style: AppTheme.caption.copyWith(
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPadTile(PadModel pad) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        collapsedIconColor: AppTheme.primaryColor,
        iconColor: AppTheme.primaryColor,
        leading: Icon(Icons.folder, color: AppTheme.primaryColor),
        title: Text(
          "Pad: ${pad.padName}",
          style: AppTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          "${pad.reports.length} ${pad.reports.length == 1 ? 'report' : 'reports'}",
          style: AppTheme.caption.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: pad.reports.map(_buildReportRow).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(ReportModel report) {
    return Obx(() => Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: report.isSelected.value
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: report.isSelected.value
                  ? AppTheme.primaryColor.withOpacity(0.3)
                  : Colors.grey.shade200,
            ),
          ),
          child: ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Checkbox(
              value: report.isSelected.value,
              onChanged: (val) => controller.toggleReport(report, val!),
              fillColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return AppTheme.primaryColor;
                  }
                  return Colors.white;
                },
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            title: Text(
              report.wellName,
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Text(
              "${report.operator} • ${report.fieldBlock}",
              style: AppTheme.caption.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 9,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                report.spudDate,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 9,
                ),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ));
  }

  // ---------------- RIGHT SECTION ----------------
  Widget _rightSection() {
    return Column(
      children: [
        // Right Section Header
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.table_chart, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                "Comparison Table",
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${controller.comparedReports.length} wells",
                      style: AppTheme.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  )),
            ],
          ),
        ),
        
        // Table
        Expanded(
          child: Obx(() => controller.comparedReports.isEmpty
              ? _emptyComparisonState()
              : _comparisonTable()),
        ),
      ],
    );
  }

  Widget _emptyComparisonState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_rows_outlined,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            "No wells selected for comparison",
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Select wells from the left panel to compare",
            style: AppTheme.caption.copyWith(
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 40,
          dataRowHeight: 40,
          dividerThickness: 0.5,
          headingRowColor: MaterialStateProperty.all(AppTheme.tableHeadColor),
          dataRowColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              return Colors.transparent;
            },
          ),
          columns: const [
            DataColumn(label: _TableHeaderCell("Well Name")),
            DataColumn(label: _TableHeaderCell("Operator")),
            DataColumn(label: _TableHeaderCell("Field/Block")),
            DataColumn(label: _TableHeaderCell("API Well No.")),
            DataColumn(label: _TableHeaderCell("Rig")),
            DataColumn(label: _TableHeaderCell("Spud Date")),
            DataColumn(label: _TableHeaderCell("Status")),
          ],
          rows: controller.comparedReports.asMap().entries.map((entry) {
            final index = entry.key;
            final report = entry.value;
            return DataRow(
              color: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  return index.isEven ? Colors.white : Colors.grey.shade50;
                },
              ),
              cells: [
                DataCell(Text(report.wellName, style: _tableCellStyle())),
                DataCell(Text(report.operator, style: _tableCellStyle())),
                DataCell(Text(report.fieldBlock, style: _tableCellStyle())),
                DataCell(Text(report.api, style: _tableCellStyle())),
                DataCell(Text(report.rig, style: _tableCellStyle())),
                DataCell(Text(report.spudDate, style: _tableCellStyle())),
                DataCell(Text(
                  report.status,
                  style: _tableCellStyle().copyWith(
                    color: report.status == "✔" ? AppTheme.successColor : AppTheme.warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  TextStyle _tableCellStyle() {
    return AppTheme.caption.copyWith(
      color: AppTheme.textPrimary,
    );
  }

  // ---------------- BOTTOM BUTTONS ----------------
  Widget _bottomButtons() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Obx(() => ElevatedButton.icon(
                onPressed: controller.comparedReports.isEmpty
                    ? null
                    : () {
                        if (controller.comparedReports.isNotEmpty) {
                          controller.deleteComparedReport(
                              controller.comparedReports.last);
                        }
                      },
                icon: Icon(Icons.delete_outline, size: 16),
                label: Text("Delete Last"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              )),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.compare_arrows, size: 16),
            label: Text("Compare Wells"),
            style: AppTheme.primaryButtonStyle,
          ),
        ],
      ),
    );
  }
}

// ---------------- TABLE HEADER CELL ----------------
class _TableHeaderCell extends StatelessWidget {
  final String text;
  const _TableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        text,
        style: AppTheme.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}